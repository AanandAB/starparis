-- Quick sales at the counter (Phase 5A).
--
-- A walk-in sale: the customer pays now and walks out with the work. Unlike an
-- order it has no quote, no production pipeline and no invoice — the sale row IS
-- the record, and the payment is on the same row. A sale, once rung, is never
-- edited; a correction is a refund later (not built yet).
--
-- Numbering follows the orders convention: `number` is the integer the device
-- leased, `number_display` is what the customer reads (`QS-SHJ1-PC1-00001`, or
-- `QS-T-0007` while offline), and uniqueness is on the display string because
-- two counters in one branch lease different series. `device_id` is stamped by
-- the server from the token, exactly like a till session.

CREATE TABLE quick_sales (
  id               TEXT PRIMARY KEY,
  tenant_id        TEXT NOT NULL,
  branch_id        TEXT,
  number           INTEGER,
  number_display   TEXT NOT NULL,
  -- Walk-in sales have no customer; the name is captured when one is given.
  customer_id      TEXT,
  customer_name    TEXT,
  status           TEXT NOT NULL DEFAULT 'paid',
  payment_method   TEXT NOT NULL
                     CHECK (payment_method IN ('cash', 'card', 'transfer')),
  subtotal_fils    INTEGER NOT NULL DEFAULT 0,
  vat_fils         INTEGER NOT NULL DEFAULT 0,
  total_fils       INTEGER NOT NULL DEFAULT 0,
  paid_fils        INTEGER NOT NULL DEFAULT 0,
  device_id        TEXT NOT NULL,
  created_at       TEXT NOT NULL,
  updated_at       TEXT NOT NULL,
  created_by       TEXT,
  updated_by       TEXT,
  version          INTEGER NOT NULL DEFAULT 1,
  deleted_at       TEXT
);
CREATE UNIQUE INDEX idx_quick_sales_number_display ON quick_sales (tenant_id, number_display);
CREATE INDEX idx_quick_sales_branch_updated ON quick_sales (tenant_id, branch_id, updated_at);

CREATE TABLE quick_sale_lines (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  branch_id     TEXT,
  quick_sale_id TEXT NOT NULL,
  product_id    TEXT,
  description   TEXT NOT NULL,
  quantity      INTEGER NOT NULL,
  -- Unit price before VAT; the sale row carries the rolled-up VAT, so a line
  -- needs no vat column of its own.
  unit_fils     INTEGER NOT NULL,
  amount_fils   INTEGER NOT NULL,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  created_by    TEXT,
  updated_by    TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE INDEX idx_quick_sale_lines_sale ON quick_sale_lines (tenant_id, quick_sale_id);
