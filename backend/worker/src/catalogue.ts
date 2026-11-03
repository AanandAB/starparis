/**
 * The catalogue: products, materials and price rules.
 *
 * This is reference data, not user data. It does not go through the change log
 * because a device never pushes it (in v1) and a pull of 400 price rules on
 * every sync would be waste. Instead the device fetches it once, caches it, and
 * refetches when `catalogue_version` changes — which is the price book's
 * `updated_at` high-water mark.
 */

import type { Env } from './types';

export interface CatalogueResponse {
  catalogue_version: string;
  price_book_version: number;
  products: Record<string, unknown>[];
  materials: Record<string, unknown>[];
  rules: Record<string, unknown>[];
  tax: { vat_bps: number };
}

export async function loadCatalogue(env: Env, tenantId: string): Promise<CatalogueResponse> {
  const [products, materials, rules, versionRow, taxRow] = await Promise.all([
    env.DB.prepare(
      `SELECT * FROM products
        WHERE tenant_id = ? AND active = 1 AND deleted_at IS NULL
        ORDER BY sort, name_en`,
    )
      .bind(tenantId)
      .all<Record<string, unknown>>(),

    env.DB.prepare(
      `SELECT * FROM materials
        WHERE tenant_id = ? AND active = 1 AND deleted_at IS NULL
        ORDER BY name`,
    )
      .bind(tenantId)
      .all<Record<string, unknown>>(),

    env.DB.prepare(
      `SELECT * FROM price_rules
        WHERE tenant_id = ? AND active = 1 AND deleted_at IS NULL
        ORDER BY priority, label`,
    )
      .bind(tenantId)
      .all<Record<string, unknown>>(),

    env.DB.prepare(
      'SELECT COALESCE(MAX(price_book_version), 0) AS version FROM price_rules WHERE tenant_id = ?',
    )
      .bind(tenantId)
      .first<{ version: number }>(),

    env.DB.prepare('SELECT value_json FROM settings WHERE tenant_id = ? AND key = ?')
      .bind(tenantId, 'tax')
      .first<{ value_json: string }>(),
  ]);

  let vatBps = 500;
  if (taxRow?.value_json) {
    try {
      const parsed = JSON.parse(taxRow.value_json) as { vat_bps?: number };
      if (typeof parsed.vat_bps === 'number') vatBps = parsed.vat_bps;
    } catch {
      // A malformed setting must not take the catalogue down; 5% is the UAE rate.
    }
  }

  const newestUpdate = [...(products.results ?? []), ...(materials.results ?? []), ...(rules.results ?? [])]
    .map((row) => String(row['updated_at'] ?? ''))
    .sort()
    .at(-1);

  return {
    catalogue_version: newestUpdate ?? '0',
    price_book_version: Number(versionRow?.version ?? 0),
    products: products.results ?? [],
    materials: materials.results ?? [],
    rules: rules.results ?? [],
    tax: { vat_bps: vatBps },
  };
}
