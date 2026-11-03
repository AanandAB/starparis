/**
 * The audit trail, read back.
 *
 * `audit_log` is append-only: every sign-in, every wrong password and every
 * price edit lands there and nothing rewrites it. That is what lets the login
 * lockout count failures without owning a counter of its own, and what makes
 * this file's output evidence rather than a report.
 *
 * Three rules shape it.
 *
 * 1. The tenant is never a parameter. It comes from the signed token and
 *    nowhere else, because a viewer that can be talked into reading another
 *    shop's history is worse than no viewer at all.
 * 2. There is always a cap. A log only grows, and "show me everything" is one
 *    day a year of rows pushed to a tablet on a weak connection.
 * 3. The trail is the shop's, not the branch's. A manager asking who changed a
 *    price needs the answer even when the answer is the other branch; the VAT
 *    report takes a branch cut, history does not.
 */
import { can, type RoleKey } from './policy';
import type { AuthContext, Env } from './types';

/** Enough to fill a screen; the default when the caller does not say. */
export const AUDIT_DEFAULT_LIMIT = 100;

/** The most one response will ever carry, whatever the caller asks for. */
export const AUDIT_MAX_LIMIT = 500;

export interface AuditEntry {
  id: string;
  at: string;
  actor_id: string;
  actor_name: string | null;
  device_id: string | null;
  action: string;
  entity: string | null;
  row_id: string | null;
}

export interface AuditQuery {
  /** Exact action code, e.g. `auth.login_failed`. */
  action?: string | null;
  /** Inclusive lower bound, ISO-8601 UTC — the same shape `at` is written in. */
  from?: string | null;
  /** Inclusive upper bound, ISO-8601 UTC. */
  to?: string | null;
  /** Raw query-string value; parsed and clamped below. */
  limit?: string | number | null;
}

/**
 * `report.view` is the gate the endpoint's callers already have to hold: the
 * owner, a manager and the accountant. Asking for a separate flag here would
 * create a second place to get the permission matrix wrong.
 */
export function canReadAudit(role: string): boolean {
  return can(role as RoleKey, 'report.view');
}

/**
 * The newest entries first, filtered and capped.
 *
 * Returned in the endpoint's own body shape so there is no second shape for a
 * caller to translate: the route hands this straight to `c.json`.
 */
export async function listAudit(
  env: Env,
  ctx: AuthContext,
  query: AuditQuery = {},
): Promise<{ entries: AuditEntry[] }> {
  // Defence in depth. The route answers 403 before reaching here, but a future
  // caller that forgets to check must get nothing rather than the shop's
  // history — an empty list is a "no", not an error to be swallowed.
  if (!canReadAudit(ctx.role)) return { entries: [] };

  const where: string[] = ['a.tenant_id = ?'];
  const binds: unknown[] = [ctx.tenantId];

  const action = (query.action ?? '').trim();
  if (action) {
    // Exact match, not a prefix: `?action=auth.login` must not quietly include
    // the failed attempts, which are the rows a manager is usually hunting.
    where.push('a.action = ?');
    binds.push(action);
  }

  // `at` is always written as an ISO-8601 UTC string, so plain string
  // comparison is chronological. Parsing into dates here would only add a way
  // to get the comparison wrong.
  if (query.from) {
    where.push('a.at >= ?');
    binds.push(query.from);
  }
  if (query.to) {
    where.push('a.at <= ?');
    binds.push(query.to);
  }

  // Bound last so the placeholder order matches the SELECT text exactly.
  binds.push(normaliseLimit(query.limit));

  // LEFT JOIN on purpose: an actor whose user row was deleted still acted, and
  // dropping the entry would leave a hole in the story. `actor_name` is then
  // null and the app shows the id instead.
  const { results } = await env.DB.prepare(
    `SELECT a.id, a.at, a.actor_id, u.name AS actor_name, a.device_id,
            a.action, a.entity, a.row_id
       FROM audit_log a
       LEFT JOIN users u ON u.id = a.actor_id AND u.tenant_id = a.tenant_id
      WHERE ${where.join(' AND ')}
      ORDER BY a.at DESC, a.rowid DESC
      LIMIT ?`,
  )
    .bind(...binds)
    .all<AuditEntry>();

  return { entries: results ?? [] };
}

/**
 * The asked-for limit, made safe.
 *
 * A missing, negative or unparseable value is not an error worth a 400 — a
 * viewer that renders nothing is a worse answer than a page of entries — so it
 * falls back to the default instead of failing the request.
 */
function normaliseLimit(raw: AuditQuery['limit']): number {
  const asked = typeof raw === 'number' ? raw : Number(raw ?? Number.NaN);
  if (!Number.isFinite(asked) || asked <= 0) return AUDIT_DEFAULT_LIMIT;
  return Math.min(Math.trunc(asked), AUDIT_MAX_LIMIT);
}
