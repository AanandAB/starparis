/**
 * The price book, editable by the owner.
 *
 * The owner must be able to change any price without a developer (design goal
 * #2), which means the server has to accept writes from the app — carefully:
 *
 *  - only a user with `price.edit` may call any of this (owner by default);
 *  - every change is written to the audit log with the old and new value, so
 *    "who made stickers cheaper in March" is answerable;
 *  - a bulk adjust has a dry run, and the preview is computed with the same
 *    integer arithmetic as the real run, so the preview cannot lie;
 *  - existing orders are untouched by design: they carry a frozen breakdown.
 *
 * Effective-dated price books (schedule a change for 1 January) are the next
 * refinement; today an edit takes effect at the next catalogue refresh.
 */

import { z } from 'zod';

import { can, type RoleKey } from './policy';
import type { AuthContext, Env } from './types';

export const rulePatchSchema = z
  .object({
    rate_fils: z.number().int().min(0).max(100_000_000).optional(),
    min_charge_fils: z.number().int().min(0).max(100_000_000).optional(),
    active: z.boolean().optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Nothing to change',
  });

export const productPatchSchema = z
  .object({
    markup_bps: z.number().int().min(0).max(100_000).optional(),
    rounding_step_fils: z.number().int().min(1).max(10_000).optional(),
    min_order_fils: z.number().int().min(0).max(100_000_000).optional(),
    print_rate_fils: z.number().int().min(0).max(10_000_000).optional(),
    area_rate_fils_per_sqm: z.number().int().min(0).max(10_000_000).optional(),
    spoilage_bps: z.number().int().min(0).max(5_000).optional(),
    // Which press this product runs on, and the finishing steps it includes.
    machine_id: z.string().min(1).nullable().optional(),
    operation_codes_json: z.array(z.string().min(1)).max(40).optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'Nothing to change',
  });

export const bulkAdjustSchema = z.object({
  product_id: z.string().min(1).optional(),
  phase: z.enum(['material', 'print', 'finishing', 'setup', 'surcharge']).optional(),
  percent_bps: z.number().int().min(-9_000).max(100_000),
  dry_run: z.boolean().default(true),
});

export interface PriceBookResult {
  status: number;
  body: Record<string, unknown>;
}

/** Rounds `value * (10000 + bps) / 10000`, halves away from zero. */
export function applyBps(value: number, bps: number): number {
  const negative = value < 0;
  const scaled = Math.abs(value) * (10_000 + bps);
  const rounded = Math.floor((scaled * 2 + 10_000) / 20_000);
  return negative ? -rounded : rounded;
}

function forbidden(): PriceBookResult {
  return {
    status: 403,
    body: {
      error: { code: 'PERMISSION_DENIED', message: 'You cannot change prices.' },
    },
  };
}

function notFound(what: string): PriceBookResult {
  return {
    status: 404,
    body: { error: { code: 'NOT_FOUND', message: `${what} not found.` } },
  };
}

export async function updateRule(
  env: Env,
  ctx: AuthContext,
  ruleId: string,
  patch: z.infer<typeof rulePatchSchema>,
): Promise<PriceBookResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const before = await env.DB.prepare(
    'SELECT * FROM price_rules WHERE id = ? AND tenant_id = ?',
  )
    .bind(ruleId, ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!before) return notFound('Price rule');

  const assignments: string[] = [];
  const values: unknown[] = [];
  if (patch.rate_fils !== undefined) {
    assignments.push('rate_fils = ?');
    values.push(patch.rate_fils);
  }
  if (patch.min_charge_fils !== undefined) {
    assignments.push('min_charge_fils = ?');
    values.push(patch.min_charge_fils);
  }
  if (patch.active !== undefined) {
    assignments.push('active = ?');
    values.push(patch.active ? 1 : 0);
  }
  assignments.push('updated_at = ?', 'version = version + 1');
  const now = new Date().toISOString();
  values.push(now, ruleId, ctx.tenantId);

  await env.DB.batch([
    env.DB.prepare(
      `UPDATE price_rules SET ${assignments.join(', ')} WHERE id = ? AND tenant_id = ?`,
    ).bind(...(values as never[])),
    auditStatement(env, ctx, 'price.rule.update', 'price_rules', ruleId, before, {
      ...before,
      ...patch,
      updated_at: now,
    }),
  ]);

  const after = await env.DB.prepare('SELECT * FROM price_rules WHERE id = ?')
    .bind(ruleId)
    .first<Record<string, unknown>>();

  return { status: 200, body: { rule: after } };
}

