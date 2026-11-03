-- Till sessions (Phase 4D).
--
-- A shift has a starting float and an ending count, and every cash payment and
-- refund made during it is attached to the session that was open at the time.
-- That attachment — not a timestamp window — is what makes the cash-up exact:
-- a payment taken at 14:03 belongs to the session it was recorded under, even
-- if someone closes the till ten minutes later.
--
-- One open session per device, enforced by a partial unique index. A second open
-- till on the same device is a mistake, not a feature.

CREATE TABLE till_sessions (
  id                 TEXT PRIMARY KEY,
  tenant_id          TEXT NOT NULL,
  branch_id          TEXT,
  device_id          TEXT NOT NULL,
  opened_by          TEXT,
  opened_at          TEXT NOT NULL,
  opening_float_fils INTEGER NOT NULL DEFAULT 0,
  closed_by          TEXT,
  closed_at          TEXT,
  -- Filled by the server at close, from the payments and refunds attached here.
  expected_fils      INTEGER,
  counted_fils       INTEGER,
  variance_fils      INTEGER,
  status             TEXT NOT NULL DEFAULT 'open'
                       CHECK (status IN ('open', 'closed')),
  notes              TEXT,
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL,
  created_by         TEXT,
  updated_by         TEXT,
  version            INTEGER NOT NULL DEFAULT 1,
  deleted_at         TEXT
);
CREATE UNIQUE INDEX idx_till_open_per_device
  ON till_sessions (tenant_id, device_id) WHERE status = 'open';
CREATE INDEX idx_till_branch_day ON till_sessions (tenant_id, branch_id, opened_at);

-- Refunds are cash leaving the same drawer, so they belong to a session too.
ALTER TABLE refunds ADD COLUMN till_session_id TEXT;
CREATE INDEX idx_refunds_session ON refunds (till_session_id);
