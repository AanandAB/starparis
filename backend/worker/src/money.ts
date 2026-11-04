/**
 * Money: invoice issue rules and payment arithmetic.
 *
 * Everything here is server-side on purpose. An invoice is the one document in
 * the system that can end up in front of a tax inspector, so:
 *   - it can be issued once per order;
 *   - it can never be edited after issue (only voided, and only before money
 *     has been taken);
 *   - `paid_fils` and the paid/part-paid status are computed from `payments`
 *     and written by the server, never trusted from a device.
 */

import type { AuthContext, Env } from './types';

type Row = Record<string, unknown>;

const MANAGERS: ReadonlySet<string> = new Set(['owner', 'manager']);

export const PAYMENT_METHODS: ReadonlySet<string> = new Set([
  'cash',
  'card',
  'transfer',
  'cheque',
]);

/**
 * The methods a deposit may be taken by. Narrower than payments: an advance
 * over a cheque would be money the shop does not hold, so it is excluded.
 */
export const DEPOSIT_METHODS: ReadonlySet<string> = new Set([
  'cash',
  'card',
  'transfer',
]);

export interface MoneyError {
  code: string;
  message: string;
}

/** Cash paid for an invoice, from the payments table. */
export async function paidTotal(
  env: Env,
  invoiceId: string,
): Promise<number> {
  const row = await env.DB.prepare(
    'SELECT COALESCE(SUM(amount_fils), 0) AS paid FROM payments WHERE invoice_id = ? AND deleted_at IS NULL',
  )
    .bind(invoiceId)
    .first<{ paid: number }>();
  return Number(row?.paid ?? 0);
}

/** Status implied by the amount settled (cash + credits). */
export function statusForPaid(paidFils: number, totalFils: number): string {
  if (paidFils <= 0) return 'issued';
  if (paidFils >= totalFils) return 'paid';
  return 'part_paid';
}

/**
 * A credit note against an invoice. It may be issued at any time — including
 * after the invoice was paid, which is the normal return-and-refund path — but
 * never beyond what is left to credit.
 */
export function prepareCreditNote(
  fields: Row,
  invoice: Row,
): { note: Row; invoiceUpdate: Row } | { error: MoneyError } {
  const total = Number(fields['total_fils'] ?? 0);
  if (!Number.isInteger(total) || total <= 0) {
    return { error: { code: 'INVALID_AMOUNT', message: 'A credit note must be more than zero.' } };
  }

  if (String(invoice['status']) === 'void') {
    return { error: { code: 'INVOICE_VOID', message: 'This invoice is void.' } };
  }

  const invoiceTotal = Number(invoice['total_fils'] ?? 0);
  const alreadyCredited = Number(invoice['credited_fils'] ?? 0);
  const creditable = invoiceTotal - alreadyCredited;
  if (total > creditable) {
    return {
      error: {
        code: 'OVER_CREDIT',
        message: `Only ${(creditable / 100).toFixed(2)} can still be credited on this invoice.`,
      },
    };
  }

  if (String(fields['reason'] ?? '').trim().length < 3) {
    return {
      error: { code: 'REASON_REQUIRED', message: 'Say why the credit note is being issued.' },
    };
  }

  const vatBps = Number(fields['vat_bps'] ?? invoice['vat_bps'] ?? 500);
  // The credit mirrors the invoice: the VAT portion is computed on the credited
  // amount at the invoice's rate, not at today's rate.
  const creditedSubtotal = Math.round((total * 10000) / (10000 + vatBps));
  const creditedVat = total - creditedSubtotal;

  const now = new Date().toISOString();
  const creditedAfter = alreadyCredited + total;
  const settled = Number(invoice['paid_fils'] ?? 0) + creditedAfter;

  return {
    note: {
      ...fields,
      subtotal_fils: creditedSubtotal,
      vat_bps: vatBps,
      vat_fils: creditedVat,
      total_fils: total,
      refunded_fils: 0,
      issued_at: fields['issued_at'] ?? now,
    },
    invoiceUpdate: {
      credited_fils: creditedAfter,
      status: statusForPaid(settled, invoiceTotal),
      updated_at: now,
      version: Number(invoice['version'] ?? 1) + 1,
      changedFields: ['credited_fils', 'status'],
    },
  };
}

