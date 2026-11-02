-- Star Paris Graphic — foundation schema (Phase 1A).
--
-- Conventions, applied to every table from here on:
--   id            UUIDv7 generated on the device (TEXT, lexicographic order = creation order)
--   tenant_id     every table, from day one, so the product can be resold
--   branch_id     nullable: NULL means organisation-level (products, price books, vendors)
--   version       optimistic concurrency counter, incremented by the Worker on every write
--   deleted_at    soft delete (tombstone) — nothing is ever hard-deleted except purged proofs
--   *_fils        integer money in fils (1 AED = 100 fils). No REAL columns anywhere.
--
-- D1 limits that shaped this file: 2 MB row, 100 bound parameters per query,
-- 100 KB per statement. Wide tables are split rather than fattened.

CREATE TABLE tenants (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  trn           TEXT,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);

CREATE TABLE branches (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  code          TEXT NOT NULL,
  name          TEXT NOT NULL,
  address       TEXT,
  phone_e164    TEXT,
  active        INTEGER NOT NULL DEFAULT 1,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  created_by    TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE UNIQUE INDEX idx_branches_code ON branches (tenant_id, code);

CREATE TABLE roles (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  role_key      TEXT NOT NULL,
  name          TEXT NOT NULL,
  is_system     INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE UNIQUE INDEX idx_roles_key ON roles (tenant_id, role_key);

CREATE TABLE role_permissions (
  role_id       TEXT NOT NULL,
  permission    TEXT NOT NULL,
  scope         TEXT NOT NULL CHECK (scope IN ('own', 'team', 'branch', 'all')),
  PRIMARY KEY (role_id, permission)
);

CREATE TABLE users (
  id                 TEXT PRIMARY KEY,
  tenant_id          TEXT NOT NULL,
  branch_id          TEXT,
  role_id            TEXT NOT NULL,
  reports_to         TEXT,
  name               TEXT NOT NULL,
  phone_e164         TEXT NOT NULL,
  email              TEXT,
  password_hash      TEXT NOT NULL,
  pin_hash           TEXT,
  active             INTEGER NOT NULL DEFAULT 1,
  permission_version INTEGER NOT NULL DEFAULT 1,
  locale             TEXT NOT NULL DEFAULT 'en',
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL,
  created_by         TEXT,
  version            INTEGER NOT NULL DEFAULT 1,
  deleted_at         TEXT
);
CREATE UNIQUE INDEX idx_users_phone ON users (tenant_id, phone_e164);
CREATE INDEX idx_users_branch ON users (tenant_id, branch_id);

-- Devices are first-class: a device holds the sync cursor, the leased number
-- blocks and the refresh-token chain, and it can be revoked remotely.
CREATE TABLE devices (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  user_id       TEXT NOT NULL,
  name          TEXT NOT NULL,
  platform      TEXT NOT NULL CHECK (platform IN ('windows', 'android')),
  app_version   TEXT,
  cursor_seq    INTEGER NOT NULL DEFAULT 0,
  last_seen_at  TEXT,
  revoked_at    TEXT,
  created_at    TEXT NOT NULL
);
CREATE INDEX idx_devices_user ON devices (tenant_id, user_id);

-- Refresh tokens are opaque and stored hashed. Rotation keeps a link to the
-- token it replaced, so a reused token can revoke the whole chain.
CREATE TABLE refresh_tokens (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  device_id     TEXT NOT NULL,
  user_id       TEXT NOT NULL,
  token_hash    TEXT NOT NULL,
  issued_at     TEXT NOT NULL,
  expires_at    TEXT NOT NULL,
  rotated_from  TEXT,
  revoked_at    TEXT
);
CREATE UNIQUE INDEX idx_refresh_hash ON refresh_tokens (token_hash);
CREATE INDEX idx_refresh_device ON refresh_tokens (device_id);

CREATE TABLE customers (
  id                 TEXT PRIMARY KEY,
  tenant_id          TEXT NOT NULL,
  branch_id          TEXT,
  name               TEXT NOT NULL,
  company            TEXT,
  trn                TEXT,
  tier               TEXT NOT NULL DEFAULT 'retail',
  credit_limit_fils  INTEGER NOT NULL DEFAULT 0,
  payment_terms_days INTEGER NOT NULL DEFAULT 0,
  notes              TEXT,
  whatsapp_opt_in    INTEGER NOT NULL DEFAULT 1,
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL,
  created_by         TEXT,
  updated_by         TEXT,
  version            INTEGER NOT NULL DEFAULT 1,
  deleted_at         TEXT
);
CREATE INDEX idx_customers_branch_updated ON customers (tenant_id, branch_id, updated_at);
CREATE INDEX idx_customers_name ON customers (tenant_id, name);

-- A customer can have several numbers; search is by phone number first, so the
-- last nine digits are stored denormalised and indexed.
CREATE TABLE customer_phones (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  customer_id   TEXT NOT NULL,
  e164          TEXT NOT NULL,
  phone_last9   TEXT NOT NULL,
  label         TEXT,
  is_primary    INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  created_by    TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  deleted_at    TEXT
);
CREATE UNIQUE INDEX idx_customer_phones_e164 ON customer_phones (tenant_id, e164);
CREATE INDEX idx_customer_phones_last9 ON customer_phones (tenant_id, phone_last9);

CREATE TABLE settings (
  tenant_id     TEXT NOT NULL,
  key           TEXT NOT NULL,
  value_json    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  updated_by    TEXT,
  version       INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (tenant_id, key)
);

-- The single source of truth for "what changed". seq is the sync cursor; the
-- pull query is one indexed range scan on (tenant_id, seq) with no joins.
CREATE TABLE change_log (
  seq                 INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id           TEXT NOT NULL,
  entity              TEXT NOT NULL,
  row_id              TEXT NOT NULL,
  op                  TEXT NOT NULL CHECK (op IN ('insert', 'patch', 'delete')),
  branch_id           TEXT,
  assignee_id         TEXT,
  job_id              TEXT,
  actor_id            TEXT NOT NULL,
  device_id           TEXT NOT NULL,
  row_version         INTEGER NOT NULL,
  changed_fields_json TEXT,
  row_json            TEXT NOT NULL,
  server_ts           TEXT NOT NULL
);
CREATE INDEX idx_change_log_cursor ON change_log (tenant_id, seq);
CREATE INDEX idx_change_log_row ON change_log (tenant_id, entity, row_id);

-- Idempotency: a retried batch after a dropped connection is a no-op here.
-- Rows older than 30 days are pruned by the scheduled job.
CREATE TABLE applied_mutations (
  mutation_id   TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  applied_at    TEXT NOT NULL,
  result        TEXT NOT NULL
);

-- Number blocks, leased per device. One atomic UPDATE..RETURNING hands out the
-- next range; a device with fewer than 20 left asks for another in the
-- background, so a counter clerk with no internet never blocks.
CREATE TABLE number_blocks (
  tenant_id     TEXT NOT NULL,
  device_id     TEXT NOT NULL,
  series        TEXT NOT NULL,
  start_no      INTEGER NOT NULL,
  end_no        INTEGER NOT NULL,
  next_no       INTEGER NOT NULL,
  leased_at     TEXT NOT NULL,
  PRIMARY KEY (device_id, series, start_no)
);
CREATE INDEX idx_number_blocks_series ON number_blocks (tenant_id, series);

CREATE TABLE audit_log (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  actor_id      TEXT NOT NULL,
  device_id     TEXT,
  action        TEXT NOT NULL,
  entity        TEXT,
  row_id        TEXT,
  old_json      TEXT,
  new_json      TEXT,
  at            TEXT NOT NULL
);
CREATE INDEX idx_audit_at ON audit_log (tenant_id, at);

-- Unmergeable changes land here for a manager to resolve, with both versions
-- side by side. Should be rare; when it is not rare, a rule is wrong.
CREATE TABLE conflicts (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT NOT NULL,
  entity        TEXT NOT NULL,
  row_id        TEXT NOT NULL,
  device_id     TEXT NOT NULL,
  mutation_id   TEXT NOT NULL,
  local_json    TEXT NOT NULL,
  server_json   TEXT NOT NULL,
  fields_json   TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'dismissed')),
  created_at    TEXT NOT NULL,
  resolved_by   TEXT,
  resolved_at   TEXT
);
CREATE INDEX idx_conflicts_open ON conflicts (tenant_id, status, created_at);

CREATE TABLE schema_meta (
  key           TEXT PRIMARY KEY,
  value         TEXT NOT NULL
);

INSERT INTO schema_meta (key, value) VALUES ('schema_version', '1');