export async function updateProduct(
  env: Env,
  ctx: AuthContext,
  productId: string,
  patch: z.infer<typeof productPatchSchema>,
): Promise<PriceBookResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const before = await env.DB.prepare(
    'SELECT * FROM products WHERE id = ? AND tenant_id = ?',
  )
    .bind(productId, ctx.tenantId)
    .first<Record<string, unknown>>();
  if (!before) return notFound('Product');

  const assignments: string[] = [];
  const values: unknown[] = [];
  for (const field of [
    'markup_bps',
    'rounding_step_fils',
    'min_order_fils',
    'print_rate_fils',
    'area_rate_fils_per_sqm',
    'spoilage_bps',
    'machine_id',
  ] as const) {
    const value = patch[field];
    if (value !== undefined) {
      assignments.push(`${field} = ?`);
      values.push(value);
    }
  }
  // The finishing steps travel as a JSON array, but are stored as JSON text so a
  // product row stays a single read on the device.
  if (patch.operation_codes_json !== undefined) {
    assignments.push('operation_codes_json = ?');
    values.push(JSON.stringify(patch.operation_codes_json));
  }
  assignments.push('updated_at = ?', 'version = version + 1');
  const now = new Date().toISOString();
  values.push(now, productId, ctx.tenantId);

  await env.DB.batch([
    env.DB.prepare(
      `UPDATE products SET ${assignments.join(', ')} WHERE id = ? AND tenant_id = ?`,
    ).bind(...(values as never[])),
    auditStatement(env, ctx, 'price.product.update', 'products', productId, before, {
      ...before,
      ...patch,
      updated_at: now,
    }),
  ]);

  const after = await env.DB.prepare('SELECT * FROM products WHERE id = ?')
    .bind(productId)
    .first<Record<string, unknown>>();

  return { status: 200, body: { product: after } };
}

export interface BulkPreviewRow {
  id: string;
  label: string;
  rate_fils: number;
  new_rate_fils: number;
}

export async function bulkAdjust(
  env: Env,
  ctx: AuthContext,
  input: z.infer<typeof bulkAdjustSchema>,
): Promise<PriceBookResult> {
  if (!can(ctx.role as RoleKey, 'price.edit')) return forbidden();

  const clauses: string[] = ['tenant_id = ?', 'active = 1'];
  const params: unknown[] = [ctx.tenantId];
  if (input.product_id) {
    clauses.push('(product_id = ? OR product_id IS NULL)');
    params.push(input.product_id);
  }
  if (input.phase) {
    clauses.push('phase = ?');
    params.push(input.phase);
  }

  const { results } = await env.DB.prepare(
    `SELECT * FROM price_rules WHERE ${clauses.join(' AND ')} ORDER BY priority`,
  )
    .bind(...(params as never[]))
    .all<Record<string, unknown>>();

  const rules = results ?? [];
  const preview: BulkPreviewRow[] = rules.map((rule) => ({
    id: rule['id'] as string,
    label: rule['label'] as string,
    rate_fils: Number(rule['rate_fils']),
    new_rate_fils: applyBps(Number(rule['rate_fils']), input.percent_bps),
  }));

  if (input.dry_run) {
    return {
      status: 200,
      body: { applied: false, percent_bps: input.percent_bps, changes: preview },
    };
  }

  const now = new Date().toISOString();
  const statements = preview.map((row) =>
    env.DB.prepare(
      'UPDATE price_rules SET rate_fils = ?, updated_at = ?, version = version + 1 WHERE id = ? AND tenant_id = ?',
    ).bind(row.new_rate_fils, now, row.id, ctx.tenantId),
  );

  if (statements.length > 0) {
    statements.push(
      auditStatement(
        env,
        ctx,
        'price.bulk_adjust',
        'price_rules',
        input.product_id ?? 'all',
        { changes: preview.map((row) => row.rate_fils) },
        { percent_bps: input.percent_bps, changes: preview.map((row) => row.new_rate_fils) },
      ),
    );
    await env.DB.batch(statements);
  }

  return {
    status: 200,
    body: { applied: true, percent_bps: input.percent_bps, changes: preview },
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
