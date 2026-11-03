/**
 * The conflicts inbox.
 *
 * §5.6 says anything the server cannot merge automatically goes to a manager,
 * with both versions side by side, and §5.10 gives the sync chip a red "Needs
 * attention" state that opens it. The table and the writes have existed since
 * day one; until now nothing could read them, which made the red state
 * unreachable and the table dead weight. This closes that loop.
 *
 * Design notes:
 *  - Read-only apart from the status. Resolving a conflict never silently picks
 *    a winner: the manager reads both versions and decides, then the record says
 *    who decided and when.
 *  - Tenant-scoped. A conflict is shop business, not branch business, and the
 *    row has no branch column to scope by — saying so beats pretending.
 *  - Resolving needs authority over someone else's work, so it rides on the same
 *    permission that lets a manager assign tasks.
 */

import type { AuthContext, Env } from './types';
import { can, type RoleKey } from './policy';

export interface ConflictRow {
  id: string;
  entity: string;
  row_id: string;
  device_id: string;
  mutation_id: string;
  fields_json: string;
  local_json: string;
  server_json: string;
  status: string;
  created_at: string;
  resolved_by: string | null;
  resolved_at: string | null;
}

export interface ConflictSummary {
  id: string;
  entity: string;
  row_id: string;
  device_id: string;
  mutation_id: string;
  fields: string[];
  local: Record<string, unknown>;
  server: Record<string, unknown>;
  status: string;
  created_at: string;
  resolved_by: string | null;
  resolved_at: string | null;
}

function parse(json: string): Record<string, unknown> {
  try {
    const value = JSON.parse(json) as unknown;
    return value && typeof value === 'object' ? (value as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

function summarise(row: ConflictRow): ConflictSummary {
  let fields: string[] = [];
  try {
    const parsed = JSON.parse(row.fields_json) as unknown;
    if (Array.isArray(parsed)) fields = parsed.map((field) => String(field));
  } catch {
    fields = [];
  }

  return {
    id: row.id,
    entity: row.entity,
    row_id: row.row_id,
    device_id: row.device_id,
    mutation_id: row.mutation_id,
    fields,
    local: parse(row.local_json),
    server: parse(row.server_json),
    status: row.status,
    created_at: row.created_at,
    resolved_by: row.resolved_by,
    resolved_at: row.resolved_at,
  };
}

function refuseUnlessAuthorised(role: RoleKey): { code: string; message: string } | null {
  if (can(role, 'task.assign')) return null;
  return {
    code: 'FORBIDDEN',
    message: 'Only a manager or the owner can open the conflicts inbox.',
  };
}

export async function listConflicts(
  env: Env,
  ctx: AuthContext,
  options: { status?: string } = {},
): Promise<ConflictSummary[]> {
  const status = options.status === 'all' ? null : (options.status ?? 'open');

  const statement = status
    ? env.DB.prepare(
        `SELECT * FROM conflicts
          WHERE tenant_id = ? AND status = ?
          ORDER BY created_at ASC
          LIMIT 200`,
      ).bind(ctx.tenantId, status)
    : env.DB.prepare(
        `SELECT * FROM conflicts
          WHERE tenant_id = ?
          ORDER BY created_at DESC
          LIMIT 200`,
      ).bind(ctx.tenantId);

  const { results } = await statement.all<ConflictRow>();
  return (results ?? []).map(summarise);
}

export type ResolveOutcome =
  | { ok: true; conflict: ConflictSummary }
  | { ok: false; status: number; code: string; message: string };

/**
 * Closes a conflict. Two outcomes only: `resolved` (someone decided something)
 * and `dismissed` (it did not matter). There is deliberately no "delete" — a
 * conflict is evidence that two devices disagreed, and evidence is kept.
 */
export async function resolveConflict(
  env: Env,
  ctx: AuthContext,
  id: string,
  status: 'resolved' | 'dismissed',
): Promise<ResolveOutcome> {
  const denied = refuseUnlessAuthorised(ctx.role as RoleKey);
  if (denied) return { ok: false, status: 403, ...denied };

  const existing = await env.DB.prepare(
    'SELECT * FROM conflicts WHERE id = ? AND tenant_id = ? LIMIT 1',
  )
    .bind(id, ctx.tenantId)
    .first<ConflictRow>();

  if (!existing) {
    return { ok: false, status: 404, code: 'NOT_FOUND', message: 'That conflict does not exist.' };
  }
  if (existing.status !== 'open') {
    return {
      ok: false,
      status: 409,
      code: 'ALREADY_CLOSED',
      message: `That conflict was already ${existing.status}.`,
    };
  }

  const at = new Date().toISOString();
  await env.DB.prepare(
    'UPDATE conflicts SET status = ?, resolved_by = ?, resolved_at = ? WHERE id = ? AND tenant_id = ?',
  )
    .bind(status, ctx.userId, at, id, ctx.tenantId)
    .run();

  return {
    ok: true,
    conflict: summarise({
      ...existing,
      status,
      resolved_by: ctx.userId,
      resolved_at: at,
    }),
  };
}

export function conflictForbidden(role: RoleKey): boolean {
  return refuseUnlessAuthorised(role) !== null;
}
