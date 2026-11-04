/**
 * Owner-editable reference data: materials, machines and finishing operations.
 *
 * These three tables ride `GET /v1/catalogue` down to every device, so an edit
 * here must move `catalogue_version` or a counter keeps quoting the old number
 * until something else changes. The version is the high-water mark of
 * `updated_at` across the catalogue rows; a soft delete removes its row from
 * that computation, so every write also stamps the `catalogue_version` settings
 * row (read back in catalogue.ts) — the same marker keeps a deletion visible to
 * the version even though the row itself is gone.
 *
 * Same rules as the price book: only `price.edit` (the owner) may write, and
 * every change is appended to audit_log with the old and the new value, so
 * "who made art card cheaper in March" is answerable.
 */

import { z } from 'zod';

import { can, type RoleKey } from './policy';
import type { AuthContext, Env } from './types';

// --- zod schemas -----------------------------------------------------------

export const materialCreateSchema = z.object({
  code: z.string().trim().min(2).max(40),
  name: z.string().trim().min(2).max(120),
  // Free text on purpose: the column predates the editor and holds 'card',
  // 'vinyl' and friends. The app offers sheet/roll/other as suggestions.
  type: z.string().trim().max(40).nullable().optional(),
  gsm: z.number().int().min(0).max(10_000).nullable().optional(),
  sheet_width_mm: z.number().int().positive().max(5_000).nullable().optional(),
  sheet_height_mm: z.number().int().positive().max(5_000).nullable().optional(),
  cost_per_sheet_fils: z.number().int().min(0).max(1_000_000_000).default(0),
  supplier_id: z.string().trim().max(60).nullable().optional(),
});

export const materialPatchSchema = z
  .object({
    name: z.string().trim().min(2).max(120).optional(),
    type: z.string().trim().max(40).nullable().optional(),
    gsm: z.number().int().min(0).max(10_000).nullable().optional(),
    sheet_width_mm: z.number().int().positive().max(5_000).nullable().optional(),
    sheet_height_mm: z.number().int().positive().max(5_000).nullable().optional(),
    cost_per_sheet_fils: z.number().int().min(0).max(1_000_000_000).optional(),
    supplier_id: z.string().trim().max(60).nullable().optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Nothing to change',
  });

export const machineCreateSchema = z.object({
  name: z.string().trim().min(2).max(120),
  // The migration CHECKs this column, so the enum is the schema, not a guess.
  type: z.enum(['offset', 'digital', 'large_format', 'finishing']).default('digital'),
  hourly_rate_fils: z.number().int().min(0).max(1_000_000_000).default(0),
  setup_minutes: z.number().int().min(0).max(10_000).default(0),
  sheets_per_hour: z.number().int().min(0).max(100_000).default(0),
  plate_cost_fils: z.number().int().min(0).max(1_000_000_000).default(0),
  click_fils: z.number().int().min(0).max(1_000_000_000).default(0),
});

export const machinePatchSchema = z
  .object({
    name: z.string().trim().min(2).max(120).optional(),
    type: z.enum(['offset', 'digital', 'large_format', 'finishing']).optional(),
    hourly_rate_fils: z.number().int().min(0).max(1_000_000_000).optional(),
    setup_minutes: z.number().int().min(0).max(10_000).optional(),
    sheets_per_hour: z.number().int().min(0).max(100_000).optional(),
    plate_cost_fils: z.number().int().min(0).max(1_000_000_000).optional(),
    click_fils: z.number().int().min(0).max(1_000_000_000).optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Nothing to change',
  });

export const operationCreateSchema = z.object({
  code: z.string().trim().min(2).max(40),
  name_en: z.string().trim().min(2).max(120),
  phase: z
    .enum(['prepress', 'print', 'finishing', 'packing', 'delivery'])
    .default('finishing'),
  // The six bases the engine and the CHECK constraint agree on.
  basis: z.enum(['per_piece', 'per_1000', 'per_side', 'per_sqm', 'per_copy', 'per_hour']),
  rate_fils: z.number().int().min(0).max(1_000_000_000).default(0),
  setup_fils: z.number().int().min(0).max(1_000_000_000).default(0),
  waste_bps: z.number().int().min(0).max(100_000).default(0),
  min_charge_fils: z.number().int().min(0).max(1_000_000_000).default(0),
  sort: z.number().int().min(0).max(10_000).default(100),
});

export const operationPatchSchema = z
  .object({
    name_en: z.string().trim().min(2).max(120).optional(),
    phase: z
      .enum(['prepress', 'print', 'finishing', 'packing', 'delivery'])
      .optional(),
    basis: z
      .enum(['per_piece', 'per_1000', 'per_side', 'per_sqm', 'per_copy', 'per_hour'])
      .optional(),
    rate_fils: z.number().int().min(0).max(1_000_000_000).optional(),
    setup_fils: z.number().int().min(0).max(1_000_000_000).optional(),
    waste_bps: z.number().int().min(0).max(100_000).optional(),
    min_charge_fils: z.number().int().min(0).max(1_000_000_000).optional(),
    sort: z.number().int().min(0).max(10_000).optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Nothing to change',
  });

