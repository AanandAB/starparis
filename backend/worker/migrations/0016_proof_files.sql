-- Proof files in D1, customer approval page, and the approval record.
--
-- The proof row keeps `url` for link-only proofs, but when the shop uploads the
-- actual artwork the FILE is the authoritative copy. It is stored as 256 KB
-- chunks because a single D1 row is capped well under a multi-megabyte file,
-- and the chunks are reassembled in `seq` order when served. The approval token
-- is the customer's login: a long random link, no account and no password, so
-- the approval page can show the proof and record the decision with no auth.
--
-- Files are kept 60 days and then purged by a scheduled job (documented in
-- docs/screen-flow.md). The purge itself is not built yet.

ALTER TABLE proofs ADD COLUMN approval_token TEXT;
ALTER TABLE proofs ADD COLUMN file_sha256 TEXT;
ALTER TABLE proofs ADD COLUMN file_size INTEGER;
ALTER TABLE proofs ADD COLUMN mime_type TEXT;
ALTER TABLE proofs ADD COLUMN thumbnail BLOB;
-- SQLite cannot add a UNIQUE column constraint via ALTER TABLE, so the
-- uniqueness of the token is a separate index.
CREATE UNIQUE INDEX idx_proofs_approval_token ON proofs (approval_token);

CREATE TABLE file_chunks (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL,
  proof_id   TEXT NOT NULL,
  seq        INTEGER NOT NULL,
  sha256     TEXT,
  data       BLOB NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE (proof_id, seq)
);

CREATE TABLE proof_approvals (
  id           TEXT PRIMARY KEY,
  tenant_id    TEXT NOT NULL,
  proof_id     TEXT NOT NULL,
  decision     TEXT NOT NULL CHECK (decision IN ('approved', 'rejected')),
  note         TEXT,
  channel      TEXT,
  decider_name TEXT,
  decided_at   TEXT NOT NULL
);
CREATE INDEX idx_proof_approvals_proof ON proof_approvals (proof_id);
