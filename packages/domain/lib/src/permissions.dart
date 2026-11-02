/// Permissions, scopes and the default role matrix.
///
/// A permission is a `resource.action` pair plus a **scope** that says how far
/// it reaches: your own work, your team's, your branch's, or the whole tenant.
/// The Worker holds the authoritative copy of this policy in TypeScript; the
/// tables here and there are kept identical by
/// `shared_test_vectors/permissions/default_roles.json`, which both sides test
/// against.
///
/// Field-level permissions are real: without [Permission.costView] the Worker
/// strips cost and margin fields from every response *before serialisation*.
/// Hiding them in the UI only would be security theatre.
library;

/// How far a permission reaches. Ordered: `own < team < branch < all`.
enum Scope {
  own(0),
  team(1),
  branch(2),
  all(3);

  const Scope(this.rank);

  final int rank;

  /// True when this scope is at least as wide as [required].
  bool covers(Scope required) => rank >= required.rank;

  static Scope fromWire(String wire) => values.firstWhere(
        (value) => value.name == wire,
        orElse: () => throw ArgumentError.value(wire, 'wire', 'unknown Scope'),
      );
}

/// Every capability the system checks. Keep the wire keys stable: they are
/// written into `role_permissions` and into the audit log.
enum Permission {
  orderView('order.view'),
  orderCreate('order.create'),
  quoteCreate('quote.create'),
  priceEdit('price.edit'),
  costView('cost.view'),
  discountApply('discount.apply'),
  invoiceIssue('invoice.issue'),
  creditNoteIssue('credit.note.issue'),
  paymentTake('payment.take'),
  taskAssign('task.assign'),
  taskUpdate('task.update'),
  vendorManage('vendor.manage'),
  userManage('user.manage'),
  reportView('report.view'),
  auditView('audit.view'),
  settingsManage('settings.manage'),
  exportData('export.data');

  const Permission(this.wire);

  final String wire;

  static Permission fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () => throw ArgumentError.value(wire, 'wire', 'unknown Permission'),
      );
}

/// Built-in roles. The owner may add more; a custom role is a row in `roles`
/// plus rows in `role_permissions`, and resolves through the same [UserContext].
enum Role {
  owner('owner'),
  manager('manager'),
  counter('counter'),
  designer('designer'),
  operator('operator'),
  accountant('accountant'),
  vendorCoordinator('vendor_coordinator'),
  driver('driver');

  const Role(this.wire);

  final String wire;

  static Role fromWire(String wire) => values.firstWhere(
        (value) => value.wire == wire,
        orElse: () => throw ArgumentError.value(wire, 'wire', 'unknown Role'),
      );
}

const Map<Permission, Scope> _owner = <Permission, Scope>{
  Permission.orderView: Scope.all,
  Permission.orderCreate: Scope.all,
  Permission.quoteCreate: Scope.all,
  Permission.priceEdit: Scope.all,
  Permission.costView: Scope.all,
  Permission.discountApply: Scope.all,
  Permission.invoiceIssue: Scope.all,
  Permission.creditNoteIssue: Scope.all,
  Permission.paymentTake: Scope.all,
  Permission.taskAssign: Scope.all,
  Permission.taskUpdate: Scope.all,
  Permission.vendorManage: Scope.all,
  Permission.userManage: Scope.all,
  Permission.reportView: Scope.all,
  Permission.auditView: Scope.all,
  Permission.settingsManage: Scope.all,
  Permission.exportData: Scope.all,
};

const Map<Permission, Scope> _manager = <Permission, Scope>{
  Permission.orderView: Scope.branch,
  Permission.orderCreate: Scope.branch,
  Permission.quoteCreate: Scope.branch,
  Permission.costView: Scope.branch,
  Permission.discountApply: Scope.branch,
  Permission.invoiceIssue: Scope.branch,
  Permission.creditNoteIssue: Scope.branch,
  Permission.paymentTake: Scope.branch,
  Permission.taskAssign: Scope.branch,
  Permission.taskUpdate: Scope.branch,
  Permission.vendorManage: Scope.branch,
  Permission.reportView: Scope.branch,
  Permission.auditView: Scope.branch,
  Permission.exportData: Scope.branch,
};