// --- results and helpers ----------------------------------------------------

export interface CatalogueAdminResult {
  status: number;
  body: Record<string, unknown>;
}

function forbidden(): CatalogueAdminResult {
  return {
    status: 403,
    body: {
      error: { code: 'PERMISSION_DENIED', message: 'Only an owner changes the catalogue.' },
    },
  };
}

function notFound(what: string): CatalogueAdminResult {
  return {
    status: 404,
    body: { error: { code: 'NOT_FOUND', message: `${what} not found.` } },
  };
}

function auditStatement(
  env: Env,
  ctx: AuthContext,
  action: string,
  entity: string,
  rowId: string,
  before: unknown,
  after: unknown,
): D1PreparedStatement {
  return env.DB.prepare(
    `INSERT INTO audit_log (id, tenant_id, actor_id, device_id, action, entity, row_id, old_json, new_json, at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
  ).bind(
    crypto.randomUUID(),
    ctx.tenantId,
    ctx.userId,
    ctx.deviceId,
    action,
    entity,
    rowId,
    JSON.stringify(before),
    JSON.stringify(after),
    new Date().toISOString(),
  );
}

/**
 * Stamps the `catalogue_version` settings row so a soft delete (whose row drops
 * out of the `updated_at` high-water mark) still moves the version. Read back in
 * `catalogue.ts`; the row is the tenant's own, keyed like `tax`.
 */
function versionStatement(env: Env, ctx: AuthContext, now: string): D1PreparedStatement {
  return env.DB.prepare(
    `INSERT INTO settings (tenant_id, key, value_json, updated_at, updated_by, version)
     VALUES (?, 'catalogue_version', ?, ?, ?, 1)
     ON CONFLICT(tenant_id, key) DO UPDATE SET
       value_json = excluded.value_json,
       updated_at = excluded.updated_at,
       updated_by = excluded.updated_by,
       version = settings.version + 1`,
  ).bind(ctx.tenantId, JSON.stringify({ at: now }), now, ctx.userId);
}

// --- materials --------------------------------------------------------------

export async function listMaterials(
  env: Env,
  tenantId: string,
): Promise<Record<string, unknown>[]> {
  const { results } = await env.DB.prepare(
    `SELECT * FROM materials
      WHERE tenant_id = ? AND active = 1 AND deleted_at IS NULL
      ORDER BY name`,
  )
    .bind(tenantId)
    .all<Record<string, unknown>>();
  return results ?? [];
}

export async function createMaterial(
  env: Env,
  ctx: AuthContext,
  input: z.infer<typeof materialCreateSchema>,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const existing = await env.DB.prepare(
    'SELECT id FROM materials WHERE tenant_id = ? AND code = ? AND deleted_at IS NULL',
  )
    .bind(ctx.tenantId, input.code)
    .first<{ id: string }>();
  if (existing) {
    return {
      status: 409,
      body: {
        error: {
          code: 'DUPLICATE_CODE',
          message: `A material with the code ${input.code} already exists.`,
        },
      },
    };
  }

  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO materials (
         id, tenant_id, code, name, type, gsm, sheet_width_mm, sheet_height_mm,
         cost_per_sheet_fils, supplier_id, active, created_at, updated_at, version
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, 1)`,
    ).bind(
      id,
      ctx.tenantId,
      input.code,
      input.name,
      input.type ?? null,
      input.gsm ?? null,
      input.sheet_width_mm ?? null,
      input.sheet_height_mm ?? null,
      input.cost_per_sheet_fils,
      input.supplier_id ?? null,
      now,
      now,
    ),
    auditStatement(env, ctx, 'price.material.create', 'materials', id, {}, {
      ...input,
      id,
      created_at: now,
    }),
    versionStatement(env, ctx, now),
  ]);

  const material = await env.DB.prepare('SELECT * FROM materials WHERE id = ?')
    .bind(id)
    .first<Record<string, unknown>>();
  return { status: 201, body: { material } };
}

