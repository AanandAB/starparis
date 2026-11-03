-- Money (Phase 4A): invoices, invoice lines and payments.
--
-- Three rules shape this schema, and they come from the accountant, not from us:
--
--  1. An issued invoice is a legal document. Nothing on it changes afterwards —
--     no totals, no customer, no lines. Corrections are credit notes (Phase 4B),
--     never edits.
--  2. VAT is computed once, on the discounted taxable amount, and stored. The
--     invoice never recomputes it from a current rate.
--  3. Money received is a separate fact from the invoice. `paid_fils` on the
--     invoice is a cache the server maintains from `payments`; if the two ever
--     disagree, `payments` is right.

CREATE TABLE invoices (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL,
  branch_id      TEXT,
  order_id       TEXT NOT NULL,
  -- INV-SHJ1-PC1-00123: the device is in the number, because two counters in
  -- one branch both allocating 00123 breaks uniqueness and sequence.
  number         TEXT NOT NULL,
  issued_at      TEXT NOT NULL,
  due_at         TEXT,
  customer_id    TEXT NOT NULL,
  -- Snapshot: the customer's name, TRN and address as printed, not as they are
  -- today. A customer who changes their TRN must not rewrite last year's invoice.
  customer_name  TEXT NOT NULL,
  customer_trn   TEXT,
  customer_address TEXT,
  subtotal_fils  INTEGER NOT NULL,
  discount_fils  INTEGER NOT NULL DEFAULT 0,
  vat_bps        INTEGER NOT NULL DEFAULT 500,
  vat_fils       INTEGER NOT NULL,
  total_fils     INTEGER NOT NULL,
  -- Maintained by the server from payments; never written by a device.
  paid_fils      INTEGER NOT NULL DEFAULT 0,
  status         TEXT NOT NULL DEFAULT 'issued'
                   CHECK (status IN ('issued', 'part_paid', 'paid', 'void')),
  notes          TEXT,
  void_reason    TEXT,
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  created_by     TEXT,
  updated_by     TEXT,
  version        INTEGER NOT NULL DEFAULT 1,
  deleted_at     TEXT
);
CREATE UNIQUE INDEX idx_invoices_number ON invoices (tenant_id, number);
-- One live invoice per order. A void one may be reissued with a new number.
CREATE UNIQUE INDEX idx_invoices_order ON invoices (order_id) WHERE status <> 'void';
CREATE INDEX idx_invoices_customer ON invoices (tenant_id, customer_id, issued_at);

CREATE TABLE invoice_lines (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  invoice_id    TEXT NOT NULL,
  line_no       INTEGER NOT NULL,
  description   TEXT NOT NULL,
  quantity      INTEGER NOT NULL,
  unit_fils     INTEGER NOT NULL,
  amount_fils   INTEGER NOT NULL,
  vat_bps       INTEGER NOT NULL DEFAULT 500,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  created_by    TEXT,
  updated_by    TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE INDEX idx_invoice_lines ON invoice_lines (invoice_id, line_no);

CREATE TABLE payments (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL,
  branch_id      TEXT,
  invoice_id     TEXT NOT NULL,
  amount_fils    INTEGER NOT NULL CHECK (amount_fils > 0),
  method         TEXT NOT NULL
                   CHECK (method IN ('cash', 'card', 'transfer', 'cheque')),
  reference      TEXT,
  taken_at       TEXT NOT NULL,
  taken_by       TEXT,
  -- A cash count ties payments to a shift; nullable until till sessions land.
  till_session_id TEXT,
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  created_by     TEXT,
  version        INTEGER NOT NULL DEFAULT 1,
  deleted_at     TEXT
);
CREATE INDEX idx_payments_invoice ON payments (invoice_id, taken_at);
CREATE INDEX idx_payments_day ON payments (tenant_id, branch_id, taken_at);