const Map<Permission, Scope> _counter = <Permission, Scope>{
  Permission.orderView: Scope.branch,
  Permission.orderCreate: Scope.branch,
  Permission.quoteCreate: Scope.branch,
  Permission.discountApply: Scope.own,
  Permission.invoiceIssue: Scope.branch,
  Permission.paymentTake: Scope.branch,
  Permission.exportData: Scope.own,
};

const Map<Permission, Scope> _designer = <Permission, Scope>{
  Permission.orderView: Scope.own,
  Permission.taskUpdate: Scope.own,
};

const Map<Permission, Scope> _operator = <Permission, Scope>{
  Permission.orderView: Scope.own,
  Permission.taskUpdate: Scope.own,
};

const Map<Permission, Scope> _accountant = <Permission, Scope>{
  Permission.orderView: Scope.all,
  Permission.costView: Scope.all,
  Permission.invoiceIssue: Scope.all,
  Permission.creditNoteIssue: Scope.all,
  Permission.paymentTake: Scope.all,
  Permission.reportView: Scope.all,
  Permission.exportData: Scope.all,
  Permission.auditView: Scope.all,
};

const Map<Permission, Scope> _vendorCoordinator = <Permission, Scope>{
  Permission.orderView: Scope.branch,
  Permission.costView: Scope.branch,
  Permission.vendorManage: Scope.branch,
  Permission.taskUpdate: Scope.branch,
  Permission.reportView: Scope.own,
};

const Map<Permission, Scope> _driver = <Permission, Scope>{
  Permission.orderView: Scope.own,
  Permission.paymentTake: Scope.own,
  Permission.taskUpdate: Scope.own,
};

/// The design's §14.2 matrix, as code. `null` means "no access at all".
const Map<Role, Map<Permission, Scope>> defaultRolePermissions =
    <Role, Map<Permission, Scope>>{
  Role.owner: _owner,
  Role.manager: _manager,
  Role.counter: _counter,
  Role.designer: _designer,
  Role.operator: _operator,
  Role.accountant: _accountant,
  Role.vendorCoordinator: _vendorCoordinator,
  Role.driver: _driver,
};

/// The signed-in user, as the policy layer needs them. Constructed once per
/// request on the server from the JWT plus the (cached) role row; constructed
/// from the cached session on the device.
final class UserContext {
  const UserContext({
    required this.userId,
    required this.tenantId,
    required this.role,
    this.branchId,
    this.teamUserIds = const <String>{},
    this.extraGrants = const <Permission, Scope>{},
  });

  final String userId;
  final String tenantId;
  final Role role;
  final String? branchId;

  /// Everyone this user leads, including themselves. Used by [Scope.team].
  final Set<String> teamUserIds;

  /// Per-user grants that widen the role's defaults. Narrowing is done by
  /// removing the default in `role_permissions`, not by adding a negative here:
  /// two mechanisms that can contradict each other is how permission bugs are
  /// born.
  final Map<Permission, Scope> extraGrants;

  /// The widest scope this user has for [permission], or `null` for none.
  Scope? scopeFor(Permission permission) {
    final extra = extraGrants[permission];
    final base = defaultRolePermissions[role]?[permission];
    if (extra == null) {
      return base;
    }
    if (base == null) {
      return extra;
    }
    return extra.rank > base.rank ? extra : base;
  }

  /// Coarse check for route guards: "may this user do X at all, at [at] scope?"
  bool can(Permission permission, {Scope at = Scope.own}) {
    final scope = scopeFor(permission);
    return scope != null && scope.covers(at);
  }

  /// Row-level check used by the sync engine and the Worker, where the answer
  /// depends on the row, not just the permission.
  ///
  /// [branchId] is the row's branch (null for org-level rows), [assigneeId] the
  /// person the work is assigned to, [ownerId] the person who created it.
  bool permits(
    Permission permission, {
    String? branchId,
    String? assigneeId,
    String? ownerId,
  }) {
    final scope = scopeFor(permission);
    if (scope == null) {
      return false;
    }
    return switch (scope) {
      Scope.all => true,
      Scope.branch => branchId == null || branchId == this.branchId,
      Scope.team => assigneeId != null
          ? teamUserIds.contains(assigneeId)
          : ownerId != null
              ? teamUserIds.contains(ownerId)
              : branchId == this.branchId,
      Scope.own => assigneeId == userId || ownerId == userId,
    };
  }

  /// True when cost, margin and vendor-price fields must be stripped from
  /// anything sent to this user.
  bool get mustRedactCosts => !can(Permission.costView);
}
