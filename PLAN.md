# Star Paris Graphic — Shop Management System
## Technical Build Plan (v1.0 draft for review)

Status: draft, awaiting sign-off. No application code has been written.
Source: Design Document v1.0, 3 November 2026.
Author: Sinu (Hermes) for Aanand AB.
Target folder: `C:\Users\aanan\Desktop\AANAND AB\WORK\Starparisprints`

---

## 0. How to read this

The design document defines **what** the system does. This plan defines **how it is built**,
in the order it will be built, with the decisions that must be frozen before the first line
of code. Anything marked `DECIDED` is my recommendation and is safe to build on. Anything
marked `OPEN` needs the client or you.

Verification date for all external limits and package versions: 3 November 2026.

---

## 1. What changed from the design document

The design is sound. Six corrections, each with a reason:

| # | Design document says | Plan says | Why |
|---|---|---|---|
| 1 | Melos monorepo | Dart **pub workspaces** (native since Dart 3.6), plus a bun workspace for `backend/` | One lockfile, `dart pub get` once at the root, no extra tool to install or debug. Melos can be added later for release scripting if it earns its keep. |
| 2 | "Each device and branch has its own invoice series (INV-SHJ1-00123)" | Series key = **branch + device** (`INV-SHJ1-PC1-00123`) | Two devices on SHJ1 would both allocate `INV-SHJ1-00123`. The series must be unique per device to stay gapless. |
| 3 | Every table carries `branch_id` | `branch_id` **nullable**; org-level tables (products, price books, materials, vendors, users) leave it null | Otherwise every price book and material is duplicated per branch and price edits become a branch-by-branch chore. |
| 4 | Pull window = "last 90 days of history" | Window = **still open OR updated within 90 days** | A banner ordered in July, still in finishing in November, is exactly the job a designer needs offline. Created-at filtering loses it. |
| 5 | Rounding "to nearest 0.25 or 1.00, configurable" | Round **price per line** (half-up, to the configured step); VAT computed **per document** on the discounted taxable total; both stored as integers | One rule, applied identically on device and server, reproducible in an audit five years later. Line-level VAT rounding accumulates fils of error against the FTA total. |
| 6 | `sqlcipher_flutter_libs` | `sqlite3` 3.8 with the `sqlite3mc` build hook and `PRAGMA key` | `sqlcipher_flutter_libs` is obsolete after sqlite3 2.x. Drift's current guidance is the SQLite3MultipleCiphers build, which works on Windows desktop as well as Android. |

---

## 2. Decisions (ADRs)

### ADR-001 — Monorepo with native pub workspaces `DECIDED`
```
Starparisprints/
  pubspec.yaml                  workspace root (SDK constraint, shared lints)
  melos.yaml                    NOT used
  apps/shop_app/                Flutter app (windows + android)
  packages/
    domain/                     pure Dart: entities, enums, state machines, permissions
    pricing_engine/             pure Dart: no Flutter, no drift, no I/O
    sync_engine/                pure Dart + drift: outbox, pull apply, conflicts
    design_system/              Flutter: tokens, components, adaptive shell
    shared_test_vectors/        JSON golden vectors consumed by Dart and (later) TypeScript
  backend/
    worker/                     Hono + D1 (bun workspace)
    migrations/                 numbered .sql, applied by wrangler
  tools/
    tasks.dart                  build/format/test/release helpers (replaces Melos scripts)
  docs/
```
Dependency rule, enforced by a dependency-graph check in CI: `domain` depends on nothing;
`pricing_engine` depends on `domain`; `design_system` depends on `domain` only; `shop_app`
depends on all; nothing depends on `shop_app`. The backend never imports Dart.

### ADR-002 — Local database `DECIDED`
- `drift` 2.35.x over `sqlite3` 3.8 with `sqlite3mc` (SQLite3MultipleCiphers) via the
  `hooks: user_defines:` block. Encryption key from `flutter_secure_storage` 11.x
  (DPAPI on Windows, Keystore on Android).
- `PRAGMA journal_mode = WAL`, `synchronous = NORMAL`, `foreign_keys = ON`, `temp_store = MEMORY`.
- One database file per user per device (`starparis_<userShortId>.db`) so two Windows logins on
  one PC never share a session or a sync cursor.
- A debug assert checks `PRAGMA cipher` returns a row on both platforms — this catches the
  "works in `flutter run`, crashes from the installer" failure before it reaches a shop.

### ADR-003 — Backend `DECIDED`
`Hono` 4.13 on Workers, `zod` 4 for every input boundary, `drizzle-orm` 0.45 for typed queries.
**Migrations are hand-written SQL**, not generated, and reviewed like code: D1's limits
(100 bound parameters per query, 100 KB per statement) shape the DDL and the batch code, and
generated migrations hide that. Drizzle types sit on top. `EXPLAIN QUERY PLAN` is recorded in
a comment above every hot query.

`TypeScript 5.9` (not 7.0). The 7.0 native compiler landed days ago; drizzle-kit and the
Workers build chain have not settled on it. A client deadline is no place to find out.

### ADR-004 — Authentication `DECIDED`
- Password: PBKDF2-SHA256 via WebCrypto, **600,000 iterations**, 16-byte salt, 32-byte output,
  stored as `pbkdf2$sha256$600000$<saltB64>$<hashB64>` so the cost is upgradeable without a
  migration. (Argon2id is not available in Workers without WASM and a CPU budget we cannot
  justify.) Login and refresh only, so the ~150 ms cost is invisible.
