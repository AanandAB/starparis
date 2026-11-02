/// Status vocabularies and the state machines that govern them.
///
/// The Worker enforces these transitions server-side. The app uses the same
/// code (via [TaskStateMachine.canTransition]) to grey out buttons, which is
/// why the tables live in `domain` rather than being duplicated.
///
/// Rule of thumb for every enum here: the [wire] value is what goes into D1,
/// JSON and the audit log. Never persist `Enum.name` — renaming a Dart value
/// would silently rewrite history.
library;

// ---------------------------------------------------------------------------
// Tasks
// ---------------------------------------------------------------------------

/// Production task states, per design §9.3.
enum TaskStatus {
  waiting('waiting'),
  available('available'),
  assigned('assigned'),
  inProgress('in_progress'),
  paused('paused'),
  done('done'),
  rework('rework'),
  cancelled('cancelled');

  const TaskStatus(this.wire);

  final String wire;

  static TaskStatus fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () => throw ArgumentError.value(wire, 'wire', 'unknown TaskStatus'),
      );

  /// States in which a task still occupies a slot on the board.
  bool get isActive => switch (this) {
        TaskStatus.done || TaskStatus.cancelled => false,
        _ => true,
      };

  /// States in which the task belongs to a named person.
  bool get isAssigned =>
      this == TaskStatus.assigned ||
      this == TaskStatus.inProgress ||
      this == TaskStatus.paused ||
      this == TaskStatus.rework;
}

/// One legal move between two task states.
///
/// [requiresReason] is enforced on the device (the UI refuses to submit) and on
/// the server (a mutation without a reason is rejected), because a pause or a
/// rework with no explanation is exactly what a manager needs to read later.
final class TaskTransition {
  const TaskTransition(
    this.from,
    this.to, {
    this.requiresReason = false,
    this.managerOnly = false,
  });

  final TaskStatus from;
  final TaskStatus to;
  final bool requiresReason;
  final bool managerOnly;
}

const List<TaskTransition> _taskTransitions = <TaskTransition>[
  TaskTransition(TaskStatus.waiting, TaskStatus.available),
  TaskTransition(TaskStatus.waiting, TaskStatus.cancelled, managerOnly: true),
  TaskTransition(TaskStatus.available, TaskStatus.assigned),
  TaskTransition(TaskStatus.available, TaskStatus.cancelled, managerOnly: true),
  TaskTransition(TaskStatus.assigned, TaskStatus.inProgress),
  TaskTransition(TaskStatus.assigned, TaskStatus.available), // released back to the pool
  TaskTransition(TaskStatus.assigned, TaskStatus.cancelled, managerOnly: true),
  TaskTransition(TaskStatus.inProgress, TaskStatus.paused, requiresReason: true),
  TaskTransition(TaskStatus.inProgress, TaskStatus.done),
  TaskTransition(TaskStatus.inProgress, TaskStatus.rework, requiresReason: true),
  TaskTransition(TaskStatus.inProgress, TaskStatus.cancelled, managerOnly: true),
  TaskTransition(TaskStatus.paused, TaskStatus.inProgress),
  TaskTransition(TaskStatus.paused, TaskStatus.rework, requiresReason: true),
  TaskTransition(TaskStatus.paused, TaskStatus.cancelled, managerOnly: true),
  // A manager may reopen a finished task (customer changed their mind);
  // that is a rework, never a silent edit.
  TaskTransition(TaskStatus.done, TaskStatus.rework, requiresReason: true,
      managerOnly: true),
  TaskTransition(TaskStatus.rework, TaskStatus.inProgress),
  TaskTransition(TaskStatus.rework, TaskStatus.cancelled, managerOnly: true),
];

final class TaskStateMachine {
  const TaskStateMachine._();

  static TaskTransition? transition(TaskStatus from, TaskStatus to) {
    for (final candidate in _taskTransitions) {
      if (candidate.from == from && candidate.to == to) {
        return candidate;
      }
    }
    return null;
  }

  static bool canTransition(TaskStatus from, TaskStatus to) =>
      transition(from, to) != null;

  /// Throws unless the move is legal. Callers on the server translate the
  /// exception into a `STATE_INVALID` mutation result.
  static void assertTransition(TaskStatus from, TaskStatus to) {
    if (!canTransition(from, to)) {
      throw StateError('Illegal task transition: ${from.wire} -> ${to.wire}');
    }
  }

  static bool requiresReason(TaskStatus from, TaskStatus to) =>
      transition(from, to)?.requiresReason ?? false;

  static bool isManagerOnly(TaskStatus from, TaskStatus to) =>
      transition(from, to)?.managerOnly ?? false;

  /// Every state reachable from [from] — used to render the status menu without
  /// duplicating the table in the UI layer.
  static List<TaskStatus> nextStates(TaskStatus from) => <TaskStatus>[
        for (final t in _taskTransitions)
          if (t.from == from) t.to,
      ];
}