/**
 * Cash going back to the customer, against a credit note. Never more than the
 * note is worth, and never more than remains unrefunded.
 */
export function prepareRefund(
  fields: Row,
  creditNote: Row,
  ctx: AuthContext,
): { refund: Row; noteUpdate: Row } | { error: MoneyError } {
  if (!MANAGERS.has(ctx.role)) {
    return {
      error: { code: 'PERMISSION_DENIED', message: 'Only a manager can refund money.' },
    };
  }

  const amount = Number(fields['amount_fils'] ?? 0);
  if (!Number.isInteger(amount) || amount <= 0) {
    return { error: { code: 'INVALID_AMOUNT', message: 'A refund must be more than zero.' } };
  }

  const method = String(fields['method'] ?? '');
  if (!PAYMENT_METHODS.has(method)) {
    return {
      error: {
        code: 'INVALID_METHOD',
        message: `Refund method must be one of ${[...PAYMENT_METHODS].join(', ')}.`,
      },
    };
  }

  const noteTotal = Number(creditNote['total_fils'] ?? 0);
  const alreadyRefunded = Number(creditNote['refunded_fils'] ?? 0);
  const refundable = noteTotal - alreadyRefunded;
  if (amount > refundable) {
    return {
      error: {
        code: 'OVER_REFUND',
        message: `Only ${(refundable / 100).toFixed(2)} is left to refund on this credit note.`,
      },
    };
  }

  const now = new Date().toISOString();
  return {
    refund: {
      ...fields,
      amount_fils: amount,
      refunded_at: fields['refunded_at'] ?? now,
      refunded_by: ctx.userId,
    },
    noteUpdate: {
      refunded_fils: alreadyRefunded + amount,
      updated_at: now,
      version: Number(creditNote['version'] ?? 1) + 1,
    },
  };
}

/**
 * Rules for changing an invoice. Only two moves exist: void a clean invoice, or
 * let the server update the paid cache. Everything else is refused, because
 * "just fix the total" is how an audit goes wrong.
 */
export function prepareInvoicePatch(
  fields: Row,
  existing: Row,
  ctx: AuthContext,
): { fields: Row } | { error: MoneyError } {
  const next: Row = { ...fields };
  const from = String(existing['status'] ?? 'issued');
  const to = next['status'] === undefined ? from : String(next['status']);

  const touched = Object.keys(next).filter(
    (key) => key !== 'status' && key !== 'void_reason',
  );
  if (touched.length > 0) {
    return {
      error: {
        code: 'INVOICE_IMMUTABLE',
        message: `An issued invoice cannot be changed (${touched.join(', ')}). Use a credit note.`,
      },
    };
  }

  if (to === from) return { fields: next };

  if (to !== 'void') {
    return {
      error: {
        code: 'ILLEGAL_TRANSITION',
        message: `An invoice cannot move from ${from} to ${to}.`,
      },
    };
  }
  if (!MANAGERS.has(ctx.role)) {
    return {
      error: {
        code: 'PERMISSION_DENIED',
        message: 'Only a manager can void an invoice.',
      },
    };
  }
  if (String(next['void_reason'] ?? '').trim().length < 3) {
    return {
      error: {
        code: 'REASON_REQUIRED',
        message: 'Say why the invoice is being voided.',
      },
    };
  }
  if (Number(existing['paid_fils'] ?? 0) > 0) {
    return {
      error: {
        code: 'HAS_PAYMENTS',
        message: 'Money has been taken against this invoice. Issue a credit note instead.',
      },
    };
  }

  (next as Row)['status'] = 'void';
  return { fields: next };
}

/**
 * Validates a payment before it is written and returns the invoice update that
 * must travel with it, so the invoice balance can never lag behind the cash.
 */