- Access token: JWT HS256 (`jose`), 15 min, claims `sub, tid, bid, role, pv, dv, exp`.
  `pv` = permission version; `dv` = device id. Verified with no database read.
- Refresh: opaque 32-byte token, SHA-256 hashed in `refresh_tokens`, 30 days, rotated on every
  use with reuse detection (a reused refresh token revokes the whole device chain).
- PIN: 4–6 digits, PBKDF2-SHA256 100,000 iterations on the device only, never sent anywhere,
  with attempt counter in secure storage and lockout after 5 failures. Wrong-PIN attempts are
  queued for the audit log.
- TOTP (RFC 6238, 30 s, ±1 step) mandatory for Owner and Accountant if the client wants it —
  flagged as optional because it is the single biggest adoption risk at a counter.

### ADR-005 — Sync protocol `DECIDED`, see Section 6
### ADR-006 — Numbering `DECIDED`, see Section 7
### ADR-007 — Money `DECIDED`
All amounts are `int` fils (1 AED = 100 fils). No `double` anywhere in `domain`,
`pricing_engine`, JSON, or D1. Percentages are basis points (`int`, 1% = 100 bps). Division
always rounds half-up explicitly; no implicit truncation. A lint rule bans `double` in the
pricing and money packages; the CI check is a grep, and it has caught real bugs in other
projects.

### ADR-008 — Proof storage `DECIDED`
Proofs live in D1, as the design says, but in a **separate table** (`file_chunks`) so that no
normal query ever touches a BLOB. 500 KB proof ⇒ 2 × 256 KB chunks + 20 KB thumbnail.
Content-addressed by SHA-256, so the same proof sent twice costs nothing. Chunks are served
through the Worker with a short-lived signed URL and `Cache-Control: private, max-age=31536000,
immutable` (content-addressed, so this is safe). Purge: a Cron Trigger at 03:00 Asia/Dubai
deletes chunks for proofs older than the configured 60 days, keeping the thumbnail, the
approval record and the audit row.

### ADR-009 — Bilingual PDF `OPEN` (spike in week 1)
`package:pdf` 3.13 lays out bidi but does not perform OpenType shaping, so Arabic renders as
isolated letterforms — visibly wrong on a tax invoice. Three options, in order of preference:

1. **`payv` 0.1.2** — pure Dart, no FFI, executes GSUB/GPOS itself, handles Arabic joining and
   UAX#9 bidi, emits real vector text with `/ActualText`. Windows + Android + server. Risk:
   v0.1, one maintainer, no table API — we would draw invoices on a canvas rather than using
   widgets.
2. **`pdf_text_shaper` 1.1.0** — HarfBuzz via FFI, renders shaped glyphs into `package:pdf`
   widgets. Correct shaping, keeps `pdf`'s widget layout. Risk: native libs to bundle on
   Windows and Android, and glyphs become vector paths (larger files).
3. **Flutter canvas render → image → PDF** — guaranteed correct because Flutter shapes Arabic
   properly, but the invoice is a picture: no selectable text, no searchable VAT number, larger
   files. Acceptable for a delivery note, poor for a tax invoice.

Week-1 spike produces the same bilingual invoice three ways on both platforms; the client's
accountant picks from the printouts. Fallback decision is a one-line change behind a
`DocumentRenderer` interface either way.

### ADR-010 — Thermal and label printing `OPEN` (hardware spike)
- A4/A5: `printing` 5.15 (Windows spooler, Android print framework). Low risk.
- 80 mm ESC/POS on Windows: no maintained Flutter plugin does raw spooler passthrough well.
  Plan is `dart:ffi` to `winspool.drv` (`OpenPrinter`, `StartDocPrinter`, `WritePrinter`) with
  a tested ESC/POS command builder; USB and network (port 9100) both covered.
- Android: Bluetooth/USB ESC/POS via `esc_pos_utils_plus` + `flutter_blue_plus`/`usb_serial`.
- This needs the client's actual printer models in week 1. Software cannot fake a printer.

### ADR-011 — Files `DECIDED`
Originals stay in a shop folder (`\\SERVER\Artwork` or a synced Google Drive path), one
subfolder per job number. The app records `file_name, size, sha256, uri` and opens the folder
with one click. Nothing large ever enters D1. The path is a per-device setting because it
differs between the front PC and a designer's laptop.

### ADR-012 — Reports `DECIDED`
Local first. Any report whose range falls inside the device's 90-day window is answered by
SQLite. Beyond that, one request to `/v1/reports/:key` returns pre-aggregated rows (`GROUP BY`
in D1), cached 60 s, then the device builds the XLSX/PDF in an isolate.

---

## 3. Package responsibilities

### `packages/domain`
Entities as immutable Dart classes with `copyWith`, no JSON (serialisation lives in the data
layer so the domain never learns about wire formats). Contains:
- Money value type (`Fils`), quantity, percentage/bps.
- Enums for every status, with `canTransitionTo` state machines (order, item, task, quote,
  invoice, payment, vendor job).
- Permission keys and the scope enum (`own | team | branch | all`), plus `AccessPolicy` — a pure
  function `(user, permission, resource) -> bool`. The Worker mirrors this logic in TypeScript;
  `shared_test_vectors/permissions.json` keeps the two honest.
