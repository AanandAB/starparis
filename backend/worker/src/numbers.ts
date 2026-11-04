/**
 * Number-block leasing.
 *
 * Job numbers, quote numbers and invoice numbers have to be short enough to say
 * on the phone. Gapless counters do not survive an offline device, so each
 * device leases a block of 100 and spends it locally. When fewer than 20
 * remain, the device asks for another in the background; if it runs out while
 * offline it issues a temporary `T-0007` and swaps it on sync.
 *
 * Both statements below are single-statement and therefore atomic in D1. The
 * INSERT..SELECT computes the next free range inside the same statement, so two
 * devices leasing at the same instant cannot receive the same block.
 *
 * The prefix on a series (`INV`, `QT`, `JOB`) is shop data, not code: it lives
 * in Settings and the owner may rename it. A block is therefore resolved
 * against the tenant's settings at lease time, so the row recorded here — and
 * the number the customer reads — carries the prefix the shop sees in Settings
 * today, even if the device asked with the one it remembered from yesterday.
 */

import type { Env } from './types';
import { loadSettings, type ShopSettings } from './settings';

export interface NumberBlock {
  start: number;
  end: number;
  /**
   * The series the block was really leased under, prefix included. Usually the
   * series that was asked for; different when Settings was renamed and the
   * device had not refreshed yet.
   */
  series: string;
}

/** The number series a shop issues. The kind is what the code reasons about —
 *  the prefix is only how that kind is spelled today. */
export type SeriesKind =
  | 'job'
  | 'quote'
  | 'invoice'
  | 'credit_note'
  | 'delivery'
  | 'quick_sale';

const DEFAULT_PREFIXES: Record<SeriesKind, string> = {
  job: 'JOB',
  quote: 'QT',
  invoice: 'INV',
  credit_note: 'CN',
  delivery: 'DN',
  quick_sale: 'QS',
};

/**
 * Prefix per kind for one tenant. Invoice/quote/job come from Settings; credit
 * notes and delivery notes keep their default because Settings has no field for
 * them yet — inventing a value here would let the lease endpoint print a prefix
 * the owner can neither see nor change.
 */
export function prefixesFromSettings(settings: ShopSettings): Record<SeriesKind, string> {
  return {
    job: settings.numbers.order_prefix,
    quote: settings.numbers.quote_prefix,
    invoice: settings.numbers.invoice_prefix,
    credit_note: DEFAULT_PREFIXES.credit_note,
    delivery: DEFAULT_PREFIXES.delivery,
    // Settings has no field for a quick-sale prefix yet, exactly like credit
    // notes and delivery notes: inventing a value here would let the lease
    // endpoint print a prefix the owner can neither see nor change.
    quick_sale: DEFAULT_PREFIXES.quick_sale,
  };
}

/**
 * Rewrites the leading prefix of `series` to the one the shop has configured.
 *
 * `series` arrives as `<prefix>-<branch>-<device>`, e.g. `INV-SHJ1-PC1`. Both
 * the configured prefix and the default count as "this is an invoice series",
 * because a device that has not pulled the new settings since a rename still
 * sends the old string — and that device must not keep numbering into a series
 * the shop no longer prints.
 *
 * An unrecognised string is returned untouched: the lease endpoint is generic,
 * and silently renaming something we do not understand would move somebody's
 * counter into a different sequence without anyone asking for it.
 */
export function resolveSeriesPrefix(
  series: string,
  prefixes: Record<SeriesKind, string>,
): string {
  // Longest prefix first, so a shop that renames `INV` to `INVX` does not have
  // `INV` matched inside `INVX-…` and the leftover `X-` glued into the tail.
  const candidates: Array<{ prefix: string; kind: SeriesKind }> = [];
  for (const kind of Object.keys(DEFAULT_PREFIXES) as SeriesKind[]) {
    for (const prefix of new Set([prefixes[kind], DEFAULT_PREFIXES[kind]])) {
      candidates.push({ prefix, kind });
    }
  }
  candidates.sort((a, b) => b.prefix.length - a.prefix.length);

  for (const candidate of candidates) {
    if (series === candidate.prefix) return prefixes[candidate.kind];
    if (series.startsWith(`${candidate.prefix}-`)) {
      return `${prefixes[candidate.kind]}${series.slice(candidate.prefix.length)}`;
    }
  }
  return series;
}

/**
 * Leases the next range for a series. Each call inserts one row describing the
 * range it handed out; the device keeps a local cursor inside that range and
 * asks again when fewer than 20 numbers remain.
 *
 * The INSERT..SELECT computes the next free range inside the same statement,
 * so there is no read-then-write race. D1 executes statements serially per
 * database and the primary key is (device, series, start), so a collision —
 * which would mean two devices got the same numbers — fails loudly instead of
 * silently duplicating an invoice number.
 */
export async function leaseBlock(
  env: Env,
  tenantId: string,
  deviceId: string,
  series: string,
  size = 100,
): Promise<NumberBlock> {
  if (size <= 0 || size > 10_000) {
    throw new Error('Block size must be between 1 and 10000');
  }

  // The prefix is read per lease rather than cached: Settings is written rarely
  // and read here once per 100 numbers, so correctness is cheap. Renaming the
  // invoice prefix therefore starts a new series on the very next lease, and the
  // numbers already handed out are untouched — they are plain strings on the
  // document, and the one thing that must never happen is an old invoice
  // changing its number because a prefix was edited.
  const settings = await loadSettings(env, tenantId);
  const resolvedSeries = resolveSeriesPrefix(series, prefixesFromSettings(settings));

  const result = await env.DB.prepare(
    `INSERT INTO number_blocks
        (tenant_id, device_id, series, start_no, end_no, next_no, leased_at)
     SELECT ?, ?, ?,
            COALESCE(MAX(end_no), 0) + 1,
            COALESCE(MAX(end_no), 0) + ?,
            COALESCE(MAX(end_no), 0) + 1,
            ?
       FROM number_blocks
      WHERE tenant_id = ? AND series = ?
  RETURNING start_no, end_no`,
  )
    .bind(tenantId, deviceId, resolvedSeries, size, new Date().toISOString(), tenantId, resolvedSeries)
    .all<{ start_no: number; end_no: number }>();

  const row = result.results?.[0];
  if (!row) {
    throw new Error('Could not lease a number block');
  }
  return {
    start: Number(row.start_no),
    end: Number(row.end_no),
    series: resolvedSeries,
  };
}

/**
 * Human-readable series key: prefix + branch + device, so invoice numbering
 * stays gapless. In production the prefix comes from Settings (see
 * {@link prefixesFromSettings}); the defaults are the shape a fresh tenant and
 * a not-yet-refreshed device use.
 */
export function seriesKey(
  kind: SeriesKind,
  branchCode: string,
  deviceCode: string,
  prefixes: Record<SeriesKind, string> = DEFAULT_PREFIXES,
): string {
  return `${prefixes[kind]}-${branchCode.toUpperCase()}-${deviceCode.toUpperCase()}`;
}
