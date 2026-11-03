-- Catalogue and sales (Phase 2A).
--
-- The catalogue (products, materials, price rules) is reference data: it is
-- read-mostly, versioned by the price book, and delivered to devices through
-- /v1/catalogue rather than the change log. Orders and items are user data and
-- sync like everything else.
--
-- Prices are never computed on the server in v1 (PLAN.md §7.7): the device
-- computes, stores the breakdown snapshot, and the server stores that snapshot.
-- That is what makes an old invoice reproducible after the price book moves on.

CREATE TABLE products (
  id                       TEXT PRIMARY KEY,
  tenant_id                TEXT NOT NULL,
  branch_id                TEXT,
  code                     TEXT NOT NULL,
  name_en                  TEXT NOT NULL,
  name_ar                  TEXT,
  category                 TEXT,
  kind                     TEXT NOT NULL
                             CHECK (kind IN ('sheet', 'area', 'per_unit', 'service', 'outsourced')),
  pricing_mode             TEXT NOT NULL
                             CHECK (pricing_mode IN ('cost_plus', 'price_table', 'vendor_markup')),
  -- Sheet specification (sheet products only)
  sheet_width_mm           INTEGER,
  sheet_height_mm          INTEGER,
  bleed_mm                 INTEGER NOT NULL DEFAULT 3,
  gutter_mm                INTEGER NOT NULL DEFAULT 3,
  setup_sheets             INTEGER NOT NULL DEFAULT 2,
  spoilage_bps             INTEGER NOT NULL DEFAULT 500,
  -- Cost inputs
  material_code            TEXT,
  print_rate_fils          INTEGER,
  area_rate_fils_per_sqm   INTEGER,
  -- Selling rules
  markup_bps               INTEGER NOT NULL DEFAULT 0,
  min_order_fils           INTEGER NOT NULL DEFAULT 0,
  rounding_step_fils       INTEGER NOT NULL DEFAULT 100,
  -- What the counter may choose, as data so the catalogue editor can change it
  sizes_json               TEXT NOT NULL DEFAULT '[]',
  finishes_json            TEXT NOT NULL DEFAULT '[]',
  quantity_presets_json    TEXT NOT NULL DEFAULT '[]',
  sort                     INTEGER NOT NULL DEFAULT 100,
  active                   INTEGER NOT NULL DEFAULT 1,
  created_at               TEXT NOT NULL,
  updated_at               TEXT NOT NULL,
  created_by               TEXT,
  version                  INTEGER NOT NULL DEFAULT 1,
  deleted_at               TEXT
);
CREATE UNIQUE INDEX idx_products_code ON products (tenant_id, code);
CREATE INDEX idx_products_sort ON products (tenant_id, active, sort);

CREATE TABLE materials (
  id                 TEXT PRIMARY KEY,
  tenant_id          TEXT NOT NULL,
  code               TEXT NOT NULL,
  name               TEXT NOT NULL,
  type               TEXT,
  gsm                INTEGER,
  sheet_width_mm     INTEGER,
  sheet_height_mm    INTEGER,
  cost_per_sheet_fils INTEGER NOT NULL DEFAULT 0,
  supplier_id        TEXT,
  active             INTEGER NOT NULL DEFAULT 1,
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL,
  version            INTEGER NOT NULL DEFAULT 1,
  deleted_at         TEXT
);
CREATE UNIQUE INDEX idx_materials_code ON materials (tenant_id, code);

-- One row per rule in a price-book version. `when_json` is the condition list
-- the pricing engine evaluates; keeping it as JSON means a new condition type
-- is a data change, not a migration.
CREATE TABLE price_rules (
  id                 TEXT PRIMARY KEY,
  tenant_id          TEXT NOT NULL,
  price_book_version INTEGER NOT NULL,
  product_id         TEXT,
  label              TEXT NOT NULL,
  phase              TEXT NOT NULL
                       CHECK (phase IN ('material', 'print', 'finishing', 'setup', 'surcharge')),
  basis              TEXT NOT NULL,
  rate_fils          INTEGER NOT NULL,
  min_charge_fils    INTEGER NOT NULL DEFAULT 0,
  priority           INTEGER NOT NULL DEFAULT 100,
  when_json          TEXT NOT NULL DEFAULT '[]',
  active             INTEGER NOT NULL DEFAULT 1,
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL,
  version            INTEGER NOT NULL DEFAULT 1,
  deleted_at         TEXT
);
CREATE INDEX idx_price_rules_version ON price_rules (tenant_id, price_book_version, active);

CREATE TABLE orders (
  id               TEXT PRIMARY KEY,
  tenant_id        TEXT NOT NULL,
  branch_id        TEXT,
  number           INTEGER,
  number_display   TEXT NOT NULL,
  is_quote         INTEGER NOT NULL DEFAULT 0,
  customer_id      TEXT NOT NULL,
  customer_name    TEXT,
  status           TEXT NOT NULL DEFAULT 'draft',
  priority         TEXT NOT NULL DEFAULT 'normal',
  due_at           TEXT,
  delivery_method  TEXT NOT NULL DEFAULT 'collect',
  notes            TEXT,
  subtotal_fils    INTEGER NOT NULL DEFAULT 0,
  vat_fils         INTEGER NOT NULL DEFAULT 0,
  total_fils       INTEGER NOT NULL DEFAULT 0,
  item_count       INTEGER NOT NULL DEFAULT 1,
  created_at       TEXT NOT NULL,
  updated_at       TEXT NOT NULL,
  created_by       TEXT,
  updated_by       TEXT,
  version          INTEGER NOT NULL DEFAULT 1,
  deleted_at       TEXT
);
CREATE INDEX idx_orders_branch_updated ON orders (tenant_id, branch_id, updated_at);
CREATE UNIQUE INDEX idx_orders_number ON orders (tenant_id, branch_id, number);

CREATE TABLE order_items (
  id                 TEXT PRIMARY KEY,
  tenant_id          TEXT NOT NULL,
  branch_id          TEXT,
  order_id           TEXT NOT NULL,
  product_id         TEXT NOT NULL,
  description        TEXT NOT NULL,
  options_json       TEXT NOT NULL DEFAULT '{}',
  quantity           INTEGER NOT NULL,
  price_book_version INTEGER NOT NULL,
  breakdown_json     TEXT NOT NULL,
  subtotal_fils      INTEGER NOT NULL DEFAULT 0,
  vat_fils           INTEGER NOT NULL DEFAULT 0,
  total_fils         INTEGER NOT NULL DEFAULT 0,
  status             TEXT NOT NULL DEFAULT 'pending',
  created_at         TEXT NOT NULL,
  updated_at         TEXT NOT NULL,
  created_by         TEXT,
  version            INTEGER NOT NULL DEFAULT 1,
  deleted_at         TEXT
);
CREATE INDEX idx_order_items_order ON order_items (tenant_id, order_id);

INSERT INTO schema_meta (key, value)
  VALUES ('schema_version', '2')
  ON CONFLICT (key) DO UPDATE SET value = excluded.value;
