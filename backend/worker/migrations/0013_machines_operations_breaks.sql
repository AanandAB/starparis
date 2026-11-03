-- Machines, finishing operations and quantity breaks (Phase 6A of pricing).
--
-- These three turn the rate card from "a price per sheet" into a cost model that
-- a print shop recognises:
--
--   * a MACHINE has an hourly rate, a setup time and a run speed, because that is
--     how press time is actually bought;
--   * an OPERATION is a finishing step with its own basis (per 1000, per side,
--     per m2, per copy) plus its own setup and its own waste — so adding foil
--     stamping is a row, not a deployment;
--   * a QUANTITY BREAK lets one product price 100 / 500 / 1000 side by side,
--     which is the question every customer asks.

CREATE TABLE machines (
  id               TEXT PRIMARY KEY,
  tenant_id        TEXT NOT NULL,
  branch_id        TEXT,
  name             TEXT NOT NULL,
  -- offset | digital | large_format | finishing
  type             TEXT NOT NULL DEFAULT 'digital'
                     CHECK (type IN ('offset', 'digital', 'large_format', 'finishing')),
  hourly_rate_fils INTEGER NOT NULL DEFAULT 0,
  setup_minutes    INTEGER NOT NULL DEFAULT 0,
  -- Sheets per hour at normal coverage; 0 means the machine is priced by click.
  sheets_per_hour  INTEGER NOT NULL DEFAULT 0,
  -- Offset plates, one per colour per side.
  plate_cost_fils  INTEGER NOT NULL DEFAULT 0,
  -- Digital click charge per impression, often inclusive of toner.
  click_fils       INTEGER NOT NULL DEFAULT 0,
  active           INTEGER NOT NULL DEFAULT 1,
  created_at       TEXT NOT NULL,
  updated_at       TEXT NOT NULL,
  created_by       TEXT,
  version          INTEGER NOT NULL DEFAULT 1,
  deleted_at       TEXT
);

CREATE TABLE operations (
  id          TEXT PRIMARY KEY,
  tenant_id   TEXT NOT NULL,
  code        TEXT NOT NULL,
  name_en     TEXT NOT NULL,
  name_ar     TEXT,
  -- Which part of the estimate it belongs to.
  phase       TEXT NOT NULL DEFAULT 'finishing'
                CHECK (phase IN ('prepress', 'print', 'finishing', 'packing', 'delivery')),
  -- How the rate is applied. per_1000 and per_side are the trade's own units.
  basis       TEXT NOT NULL
                CHECK (basis IN ('per_piece', 'per_1000', 'per_side', 'per_sqm', 'per_copy', 'per_hour')),
  rate_fils   INTEGER NOT NULL DEFAULT 0,
  setup_fils  INTEGER NOT NULL DEFAULT 0,
  -- Waste this operation adds on top of the press waste, in basis points (50 = 0.5%).
  waste_bps   INTEGER NOT NULL DEFAULT 0,
  min_charge_fils INTEGER NOT NULL DEFAULT 0,
  machine_id  TEXT,
  active      INTEGER NOT NULL DEFAULT 1,
  sort        INTEGER NOT NULL DEFAULT 100,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  created_by  TEXT,
  version     INTEGER NOT NULL DEFAULT 1,
  deleted_at  TEXT
);
CREATE UNIQUE INDEX idx_operations_code ON operations (tenant_id, code);
CREATE INDEX idx_operations_active ON operations (tenant_id, active);

-- Price at quantity: the trade's answer to "what if I order 1000?".
-- Amount is the sell price before VAT for that quantity, so a break can be
-- stair-stepped by hand rather than derived from a single unit rate.
CREATE TABLE product_price_breaks (
  id         TEXT PRIMARY KEY,
  tenant_id  TEXT NOT NULL,
  product_id TEXT NOT NULL,
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  amount_fils INTEGER NOT NULL CHECK (amount_fils >= 0),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_by TEXT,
  version    INTEGER NOT NULL DEFAULT 1,
  deleted_at TEXT
);
CREATE UNIQUE INDEX idx_breaks_product_qty ON product_price_breaks (product_id, quantity);