export async function updateMaterial(
  env: Env,
  ctx: AuthContext,
  materialId: string,
  patch: z.infer<typeof materialPatchSchema>,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const before = await env.DB.prepare(
    'SELECT * FROM materials WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL',
  )
    .bind(materialId, ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!before) return notFound('Material');

  const assignments: string[] = [];
  const values: unknown[] = [];
  for (const field of [
    'name',
    'type',
    'gsm',
    'sheet_width_mm',
    'sheet_height_mm',
    'cost_per_sheet_fils',
    'supplier_id',
  ] as const) {
    if (patch[field] !== undefined) {
      assignments.push(`${field} = ?`);
      values.push(patch[field] === null ? null : patch[field]);
    }
  }
  assignments.push('updated_at = ?', 'version = version + 1');
  const now = new Date().toISOString();
  values.push(now, materialId, ctx.tenantId);

  await env.DB.batch([
    env.DB.prepare(
      `UPDATE materials SET ${assignments.join(', ')} WHERE id = ? AND tenant_id = ?`,
    ).bind(...(values as never[])),
    auditStatement(env, ctx, 'price.material.update', 'materials', materialId, before, {
      ...before,
      ...patch,
      updated_at: now,
    }),
    versionStatement(env, ctx, now),
  ]);

  const material = await env.DB.prepare('SELECT * FROM materials WHERE id = ?')
    .bind(materialId)
    .first<Record<string, unknown>>();
  return { status: 200, body: { material } };
}

export async function deleteMaterial(
  env: Env,
  ctx: AuthContext,
  materialId: string,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const before = await env.DB.prepare(
    'SELECT * FROM materials WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL',
  )
    .bind(materialId, ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!before) return notFound('Material');

  const now = new Date().toISOString();
  await env.DB.batch([
    env.DB.prepare(
      'UPDATE materials SET deleted_at = ?, active = 0, updated_at = ?, version = version + 1 WHERE id = ? AND tenant_id = ?',
    ).bind(now, now, materialId, ctx.tenantId),
    auditStatement(env, ctx, 'price.material.delete', 'materials', materialId, before, {
      ...before,
      deleted_at: now,
      active: 0,
    }),
    versionStatement(env, ctx, now),
  ]);

  return { status: 200, body: { ok: true } };
}

// --- machines ---------------------------------------------------------------

export async function listMachines(
  env: Env,
  tenantId: string,
): Promise<Record<string, unknown>[]> {
  const { results } = await env.DB.prepare(
    `SELECT * FROM machines
      WHERE tenant_id = ? AND active = 1 AND deleted_at IS NULL
      ORDER BY name`,
  )
    .bind(tenantId)
    .all<Record<string, unknown>>();
  return results ?? [];
}

export async function createMachine(
  env: Env,
  ctx: AuthContext,
  input: z.infer<typeof machineCreateSchema>,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO machines (
         id, tenant_id, name, type, hourly_rate_fils, setup_minutes,
         sheets_per_hour, plate_cost_fils, click_fils, active,
         created_at, updated_at, created_by, version
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, 1)`,
    ).bind(
      id,
      ctx.tenantId,
      input.name,
      input.type,
      input.hourly_rate_fils,
      input.setup_minutes,
      input.sheets_per_hour,
      input.plate_cost_fils,
      input.click_fils,
      now,
      now,
      ctx.userId,
    ),
    auditStatement(env, ctx, 'price.machine.create', 'machines', id, {}, {
      ...input,
      id,
      created_at: now,
    }),
    versionStatement(env, ctx, now),
  ]);

  const machine = await env.DB.prepare('SELECT * FROM machines WHERE id = ?')
    .bind(id)
    .first<Record<string, unknown>>();
  return { status: 201, body: { machine } };
}

export async function updateMachine(
  env: Env,
  ctx: AuthContext,
  machineId: string,
  patch: z.infer<typeof machinePatchSchema>,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const before = await env.DB.prepare(
    'SELECT * FROM machines WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL',
  )
    .bind(machineId, ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!before) return notFound('Machine');

  const assignments: string[] = [];
  const values: unknown[] = [];
  for (const field of [
    'name',
    'type',
    'hourly_rate_fils',
    'setup_minutes',
    'sheets_per_hour',
    'plate_cost_fils',
    'click_fils',
  ] as const) {
    if (patch[field] !== undefined) {
      assignments.push(`${field} = ?`);
      values.push(patch[field]);
    }
  }
  assignments.push('updated_at = ?', 'version = version + 1');
  const now = new Date().toISOString();
  values.push(now, machineId, ctx.tenantId);

  await env.DB.batch([
    env.DB.prepare(
      `UPDATE machines SET ${assignments.join(', ')} WHERE id = ? AND tenant_id = ?`,
    ).bind(...(values as never[])),
    auditStatement(env, ctx, 'price.machine.update', 'machines', machineId, before, {
      ...before,
      ...patch,
      updated_at: now,
    }),
    versionStatement(env, ctx, now),
  ]);

  const machine = await env.DB.prepare('SELECT * FROM machines WHERE id = ?')
    .bind(machineId)
    .first<Record<string, unknown>>();
  return { status: 200, body: { machine } };
}

export async function deleteMachine(
  env: Env,
  ctx: AuthContext,
  machineId: string,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const before = await env.DB.prepare(
    'SELECT * FROM machines WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL',
  )
    .bind(machineId, ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!before) return notFound('Machine');

  const now = new Date().toISOString();
  await env.DB.batch([
    env.DB.prepare(
      'UPDATE machines SET deleted_at = ?, active = 0, updated_at = ?, version = version + 1 WHERE id = ? AND tenant_id = ?',
    ).bind(now, now, machineId, ctx.tenantId),
    auditStatement(env, ctx, 'price.machine.delete', 'machines', machineId, before, {
      ...before,
      deleted_at: now,
      active: 0,
    }),
    versionStatement(env, ctx, now),
  ]);

  return { status: 200, body: { ok: true } };
}

// --- operations --------------------------------------------------------------

export async function listOperations(
  env: Env,
  tenantId: string,
): Promise<Record<string, unknown>[]> {
  const { results } = await env.DB.prepare(
    `SELECT * FROM operations
      WHERE tenant_id = ? AND active = 1 AND deleted_at IS NULL
      ORDER BY sort, name_en`,
  )
    .bind(tenantId)
    .all<Record<string, unknown>>();
  return results ?? [];
}

export async function createOperation(
  env: Env,
  ctx: AuthContext,
  input: z.infer<typeof operationCreateSchema>,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const existing = await env.DB.prepare(
    'SELECT id FROM operations WHERE tenant_id = ? AND code = ? AND deleted_at IS NULL',
  )
    .bind(ctx.tenantId, input.code)
    .first<{ id: string }>();
  if (existing) {
    return {
      status: 409,
      body: {
        error: {
          code: 'DUPLICATE_CODE',
          message: `An operation with the code ${input.code} already exists.`,
        },
      },
    };
  }

  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO operations (
         id, tenant_id, code, name_en, phase, basis, rate_fils, setup_fils,
         waste_bps, min_charge_fils, active, sort, created_at, updated_at, created_by, version
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, 1)`,
    ).bind(
      id,
      ctx.tenantId,
      input.code,
      input.name_en,
      input.phase,
      input.basis,
      input.rate_fils,
      input.setup_fils,
      input.waste_bps,
      input.min_charge_fils,
      input.sort,
      now,
      now,
      ctx.userId,
    ),
    auditStatement(env, ctx, 'price.operation.create', 'operations', id, {}, {
      ...input,
      id,
      created_at: now,
    }),
    versionStatement(env, ctx, now),
  ]);

  const operation = await env.DB.prepare('SELECT * FROM operations WHERE id = ?')
    .bind(id)
    .first<Record<string, unknown>>();
  return { status: 201, body: { operation } };
}