- Customer-facing status mapping (six states) and the internal-to-customer projection.

### `packages/pricing_engine`
Pure Dart, no I/O, no clock, no randomness. `PriceRequest -> PriceBreakdown`. Rules are data.
Deterministic by construction: every input is explicit, including `price_book_version` and
`now` (injected, never `DateTime.now()` inside).
Sub-parts: `sheet_layout.dart` (fit + rotation + bleed + gutter + waste),
`rule_interpreter.dart` (safe JSON evaluator, no `eval`), `tables.dart` (price matrices),
`compat.dart` (invalid combination rules), `rounding.dart`.

### `packages/sync_engine`
Owns the outbox, the cursor, the apply-pull transaction and the conflict inbox. Depends on
`domain` and the generated drift database; knows nothing about screens. Exposes a
`SyncController` with a `Stream<SyncState>` that the UI's sync chip listens to.

### `packages/design_system`
Brand tokens (colour, type scale, spacing on an 8 pt grid), `StarTheme.light/dark`, RTL-aware
components: `StatusChip`, `JobCard`, `TaskCard`, `OptionChip`, `PriceBar`, `PriceBreakdown`,
`SyncChip`, `EmptyState`, `ConfirmSheet`, `ApprovalSheet`, `MoneyText` (formats fils, respects
locale), `SearchField` with Ctrl+K binding. Compact (Windows) and comfortable (Android) density
as a theme extension, not a global flag.

### `apps/shop_app`
Composition root. Riverpod 3.4 (`Notifier`/`AsyncNotifier`, no codegen for state — codegen is
reserved for drift), `go_router` 18 with role guards, adaptive shell
(`NavigationBar` / `NavigationRail` / labelled three-pane rail), and one folder per feature.

---

## 4. Data model

Every table: `id TEXT PRIMARY KEY` (UUIDv7), `tenant_id`, `branch_id NULL`, `created_at`,
`updated_at`, `created_by`, `updated_by`, `version INTEGER NOT NULL DEFAULT 1`,
`deleted_at NULL`, `sync_state` (device-side only, not stored in D1).

Groups and the columns that carry the design's intent:

**Org** `tenant` · `branches` · `users(name, phone, email, pin_hash, role_id, branch_id,
reports_to, active, locale)` · `roles` · `role_permissions(permission, scope)` ·
`user_permissions` (extra grants) · `devices(name, platform, app_version, last_seen,
cursor_seq, revoked_at)` · `delegations(from_user, to_user, from_date, to_date)`

**Customers** `customers(name, company, trn, tier, credit_limit, payment_terms, notes,
whatsapp_opt_in)` · `customer_phones(customer_id, e164, is_primary)` (indexed) ·
`customer_addresses`

**Catalogue** `product_categories` · `products(kind, pricing_mode, workflow_template_id,
default_machine_id, active)` · `option_groups(code)` · `option_values(group_id, code, label_en,
label_ar, sort)` · `product_options(product_id, group_id, allowed_value_ids_json, required)` ·
`materials(type, gsm, sheet_w, sheet_h, cost_per_sheet_fils, supplier_id)` ·
`finishing_processes(basis, rate_fils)` · `machines(rate_per_click_fils, rate_per_sqm_fils)` ·
`price_books(version, effective_from, effective_to, status, approved_by)` ·
`price_rules(price_book_id, scope_json, when_json, basis, rate_fils, table_json, min_charge_fils,
priority)` · `price_tiers(product_id, qty_from, qty_to, price_fils, mode)` ·
`customer_price_overrides(customer_id, product_id, rule_json, effective_from)`

**Sales** `quotes(number, customer_id, status, validity_days, ...)` · `quote_revisions` ·
`quote_items(quote_revision_id, product_id, options_json, qty, breakdown_json,
price_book_version)` · `orders(number, customer_id, status_derived, due_at, priority,
delivery_method, deposit_required_fils, notes)` · `order_items(order_id, ..., workflow_template_id,
artwork_status, outsourced, vendor_id)` · `discounts(scope, kind, value, reason, approved_by)` ·
`discount_approvals`

**Production** `workflow_templates(product_scope, assignment_mode)` ·
`workflow_stages(name, role_code, est_minutes, requires_approval, skippable,
notify_template_id, sort)` · `tasks(order_item_id, stage_id, status, assignee_id, priority,
due_at, est_minutes, started_at, paused_at, finished_at, claim_token)` ·
`task_events(task_id, from_status, to_status, reason, user_id, device_id, occurred_at,
was_offline)` · `time_entries` · `artwork_files(job_number, name, sha256, size, uri, kind)` ·
`proofs(order_item_id, version, sha256, thumb_sha256, approved_at)` ·
`proof_approvals(proof_id, decision, channel, decided_by, decided_at, ip_hash)` · `qc_checks`

**Outsourcing** `vendors` · `vendor_services` · `vendor_rates(service_id, qty_from, rate_fils,
effective_from)` · `vendor_jobs(order_item_id, vendor_id, sent_at, promised_at, received_at,
cost_fils, markup_bps, commission_fils, status)` · `vendor_bills(vendor_job_id, amount_fils,
due_at, paid_fils, status)`

