/**
 * The sync protocol: push, pull, head.
 *
 * Design rules this file implements (PLAN.md §6):
 *  - every mutation is idempotent, keyed by `mutation_id`, so a retry after a
 *    dropped connection is a no-op;
 *  - the server is the authority: it re-checks the caller's permission on every
 *    row, not just on the route;
 *  - a legal state machine transition is required for status fields, so a
 *    patched client cannot mark a job Done from Waiting;
 *  - unmergeable changes are recorded in `conflicts` with both versions, never
 *    silently dropped.
 *
 * Each mutation is applied in ONE D1 batch (write + change_log + idempotency
 * row), which gives per-mutation atomicity. The design's "one batch per push"
 * is a later optimisation: it needs the resulting row JSON known before the
 * write, which only holds once every entity has a deterministic projection.
 */

import type { AuthContext, Env, Mutation, MutationResult } from './types';
import { can, permits, redactCosts, type Permission, type RoleKey } from './policy';
import { cascadeStage, prepareTaskPatch, taskEventStatement } from './tasks';
import { prepareProofPatch, recordTimeEntry } from './proofs';

interface EntityDef {
  table: string;
  /** Columns a device may write. Anything else is rejected, not ignored. */
  columns: ReadonlySet<string>;
  required: readonly string[];
  permission: Permission;
  /** True when a version mismatch may be merged field-by-field. */
  mergeable: boolean;
  /** True when the row carries the caller's branch. */
  branchScoped: boolean;
  softDelete: boolean;
  /**
   * Server-owned rules for a patch: may complete or reject the fields. Used by
   * tasks for the state machine and for timestamps the client must not set.
   */
  mutate?: (input: {
    fields: Row;
    existing: Row;
    ctx: AuthContext;
  }) => { fields: Row } | { error: { code: string; message: string } };
}

export const ENTITIES: Record<string, EntityDef> = {
  customers: {
    table: 'customers',
    columns: new Set([
      'name',
      'company',
      'trn',
      'tier',
      'credit_limit_fils',
      'payment_terms_days',
      'notes',
      'whatsapp_opt_in',
      'branch_id',
    ]),
    required: ['name'],
    permission: 'order.create',
    mergeable: true,
    branchScoped: true,
    softDelete: true,
  },
  customer_phones: {
    table: 'customer_phones',
    columns: new Set(['customer_id', 'e164', 'phone_last9', 'label', 'is_primary']),
    required: ['customer_id', 'e164', 'phone_last9'],
    permission: 'order.create',
    mergeable: true,
    branchScoped: false,
    softDelete: true,
  },
  orders: {
    table: 'orders',
    columns: new Set([
      'number',
      'number_display',
      'is_quote',
      'customer_id',
      'customer_name',
      'status',
      'priority',
      'due_at',
      'delivery_method',
      'notes',
      'subtotal_fils',
      'vat_fils',
      'total_fils',
      'item_count',
      'branch_id',
    ]),
    required: ['customer_id', 'number_display'],
    permission: 'order.create',
    mergeable: false,
    branchScoped: true,
    softDelete: true,
  },
  order_items: {
    table: 'order_items',
    columns: new Set([
      'order_id',
      'product_id',
      'description',
      'options_json',
      'quantity',
      'price_book_version',
      'breakdown_json',
      'subtotal_fils',
      'vat_fils',
      'total_fils',
      'status',
    ]),
    required: ['order_id', 'product_id', 'description', 'quantity', 'breakdown_json'],
    permission: 'order.create',
    mergeable: false,
    branchScoped: true,
    softDelete: true,
  },
  tasks: {
    table: 'tasks',
    columns: new Set([
      'order_id',
      'order_item_id',
      'stage_key',
      'stage_name',
      'sequence',
      'title',
      'status',
      'assigned_to',
      'required_role',
      'qty',
      'priority',
      'due_at',
      'started_at',
      'done_at',
      'reason',
      'rework_count',
      'notes',
      'branch_id',
    ]),
    required: ['order_id', 'stage_key', 'stage_name', 'sequence', 'title', 'required_role'],
    permission: 'task.update',
    mergeable: false,
    branchScoped: true,
    softDelete: true,
    mutate: ({ fields, existing, ctx }) => prepareTaskPatch(fields, existing, ctx),
  },
  proofs: {
    table: 'proofs',
    columns: new Set([
      'order_id',
      'revision',
      'kind',
      'label',
      'url',
      'note',
      'status',
      'sent_at',
      'decided_at',
      'decided_note',
      'branch_id',
    ]),
    required: ['order_id', 'label', 'url'],
    permission: 'order.create',
    mergeable: false,
    branchScoped: true,
    softDelete: true,
    mutate: ({ fields, existing, ctx }) => prepareProofPatch(fields, existing, ctx),
  },
};

