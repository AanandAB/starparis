/**
 * The two reports the owner and the accountant actually ask for.
 *
 * Both are pure reads over `invoices`, `credit_notes` and `payments` — the same
 * rows the rest of the system writes — so a number can never disagree with the
 * document it came from. Nothing here recalculates VAT: it sums the `vat_fils`
 * that were frozen when each document was issued.
 */

import type { AuthContext, Env } from './types';

type Row = Record<string, unknown>;

export interface VatSummary {
  from: string;
  to: string;
  /** Sales before VAT, from invoices issued in the period. */
  sales_net_fils: number;
  /** VAT charged on those invoices. */
  output_vat_fils: number;
  /** Gross invoiced. */
  sales_gross_fils: number;
  invoice_count: number;
  /** Credits issued in the period, net / VAT / gross. */
  credited_net_fils: number;
  credited_vat_fils: number;
  credited_gross_fils: number;
  credit_note_count: number;
  /** What is actually due to the FTA for the period. */
  net_vat_due_fils: number;
  /** Cash collected in the period, by method — a till figure, not a VAT one. */
  collected_fils: number;
  collected_by_method: Record<string, number>;
  refunded_fils: number;
}

/** Days between two ISO dates, floored, never negative. */
function daysBetween(fromIso: string, toIso: string): number {
  const from = Date.parse(fromIso);
  const to = Date.parse(toIso);
  if (Number.isNaN(from) || Number.isNaN(to)) return 0;
  return Math.max(0, Math.floor((to - from) / 86_400_000));
}

export async function vatSummary(
  env: Env,
  tenantId: string,
  from: string,
  to: string,
  branchId?: string | null,
): Promise<VatSummary> {
  const branchClause = branchId ? ' AND branch_id = ?' : '';
  const bind = (statement: D1PreparedStatement): D1PreparedStatement =>
    branchId
      ? statement.bind(tenantId, from, to, branchId)
      : statement.bind(tenantId, from, to);

  const invoices = await bind(
    env.DB.prepare(
      `SELECT COUNT(*) AS n,
              COALESCE(SUM(subtotal_fils), 0) AS net,
              COALESCE(SUM(vat_fils), 0) AS vat,
              COALESCE(SUM(total_fils), 0) AS gross
         FROM invoices
        WHERE tenant_id = ? AND deleted_at IS NULL AND status <> 'void'
          AND issued_at >= ? AND issued_at < ?${branchClause}`,
    ),
  ).all<Row>();

  const credits = await bind(
    env.DB.prepare(
      `SELECT COUNT(*) AS n,
              COALESCE(SUM(subtotal_fils), 0) AS net,
              COALESCE(SUM(vat_fils), 0) AS vat,
              COALESCE(SUM(total_fils), 0) AS gross
         FROM credit_notes
        WHERE tenant_id = ? AND deleted_at IS NULL
          AND issued_at >= ? AND issued_at < ?${branchClause}`,
    ),
  ).all<Row>();

  const payments = await bind(
    env.DB.prepare(
      `SELECT method, COALESCE(SUM(amount_fils), 0) AS amount
         FROM payments
        WHERE tenant_id = ? AND deleted_at IS NULL
          AND taken_at >= ? AND taken_at < ?${branchClause}
        GROUP BY method`,
    ),
  ).all<{ method: string; amount: number }>();

  const refunds = await bind(
    env.DB.prepare(
      `SELECT COALESCE(SUM(amount_fils), 0) AS amount
         FROM refunds
        WHERE tenant_id = ? AND deleted_at IS NULL
          AND refunded_at >= ? AND refunded_at < ?${branchClause}`,
    ),
  ).first<{ amount: number }>();

  const invoiceRow = invoices.results?.[0] ?? {};
  const creditRow = credits.results?.[0] ?? {};
  const collectedByMethod: Record<string, number> = {};
  let collected = 0;
  for (const row of payments.results ?? []) {
    const amount = Number(row.amount ?? 0);
    collectedByMethod[row.method] = amount;
    collected += amount;
  }

  const outputVat = Number(invoiceRow['vat'] ?? 0);
  const creditedVat = Number(creditRow['vat'] ?? 0);

  return {
    from,
    to,
    sales_net_fils: Number(invoiceRow['net'] ?? 0),
    output_vat_fils: outputVat,
    sales_gross_fils: Number(invoiceRow['gross'] ?? 0),
    invoice_count: Number(invoiceRow['n'] ?? 0),
    credited_net_fils: Number(creditRow['net'] ?? 0),
    credited_vat_fils: creditedVat,
    credited_gross_fils: Number(creditRow['gross'] ?? 0),
    credit_note_count: Number(creditRow['n'] ?? 0),
    // A credit note refunds the VAT it charged, so it reduces what is due.
    net_vat_due_fils: outputVat - creditedVat,
    collected_fils: collected,
    collected_by_method: collectedByMethod,
    refunded_fils: Number(refunds?.amount ?? 0),
  };
}