**Money** `invoices(number, series_id, customer_id, order_id, type, issued_at, taxable_fils,
vat_fils, total_fils, status, void_reason)` · `invoice_lines(description, qty, unit_fils,
discount_fils, taxable_fils, vat_fils)` · `credit_notes` · `payments(method, amount_fils,
received_at, reference, cheque_date, cleared_at, mutation_id UNIQUE)` · `expenses` ·
`cash_sessions(opened_at, float_fils, closed_at, counted_fils, variance_fils)` · `tax_settings`

**Inventory** `inventory_items(kind, unit, reorder_level)` · `inventory_movements(item_id,
kind, qty_x1000, reason, ref_type, ref_id, occurred_at)` · `suppliers` · `purchase_orders` ·
`purchase_order_lines`

**Comms** `message_templates(code, channel, lang, body)` · `messages(order_id, template_code,
channel, opened_by, opened_at, status='opened_in_whatsapp')` · `notifications`

**System** `change_log(seq INTEGER PRIMARY KEY AUTOINCREMENT, entity, row_id, op, branch_id,
assignee_id, job_id, version, changed_fields_json, row_json, actor_id, device_id, server_ts)` ·
`audit_log(id, actor_id, action, entity, row_id, old_json, new_json, device_id, at)` ·
`applied_mutations(mutation_id PRIMARY KEY, applied_at, result)` · `number_blocks(device_id,
series, start, end, next)` · `settings(key, value_json)` · `conflicts(id, entity, row_id,
local_json, server_json, status, resolved_by)` · `schema_meta`

**Invariants worth writing down now**
1. `quotes`, `orders`, `invoices` store `price_book_version` and the full `breakdown_json` per
   line. Price edits never rewrite a sent document.
2. `invoices` are immutable after `issued_at`; the only permitted mutation is `status='void'`
   plus a `credit_notes` row.
3. `payments` and `inventory_movements` are append-only; a correction is a compensating row.
4. `tasks.status` changes only through the state machine, enforced in the Worker.
5. `deleted_at` is the only delete; nothing is hard-deleted except purged proof chunks and
   expired `applied_mutations` (30 days).
6. `customer_phones.e164` is normalised (`+9715XXXXXXXX`), with a `phone_last9` generated
   column used for search.

Indexes exactly where reads need them (design §5.11 rule 6): `change_log(seq)`,
`orders(branch_id, updated_at)`, `orders(number)`, `customer_phones(phone_last9)`,
`tasks(assignee_id, status)`, `tasks(branch_id, status)`, `invoices(number)`,
`payments(mutation_id)`, plus an FTS5 table `search_index(job_number, customer_name, phone,
quote_number, invoice_number)`. Every index is justified in a comment; no speculative ones.

---

## 5. Sequence of truth: how a write travels

```
tap "Confirm order"
  → drift transaction: insert order + items + outbox rows          (atomic, local, <20 ms)
  → UI updates from the drift stream                                 (never awaits network)
  → outbox debounce 2 s (max 15 s) → coalesce per row
  → POST /v1/push  {device_id, mutations[≤100], base_head}
       Worker: verify JWT → load pv → for each mutation: permission check → state machine
               → optimistic version check → merge or reject
               → one db.batch(): upserts + change_log rows
       Response: {head, results[]}
  → device marks outbox rows applied, stores server versions, updates cursor
  → other devices: poll /v1/head (ETag, 304) → /v1/pull?since=cursor → apply in one txn
```

Failure paths are designed, not accidental: a rejected mutation is kept locally with its error,
shown in the conflict inbox, and never silently dropped. A push that fails mid-flight is
retried with the same `mutation_id`, which `applied_mutations` makes a no-op.

---

## 6. Sync protocol (frozen before coding)

### 6.1 Mutation envelope
```json
{
  "mutation_id": "0193f0c2-...",          // UUIDv7, device-generated, idempotency key
  "entity": "orders",
  "row_id": "0193f0b1-...",
  "op": "insert | patch | delete",
  "fields": { "due_at": "2026-11-05T14:00:00+04:00", "priority": "urgent" },
  "base_version": 3,                       // 0 for insert
  "device_ts": "2026-11-03T09:14:22+04:00",
  "job_id": "0193f0b1-...",                // optional, used for visibility filtering
  "origin": "offline"                      // informative, shown in the audit trail
}
```
Limits: ≤ 100 mutations or ≤ 256 KB per request, whichever bites first. Server rejects the
whole request with `413` and the client re-chunks — never partial-applies a batch.

### 6.2 Endpoints
| Method | Path | Purpose | Notes |
|---|---|---|---|
| POST | `/v1/auth/login` | phone/email + password → tokens + user + permissions + branches | rate limited 10/min/IP, 5/min/account |
| POST | `/v1/auth/refresh` | rotate refresh token | reuse detection |
| POST | `/v1/auth/logout` | revoke device chain | |
| GET | `/v1/head` | `{head, pv, min_app_version, server_time}` | ETag, 304 on match |
| POST | `/v1/push` | apply mutations | one D1 batch |
| GET | `/v1/pull?since=&limit=` | `{rows[], next_cursor, head}` | `limit` ≤ 500 |
| GET | `/v1/bootstrap?page=` | chunked first-install snapshot at head H | 2,000 rows/page |
| POST | `/v1/number-blocks/lease` | lease 100 numbers for a series | atomic UPDATE..RETURNING |
| POST | `/v1/proofs` | upload chunk (256 KB, sha256 address) | resumable |
| GET | `/v1/proofs/:sha` | signed, cached chunk | |
| GET | `/public/approve/:token` | customer approval page (HTML, no login) | single-use decision |
| GET | `/v1/reports/:key` | server aggregates for >90-day ranges | 60 s cache |
| GET | `/v1/health` | deploy smoke test | |

