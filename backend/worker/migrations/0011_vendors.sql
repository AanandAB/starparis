-- Vendors and the work handed to them (Phase 7A).
--
-- A vendor job is not a note on an order: it is a commitment with a cost and a
-- date. The shop needs to know three things at any moment — what is out, when it
-- was promised back, and what it costs against what the customer pays — so both
-- live in their own table with their own status.

CREATE TABLE vendors (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL,
  -- NULL means the vendor works for the whole shop, not one branch.
  branch_id  TEXT,
  name       TEXT NOT NULL,
  -- Free text: "embroidery", "offset", "binding". A fixed list is wrong in a
  -- month and blocks the first vendor who does something else.
  trade      TEXT,
  phone_e164 TEXT,
  notes      TEXT,
  active     INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_by TEXT,
  updated_by TEXT,
  version    INTEGER NOT NULL DEFAULT 1,
  deleted_at TEXT
);
CREATE INDEX idx_vendors_name ON vendors (tenant_id, name);

CREATE TABLE vendor_jobs (
  id             TEXT PRIMARY KEY,
  tenant_id      TEXT NOT NULL,
  branch_id      TEXT,
  -- The job this belongs to. NOT NULL: work handed out for no order is a
  -- purchase, and purchases are expenses, not vendor jobs.
  order_id       TEXT NOT NULL,
  vendor_id      TEXT NOT NULL,
  description    TEXT NOT NULL,
  qty            INTEGER NOT NULL DEFAULT 0,
  -- What the vendor charges us. The margin is the order total minus this.
  cost_fils      INTEGER NOT NULL CHECK (cost_fils >= 0),
  vat_fils       INTEGER NOT NULL DEFAULT 0,
  -- draft (being written) -> sent (with the vendor) -> received (back, checked)
  -- -> closed (invoiced/costed) ; cancelled from any open state.
  status         TEXT NOT NULL DEFAULT 'draft'
                   CHECK (status IN ('draft', 'sent', 'received', 'closed', 'cancelled')),
  promised_at    TEXT,
  sent_at        TEXT,
  received_at    TEXT,
  notes          TEXT,
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL,
  created_by     TEXT,
  updated_by     TEXT,
  version        INTEGER NOT NULL DEFAULT 1,
  deleted_at     TEXT
);
CREATE INDEX idx_vendor_jobs_order ON vendor_jobs (tenant_id, order_id);
CREATE INDEX idx_vendor_jobs_open ON vendor_jobs (tenant_id, status);
