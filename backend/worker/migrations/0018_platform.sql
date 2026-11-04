-- Platform admin (the software vendor's own view).
--
-- A tenant is a shop. Tenants are isolated: one shop can never read another's
-- data. The platform layer is the single deliberate exception — a token held
-- only by the vendor unlocks a READ-ONLY view over every tenant, plus a server
-- error log, so the vendor can find and fix problems without asking a client to
-- describe them.
--
-- platform_errors is where the Worker records anything that goes wrong on the
-- server (unhandled 500s first; sync/auth rejections can be added beside them).
-- tenant_id is NULL when the error is not attributable to one shop.

CREATE TABLE platform_errors (
  id            TEXT PRIMARY KEY,
  tenant_id     TEXT,
  source        TEXT NOT NULL DEFAULT 'worker',
  code          TEXT NOT NULL,
  message       TEXT NOT NULL,
  context_json  TEXT,
  created_at    TEXT NOT NULL
);
CREATE INDEX idx_platform_errors_created ON platform_errors (created_at DESC);
CREATE INDEX idx_platform_errors_tenant ON platform_errors (tenant_id, created_at DESC);
