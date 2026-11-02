import 'package:starparis_domain/starparis_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Fils', () {
    test('parses whole and fractional amounts exactly', () {
      expect(Fils.parse('122').raw, 12200);
      expect(Fils.parse('122.5').raw, 12250);
      expect(Fils.parse('122.05').raw, 12205);
      expect(Fils.parse('-3.25').raw, -325);
      expect(Fils.parse(' 7.00 ').raw, 700);
    });

    test('rejects anything that is not a plain money value', () {
      for (final bad in <String>['', 'AED 12', '12,000', '1.234', 'abc', '.5', '1e3']) {
        expect(() => Fils.parse(bad), throwsA(isA<FormatException>()),
            reason: 'should reject "$bad"');
      }
    });

    test('added amounts stay exact where doubles would drift', () {
      var total = Fils.zero;
      for (var i = 0; i < 1000; i++) {
        total += Fils.parse('0.10');
      }
      expect(total.raw, 10000);
      expect(total.aedText, '100.00');
    });

    test('applies basis-point rates with half-up rounding', () {
      // 5% VAT on AED 122.00 = AED 6.10 exactly.
      expect(const Fils(12200).timesBps(500).raw, 610);
      // 65% markup on AED 73.80 = AED 47.97 — the markup itself rounds down.
      expect(const Fils(7380).timesBps(6500).raw, 4797);
      // …and cost + markup reproduces the document's 121.77 exactly.
      expect((const Fils(7380) + const Fils(7380).timesBps(6500)).raw, 12177);
      // 0.5 fil must round away from zero, not to even.
      expect(const Fils(1).timesBps(5000).raw, 1);
      expect(const Fils(-1).timesBps(5000).raw, -1);
    });

    test('rounds to the configured step', () {
      expect(const Fils(12177).roundToStep(100).raw, 12200); // AED 1.00 step
      expect(const Fils(12124).roundToStep(100).raw, 12100);
      expect(const Fils(12150).roundToStep(100).raw, 12200); // half rounds up
      expect(const Fils(12162).roundToStep(25).raw, 12150);
      expect(const Fils(12163).roundToStep(25).raw, 12175);
      expect(const Fils(-12150).roundToStep(100).raw, -12200);
    });

    test('splits without losing a fil', () {
      final parts = const Fils(10000).splitAcross(3);
      expect(parts.map((p) => p.raw).toList(), <int>[3334, 3333, 3333]);
      expect(parts.fold<int>(0, (sum, p) => sum + p.raw), 10000);
    });

    test('formats for documents and screens', () {
      expect(const Fils(12200).aedText, '122.00');
      expect(const Fils(12200).aedDisplay, '122.00');
      expect(const Fils(123450).aedDisplay, '1,234.50');
      expect(const Fils(123450).aedLabel, 'AED 1,234.50');
      expect(const Fils(-325).aedText, '-3.25');
      expect(Fils.zero.aedLabel, 'AED 0.00');
    });

    test('compares by value', () {
      expect(const Fils(100), const Fils(100));
      expect(const Fils(100).hashCode, const Fils(100).hashCode);
      expect(const Fils(100) > const Fils(99), isTrue);
      expect(const Fils(100) <= const Fils(100), isTrue);
    });
  });

  group('Uuid7', () {
    test('produces canonical lowercase identifiers', () {
      final id = Uuid7.generate();
      expect(Uuid7.isValid(id), isTrue, reason: id);
      expect(id.split('-').map((p) => p.length).toList(),
          <int>[8, 4, 4, 4, 12]);
      expect(id[14], '7', reason: 'version nibble');
      expect(<String>['8', '9', 'a', 'b'], contains(id[19]),
          reason: 'variant nibble');
    });

    test('is strictly increasing across many rapid calls', () {
      var previous = Uuid7.generate();
      for (var i = 0; i < 5000; i++) {
        final next = Uuid7.generate();
        expect(next.compareTo(previous), 1,
            reason: 'ids must sort by creation order: $previous then $next');
        previous = next;
      }
    });

    test('survives a clock that moves backwards', () {
      Uuid7.debugReset(millis: DateTime.now().millisecondsSinceEpoch);
      final first = Uuid7.generate();
      final second = Uuid7.generate();
      expect(second.compareTo(first), greaterThan(0));
    });

    test('encodes and recovers the creation time', () {
      final before = DateTime.now().toUtc();
      final id = Uuid7.generate();
      final stamp = Uuid7.timestampOf(id)!.toUtc();
      expect(stamp.difference(before).inSeconds.abs(), lessThan(2));
    });

    test('rejects malformed identifiers', () {
      expect(Uuid7.isValid('not-an-id'), isFalse);
      expect(Uuid7.isValid(''), isFalse);
      expect(Uuid7.timestampOf('11111111-1111-4111-8111-111111111111'), isNull,
          reason: 'v4 identifier has no embedded timestamp');
    });
  });

  group('TaskStateMachine', () {
    test('allows the happy path end to end', () {
      const path = <TaskStatus>[
        TaskStatus.waiting,
        TaskStatus.available,
        TaskStatus.assigned,
        TaskStatus.inProgress,
        TaskStatus.done,
      ];
      for (var i = 0; i < path.length - 1; i++) {
        expect(TaskStateMachine.canTransition(path[i], path[i + 1]), isTrue,
            reason: '${path[i].wire} -> ${path[i + 1].wire}');
      }
    });

    test('refuses shortcuts that skip the floor', () {
      expect(TaskStateMachine.canTransition(
          TaskStatus.waiting, TaskStatus.inProgress), isFalse);
      expect(TaskStateMachine.canTransition(
          TaskStatus.available, TaskStatus.done), isFalse);
      expect(TaskStateMachine.canTransition(
          TaskStatus.done, TaskStatus.inProgress), isFalse);
      expect(TaskStateMachine.canTransition(
          TaskStatus.cancelled, TaskStatus.available), isFalse);
    });

    test('demands a reason for pause and rework', () {
      expect(TaskStateMachine.requiresReason(
          TaskStatus.inProgress, TaskStatus.paused), isTrue);
      expect(TaskStateMachine.requiresReason(
          TaskStatus.inProgress, TaskStatus.rework), isTrue);
      expect(TaskStateMachine.requiresReason(
          TaskStatus.inProgress, TaskStatus.done), isFalse);
    });

    test('restricts cancellation and reopening to managers', () {
      expect(TaskStateMachine.isManagerOnly(
          TaskStatus.inProgress, TaskStatus.cancelled), isTrue);
      expect(TaskStateMachine.isManagerOnly(
          TaskStatus.done, TaskStatus.rework), isTrue);
      expect(TaskStateMachine.isManagerOnly(
          TaskStatus.inProgress, TaskStatus.done), isFalse);
    });

    test('assertTransition throws with a useful message', () {
      expect(
        () => TaskStateMachine.assertTransition(
            TaskStatus.waiting, TaskStatus.done),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('waiting -> done'))),
      );
    });

    test('every state except the terminals has at least one exit', () {
      for (final status in TaskStatus.values) {
        if (status == TaskStatus.cancelled) {
          continue;
        }
        expect(TaskStateMachine.nextStates(status), isNotEmpty,
            reason: '${status.wire} is a dead end');
      }
    });
  });

  group('deriveOrderStatus', () {
    test('an empty order is a draft', () {
      expect(deriveOrderStatus(const <ItemStatus>[]), OrderStatus.draft);
    });

    test('one item on the press puts the whole order in production', () {
      expect(
        deriveOrderStatus(const <ItemStatus>[
          ItemStatus.ready,
          ItemStatus.inProduction,
        ]),
        OrderStatus.inProduction,
      );
    });

    test('the order is ready only when every live item is ready', () {
      expect(
        deriveOrderStatus(const <ItemStatus>[
          ItemStatus.ready,
          ItemStatus.ready,
          ItemStatus.cancelled,
        ]),
        OrderStatus.ready,
      );
    });

    test('partial delivery is visible', () {
      expect(
        deriveOrderStatus(const <ItemStatus>[
          ItemStatus.delivered,
          ItemStatus.inProduction,
        ]),
        OrderStatus.partiallyDelivered,
      );
    });

    test('all cancelled means cancelled, not delivered', () {
      expect(
        deriveOrderStatus(const <ItemStatus>[
          ItemStatus.cancelled,
          ItemStatus.cancelled,
        ]),
        OrderStatus.cancelled,
      );
    });
  });

  group('customer-facing projection', () {
    test('never leaks internal stage detail', () {
      expect(OrderStatus.confirmed.customerView, CustomerFacingStatus.received);
      expect(OrderStatus.inProduction.customerView,
          CustomerFacingStatus.inProduction);
      expect(OrderStatus.partiallyDelivered.customerView,
          CustomerFacingStatus.delivered);
      expect(OrderStatus.closed.customerView, CustomerFacingStatus.delivered);
    });
  });

  group('permissions', () {
    const owner = UserContext(
        userId: 'u-owner', tenantId: 't1', role: Role.owner);
    const counter = UserContext(
        userId: 'u-counter', tenantId: 't1', role: Role.counter, branchId: 'b-shj');
    const designer = UserContext(
        userId: 'u-designer', tenantId: 't1', role: Role.designer,
        branchId: 'b-shj');
    const accountant = UserContext(
        userId: 'u-acc', tenantId: 't1', role: Role.accountant);

    test('owner reaches everything at every scope', () {
      for (final permission in Permission.values) {
        expect(owner.can(permission, at: Scope.all), isTrue,
            reason: permission.wire);
      }
    });

    test('a designer never sees cost or margin', () {
      expect(designer.can(Permission.costView), isFalse);
      expect(designer.mustRedactCosts, isTrue);
      expect(designer.can(Permission.taskUpdate), isTrue);
      expect(designer.can(Permission.orderCreate), isFalse);
    });

    test('the counter sells and takes money but cannot price or issue credit', () {
      expect(counter.can(Permission.orderCreate), isTrue);
      expect(counter.can(Permission.paymentTake), isTrue);
      expect(counter.can(Permission.invoiceIssue), isTrue);
      expect(counter.can(Permission.creditNoteIssue), isFalse);
      expect(counter.can(Permission.priceEdit), isFalse);
      expect(counter.can(Permission.costView), isFalse);
      expect(counter.mustRedactCosts, isTrue);
    });

    test('the accountant reads everything but never touches production', () {
      expect(accountant.can(Permission.orderView, at: Scope.all), isTrue);
      expect(accountant.can(Permission.costView), isTrue);
      expect(accountant.can(Permission.creditNoteIssue), isTrue);
      expect(accountant.can(Permission.orderCreate), isFalse);
      expect(accountant.can(Permission.taskAssign), isFalse);
    });

    test('scope is enforced per row, not just per permission', () {
      // Counter's order.view is branch-scoped.
      expect(
        counter.permits(Permission.orderView, branchId: 'b-shj'),
        isTrue,
      );
      expect(
        counter.permits(Permission.orderView, branchId: 'b-dxb'),
        isFalse,
        reason: 'a Sharjah counter clerk must not see Dubai orders',
      );
      // Designer sees only their own task.
      expect(
        designer.permits(Permission.taskUpdate, assigneeId: 'u-designer'),
        isTrue,
      );
      expect(
        designer.permits(Permission.taskUpdate, assigneeId: 'u-other'),
        isFalse,
      );
    });

    test('extra grants widen a role without rewriting it', () {
      const promoted = UserContext(
        userId: 'u-counter2',
        tenantId: 't1',
        role: Role.counter,
        branchId: 'b-shj',
        extraGrants: <Permission, Scope>{Permission.priceEdit: Scope.branch},
      );
      expect(promoted.can(Permission.priceEdit, at: Scope.branch), isTrue);
      expect(promoted.can(Permission.priceEdit, at: Scope.all), isFalse);
      // The role's other limits are untouched.
      expect(promoted.can(Permission.creditNoteIssue), isFalse);
    });

    test('scopes compare by reach', () {
      expect(Scope.branch.covers(Scope.own), isTrue);
      expect(Scope.own.covers(Scope.branch), isFalse);
      expect(Scope.all.covers(Scope.branch), isTrue);
    });
  });
}