### 6.3 Conflict resolution
- Field-level last-writer-wins for `customers`, `products`, `materials`, `price_*`,
  `vendor_*`, `settings`: merge the fields that changed on the server since `base_version`,
  unless the same field changed on both sides → conflict row.
- Append-only: `task_events`, `payments`, `inventory_movements`, `messages`, `audit_log` — no
  merge possible, server stamps order.
- State machine: `tasks.status`, `orders.status`, `quotes.status`, `vendor_jobs.status` —
  illegal transition ⇒ `rejected` with the authoritative state returned; the device applies it
  and shows "This job moved to *Printing* on another device".
- Locked documents: `invoices` (issued), `quotes`/`orders` (sent) — a patch to a locked field
  ⇒ `rejected` with code `DOCUMENT_LOCKED` and the app offers "Create revision".
- Claiming a task: conditional update
  `UPDATE tasks SET assignee_id=?, claim_token=?, version=version+1 WHERE id=? AND status='available'`
  — zero rows ⇒ `CLAIM_LOST`; the claimant gets a snackbar and the task is removed from their
  list.

### 6.4 Pull filtering
`change_log` carries `branch_id`, `assignee_id` and `job_id`. A pull returns rows where
`branch_id ∈ user's scope` OR `assignee_id = user` OR `created_by = user`, and
(`row is open` OR `server_ts > now - 90 days`). Owner scope = tenant. The filter is one indexed
range scan on `seq` plus a filter; it is not a join, per design §5.11.

### 6.5 Head and revocation
`GET /v1/head` returns `pv` (permission version) and `min_app_version`. If the device's token
`pv` differs, the client refreshes before its next push. Revoking a device sets
`devices.revoked_at`, bumps `pv`, and returns `401 DEVICE_REVOKED` on any push, which triggers
a local wipe behind a PIN prompt. No token blacklist table, no extra read on the hot path.

### 6.6 Deterministic simulation tests (built in Phase 1, not later)
`packages/sync_engine/test/simulation_test.dart` runs N virtual devices against an in-memory
copy of the Worker's rules, randomly: going offline for 1–10 days, duplicating batches,
reordering batches, editing the same customer from two devices, claiming the same task twice,
and killing the connection between the batch write and the response. Assertions: no lost
mutation, no duplicate row, no divergence from the server's final state, and every rejection
traceable to a rule. This is the single highest-value test suite in the project.

---

## 7. Numbering

| Series | Format | Allocation |
|---|---|---|
| Job | `10452` (numeric, per tenant) | blocks of 100 leased per device; temp `T-0007` if a device runs dry offline, swapped and badged on sync |
| Quote | `QT-SHJ1-PC1-00045` | **per device** (branch + device code), gapless blocks |
| Invoice | `INV-SHJ1-PC1-00123` | per device, gapless, never reused, void keeps the number |
| Credit note | `CN-SHJ1-PC1-00012` | per device |
| Delivery note | `DN-SHJ1-PC1-00034` | per device |
| Receipt | `RCP-SHJ1-PC1-00078` | per device |
| Purchase order | `PO-2026-0042` | server-only (vendor coordinator is usually online) |

Block lease is one atomic statement:
```sql
UPDATE number_blocks SET next = next + :n, updated_at = :now
 WHERE device_id = :d AND series = :s AND next + :n - 1 <= "end"
 RETURNING next - :n AS start, next - 1 AS "end";   -- zero rows ⇒ lease a new block
```
A device asks for a new block at 20 remaining, and again at 5 if the first request failed.
Gaps are accepted for job numbers; gaplessness is preserved for invoices because the series is
per device.

---

## 8. Permissions and enforcement

`resource.action` keys with scopes, exactly as design §14. The Worker holds the canonical
policy in TypeScript, generated from `shared_test_vectors/permissions.json` so that Dart and TS
cannot drift. Enforcement points:
1. `requirePermission(key, scope)` middleware on every route.
2. Per-mutation re-check inside `/v1/push` — the JWT says who you are, never what you may do to
   *this* row; the row's branch, assignee and state are re-read in the same transaction.
3. Field-level redaction on the way out: without `cost.view`, the Worker strips `cost_*`,
   `margin_*`, `vendor_cost_*` from every response before serialisation. Not a UI concern.
4. Every rejection is a typed code (`PERMISSION_DENIED`, `SCOPE_DENIED`, `DOCUMENT_LOCKED`,
   `STATE_INVALID`, `VERSION_CONFLICT`, `CLAIM_LOST`), so the app can say something useful.

