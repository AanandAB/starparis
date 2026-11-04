import type { Env } from './types';

/**
 * Platform admin: the vendor's own cross-tenant view.
 *
 * Tenants are isolated — a shop can never read another shop's data. This layer
 * is the deliberate exception: a single token (held only by the vendor, in a
 * Worker secret) unlocks a READ-ONLY view over every tenant, plus the server
 * error log. It is read-only by design — the vendor diagnoses here; a fix is a
 * code change, never a data write through this surface.
 */

export interface TenantSummary {
  id: string;
  name: string;
  trn: string | null;
  created_at: string;
  user_count: number;
  order_count: number;
  branch_count: number;
  last_activity: string | null;
}

type RequestLike = { req: { header: (name: string) => string | undefined } };

/// A platform token must be long enough to be unguessable and present at all.
/// Anything shorter than 16 chars (including an unset secret) is refused.
export function requirePlatform(env: Env, c: RequestLike): boolean {
  const token = c.req.header('x-platform-token') ?? '';
  const expected = env.PLATFORM_TOKEN ?? '';
  return expected.length >= 16 && token === expected;
}

export async function listTenants(env: Env): Promise<TenantSummary[]> {
  const { results } = await env.DB.prepare(
    `SELECT t.id, t.name, t.trn, t.created_at,
            (SELECT COUNT(*) FROM users u
              WHERE u.tenant_id = t.id AND u.deleted_at IS NULL) AS user_count,
            (SELECT COUNT(*) FROM orders o
              WHERE o.tenant_id = t.id AND o.deleted_at IS NULL) AS order_count,
            (SELECT COUNT(*) FROM branches b WHERE b.tenant_id = t.id) AS branch_count,
            (SELECT MAX(a.at) FROM audit_log a WHERE a.tenant_id = t.id) AS last_activity
       FROM tenants t
      ORDER BY t.created_at DESC`,
  ).all<TenantSummary>();
  return results ?? [];
}

export async function tenantAudit(
  env: Env,
  tenantId: string,
  limit: number,
): Promise<Record<string, unknown>[]> {
  const { results } = await env.DB.prepare(
    `SELECT id, actor_id, action, entity, row_id, at
       FROM audit_log WHERE tenant_id = ? ORDER BY at DESC LIMIT ?`,
  )
    .bind(tenantId, limit)
    .all<Record<string, unknown>>();
  return results ?? [];
}

export async function listPlatformErrors(
  env: Env,
  tenantId: string | null,
  limit: number,
): Promise<Record<string, unknown>[]> {
  const { results } = tenantId
    ? await env.DB.prepare(
        'SELECT * FROM platform_errors WHERE tenant_id = ? ORDER BY created_at DESC LIMIT ?',
      )
        .bind(tenantId, limit)
        .all<Record<string, unknown>>()
    : await env.DB.prepare(
        'SELECT * FROM platform_errors ORDER BY created_at DESC LIMIT ?',
      )
        .bind(limit)
        .all<Record<string, unknown>>();
  return results ?? [];
}

/// Records one server error. Best effort: a logging failure must never take
/// down the request it is logging, so callers fire-and-forget this.
export async function recordPlatformError(
  env: Env,
  input: {
    tenantId?: string | null;
    source?: string;
    code: string;
    message: string;
    context?: unknown;
  },
): Promise<void> {
  await env.DB.prepare(
    `INSERT INTO platform_errors (id, tenant_id, source, code, message, context_json, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      crypto.randomUUID(),
      input.tenantId ?? null,
      input.source ?? 'worker',
      input.code,
      input.message,
      input.context === undefined ? null : JSON.stringify(input.context),
      new Date().toISOString(),
    )
    .run();
}
