-- Credit notes and refunds (Phase 4B).
--
-- An issued invoice is never edited, so the only way money comes back is a
-- credit note against it, and the only way cash comes back is a refund against
-- that credit note. Two documents, two signatures, one trail — which is exactly
-- what an auditor asks for and what "just change the total" destroys.
--
-- `invoices.credited_fils` is the server-maintained mirror of the credit notes,
-- next to `paid_fils`: settled = paid + credited. The invoice status keeps its
-- existing vocabulary (issued / part_paid / paid) because SQLite cannot alter a
-- CHECK constraint in place; the accountant reads the amounts, and the UI and
-- the printed document both show "credited" explicitly.

ALTER TABLE invoices ADD COLUMN credited_fils INTEGER NOT NULL DEFAULT 0;

CREATE TABLE credit_notes (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  branch_id     TEXT,
  invoice_id    TEXT NOT NULL,
  number        TEXT NOT NULL,
  issued_at     TEXT NOT NULL,
  -- Why the customer is being credited. Mandatory: a credit note with no reason
  -- is the first thing a VAT inspector questions.
  reason        TEXT NOT NULL,
  subtotal_fils INTEGER NOT NULL,
  vat_bps       INTEGER NOT NULL DEFAULT 500,
  vat_fils      INTEGER NOT NULL,
  total_fils    INTEGER NOT NULL,
  -- Cash actually returned against this note; the server maintains it.
  refunded_fils INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  created_by    TEXT,
  updated_by    TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE UNIQUE INDEX idx_credit_notes_number ON credit_notes (tenant_id, number);
CREATE INDEX idx_credit_notes_invoice ON credit_notes (invoice_id, issued_at);

CREATE TABLE refunds (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL,
  branch_id      TEXT,
  credit_note_id TEXT NOT NULL,
  invoice_id     TEXT NOT NULL,
  amount_fils    INTEGER NOT NULL CHECK (amount_fils > 0),
  method         TEXT NOT NULL
                   CHECK (method IN ('cash', 'card', 'transfer', 'cheque')),
  reference      TEXT,
  refunded_at    TEXT NOT NULL,
  refunded_by    TEXT,
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  created_by     TEXT,
  version        INTEGER NOT NULL DEFAULT 1,
  deleted_at     TEXT
);
CREATE INDEX idx_refunds_note ON refunds (credit_note_id, refunded_at);
CREATE INDEX idx_refunds_day ON refunds (tenant_id, branch_id, refunded_at);