Discount limits are data: `roles.discount_limit_bps`, with approval rows carrying both the
requester and the approver (PIN entry at the counter allowed offline; the approval mutation
carries the approver's PIN hash proof, verified server-side).

---

## 9. Pricing engine

### 9.1 Input
```json
{
  "product_id": "...",
  "options": {"size":"90x55", "material":"art_card", "gsm":350, "sides":2,
              "colour":"cmyk", "finish":["matt_lamination"], "qty":500},
  "turnaround": "standard",
  "customer_tier": "retail",
  "price_book_version": 7,
  "now": "2026-11-03T09:00:00+04:00"
}
```
### 9.2 Output
`PriceBreakdown { lines[]{code, label, basis, qty, rate_fils, amount_fils, explain},
cost_subtotal_fils, markup_bps, price_fils, surcharges[], discount_fils,
rounding_fils, total_fils, vat_fils, grand_total_fils, warnings[], price_book_version }`

`explain` is a human string generated from the basis ("28 sheets × 2 sides × AED 0.35"), because
the owner will ask "why is this 122?" on day one, and the answer must be on screen.

### 9.3 Rule language
```json
{
  "id": "rule_lamination_matt",
  "applies_to": {"product_kind": ["sheet"]},
  "when": [{"option.finish": "contains:matt_lamination"}],
  "basis": "per_sheet_side",
  "rate_fils": 40,
  "min_charge_fils": 0,
  "priority": 40
}
```
Supported `basis`: `per_sheet`, `per_sheet_side`, `per_piece`, `per_sqm`, `flat`,
`percent_of_subtotal`, `per_hour`, `table_lookup`. Conditions support `eq`, `in`, `gte`, `lte`,
`contains`, `and`/`or`/`not` — a tiny evaluator with a fixed grammar, depth-limited, no `eval`,
no reflection. A malformed rule fails validation in the price-book editor, never at quote time.

### 9.4 Sheet layout algorithm
`piecesPerSheet(finishedW, finishedH, sheetW, sheetH, bleed, gutter)` tries both orientations
and the 4 rotations, picks the maximum; waste: `setupSheets` (default 2) + `spoilage_bps`
(default 300 = 3%); `sheets = ceil(qty / pieces) + setup + ceil(sheets * spoilage_bps / 10000)`.
All integer arithmetic with `ceilDiv`.

### 9.5 Price modes
- `cost_plus`: `price = cost × (1 + markup_bps/10000)`, markup from product → category → tier.
- `price_table`: matrix lookup on `(product, option-hash, qty band)`; add-ons (foil, rush) are
  rules applied on top.
- `outsourced`: `price = vendor_cost × (1 + markup_bps/10000)` or `vendor_cost + commission_fils`.
- `service`: fixed fee or `hours × hourly_rate`.

All three are exercised by the same breakdown renderer, so the counter staff see a consistent
panel regardless of how the product is priced.

### 9.6 Golden vectors
`shared_test_vectors/pricing/*.json` — each file is a request, the expected breakdown, and a
plain-English `note` explaining the arithmetic. First vector is the design's §7.5 worked example
(500 cards, 350 gsm, matt both sides, 28 sheets → AED 122.00 → VAT 6.10 → AED 128.10). The
owner signs off on these vectors; from then on they are the contract. Later a TypeScript port
runs the same JSON so the server can verify a client's price; that port is explicitly out of
scope for v1.

---

## 10. Documents

`DocumentRenderer` interface in `domain`; implementations in `apps/shop_app`. Documents:
quotation, tax invoice, simplified invoice, credit note, delivery note, receipt (A4/80 mm),
job ticket (A5/A4/80 mm, QR), job sheet, vendor brief, customer statement, receipt pack.

Every document is regenerated from stored data — the design is right that files are never the
source of truth. Rendering happens in an isolate; a 40-line invoice must render in under 300 ms
on the low-end Windows PC. Watermarks (`DRAFT`, `VOID`, `PAID`) are a parameter, not a variant.

Arabic: see ADR-009. The renderer takes `lang: en | ar | both`, and `both` lays out two columns
on A4 and stacks on A5. Fonts: Inter (Latin) and Noto Naskh Arabic (Arabic), subset-embedded,
bundled in `assets/fonts` so no document ever depends on a system font.

---

## 11. WhatsApp

Click-to-chat only, as designed. One `WhatsAppService`:
- `buildMessage(templateCode, orderId, lang)` → filled text with variables validated against
  the template's declared placeholders.
- `openChat(phoneE164, text)` → `https://wa.me/<e164>?text=<encoded>`; Windows opens the
  desktop app via URI association, Android the installed app.
- File attachment: Android share sheet (`share_plus`) with the generated PDF; Windows saves to
  a temp folder, puts the file on the clipboard (`win32` `CF_HDROP`) and opens the chat.
- Every open writes a `messages` row (who, when, template, order) — that is the only delivery
  evidence we will ever have, and the UI must say "opened in WhatsApp", never "sent".
- `Send now` queue: rules in `settings` (event → template → delay → working hours), respecting
  `customers.whatsapp_opt_in`.

---

## 12. UI / UX

**Design language.** Material 3 with brand tokens. Not neumorphism — a counter clerk under
fluorescent light needs contrast, not soft shadows. Glass is used only on the top bar and the
three-pane side panel where it costs no legibility; content surfaces are opaque. Density:
`VisualDensity.compact` on Windows, `standard` on Android, both as theme extensions.

**Why this is defensible to the client:** the screen that matters is the order builder, used
~100 times a day. Every element either speeds entry or shows a number. Decoration is confined
to the shell.

**Shell**
- Windows: labelled left rail (collapsible), content, optional right panel (order summary /
  price breakdown). Shortcuts: F2 new order, Ctrl+K search, F9 payment, Ctrl+P job ticket,
  Ctrl+S draft, Esc back, F1 help.
- Android: 4–5 bottom destinations per role, one primary FAB-style action per screen.
- Tablet/medium: navigation rail + list/detail.

**Home by role** exactly as design §16.3, driven by a `RoleHome` table so a role change
reflows the app without code.

**Non-negotiables in the design system**
- `SyncChip` always present in the shell: `Synced / Syncing n / Offline n waiting / Needs
  attention`, with last-sync time and Sync now.
- Every status is icon + text + colour (`StatusChip`), never colour alone.
- Forms autosave to a draft row on every change (debounced 800 ms); a crash loses nothing.
- Money rendered by `MoneyText` only — never a raw `toStringAsFixed`.
- All strings in ARB files, `flutter_localizations`, full RTL mirroring; Arabic numerals
  toggle per locale.
- 48 dp minimum targets; focus rings on Windows; screen-reader labels on all icon buttons.

**The 60-second repeat order** is a first-class flow, not a nicety: customer card → Reorder →
copy items, keep prices from the price book's *current* version, show a diff if any price
changed since the original order, then Confirm.

---

## 13. Reports and exports

Reports are SQL views + a Dart `ReportSpec` (columns, formats, totals, grouping) consumed by
three renderers: on-screen table, XLSX writer, PDF writer. One spec per report prevents the
classic "the PDF says 1,240 and the screen says 1,241".

Excel: `excel` 4.0.6, real typed cells, `#,##0.00` number format for AED, frozen header,
auto-filter, formula totals, an `Info` sheet with filters + generation time. Large exports run
in a background isolate with a progress dialog and cancel; above 100k rows, stream CSV.
PDF: same `DocumentRenderer`, company header, page numbers, generated-by, watermarks.
Every export writes an `audit_log` row (who, filters, row count).

---

## 14. Security and compliance

- TLS only; HSTS; strict CSP on the public approval page; no third-party scripts.
- Rate limiting via Cloudflare WAF rules + a D1-backed counter for login attempts.
- Proof links: HMAC-signed, 15-minute expiry, single order scope; the public approval page
  uses a 256-bit random token stored hashed, never an id.
- SQLCipher at rest on every device; secrets only in Worker secrets (`wrangler secret put`).
- Tenant column on every table from day one (design §17) — cheap now, impossible later.
- Audit log is append-only and exportable only with `audit.view`; every export is itself
  audited.
- UAE PDPL: consent flag on customers, opt-out honoured in the Send now queue, data-retention
  policy documented (invoices 5 years; proofs 60 days; audit 5 years).
- Backups: D1 Time Travel 30 days (confirmed for Workers Paid, current docs), plus a nightly
  `wrangler d1 export` to the shop's drive kept 90 days, plus a daily encrypted local copy on
  each Windows device.
- Passwords, PINs, tokens never logged. Structured logs carry ids, never payloads.

---

## 15. Testing

| Layer | Tool | Gate |
|---|---|---|
| Pricing | `dart test` + golden JSON | every vector, both modes, all rounding edges |
| Domain state machines | `dart test` | every legal and illegal transition |
| Permissions | shared JSON | Dart and TS read the same file |
| Sync | simulation suite + drift in-memory | randomised 10k-step run, zero divergence |
| Worker | `vitest` + `@cloudflare/vitest-pool-workers` + local D1 | per-role permission matrix, idempotent replay, batch atomicity |
| App | widget tests for the order builder, My Work, price book grid | golden screenshots at 3 widths |
| Integration | `integration_test` on Windows and Android | login → order → sync → invoice |
| Performance | benchmark harness | the §18.1 targets, fail >20% regression |
| UAT | parallel run, one branch | staff complete 20 real jobs unaided |

CI (GitHub Actions): `dart format --set-exit-if-changed`, `dart analyze --fatal-infos`,
`dart test` per package, `bun test` for the worker, a migration dry-run against a fresh D1,
`flutter build windows --release` and `flutter build apk --release`. Release artefacts:
Inno Setup installer for Windows (consistent with the other desktop apps in this shop) and a
signed AAB for Android.

---

## 16. Phased delivery

Estimates assume one builder plus your review, and are given as ranges. They are not promises
until Phase 0 answers the open questions.

### Phase 0 — Discovery (1–2 weeks, client-dependent)
Collect: real price lists, 20 past jobs with their quotes, workflow per product, document
samples (invoice/quote/job ticket in both languages), printer models, branch/device counts.
Deliverables: `docs/discovery/` notes, pricing vectors in JSON, the three PDF spikes printed,
the thermal spike printed. **Exit:** signed scope.

### Phase 1A — Skeleton and risk retirement (2–3 weeks)
- Pub workspace, CI, lint rules, dependency-graph check.
- `domain`: entities, enums, state machines, `Fils`, permissions.
- `pricing_engine` + vectors from §7.5 + discovery data.
- D1 schema, migrations, seed script, `EXPLAIN QUERY PLAN` for hot queries.
- Worker: auth, JWT, head, push, pull, bootstrap, number blocks, proofs, health.
- `sync_engine`: outbox, push/pull, conflict inbox, simulation tests.
- Worker tests: permission matrix, idempotency, batch limits.
**Exit:** `curl` creates a customer and an order, syncs between two simulated devices, and a
1,000-step randomised simulation diverges zero times. Arabic PDF and thermal spikes pass.

### Phase 1B — App shell (2–3 weeks)
Drift schema + SQLCipher on both platforms, design system + tokens, adaptive shell, login and
offline PIN, sync chip, roles/permissions admin, branches, users, devices, settings, backup and
restore, in-app diagnostics screen.
**Exit:** a Windows installer and an Android APK where a user logs in offline, sees their role's
home, and the sync chip tells the truth.

### Phase 2 — Sales core (3–4 weeks)
Customers (phone-first), catalogue, price-book spreadsheet editor (paste, import, bulk adjust,
effective dates, margin guard, test calculator, revert), order builder with live pricing,
quotes + revisions, orders, PDF quote/order, WhatsApp click-to-chat, Excel import/export.
**Exit:** a real repeat order in under 60 s on the shop's own PC, signed off by the owner.

### Phase 3 — Production (3 weeks)
Workflow templates, task generation, pool/pick-up, My Work, live board, time tracking, proofs
and approvals, customer approval page, job ticket + QR, notifications (FCM Android, local on
Windows), rework and problem reporting.
**Exit:** 20 real jobs through the system in parallel with paper.

### Phase 4 — Money and vendors (3 weeks)
Invoices (VAT, bilingual, immutable), credit notes, payments, credit accounts and ageing,
till sessions, expenses, VAT report, vendors, outsourced jobs, vendor bills, commissions.
**Exit:** month-end reconciles with the accountant's numbers.

### Phase 5 — Growth (3 weeks)
Inventory and purchasing, dashboards, all reports + exports, customer tracking page, Send now
queue, accountant pack, owner daily WhatsApp summary.
**Exit:** accountant accepts the export pack; owner uses the dashboard daily.

### Phase 6 — Pilot (2–3 weeks)
Data migration, training, parallel run, fixes, go-live and handover docs.

Working order differs from the design document in one respect: **the vertical slice (Phase 2's
order builder) starts during Phase 1B**, with sync stubbed, because staff feedback on that
screen is worth more in week 5 than in week 12. The sync engine is still built and proven first.

---

## 17. Risks, ranked by damage

| Risk | Likelihood | Damage | Mitigation |
|---|---|---|---|
| Sync edge cases corrupt data | Medium | Severe | Build first, simulate 10k steps, append-only where possible, typed rejections, diagnostics screen |
| Arabic PDF unusable | Medium | Severe (legal docs) | Week-1 three-way spike, accountant picks, interface isolates the choice |
| Windows thermal/label printing | Medium | High | Hardware spike in week 1 with the actual printers; ESC/POS via FFI |
| Price lists messier than expected | High | High | Start with price tables, CSV importer, owner-signed vectors, bulk adjust tool |
| Windows installer breaks SQLCipher | Low | High | Test the installed MSIX/Inno build in CI, not `flutter run` |
| Staff adoption | Medium | High | Role-shaped home, 60-second repeat order, training mode, one champion per branch |
| Scope creep from the owner | High | Medium | Fixed phase scope, change requests, visible backlog, demo every two weeks |
| D1 limits (100 params, 2 MB row) hit by bulk operations | Medium | Medium | Chunked multi-row inserts sized to 100 params; chunked proof table; nightly size metric |
| Offline invoice numbering disputed by accountant | Low | High | Accountant sign-off on per-device series before go-live |
| Cloudflare account ownership | Low | Medium | Client owns the account; we get scoped tokens, never the global key |

---

## 18. Cost estimate (monthly, production)

| Item | Estimate |
|---|---|
| Workers Paid | USD 5 |
| D1 (≈1 GB, 20 devices polling, 100 orders/day) | USD 5–15 |
| FCM | free |
| Domain + email (existing) | — |
| **Total** | **≈ USD 10–20/month**, dominated by polling and D1 row reads |

Polling math: 20 devices × 120 head calls/hour (30 s) ≈ 2,400/hour ≈ 1.7 M/month, mostly
304s. Fine on Paid; would break the Free plan, as the design notes.

---

## 19. Blocking questions (need answers before Phase 1A ends)

1. Branch count, device count, users per role — sizing and number blocks.
2. Price lists: cost-plus or table? Can we have 20 recent real jobs with quotes?
3. Machine list and sheet sizes; which products are outsourced.
4. Invoice samples in both languages; TRN; VAT-registered? Per-device series acceptable to the
   accountant?
5. Printers: thermal model, A4 model, label printer, at each counter.
6. WhatsApp numbers per branch; WhatsApp Desktop or Business app.
7. Original artwork today: shared folder, Google Drive, or WhatsApp?
8. Does the client want the customer tracking page in v1?
9. Cloudflare and Google/FCM accounts: who owns them, who creates them (needed for Phase 1B
   push notifications).
10. Logo, brand colours, fonts.
11. Will this be resold to other print shops? (Multi-tenancy and licensing — cheap now,
    expensive later.)
12. Internet reliability per branch and typical outage length.

---

## 20. Definition of done for v1

A counter employee who has never seen the app can, on day one: create a customer by phone
number, price a 500-card order correctly, print the job ticket, and take a deposit — while the
internet is unplugged — and the manager sees the same job on their board within 30 seconds of
the cable going back in. That is the whole product in one sentence, and every phase above
serves it.
