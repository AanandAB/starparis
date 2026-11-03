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
  /** Production stages per workflow key; the app generates tasks from these. */
  workflow_stages: Record<string, unknown>[];
  tax: { vat_bps: number };
}

/**
 * The workflow a tenant gets before the owner edits anything. Mirrored in
 * apps/shop_app (TaskTemplates.defaults) and seeds/catalogue.sql; the app and
 * the server must agree, because the device generates tasks offline.
 */
export const DEFAULT_WORKFLOW: ReadonlyArray<{
  workflow_key: string;
  stage_key: string;
  name_en: string;
  name_ar: string;
  sequence: number;
  required_role: string;
  waits_for_previous: number;
}> = [
  { workflow_key: 'print_std', stage_key: 'design', name_en: 'Design', name_ar: 'التصميم', sequence: 10, required_role: 'designer', waits_for_previous: 1 },
  { workflow_key: 'print_std', stage_key: 'print', name_en: 'Print', name_ar: 'الطباعة', sequence: 20, required_role: 'operator', waits_for_previous: 1 },
  { workflow_key: 'print_std', stage_key: 'finish', name_en: 'Finishing', name_ar: 'التشطيب', sequence: 30, required_role: 'operator', waits_for_previous: 1 },
  { workflow_key: 'print_std', stage_key: 'qc', name_en: 'Quality check', name_ar: 'فحص الجودة', sequence: 40, required_role: 'manager', waits_for_previous: 1 },
  { workflow_key: 'print_std', stage_key: 'delivery', name_en: 'Delivery', name_ar: 'التوصيل', sequence: 50, required_role: 'driver', waits_for_previous: 1 },
];

export async function loadCatalogue(env: Env, tenantId: string): Promise<CatalogueResponse> {
  const [products, materials, rules, versionRow, taxRow, stages] = await Promise.all([
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

    env.DB.prepare(
      `SELECT * FROM workflow_stages
        WHERE tenant_id = ? AND deleted_at IS NULL
        ORDER BY workflow_key, sequence`,
    )
      .bind(tenantId)
      .all<Record<string, unknown>>(),
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

  const stageRows =
    (stages.results ?? []).length > 0
      ? (stages.results as Record<string, unknown>[])
      : DEFAULT_WORKFLOW.map((stage) => ({
          ...stage,
          id: `default_${stage.stage_key}`,
        }));

  return {
    catalogue_version: newestUpdate ?? '0',
    price_book_version: Number(versionRow?.version ?? 0),
    products: products.results ?? [],
    materials: materials.results ?? [],
    rules: rules.results ?? [],
    workflow_stages: stageRows,
    tax: { vat_bps: vatBps },
  };
}
