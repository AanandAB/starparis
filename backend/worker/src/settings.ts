/**
 * Shop settings: the things the owner must be able to change without a
 * developer — the name and TRN on every document, the VAT rate, and the prefixes
 * on the numbers.
 *
 * Stored as JSON rows in `settings` (keyed by tenant), with the tenant's own
 * `name`/`trn` mirrored on write so a raw database read is never stale. Reading
 * falls back to sensible values rather than failing: a fresh shop must be able to
 * open Settings and fill it in.
 */
import { z } from 'zod';
import type { Env } from './types';

export interface CompanyProfile {
  name: string;
  trn: string;
  address: string;
  phone: string;
  email: string;
}

export interface ShopSettings {
  company: CompanyProfile;
  vat_bps: number;
  numbers: { order_prefix: string; invoice_prefix: string; quote_prefix: string };
}

export const settingsSchema = z.object({
  company: z
    .object({
      name: z.string().trim().min(2).max(120),
      trn: z
        .string()
        .trim()
        .regex(/^\d{15}$/, 'A UAE TRN is 15 digits.')
        .or(z.literal('')),
      address: z.string().trim().max(300),
      phone: z.string().trim().max(40),
      email: z.string().trim().max(120),
    })
    .partial()
    .optional(),
  // 0 to 100% in basis points, so 5% is 500 and a fraction of a percent is legal.
  vat_bps: z.number().int().min(0).max(10000).optional(),
  numbers: z
    .object({
      order_prefix: z.string().trim().min(2).max(12),
      invoice_prefix: z.string().trim().min(2).max(12),
      quote_prefix: z.string().trim().min(2).max(12),
    })
    .partial()
    .optional(),
});

export const DEFAULT_SETTINGS: ShopSettings = {
  company: {
    name: 'Star Paris Graphic LLC',
    trn: '',
    address: '',
    phone: '',
    email: '',
  },
  vat_bps: 500,
  numbers: { order_prefix: 'JOB', invoice_prefix: 'INV', quote_prefix: 'QT' },
};

async function readJson(
  env: Env,
  tenantId: string,
  key: string,
): Promise<Record<string, unknown> | null> {
  const row = await env.DB.prepare(
    'SELECT value_json FROM settings WHERE tenant_id = ? AND key = ?',
  )
    .bind(tenantId, key)
    .first<{ value_json: string }>();
  if (row == null) return null;
  try {
    return JSON.parse(row.value_json) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export async function loadSettings(env: Env, tenantId: string): Promise<ShopSettings> {
  const tenant = await env.DB.prepare('SELECT name, trn FROM tenants WHERE id = ?')
    .bind(tenantId)
    .first<{ name: string; trn: string | null }>();

  const company = (await readJson(env, tenantId, 'company')) ?? {};
  const tax = (await readJson(env, tenantId, 'tax')) ?? {};
  const numbers = (await readJson(env, tenantId, 'numbers')) ?? {};

  return {
    company: {
      name: String(company['name'] ?? tenant?.name ?? DEFAULT_SETTINGS.company.name),
      trn: String(company['trn'] ?? tenant?.trn ?? ''),
      address: String(company['address'] ?? ''),
      phone: String(company['phone'] ?? ''),
      email: String(company['email'] ?? ''),
    },
    vat_bps: Number(tax['vat_bps'] ?? DEFAULT_SETTINGS.vat_bps),
    numbers: {
      order_prefix: String(numbers['order_prefix'] ?? DEFAULT_SETTINGS.numbers.order_prefix),
      invoice_prefix: String(
        numbers['invoice_prefix'] ?? DEFAULT_SETTINGS.numbers.invoice_prefix,
      ),
      quote_prefix: String(numbers['quote_prefix'] ?? DEFAULT_SETTINGS.numbers.quote_prefix),
    },
  };
}

/**
 * Applies a patch and returns the whole settings object, so the app never has to
 * guess what the result was. Company writes mirror `tenants.name` / `tenants.trn`.
 */
export async function saveSettings(
  env: Env,
  tenantId: string,
  userId: string,
  patch: z.infer<typeof settingsSchema>,
): Promise<ShopSettings> {
  const current = await loadSettings(env, tenantId);
  const now = new Date().toISOString();

  const next: ShopSettings = {
    company: { ...current.company, ...(patch.company ?? {}) },
    vat_bps: patch.vat_bps ?? current.vat_bps,
    numbers: { ...current.numbers, ...(patch.numbers ?? {}) },
  };

  const statements = [
    env.DB.prepare(
      `INSERT INTO settings (tenant_id, key, value_json, updated_at, updated_by, version)
       VALUES (?, 'company', ?, ?, ?, 1)
       ON CONFLICT(tenant_id, key) DO UPDATE SET
         value_json = excluded.value_json,
         updated_at = excluded.updated_at,
         updated_by = excluded.updated_by,
         version = settings.version + 1`,
    ).bind(tenantId, JSON.stringify(next.company), now, userId),
    env.DB.prepare(
      `INSERT INTO settings (tenant_id, key, value_json, updated_at, updated_by, version)
       VALUES (?, 'tax', ?, ?, ?, 1)
       ON CONFLICT(tenant_id, key) DO UPDATE SET
         value_json = excluded.value_json,
         updated_at = excluded.updated_at,
         updated_by = excluded.updated_by,
         version = settings.version + 1`,
    ).bind(tenantId, JSON.stringify({ vat_bps: next.vat_bps }), now, userId),
    env.DB.prepare(
      `INSERT INTO settings (tenant_id, key, value_json, updated_at, updated_by, version)
       VALUES (?, 'numbers', ?, ?, ?, 1)
       ON CONFLICT(tenant_id, key) DO UPDATE SET
         value_json = excluded.value_json,
         updated_at = excluded.updated_at,
         updated_by = excluded.updated_by,
         version = settings.version + 1`,
    ).bind(tenantId, JSON.stringify(next.numbers), now, userId),
    env.DB.prepare(
      'UPDATE tenants SET name = ?, trn = ?, updated_at = ?, version = version + 1 WHERE id = ?',
    ).bind(next.company.name, next.company.trn || null, now, tenantId),
  ];

  await env.DB.batch(statements);
  return next;
}
