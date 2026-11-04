-- Customer deposits (Phase 8B): money taken before an invoice exists.
--
-- A deposit is cash in hand that has no invoice to hang on yet — an advance, a
-- booking fee, a "we will start when you pay half". It lowers what the customer
-- actually owes, so it is a fact once taken, exactly like a payment: it can
-- never be edited or deleted (a refund is a separate, future path), and the
-- only thing that ever changes is `allocated_fils`, which the server advances
-- as the deposit is applied to invoices later.
--
-- `allocated_fils` is how much of the deposit has been applied, so the balance
-- still available is `amount_fils - allocated_fils`. A deposit's method is one
-- of the three the counter takes at the desk — no cheque on an advance.

CREATE TABLE customer_deposits (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL,
  branch_id      TEXT,
  customer_id    TEXT NOT NULL,
  amount_fils    INTEGER NOT NULL CHECK (amount_fils > 0),
  method         TEXT NOT NULL
                   CHECK (method IN ('cash', 'card', 'transfer')),
  note           TEXT,
  allocated_fils INTEGER NOT NULL DEFAULT 0,
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  created_by     TEXT,
  version        INTEGER NOT NULL DEFAULT 1,
  deleted_at     TEXT
);
CREATE INDEX idx_customer_deposits_customer ON customer_deposits (tenant_id, customer_id);

-- One row per (deposit, invoice) pair a deposit has been applied to. The
-- unique pair is what makes a retried allocation idempotent: replaying the
-- same allocation finds this row and is refused, so money can never be applied
-- to the same invoice twice.
CREATE TABLE deposit_allocations (
  id          TEXT PRIMARY KEY,
  tenant_id   TEXT NOT NULL,
  deposit_id  TEXT NOT NULL,
  invoice_id  TEXT NOT NULL,
  amount_fils INTEGER NOT NULL CHECK (amount_fils > 0),
  created_at  TEXT NOT NULL,
  created_by  TEXT,
  UNIQUE (deposit_id, invoice_id)
);
CREATE INDEX idx_deposit_allocations_deposit ON deposit_allocations (deposit_id);
