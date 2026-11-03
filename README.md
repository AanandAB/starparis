# starparis

Star Paris Graphic LLC — Shop Management System.

Flutter (Windows + Android) · offline-first · Cloudflare Workers + D1.

The engineering plan lives in [PLAN.md](PLAN.md). Nothing in this repository is a mock:
every phase ships tested, working code.

## Where it stands

Phase 1A is built and verified:

| Piece | State |
|---|---|
| `packages/domain` | money (integer fils), UUIDv7, status machines, permissions — 32 tests |
| `packages/pricing_engine` | sheet layout, rule engine, cost-plus/table/vendor pricing — 19 tests, 5 golden vectors |
| `backend/worker` | Hono API on Cloudflare Workers + D1, auth, sync push/pull/head, number blocks — 15 integration tests in workerd |
| Live dev API | https://starparis-api.theblacklightstudio.workers.dev |

The §7.5 worked example from the design document prices at exactly **AED 122.00 + 6.10 VAT = 128.10**, asserted by a test and by the live API.

### Phase 1B — the app shell

| Piece | State |
|---|---|
| `apps/shop_app` | Flutter Windows + Android: sign-in, offline PIN, sync chip, customer directory, adaptive rail / bottom navigation |
| `packages/sync_engine` | Drift local database with SQLCipher, outbox with coalescing, push/pull loop, conflict surfacing — 10 tests |
| `packages/design_system` | tokens, Material 3 theme, SyncChip, StatusChip, MoneyText, EmptyState |

Verified on the build machine: `flutter build windows --release` succeeds, the app launches,
and the local database file on disk starts with random bytes rather than `SQLite format 3` —
which is the only proof that matters that SQLCipher is actually active.
Screenshot: `docs/screenshots/login-windows.png`.

Sign in with `+971500000001` / `starparis-demo`, then choose a PIN. The PIN unlocks the app
with no connection; the sync chip tells you what is waiting to upload.

### Phase 2A — price book and the order builder

| Piece | State |
|---|---|
| Catalogue | `GET /v1/catalogue` serves products, materials and price rules; the device caches them in one transaction |
| Order builder | product → size → sides → finishing → quantity → live breakdown → confirm |
| Pricing | the same engine the golden vectors test, now fed by real catalogue rows rather than fixtures |
| Numbering | job numbers leased in blocks of 100 per device; `T-0007` when the block runs dry offline |
| Orders | saved locally with the frozen breakdown, pushed to D1, listed with status and "waiting to upload" |

Verified live with `apps/shop_app/tool/live_order_smoke.dart`:

    login            ok  role=owner
    catalogue        ok  products=2 rules=5 book v1
    price            ok  total=AED 122.00 vat=AED 6.10 grand=AED 128.10
    job number       ok  201
    push             synced  pending=0
    pull             ok  job=201 total_fils=12810 branch=0193f0b1-…

That run used the shipped client code — the real database, the real pricing engine, the real
push/pull — against the deployed Worker. The first attempt failed on a real bug (the server
injected `branch_id` into a table that has no such column); it is fixed and covered by a test.

### Phase 2B — the owner can change prices

| Piece | State |
|---|---|
| Endpoints | `PATCH /v1/price-book/rules/:id`, `PATCH /v1/price-book/products/:id`, `POST /v1/price-book/bulk-adjust` |
| Permission | `price.edit` only — owner by default; the Worker refuses everyone else with `PERMISSION_DENIED` |
| Audit | every change writes old and new JSON to `audit_log` |
| Bulk adjust | dry-run preview computed with the same integer arithmetic as the apply |
| App | Prices tab (owner only): every rule with its rate, edit dialog, bulk adjust with preview |

Verified live with `apps/shop_app/tool/live_price_book_smoke.dart`:

    baseline         rate=80 fils total=AED 122.00
    edit             ok  rate=100 fils total=AED 131.00 (+900 fils)
    restore          ok  total=AED 122.00
    OK — the owner can change a price and the quote follows immediately.

Design goal #2 — "let the owner edit every price from inside the software" — is now true for
rates, minimum charges, markups, print rates, area rates, rounding and minimum order values.
What it does **not** yet do: schedule a change for a future date (effective-dated price books),
and import a whole price list from Excel.

### Phase 2C — quotes and documents

| Piece | State |
|---|---|
| `packages/documents` | quotation (A4) and job ticket (A5) as PDF, pure Dart, no Flutter |
| Quotes | "Save as quote" in the builder, `QT-00045` numbering, convert to order keeps the frozen prices |
| Order sheet | Quote PDF, Job ticket, WhatsApp, and Convert to order for quotes |
| WhatsApp | click-to-chat `wa.me` link with the message pre-filled; staff review and send |
| Output files | saved to `Documents/StarParis`, opened with one tap |