// ---------------------------------------------------------------------------
// Orders and items
// ---------------------------------------------------------------------------

enum ItemStatus {
  pending('pending'),
  inProduction('in_production'),
  ready('ready'),
  delivered('delivered'),
  cancelled('cancelled');

  const ItemStatus(this.wire);

  final String wire;

  static ItemStatus fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () => throw ArgumentError.value(wire, 'wire', 'unknown ItemStatus'),
      );
}

/// Order state. Never set by hand: it is always derived from the items, so an
/// order cannot claim to be Ready while one banner is still on the press.
enum OrderStatus {
  draft('draft'),
  confirmed('confirmed'),
  inProduction('in_production'),
  ready('ready'),
  partiallyDelivered('partially_delivered'),
  delivered('delivered'),
  collected('collected'),
  cancelled('cancelled'),
  closed('closed');

  const OrderStatus(this.wire);

  final String wire;

  static OrderStatus fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () => throw ArgumentError.value(wire, 'wire', 'unknown OrderStatus'),
      );

  /// The six states a customer is allowed to see (design §8.3).
  CustomerFacingStatus get customerView => switch (this) {
        OrderStatus.draft || OrderStatus.confirmed => CustomerFacingStatus.received,
        OrderStatus.cancelled => CustomerFacingStatus.cancelled,
        OrderStatus.inProduction => CustomerFacingStatus.inProduction,
        OrderStatus.ready => CustomerFacingStatus.ready,
        OrderStatus.partiallyDelivered ||
        OrderStatus.delivered ||
        OrderStatus.collected ||
        OrderStatus.closed =>
          CustomerFacingStatus.delivered,
      };
}

enum CustomerFacingStatus {
  received('received'),
  inDesign('in_design'),
  awaitingApproval('awaiting_approval'),
  inProduction('in_production'),
  ready('ready'),
  delivered('delivered'),
  cancelled('cancelled');

  const CustomerFacingStatus(this.wire);

  final String wire;
}

/// Derives the order status from its items. Pure, total, and tested against
/// every combination the production floor can actually produce.
OrderStatus deriveOrderStatus(Iterable<ItemStatus> items) {
  final list = items.toList(growable: false);
  if (list.isEmpty) {
    return OrderStatus.draft;
  }
  if (list.every((s) => s == ItemStatus.cancelled)) {
    return OrderStatus.cancelled;
  }
  final live = list.where((s) => s != ItemStatus.cancelled).toList(growable: false);
  if (live.every((s) => s == ItemStatus.delivered)) {
    return OrderStatus.delivered;
  }
  if (live.any((s) => s == ItemStatus.delivered)) {
    return OrderStatus.partiallyDelivered;
  }
  if (live.every((s) => s == ItemStatus.ready)) {
    return OrderStatus.ready;
  }
  if (live.any((s) => s == ItemStatus.inProduction)) {
    return OrderStatus.inProduction;
  }
  return OrderStatus.confirmed;
}

// ---------------------------------------------------------------------------
// Quotes, invoices, vendor jobs
// ---------------------------------------------------------------------------

enum QuoteStatus {
  draft('draft'),
  sent('sent'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired'),
  converted('converted');

  const QuoteStatus(this.wire);

  final String wire;

  /// A quote that has left the building is locked: changes create a revision.
  bool get isLocked => this == QuoteStatus.sent || this == QuoteStatus.accepted;
}

enum InvoiceStatus {
  draft('draft'),
  issued('issued'),
  partiallyPaid('partially_paid'),
  paid('paid'),
  voided('void');

  const InvoiceStatus(this.wire);

  final String wire;

  /// An issued invoice is immutable; corrections go through a credit note.
  bool get isImmutable => this != InvoiceStatus.draft;
}

enum InvoiceType {
  taxInvoice('tax_invoice'),
  simplifiedTaxInvoice('simplified_tax_invoice'),
  proforma('proforma'),
  creditNote('credit_note'),
  deliveryNote('delivery_note');

  const InvoiceType(this.wire);

  final String wire;
}

enum PaymentMethod {
  cash('cash'),
  card('card'),
  bankTransfer('bank_transfer'),
  cheque('cheque'),
  credit('credit');

  const PaymentMethod(this.wire);

  final String wire;
}

enum VendorJobStatus {
  toBrief('to_brief'),
  sent('sent'),
  inProduction('in_production'),
  received('received'),
  qc('qc'),
  ready('ready'),
  cancelled('cancelled');

  const VendorJobStatus(this.wire);

  final String wire;
}

enum Priority {
  normal('normal'),
  urgent('urgent'),
  rush('rush');

  const Priority(this.wire);

  final String wire;

  /// Rush percentages are data in the price book, not constants in code; this
  /// is only the ordering used for sorting and for "is this expensive?".
  int get rank => index;
}