type Row = Record<string, unknown>;

function nowIso(): string {
  return new Date().toISOString();
}

function asRole(value: string): RoleKey {
  return value as RoleKey;
}

export interface PushResponse {
  head: number;
  results: MutationResult[];
}

export async function pushMutations(
  env: Env,
  ctx: AuthContext,
  mutations: Mutation[],
): Promise<PushResponse> {
  const results: MutationResult[] = [];

  for (const mutation of mutations) {
    results.push(await applyMutation(env, ctx, mutation));
  }

  const head = await currentHead(env, ctx.tenantId);
  return { head, results };
}

async function applyMutation(
  env: Env,
  ctx: AuthContext,
  mutation: Mutation,
): Promise<MutationResult> {
  const def = ENTITIES[mutation.entity];
  if (!def) {
    return reject(mutation, 'UNKNOWN_ENTITY', `Unknown entity ${mutation.entity}`);
  }

  const already = await env.DB.prepare(
    'SELECT 1 AS present FROM applied_mutations WHERE mutation_id = ?',
  )
    .bind(mutation.mutation_id)
    .first<{ present: number }>();
  if (already) {
    return {
      mutation_id: mutation.mutation_id,
      status: 'duplicate',
      row_id: mutation.row_id,
    };
  }

  const fields = mutation.fields ?? {};
  for (const key of Object.keys(fields)) {
    if (!def.columns.has(key)) {
      return reject(mutation, 'UNKNOWN_FIELD', `Cannot write field ${key}`);
    }
  }

  const existing = await env.DB.prepare(
    `SELECT * FROM ${def.table} WHERE id = ? AND tenant_id = ?`,
  )
    .bind(mutation.row_id, ctx.tenantId)
    .first<Row>();

  try {
    if (mutation.op === 'insert') {
      return await insertRow(env, ctx, def, mutation, fields, existing);
    }
    if (!existing) {
      return reject(mutation, 'NOT_FOUND', 'Row does not exist on the server');
    }
    if (mutation.op === 'patch') {
      return await patchRow(env, ctx, def, mutation, fields, existing);
    }
    return await deleteRow(env, ctx, def, mutation, existing);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return reject(mutation, 'WRITE_FAILED', message);
  }
}

async function insertRow(
  env: Env,
  ctx: AuthContext,
  def: EntityDef,
  mutation: Mutation,
  fields: Row,
  existing: Row | null,
): Promise<MutationResult> {
  if (existing) {
    return reject(mutation, 'ALREADY_EXISTS', 'Row already exists');
  }

  const row: Row = { ...fields };
  for (const required of def.required) {
    if (row[required] === undefined || row[required] === null) {
      return reject(mutation, 'MISSING_FIELD', `Missing required field ${required}`);
    }
  }

  const now = nowIso();
  row['id'] = mutation.row_id;
  row['tenant_id'] = ctx.tenantId;
  // Only tables that actually carry a branch get one. Setting it blindly broke
  // customer_phones, which has no such column — caught by the live smoke test.
  if (def.branchScoped) {
    row['branch_id'] = row['branch_id'] ?? ctx.branchId;
  }
  row['created_at'] = now;
  row['updated_at'] = now;
  row['created_by'] = ctx.userId;
  row['version'] = 1;
  row['deleted_at'] = null;

  if (!can(asRole(ctx.role), def.permission)) {
    return reject(mutation, 'PERMISSION_DENIED', 'Not allowed to create this record');
  }

  const columns = Object.keys(row);
  const placeholders = columns.map(() => '?').join(', ');
  const insert = env.DB.prepare(
    `INSERT INTO ${def.table} (${columns.join(', ')}) VALUES (${placeholders})`,
  ).bind(...columns.map((column) => row[column] as never));

  const changeLog = await buildChangeLog(env, ctx, {
    entity: mutation.entity,
    rowId: mutation.row_id,
    op: 'insert',
    row,
    version: 1,
    changedFields: null,
  });

  await env.DB.batch([
    insert,
    changeLog,
    markApplied(env, ctx, mutation, 'applied'),
  ]);

  return {
    mutation_id: mutation.mutation_id,
    status: 'applied',
    row_id: mutation.row_id,
    server_version: 1,
    row: redactCosts(row, can(asRole(ctx.role), 'cost.view')),
  };
}