Sample output you can open: `docs/samples/sample-quote.pdf` and `docs/samples/sample-job-ticket.pdf`.
The quote's text layer reads back as:

    QT-SHJ1-PC1-00045        Valid until 10 Nov 2026
    Business cards | 500 | 90 x 55 mm | double sided | matt lamination   500   2.44   122.00
    Subtotal AED 122.00   VAT 5% AED 6.10   Total AED 128.10

Arabic is deliberately **not** in these documents yet. `package:pdf` lays out bidirectional text
but does not shape Arabic letters, so an Arabic invoice would print isolated letterforms —
worse than an English one for a legal document. The decision and the three candidate solutions
are in PLAN.md ADR-009; it needs the accountant and a font before it ships.

### Phase 3A — production

| Piece | State |
|---|---|
| Workflow stages | `workflow_stages` per workflow key, shipped in the catalogue, editable as rows |
| Task generation | confirming an order (or converting a quote) creates one task per stage: first `available`, rest `waiting` |
| Board | Production tab: Board / My work, one column per stage, qty, due date, overdue in red, rework reason on the card |
| Moving work | Claim → Start → Finish, Pause or Send back with a mandatory reason; only legal moves are ever offered |
| Cascade | finishing a stage opens the next, on the device and on the server |
| Server rules | the Worker enforces the same state machine, refuses a jump (`available` → `done`), and stamps `started_at` / `done_at` itself |
| Audit | `task_events` records every status change with actor, reason and time |

Proven end to end against a real Worker and a real D1 (locally, via `wrangler dev`):

    login            ok  role=owner
    workflow         ok  design -> print -> finish -> qc -> delivery
    tasks            ok  5 created, first=available rest={waiting}
    push             synced  pending=0
    transitions      synced  pending=0
    server           design=done print=available finish=waiting qc=waiting delivery=waiting
    server refuses   ILLEGAL_TRANSITION  (status=rejected)

Run it yourself:

```bash
cd backend/worker && bunx wrangler d1 migrations apply starparis-dev --local
bunx wrangler d1 execute starparis-dev --local --file ../../seeds/demo.sql
bunx wrangler d1 execute starparis-dev --local --file ../../seeds/catalogue.sql
bunx wrangler dev --port 8788            # needs backend/worker/.dev.vars with JWT_SECRET
cd ../../apps/shop_app && dart run tool/live_tasks_smoke.dart http://127.0.0.1:8788 <owner-phone>
```

Two real bugs surfaced only by running it, both now covered by tests:

1. **The outbox coalesced state changes.** Claim → start → finish, all offline, merged into one
   patch, so the server saw `available → done` and correctly refused it. Status patches are now
   never coalesced, and the outbox is ordered by `created_at` then the monotonic UUIDv7 id so a
   chain of moves arrives in the order it was made.
2. **A cascade done on both sides looked like a conflict.** The device opens the next stage and so
   does the server; the device's copy came back `VERSION_CONFLICT` and sat in the outbox forever.
   A rejected patch whose fields already equal the server's row is a duplicate, and is now
   dropped instead of pinning a permanent "1 pending" badge.

## Commands
```bash
# Dart workspace
dart pub get
dart analyze
(cd packages/domain && dart test)
(cd packages/pricing_engine && dart test)

# Backend
cd backend/worker
bun install
bun run typecheck
bun run test                     # runs inside workerd with a real D1
bunx wrangler d1 migrations apply starparis-dev --remote
bunx wrangler deploy             # needs CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID

# Seed the dev database (demo owner + counter)
python tools/seed_demo.py > seeds/demo.sql
bunx wrangler d1 execute starparis-dev --remote --file ../../seeds/demo.sql

# Seed the starter price book
python tools/seed_catalogue.py > seeds/catalogue.sql
bunx wrangler d1 execute starparis-dev --remote --file ../../seeds/catalogue.sql

# Prove the deployed API end to end
python tools/smoke_live.py
(cd apps/shop_app && dart run tool/live_order_smoke.dart)
(cd apps/shop_app && dart run tool/live_price_book_smoke.dart)

# The app
cd apps/shop_app
flutter run -d windows
flutter build windows --release
flutter build apk --release        # needs Android licences accepted once

# Sample documents (writes docs/samples/*.pdf)
cd packages/documents && dart run tool/make_samples.dart
```

Credentials live in `.env.local` (git-ignored). The demo login is
`+971500000001` / `starparis-demo` — development only; change it before the
client sees this environment.

## Why Flutter

The app is Flutter/Dart on Windows and Android. The Worker is TypeScript
because Cloudflare's runtime executes JavaScript/WASM, not Dart. Pricing,
validation and document generation all happen on the device in pure Dart, so
the backend can fall over and the counter keeps quoting.