export interface AgeingRow {
  customer_id: string;
  customer_name: string;
  current_fils: number;
  days_31_60_fils: number;
  days_61_90_fils: number;
  over_90_fils: number;
  total_fils: number;
  invoices: number;
}

export interface AgeingReport {
  as_of: string;
  buckets: AgeingRow[];
  totals: {
    current_fils: number;
    days_31_60_fils: number;
    days_61_90_fils: number;
    over_90_fils: number;
    total_fils: number;
    customers: number;
  };
}

/**
 * Who owes what, by how late they are. `outstanding = total - paid - credited`,
 * which is the same arithmetic the invoice card shows, so the ageing report and
 * the screen agree to the fils.
 */
export async function ageingReport(
  env: Env,
  ctx: AuthContext,
  asOf: string,
): Promise<AgeingReport> {
  // Managers and counter see their branch; owner and accountant see everything.
  const branchScoped = !['owner', 'accountant'].includes(ctx.role);
  const statement = env.DB.prepare(
    `SELECT id, customer_id, customer_name, issued_at, total_fils, paid_fils, credited_fils
       FROM invoices
      WHERE tenant_id = ? AND deleted_at IS NULL AND status <> 'void'
        AND (total_fils - paid_fils - credited_fils) > 0
        ${branchScoped ? 'AND branch_id = ?' : ''}`,
  );
  const bound = branchScoped
    ? statement.bind(ctx.tenantId, ctx.branchId)
    : statement.bind(ctx.tenantId);
  const rows = await bound.all<Row>();

  const byCustomer = new Map<string, AgeingRow>();
  for (const row of rows.results ?? []) {
    const outstanding =
      Number(row['total_fils'] ?? 0) -
      Number(row['paid_fils'] ?? 0) -
      Number(row['credited_fils'] ?? 0);
    if (outstanding <= 0) continue;

    const key = String(row['customer_id']);
    const entry =
      byCustomer.get(key) ??
      ({
        customer_id: key,
        customer_name: String(row['customer_name'] ?? ''),
        current_fils: 0,
        days_31_60_fils: 0,
        days_61_90_fils: 0,
        over_90_fils: 0,
        total_fils: 0,
        invoices: 0,
      } satisfies AgeingRow);

    const days = daysBetween(String(row['issued_at']), asOf);
    if (days <= 30) entry.current_fils += outstanding;
    else if (days <= 60) entry.days_31_60_fils += outstanding;
    else if (days <= 90) entry.days_61_90_fils += outstanding;
    else entry.over_90_fils += outstanding;
    entry.total_fils += outstanding;
    entry.invoices += 1;
    byCustomer.set(key, entry);
  }

  const buckets = [...byCustomer.values()].sort((a, b) => b.total_fils - a.total_fils);
  return {
    as_of: asOf,
    buckets,
    totals: {
      current_fils: buckets.reduce((sum, row) => sum + row.current_fils, 0),
      days_31_60_fils: buckets.reduce((sum, row) => sum + row.days_31_60_fils, 0),
      days_61_90_fils: buckets.reduce((sum, row) => sum + row.days_61_90_fils, 0),
      over_90_fils: buckets.reduce((sum, row) => sum + row.over_90_fils, 0),
      total_fils: buckets.reduce((sum, row) => sum + row.total_fils, 0),
      customers: buckets.length,
    },
  };
}