async function patchRow(
  env: Env,
  ctx: AuthContext,
  def: EntityDef,
  mutation: Mutation,
  fields: Row,
  existing: Row,
): Promise<MutationResult> {
  const rowBranch = (existing['branch_id'] as string | null) ?? null;
  if (
    !permits(
      { role: asRole(ctx.role), userId: ctx.userId, branchId: ctx.branchId },
      def.permission,
      { branchId: rowBranch, ownerId: (existing['created_by'] as string) ?? null },
    )
  ) {
    return reject(mutation, 'SCOPE_DENIED', 'Not allowed to change this record');
  }

  // Server-owned rules run before anything is written: an illegal transition
  // must be rejected even when the version matches.
  let working = fields;
  if (def.mutate) {
    const outcome = def.mutate({ fields, existing, ctx });
    if ('error' in outcome) {
      return reject(mutation, outcome.error.code, outcome.error.message);
    }
    working = outcome.fields;
  }

  const currentVersion = Number(existing['version'] ?? 0);
  const versionMatches = currentVersion === mutation.base_version;

  if (!versionMatches && !def.mergeable) {
    return {
      mutation_id: mutation.mutation_id,
      status: 'rejected',
      row_id: mutation.row_id,
      server_version: currentVersion,
      row: redactCosts(existing, can(asRole(ctx.role), 'cost.view')),
      error: {
        code: 'VERSION_CONFLICT',
        message: 'This record changed on another device.',
      },
    };
  }

  // Which fields actually disagree with the server? Those are the ones a
  // manager needs to see side by side when the versions did not match.
  const differing = Object.entries(working)
    .filter(([key, value]) => existing[key] !== value)
    .map(([key]) => key);

  const nextVersion = currentVersion + 1;
  const row: Row = { ...existing, ...working, version: nextVersion, updated_at: nowIso(), updated_by: ctx.userId };

  if (Object.keys(working).length === 0) {
    return {
      mutation_id: mutation.mutation_id,
      status: 'applied',
      row_id: mutation.row_id,
      server_version: currentVersion,
      row,
    };
  }

  const assignments = Object.keys(working)
    .map((column) => `${column} = ?`)
    .join(', ');
  const update = env.DB.prepare(
    `UPDATE ${def.table}
        SET ${assignments}, version = ?, updated_at = ?, updated_by = ?
      WHERE id = ? AND tenant_id = ? AND version = ?`,
  ).bind(
    ...Object.keys(working).map((column) => working[column] as never),
    nextVersion,
    row['updated_at'] as string,
    ctx.userId,
    mutation.row_id,
    ctx.tenantId,
    currentVersion,
  );

  const statusChanged =
    working['status'] !== undefined &&
    String(working['status']) !== String(existing['status']);

  const statements = [
    update,
    await buildChangeLog(env, ctx, {
      entity: mutation.entity,
      rowId: mutation.row_id,
      op: 'patch',
      row,
      version: nextVersion,
      changedFields: Object.keys(working),
    }),
    markApplied(env, ctx, mutation, versionMatches ? 'applied' : 'merged'),
  ];

  if (statusChanged && mutation.entity === 'tasks') {
    statements.push(
      taskEventStatement(
        env,
        ctx,
        mutation.row_id,
        String(existing['status'] ?? '') || null,
        String(working['status']),
        working['reason'] === undefined || working['reason'] === null
          ? null
          : String(working['reason']),
      ),
    );
  }

  if (!versionMatches && differing.length > 0) {
    statements.push(
      buildConflict(env, ctx, mutation, working, existing, differing),
    );
  }

  // Time is recorded when work stops, from the server's own clock.
  if (
    mutation.entity === 'tasks' &&
    statusChanged &&
    String(existing['status']) === 'in_progress'
  ) {
    statements.push(...recordTimeEntry(env, ctx, existing));
  }

  await env.DB.batch(statements);

  // Outside the batch on purpose: a failed cascade leaves the next stage
  // waiting, which is visible on the board and safe to repeat — whereas a
  // half-applied cascade inside the batch would be invisible.
  if (mutation.entity === 'tasks' && statusChanged) {
    await cascadeStage(
      env,
      ctx,
      String(row['order_id']),
      Number(row['sequence']),
      String(working['status']),
    );
  }

  return {
    mutation_id: mutation.mutation_id,
    status: versionMatches ? 'applied' : 'merged',
    row_id: mutation.row_id,
    server_version: nextVersion,
    row: redactCosts(row, can(asRole(ctx.role), 'cost.view')),
  };
}

