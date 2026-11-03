-- Proofs, approvals and time (Phase 3B).
--
-- Proofs are stored as LINKS, not bytes. That is a deliberate v1 decision: the
-- shop already sends artwork by WhatsApp and Drive, R2 is not enabled on this
-- account, and D1 rows are capped at 2 MB. What the system adds is the record —
-- which version went to the customer, when, and what they said — plus the
-- rework loop when they say no.
--
-- `revision` is the proof number the customer sees (v1, v2, …); `version` is
-- row-level optimistic concurrency, as on every other table. Two different
-- things with similar names, so they are spelled differently on purpose.

CREATE TABLE proofs (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  branch_id     TEXT,
  order_id      TEXT NOT NULL,
  revision      INTEGER NOT NULL DEFAULT 1,
  kind          TEXT NOT NULL DEFAULT 'proof'
                  CHECK (kind IN ('proof', 'artwork', 'final')),
  label         TEXT NOT NULL,
  url           TEXT NOT NULL,
  note          TEXT,
  status        TEXT NOT NULL DEFAULT 'draft'
                  CHECK (status IN ('draft', 'sent', 'approved', 'rejected', 'superseded')),
  sent_at       TEXT,
  decided_at    TEXT,
  decided_note  TEXT,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  created_by    TEXT,
  updated_by    TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE INDEX idx_proofs_order ON proofs (order_id, revision);
CREATE INDEX idx_proofs_status ON proofs (tenant_id, status, updated_at);

-- Time is recorded by the SERVER, never by the device: a counter PC with a
-- wrong clock must not be able to bill an hour that never happened. One row per
-- stretch of work, written when a task leaves in_progress.
CREATE TABLE time_entries (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL,
  branch_id  TEXT,
  task_id    TEXT NOT NULL,
  order_id   TEXT NOT NULL,
  user_id    TEXT,
  started_at TEXT NOT NULL,
  ended_at   TEXT NOT NULL,
  minutes    INTEGER NOT NULL,
  auto       INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  version    INTEGER NOT NULL DEFAULT 1,
  deleted_at TEXT
);
CREATE INDEX idx_time_task ON time_entries (task_id, started_at);
CREATE INDEX idx_time_order ON time_entries (order_id, started_at);
