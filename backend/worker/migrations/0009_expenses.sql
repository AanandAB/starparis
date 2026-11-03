-- Expenses (Phase 4E).
--
-- A shop pays for things out of the drawer all day: a taxi, a courier, paper
-- from the shop next door. Those are not invoices to a customer, but they are
-- money, and cash spent must leave the till or the cash-up will never reconcile.
--
-- `till_session_id` is what ties a cash expense to the shift that paid it — the
-- same mechanism payments and refunds use, and the reason `expectedCash()`
-- subtracts it.

CREATE TABLE expenses (
  id              TEXT PRIMARY KEY,
  tenant_id       TEXT NOT NULL,
  branch_id       TEXT,
  spent_at        TEXT NOT NULL,
  -- Free text on purpose: a fixed list of categories is wrong within a month,
  -- and the accountant only needs the category to group the export.
  category        TEXT NOT NULL,
  supplier        TEXT,
  description     TEXT NOT NULL,
  amount_fils     INTEGER NOT NULL CHECK (amount_fils > 0),
  -- VAT included in the amount, as printed on the receipt. Zero for the many
  -- small receipts that carry none.
  vat_fils        INTEGER NOT NULL DEFAULT 0,
  method          TEXT NOT NULL
                    CHECK (method IN ('cash', 'card', 'transfer', 'cheque')),
  receipt_url     TEXT,
  paid_by         TEXT,
  till_session_id TEXT,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL,
  created_by      TEXT,
  updated_by      TEXT,
  version         INTEGER NOT NULL DEFAULT 1,
  deleted_at      TEXT
);
CREATE INDEX idx_expenses_day ON expenses (tenant_id, branch_id, spent_at);
CREATE INDEX idx_expenses_session ON expenses (till_session_id);
