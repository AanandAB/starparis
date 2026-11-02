/**
 * The permission matrix, mirroring `packages/domain/lib/src/permissions.dart`.
 *
 * Two copies of a security policy is a smell, so the copies are held identical
 * by tests on both sides: the Dart suite asserts the same role/scope pairs this
 * file declares, and `shared_test_vectors/permissions/default_roles.json` is
 * the file both read. If they ever disagree, CI fails instead of a designer
 * seeing cost prices.
 *
 * The Worker is the enforcement point: the app hides what a user cannot do, but
 * a patched client cannot bypass anything here.
 */

export type Scope = 'own' | 'team' | 'branch' | 'all';

export const SCOPE_RANK: Record<Scope, number> = {
  own: 0,
  team: 1,
  branch: 2,
  all: 3,
};

export type Permission =
  | 'order.view'
  | 'order.create'
  | 'quote.create'
  | 'price.edit'
  | 'cost.view'
  | 'discount.apply'
  | 'invoice.issue'
  | 'credit.note.issue'
  | 'payment.take'
  | 'task.assign'
  | 'task.update'
  | 'vendor.manage'
  | 'user.manage'
  | 'report.view'
  | 'audit.view'
  | 'settings.manage'
  | 'export.data';

export type RoleKey =
  | 'owner'
  | 'manager'
  | 'counter'
  | 'designer'
  | 'operator'
  | 'accountant'
  | 'vendor_coordinator'
  | 'driver';

type Matrix = Record<RoleKey, Partial<Record<Permission, Scope>>>;

export const DEFAULT_ROLE_PERMISSIONS: Matrix = {
  owner: {
    'order.view': 'all',
    'order.create': 'all',
    'quote.create': 'all',
    'price.edit': 'all',
    'cost.view': 'all',
    'discount.apply': 'all',
    'invoice.issue': 'all',
    'credit.note.issue': 'all',
    'payment.take': 'all',
    'task.assign': 'all',
    'task.update': 'all',
    'vendor.manage': 'all',
    'user.manage': 'all',
    'report.view': 'all',
    'audit.view': 'all',
    'settings.manage': 'all',
    'export.data': 'all',
  },
  manager: {
    'order.view': 'branch',
    'order.create': 'branch',
    'quote.create': 'branch',
    'cost.view': 'branch',
    'discount.apply': 'branch',
    'invoice.issue': 'branch',
    'credit.note.issue': 'branch',
    'payment.take': 'branch',
    'task.assign': 'branch',
    'task.update': 'branch',
    'vendor.manage': 'branch',
    'report.view': 'branch',
    'audit.view': 'branch',
    'export.data': 'branch',
  },
  counter: {
    'order.view': 'branch',
    'order.create': 'branch',
    'quote.create': 'branch',
    'discount.apply': 'own',
    'invoice.issue': 'branch',
    'payment.take': 'branch',
    'export.data': 'own',
  },
  designer: {
    'order.view': 'own',
    'task.update': 'own',
  },
  operator: {
    'order.view': 'own',
    'task.update': 'own',
  },
  accountant: {
    'order.view': 'all',
    'cost.view': 'all',
    'invoice.issue': 'all',
    'credit.note.issue': 'all',
    'payment.take': 'all',
    'report.view': 'all',
    'export.data': 'all',
    'audit.view': 'all',
  },
  vendor_coordinator: {
    'order.view': 'branch',
    'cost.view': 'branch',
    'vendor.manage': 'branch',
    'task.update': 'branch',
    'report.view': 'own',
  },
  driver: {
    'order.view': 'own',
    'payment.take': 'own',
    'task.update': 'own',
  },
};

export function scopeFor(role: RoleKey, permission: Permission): Scope | null {
  return DEFAULT_ROLE_PERMISSIONS[role]?.[permission] ?? null;
}

export function can(
  role: RoleKey,
  permission: Permission,
  at: Scope = 'own',
): boolean {
  const scope = scopeFor(role, permission);
  if (scope === null) return false;
  return SCOPE_RANK[scope] >= SCOPE_RANK[at];
}

/** Row-level check: the answer depends on the row, not just the permission. */
export function permits(
  ctx: { role: RoleKey; userId: string; branchId: string | null },
  permission: Permission,
  row: { branchId?: string | null; assigneeId?: string | null; ownerId?: string | null },
): boolean {
  const scope = scopeFor(ctx.role, permission);
  if (scope === null) return false;
  switch (scope) {
    case 'all':
      return true;
    case 'branch':
      return row.branchId === undefined || row.branchId === null || row.branchId === ctx.branchId;
    case 'team':
      return row.branchId === null || row.branchId === undefined || row.branchId === ctx.branchId;
    case 'own':
      return row.assigneeId === ctx.userId || row.ownerId === ctx.userId;
  }
}

/**
 * Fields that must never reach a user without `cost.view` — stripped on the
 * way out, not hidden in the UI. A modified client gets nothing to hide.
 */
export const COST_FIELDS: ReadonlySet<string> = new Set([
  'cost_fils',
  'unit_cost_fils',
  'cost_subtotal_fils',
  'vendor_cost_fils',
  'vendor_rate_fils',
  'margin_bps',
  'markup_bps',
  'commission_fils',
]);

export function redactCosts(
  row: Record<string, unknown>,
  canSeeCosts: boolean,
): Record<string, unknown> {
  if (canSeeCosts) return row;
  const copy: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(row)) {
    if (!COST_FIELDS.has(key)) copy[key] = value;
  }
  return copy;
}