export function preparePayment(
  fields: Row,
  invoice: Row,
  ctx: AuthContext,
): { payment: Row; invoiceUpdate: Row } | { error: MoneyError } {
  const amount = Number(fields['amount_fils'] ?? 0);
  if (!Number.isInteger(amount) || amount <= 0) {
    return { error: { code: 'INVALID_AMOUNT', message: 'A payment must be more than zero.' } };
  }

  const method = String(fields['method'] ?? '');
  if (!PAYMENT_METHODS.has(method)) {
    return {
      error: {
        code: 'INVALID_METHOD',
        message: `Payment method must be one of ${[...PAYMENT_METHODS].join(', ')}.`,
      },
    };
  }

  if (String(invoice['status']) === 'void') {
    return { error: { code: 'INVOICE_VOID', message: 'This invoice is void.' } };
  }

  const total = Number(invoice['total_fils'] ?? 0);
  const alreadyPaid = Number(invoice['paid_fils'] ?? 0);
  const outstanding = total - alreadyPaid;
  if (amount > outstanding) {
    return {
      error: {
        code: 'OVERPAYMENT',
        message: `Only ${(outstanding / 100).toFixed(2)} is outstanding on this invoice.`,
      },
    };
  }

  const now = new Date().toISOString();
  const payment: Row = {
    ...fields,
    amount_fils: amount,
    taken_at: fields['taken_at'] ?? now,
    taken_by: fields['taken_by'] ?? ctx.userId,
  };

  const paidAfter = alreadyPaid + amount;
  return {
    payment,
    invoiceUpdate: {
      paid_fils: paidAfter,
      status: statusForPaid(paidAfter, total),
      updated_at: now,
      version: Number(invoice['version'] ?? 1) + 1,
      changedFields: ['paid_fils', 'status'],
    },
  };
}

/**
 * What should be in the drawer at close: the float, plus cash taken, minus cash
 * refunded, all attached to this session. Card, transfer and cheque never touch
 * the drawer, so they are excluded by design.
 */
export async function expectedCash(
  env: Env,
  sessionId: string,
  openingFloatFils: number,
): Promise<number> {
  const row = await env.DB.prepare(
    `SELECT
        COALESCE((SELECT SUM(amount_fils) FROM payments
                   WHERE till_session_id = ? AND method = 'cash' AND deleted_at IS NULL), 0) AS taken,
        COALESCE((SELECT SUM(amount_fils) FROM refunds
                   WHERE till_session_id = ? AND method = 'cash' AND deleted_at IS NULL), 0) AS refunded,
        COALESCE((SELECT SUM(amount_fils) FROM expenses
                   WHERE till_session_id = ? AND method = 'cash' AND deleted_at IS NULL), 0) AS spent`,
  )
    .bind(sessionId, sessionId, sessionId)
    .first<{ taken: number; refunded: number; spent: number }>();

  return (
    openingFloatFils +
    Number(row?.taken ?? 0) -
    Number(row?.refunded ?? 0) -
    Number(row?.spent ?? 0)
  );
}

/**
 * What a customer still owes, across every live invoice. The same arithmetic
 * the ageing report and the invoice card use — `total - paid - credited` — so
 * the three places can never disagree about the same number.
 */
export async function customerOutstandingFils(
  env: Env,
  tenantId: string,
  customerId: string,
): Promise<number> {
  const row = await env.DB.prepare(
    `SELECT COALESCE(SUM(total_fils - paid_fils - credited_fils), 0) AS outstanding
       FROM invoices
      WHERE tenant_id = ? AND customer_id = ? AND deleted_at IS NULL AND status <> 'void'`,
  )
    .bind(tenantId, customerId)
    .first<{ outstanding: number }>();
  return Number(row?.outstanding ?? 0);
}

/**
 * How much of a customer's deposits has not yet been applied to an invoice.
 * `amount_fils - allocated_fils` summed over every live deposit.
 */