export async function updateOperation(
  env: Env,
  ctx: AuthContext,
  operationId: string,
  patch: z.infer<typeof operationPatchSchema>,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const before = await env.DB.prepare(
    'SELECT * FROM operations WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL',
  )
    .bind(operationId, ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!before) return notFound('Operation');

  const assignments: string[] = [];
  const values: unknown[] = [];
  for (const field of [
    'name_en',
    'phase',
    'basis',
    'rate_fils',
    'setup_fils',
    'waste_bps',
    'min_charge_fils',
    'sort',
  ] as const) {
    if (patch[field] !== undefined) {
      assignments.push(`${field} = ?`);
      values.push(patch[field]);
    }
  }
  assignments.push('updated_at = ?', 'version = version + 1');
  const now = new Date().toISOString();
  values.push(now, operationId, ctx.tenantId);

  await env.DB.batch([
    env.DB.prepare(
      `UPDATE operations SET ${assignments.join(', ')} WHERE id = ? AND tenant_id = ?`,
    ).bind(...(values as never[])),
    auditStatement(env, ctx, 'price.operation.update', 'operations', operationId, before, {
      ...before,
      ...patch,
      updated_at: now,
    }),
    versionStatement(env, ctx, now),
  ]);

  const operation = await env.DB.prepare('SELECT * FROM operations WHERE id = ?')
    .bind(operationId)
    .first<Record<string, unknown>>();
  return { status: 200, body: { operation } };
}

export async function deleteOperation(
  env: Env,
  ctx: AuthContext,
  operationId: string,
): Promise<CatalogueAdminResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const before = await env.DB.prepare(
    'SELECT * FROM operations WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL',
  )
    .bind(operationId, ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!before) return notFound('Operation');

  const now = new Date().toISOString();
  await env.DB.batch([
    env.DB.prepare(
      'UPDATE operations SET deleted_at = ?, active = 0, updated_at = ?, version = version + 1 WHERE id = ? AND tenant_id = ?',
    ).bind(now, now, operationId, ctx.tenantId),
    auditStatement(env, ctx, 'price.operation.delete', 'operations', operationId, before, {
      ...before,
      deleted_at: now,
      active: 0,
    }),
    versionStatement(env, ctx, now),
  ]);

  return { status: 200, body: { ok: true } };
}
