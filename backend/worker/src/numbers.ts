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
 */

import type { Env } from './types';

export interface NumberBlock {
  start: number;
  end: number;
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
    .bind(tenantId, deviceId, series, size, new Date().toISOString(), tenantId, series)
    .all<{ start_no: number; end_no: number }>();

  const row = result.results?.[0];
  if (!row) {
    throw new Error('Could not lease a number block');
  }
  return { start: Number(row.start_no), end: Number(row.end_no) };
}

/** Human-readable series key: branch + device, so invoice numbering stays gapless. */
export function seriesKey(kind: 'job' | 'quote' | 'invoice' | 'credit_note' | 'delivery', branchCode: string, deviceCode: string): string {
  const prefix: Record<typeof kind, string> = {
    job: 'JOB',
    quote: 'QT',
    invoice: 'INV',
    credit_note: 'CN',
    delivery: 'DN',
  };
  return `${prefix[kind]}-${branchCode.toUpperCase()}-${deviceCode.toUpperCase()}`;
}