export async function depositBalanceFils(
  env: Env,
  tenantId: string,
  customerId: string,
): Promise<number> {
  const row = await env.DB.prepare(
    `SELECT COALESCE(SUM(amount_fils), 0) AS total,
            COALESCE(SUM(allocated_fils), 0) AS allocated
       FROM customer_deposits
      WHERE tenant_id = ? AND customer_id = ? AND deleted_at IS NULL`,
  )
    .bind(tenantId, customerId)
    .first<{ total: number; allocated: number }>();
  return Number(row?.total ?? 0) - Number(row?.allocated ?? 0);
}

/**
 * Applies [amountFils] of a deposit to an invoice: advances `allocated_fils`
 * on the deposit and records the allocation. Idempotent against a retried
 * batch — the `UNIQUE (deposit_id, invoice_id)` on `deposit_allocations` means
 * a second call for the same pair finds the existing row and is refused rather
 * than applying the money twice. It never updates the invoice: auto-applying
 * deposits at invoice time is out of scope, so the caller owns that step.
 */
export async function allocateDeposit(
  env: Env,
  tenantId: string,
  depositId: string,
  invoiceId: string,
  amountFils: number,
): Promise<{ ok: true } | { error: MoneyError }> {
  if (!Number.isInteger(amountFils) || amountFils <= 0) {
    return { error: { code: 'INVALID_AMOUNT', message: 'An allocation must be more than zero.' } };
  }

  const deposit = await env.DB.prepare(
    'SELECT * FROM customer_deposits WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL',
  )
    .bind(depositId, tenantId)
    .first<Row>();
  if (!deposit) {
    return { error: { code: 'NOT_FOUND', message: 'That deposit does not exist.' } };
  }

  const already = await env.DB.prepare(
    'SELECT 1 AS present FROM deposit_allocations WHERE deposit_id = ? AND invoice_id = ?',
  )
    .bind(depositId, invoiceId)
    .first<{ present: number }>();
  if (already) {
    return {
      error: {
        code: 'ALREADY_ALLOCATED',
        message: 'This deposit was already applied to that invoice.',
      },
    };
  }

  const available = Number(deposit['amount_fils'] ?? 0) - Number(deposit['allocated_fils'] ?? 0);
  if (amountFils > available) {
    return {
      error: {
        code: 'OVER_ALLOCATION',
        message: `Only ${(available / 100).toFixed(2)} is left unallocated on this deposit.`,
      },
    };
  }

  const now = new Date().toISOString();
  await env.DB.batch([
    env.DB.prepare(
      'UPDATE customer_deposits SET allocated_fils = allocated_fils + ?, updated_at = ?, version = version + 1 WHERE id = ? AND tenant_id = ?',
    ).bind(amountFils, now, depositId, tenantId),
    env.DB.prepare(
      'INSERT INTO deposit_allocations (id, tenant_id, deposit_id, invoice_id, amount_fils, created_at) VALUES (?, ?, ?, ?, ?, ?)',
    ).bind(crypto.randomUUID(), tenantId, depositId, invoiceId, amountFils, now),
  ]);

  return { ok: true };
}

/**
 * The gate an invoice passes when it is issued: the customer's outstanding plus
 * the new total must stay under their credit limit, unless the issuer is an
 * owner or manager (the override). A zero limit is a cash customer — no credit
 * to exceed — so they are never blocked.
 */
export async function enforceCreditLimit(
  env: Env,
  ctx: AuthContext,
  customerId: string,
  newTotalFils: number,
): Promise<MoneyError | null> {
  if (MANAGERS.has(ctx.role)) return null;

  const customer = await env.DB.prepare(
    'SELECT credit_limit_fils FROM customers WHERE id = ? AND tenant_id = ?',
  )
    .bind(customerId, ctx.tenantId)
    .first<{ credit_limit_fils: number }>();
  const limit = Number(customer?.credit_limit_fils ?? 0);
  if (limit <= 0) return null;

  const outstanding = await customerOutstandingFils(env, ctx.tenantId, customerId);
  if (outstanding + newTotalFils > limit) {
    return {
      code: 'CREDIT_LIMIT_EXCEEDED',
      message: `This invoice would take the customer to ${((outstanding + newTotalFils) / 100).toFixed(2)} against a ${(limit / 100).toFixed(2)} credit limit.`,
    };
  }
  return null;
}