async function deleteRow(
  env: Env,
  ctx: AuthContext,
  def: EntityDef,
  mutation: Mutation,
  existing: Row,
): Promise<MutationResult> {
  if (!def.softDelete) {
    return reject(mutation, 'DELETE_NOT_ALLOWED', 'This record cannot be deleted');
  }
  if (!can(asRole(ctx.role), def.permission, 'branch')) {
    return reject(mutation, 'PERMISSION_DENIED', 'Not allowed to delete this record');
  }

  const currentVersion = Number(existing['version'] ?? 0);
  if (currentVersion !== mutation.base_version) {
    return {
      mutation_id: mutation.mutation_id,
      status: 'rejected',
      row_id: mutation.row_id,
      server_version: currentVersion,
      error: { code: 'VERSION_CONFLICT', message: 'This record changed on another device.' },
    };
  }

  const nextVersion = currentVersion + 1;
  const now = nowIso();
  const row: Row = { ...existing, deleted_at: now, version: nextVersion, updated_at: now };

  await env.DB.batch([
    env.DB.prepare(
      `UPDATE ${def.table} SET deleted_at = ?, version = ?, updated_at = ? WHERE id = ? AND tenant_id = ?`,
    ).bind(now, nextVersion, now, mutation.row_id, ctx.tenantId),
    await buildChangeLog(env, ctx, {
      entity: mutation.entity,
      rowId: mutation.row_id,
      op: 'delete',
      row,
      version: nextVersion,
      changedFields: null,
    }),
    markApplied(env, ctx, mutation, 'applied'),
  ]);

  return {
    mutation_id: mutation.mutation_id,
    status: 'applied',
    row_id: mutation.row_id,
    server_version: nextVersion,
  };
}

interface ChangeLogInput {
  entity: string;
  rowId: string;
  op: 'insert' | 'patch' | 'delete';
  row: Row;
  version: number;
  changedFields: string[] | null;
}

async function buildChangeLog(
  env: Env,
  ctx: AuthContext,
  input: ChangeLogInput,
): Promise<D1PreparedStatement> {
  return env.DB.prepare(
    `INSERT INTO change_log (
        tenant_id, entity, row_id, op, branch_id, assignee_id, job_id,
        actor_id, device_id, row_version, changed_fields_json, row_json, server_ts
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  ).bind(
    ctx.tenantId,
    input.entity,
    input.rowId,
    input.op,
    (input.row['branch_id'] as string | null) ?? null,
    (input.row['assignee_id'] as string | null) ?? null,
    (input.row['job_id'] as string | null) ?? null,
    ctx.userId,
    ctx.deviceId,
    input.version,
    input.changedFields === null ? null : JSON.stringify(input.changedFields),
    JSON.stringify(input.row),
    nowIso(),
  );
}

function markApplied(
  env: Env,
  ctx: AuthContext,
  mutation: Mutation,
  result: string,
): D1PreparedStatement {
  return env.DB.prepare(
    'INSERT OR REPLACE INTO applied_mutations (mutation_id, tenant_id, applied_at, result) VALUES (?, ?, ?, ?)',
  ).bind(mutation.mutation_id, ctx.tenantId, nowIso(), result);
}

function buildConflict(
  env: Env,
  ctx: AuthContext,
  mutation: Mutation,
  local: Row,
  server: Row,
  fields: string[],
): D1PreparedStatement {
  return env.DB.prepare(
    `INSERT INTO conflicts (
        id, tenant_id, entity, row_id, device_id, mutation_id,
        local_json, server_json, fields_json, status, created_at
     ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?)`,
  ).bind(
    crypto.randomUUID(),
    ctx.tenantId,
    mutation.entity,
    mutation.row_id,
    ctx.deviceId,
    mutation.mutation_id,
    JSON.stringify(local),
    JSON.stringify(server),
    JSON.stringify(fields),
    nowIso(),
  );
}

function reject(mutation: Mutation, code: string, message: string): MutationResult {
  return {
    mutation_id: mutation.mutation_id,
    status: 'rejected',
    row_id: mutation.row_id,
    error: { code, message },
  };
}

export async function currentHead(env: Env, tenantId: string): Promise<number> {
  const row = await env.DB.prepare(
    'SELECT COALESCE(MAX(seq), 0) AS head FROM change_log WHERE tenant_id = ?',
  )
    .bind(tenantId)
    .first<{ head: number }>();
  return Number(row?.head ?? 0);
}

export interface PullRow {
  seq: number;
  entity: string;
  row_id: string;
  op: string;
  version: number;
  server_ts: string;
  data: Row;
}

export interface PullResponse {
  rows: PullRow[];
  next_cursor: number;
  head: number;
}

/**
 * Visibility: a row reaches a device when it is organisation-level, in the
 * caller's branch, or theirs. This is the same predicate the design describes
 * in §5.4 — one indexed range scan, no joins.
 */
function scopeClause(ctx: AuthContext): { sql: string; params: string[] } {
  switch (ctx.role) {
    case 'owner':
    case 'accountant':
      return { sql: '', params: [] };
    case 'manager':
    case 'counter':
    case 'vendor_coordinator':
      return {
        sql: ' AND (branch_id IS NULL OR branch_id = ?)',
        params: [ctx.branchId ?? ''],
      };
    default:
      return {
        sql: ' AND (branch_id IS NULL OR actor_id = ? OR assignee_id = ?)',
        params: [ctx.userId, ctx.userId],
      };
  }
}

export async function pullChanges(
  env: Env,
  ctx: AuthContext,
  since: number,
  limit: number,
): Promise<PullResponse> {
  const safeLimit = Math.min(Math.max(limit, 1), 500);
  const scope = scopeClause(ctx);

  const { results } = await env.DB.prepare(
    `SELECT seq, entity, row_id, op, row_version, row_json, server_ts
       FROM change_log
      WHERE tenant_id = ? AND seq > ?${scope.sql}
      ORDER BY seq ASC
      LIMIT ?`,
  )
    .bind(ctx.tenantId, since, ...scope.params, safeLimit)
    .all<{
      seq: number;
      entity: string;
      row_id: string;
      op: string;
      row_version: number;
      row_json: string;
      server_ts: string;
    }>();

  const rows: PullRow[] = (results ?? []).map((row) => ({
    seq: Number(row.seq),
    entity: row.entity,
    row_id: row.row_id,
    op: row.op,
    version: Number(row.row_version),
    server_ts: row.server_ts,
    data: redactCosts(
      JSON.parse(row.row_json) as Row,
      can(asRole(ctx.role), 'cost.view'),
    ),
  }));

  const nextCursor = rows.length > 0 ? rows[rows.length - 1]!.seq : since;
  return {
    rows,
    next_cursor: nextCursor,
    head: await currentHead(env, ctx.tenantId),
  };
}
