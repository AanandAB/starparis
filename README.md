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

### Phase 3B — proofs, approvals and time

| Piece | State |
|---|---|
| Proofs | versions per order (v1, v2, …), stored as **links** to wherever the artwork already lives |
| Sending | "Send" marks it sent and opens WhatsApp with the version, the link and "reply APPROVED or tell us what to change" |
| Decision | staff record Approved, or Rejected with the customer's reason (mandatory) |
| Server rules | nothing is approved before it was sent; a rejection needs a note; a new version supersedes the old |
| Time | the Server writes a `time_entries` row when a task leaves `in_progress`, from its own clock — a device cannot bill minutes |
| Where it shows | order sheet: proof list with status, decisions and "Time logged"; Production task sheet: live timer |

Why links and not files: R2 is not enabled on this account and a D1 row is capped at 2 MB, so
uploading proofs would mean a storage decision the client has not made yet. The shop already
sends artwork through WhatsApp and Drive; what goes missing is the *record*, and that is what this
keeps. When the client picks storage, the `url` column is what changes.

Live proof from the same smoke run:

    proof            rejected  note=Trim is too tight on the back  pending=0
    time             1 entries, 1m total

Time is deliberately server-side. The device sets `started_at` so the board shows a live timer, but
the Worker overwrites it, and the minutes in `time_entries` come from the Worker's clock and the
Worker's `started_at`. Each stretch of work is its own row, so pause → resume does not double-count.

### Phase 3C — QR, role-shaped home

| Piece | State |
|---|---|
| QR on the job ticket | encodes `starparis://job/<number>`; verified by rendering the PDF and decoding it with a real QR detector: `starparis://job/10452` |
| Role-shaped home | live counts per role — open tasks, due today, overdue, proofs waiting, ready to collect, sent back — plus a role-specific primary action |
| Honesty | every number comes from the local database, updates as work moves, and is correct offline |

    QR decode        starparis://job/10452
    home (designer)  Due today 2 · Proofs waiting 1 · Sent back 1 · All changes sent

The QR uses a custom scheme rather than a web address on purpose: pointing a printed ticket at a page
that does not exist yet is a promise the paper cannot keep. A scanner shows the job number today; the
scheme handler ships with the customer tracking page in Phase 5. See
`docs/samples/job-ticket-render.png` for the rendered ticket.

Windows toast notifications and the FCM path for Android are **not** in this phase. The board and the
home counts answer "what needs me now" inside the app, which is what was blocking staff use; OS-level
notifications need a signed installer to test properly and belong with the pilot hardening.

Phase 3 is now closed: tasks, board, proofs, approvals, time, documents and the role-shaped home are
all working and proven. Phase 4 is money — invoices, payments, credit accounts and the VAT report.

### Phase 4A — invoices and payments

| Piece | State |
|---|---|
| Invoices | `invoices` + `invoice_lines`, snapshotting customer, TRN, totals and VAT at issue |
| Numbering | `INV-SHJ1-PC1-00101` — branch and device in the series, so two counters cannot both issue 00101 |
| Immutability | an issued invoice cannot be edited; the server refuses any field change (`INVOICE_IMMUTABLE`) |
| One per order | a second invoice for the same order is refused (`DUPLICATE_INVOICE`), enforced by a unique index |
| Payments | cash, card, transfer, cheque; `paid_fils` and paid/part-paid are computed **by the server** in the same D1 batch as the payment |
| Guardrails | overpayment refused with the exact outstanding amount; payments cannot be edited; void is manager-only, needs a reason, and is refused once money is taken |
| Document | A4 tax invoice with supplier TRN, billed-to TRN, VAT line, paid and balance due |
| In the app | order sheet → issue invoice (with a warning that it locks), take payment, invoice PDF, send on WhatsApp |

Live proof from the smoke run — an invoice issued on the device, settled with two payments:

    invoice          INV-SHJ1-PC1-00101  paid=12810  status=paid  payments=2  pending=0
    time             1 entries, 1m total
    proof            rejected  note=Trim is too tight on the back  pending=0

Two things the live run caught and this phase fixed:

1. **Order numbering was unique on the bare integer.** Once numbering carries the device
   (`JOB-SHJ1-PC1-00001`), two devices' 00001 collide on `(tenant, branch, number)`. Uniqueness now
   sits on `number_display`, which is what the customer reads and what the sequence guarantees
   (migration 0006).
2. **Printed unit prices did not reconcile.** AED 122.00 ÷ 500 is 0.244 per card, not 2.44; a unit
   column that multiplies to the wrong total is the first thing a buyer checks. `unitPriceText()`
   now derives the unit from the line amount, showing 3 decimals only when 2 would not reconcile.

Not in 4A, deliberately: credit notes, payments against credit accounts, ageing, till sessions,
expenses and the VAT report. A void is only possible before money is taken, and a refunded payment
does not exist yet — 4B adds both, and invoices stay immutable so nothing already issued has to be
rewritten when it lands.

### Phase 4B — credit notes and refunds

| Piece | State |
|---|---|
| Credit notes | `credit_notes`, numbered `CN-SHJ1-PC1-00001`, issued **against** an invoice, reason mandatory |
| VAT split | the credited gross is split back into net + VAT at the invoice's own rate (50.00 → 47.62 + 2.38) |
| Cap | never more than the invoice still has to credit (`OVER_CREDIT`); the invoice's `credited_fils` is mirrored by the server |
| Refunds | `refunds` against a credit note, manager-only, capped at what the note still has left (`OVER_REFUND`) |
| Immutability | a credit note cannot be edited (`CREDIT_NOTE_IMMUTABLE`); a refund is a fact (`REFUND_IMMUTABLE`) |
| Balance | outstanding = total − paid − credited, shown on the invoice card next to the credits and their refunds |

Live proof, after settling the invoice with two payments:

    invoice          INV-SHJ1-PC1-00201  paid=12810  status=paid  payments=2  pending=0
    credit note      CN-SHJ1-PC1-00001  total=5000  refunded=5000  refunds=1  invoice_credited=5000  pending=0

The shape that matters: an invoice is never edited. Money comes back through a credit note, cash comes
back through a refund against that note, and both are single-writer rows the server validates. That is
the trail an auditor asks for.

Still open in money: credit accounts and ageing, till sessions and cash-up, expenses, and the VAT
summary/export the accountant signs off. Those are reads over what now exists, plus one new table for
till sessions — Phase 4C.

### Deployed

`https://starparis-api.theblacklightstudio.workers.dev` now runs the code through Phase 4B, against
`starparis-dev` in Cloudflare account `5a1b8404…`, with migrations 0001–0007 applied. Both smokes pass
against the live Worker, not just locally:

    invoice          INV-SHJ1-PC1-00001  paid=12810  status=paid  payments=2  pending=0
    credit note      CN-SHJ1-PC1-00001  total=5000  refunded=5000  refunds=1  invoice_credited=5000
    job number       ok  JOB-SHJ1-PC1-00101
    price            ok  total=AED 122.00 vat=AED 6.10 grand=AED 128.10

Deploying needs the account token, exported per shell session (never committed):

```bash
export CLOUDFLARE_ACCOUNT_ID=5a1b840410cdb75395413eec56be1c2d
export CLOUDFLARE_API_TOKEN=…                     # in .env.local, git-ignored
cd backend/worker && bunx wrangler d1 migrations apply starparis-dev --remote && bunx wrangler deploy
```

`starparis-staging` still has no tables — it gets its own migrate before a staging deploy.

### Phase 4C — credit note document

The printing gap from 4B is closed: a credit note is now its own A4 document, laid out like the
invoice on purpose so the customer files them together — title `CREDIT NOTE`, the number, an
`Against INV-SHJ1-PC1-00001` reference, net + VAT + total credited, and no paid/balance block. The
invoice card lists each credit note with a `PDF` action.

    CN-SHJ1-PC1-00001   Against INV-SHJ1-PC1-00001
    Credit - 100 cards damaged in finishing   1   47.620   47.62
    Subtotal 47.62   VAT 5% 2.38   Total 50.00

Sample: `docs/samples/sample-credit-note.pdf` (rendered proof: `credit-note-render.png`). The same
builder prints both documents — one `documentTitle` field and a `showPayments` flag — because two
layouts for two halves of the same transaction is how they drift apart.

Still to come in money: ageing by customer, till sessions and cash-up, expenses, and the VAT summary
export for the accountant.

### Phase 4C — reports: VAT and ageing

Two read-only endpoints, both summing the `vat_fils` frozen on each document rather than recalculating
anything:

| Endpoint | Returns |
|---|---|
| `GET /v1/reports/vat?from&to` | sales net / output VAT / gross, credits net / VAT / gross, **net VAT due**, cash collected by method, refunds |
| `GET /v1/reports/ageing?as_of` | per customer: current, 31–60, 61–90, 90+, total — outstanding = total − paid − credited |

`report.view` is required (owner, manager, accountant); everyone but owner/accountant is scoped to
their own branch. The counter gets a 403, and there is a test that says so.

Live against the deployed Worker and real D1:

    vat:  sales_net 12200  output_vat 610  credited_vat 238  due 372  collected 12810  refunded 5000
    ageing: customers 1  outstanding 10500  buckets {current 0, 31-60 10500, 61-90 0, 90+ 0}

The ageing probe was a real 45-day-old unpaid invoice pushed through `/v1/push`, so the bucket path is
proven against D1, not only in unit tests.

Still to come in money: the Reports screen in the app (the endpoints are in place), till sessions and
cash-up, expenses, and the VAT export file for the accountant.

### Phase 4C — the Reports screen

Owner, manager and accountant get a **Reports** tab: the month's VAT on one row of cards (sales,
output VAT, credits, **VAT due**, cash collected with its method breakdown, refunds) and the ageing
table underneath (current · 31–60 · 61–90 · 90+ · total, with a totals row, 90+ in red).

It is the one screen that says out loud that it needs the network: a VAT return and an ageing list
span every branch, so they cannot come from this tablet's database. The failure state says exactly
that — "these figures come from the server, everything else still works offline" — rather than
showing an empty table that looks like zero sales.

Checked through the app's own client, against the deployed API:

    vat        AED 122.00 sales · AED 6.10 output · AED 2.38 credited · AED 3.72 due · AED 128.10 collected
    ageing     AED 105.00 outstanding across 1 customer (31-60: 105.00)
               Ageing Probe LLC · AED 105.00

`tool/reports_smoke.dart` is the gate; it also asserts the client's own arithmetic (due = output −
credits) before printing OK.

Now left in money: till sessions and cash-up, expenses, and the VAT export file for the accountant.

### Phase 4D — till sessions and cash-up

| Piece | State |
|---|---|
| Session | `till_sessions`: device, who opened, opening float, opened_at; one **open** session per device (partial unique index) |
| Attachment | every payment and refund is stamped with the open session's id **by the server** — cash-up counts what is attached, not what fell inside a time window |
| Close | the device enters the counted amount; the server computes `expected = float + cash taken − cash refunded` and the variance, in the same batch |
| Refusals | a second open till (`TILL_ALREADY_OPEN`), a second close (`TILL_ALREADY_CLOSED`), a close with no count (`INVALID_AMOUNT`) |
| Who | `payment.take` (counter, manager, owner, accountant); card/transfer/cheque never touch the drawer and are excluded from expected cash |

Live on the deployed Worker, real D1 — open 200.00, take 105.00 cash against an invoice, count the
drawer:

    applied  applied  applied
    till: closed  float 20000  expected 30500  counted 30500  variance 0

Still to come: the Till screen in the app (open, see today's cash, close with a count), expenses, and
the VAT export file.

### Phase 4D — the Cash drawer

The counter reaches it from the user menu: **Cash drawer**. Closed, it asks for the opening float and
starts the shift. Open, it shows the float, when the shift began, the cash taken since, and **should
be in the drawer** — float plus cash taken, a local preview. Closing asks for the counted amount,
pre-filled with the preview, and tells you straight away whether it matches, or by how much it is
over or short, before you confirm.

The sheet says out loud that the server recomputes the expected amount from the payments attached to
the session, and that a difference is the variance. The device is a preview; the Worker is the till.

State: `schemaVersion 7` locally (`till_sessions` plus `payments.till_session_id`), 26 sync tests, 6
app tests, analyzer clean, Windows release build green.

### Phase 4E — expenses and the accountant's file

| Piece | State |
|---|---|
| `expenses` (0009) | category, supplier, description, amount, VAT on the receipt, method, optional receipt link; `amount > 0` enforced |
| Cash out | a **cash** expense is stamped with the open session and is subtracted from `expectedCash()` — the cash-up only reconciles if money leaving the drawer is recorded |
| Refusals | an expense of nothing (`INVALID_AMOUNT`); card/transfer/cheque never touch the drawer |
| Export | `GET /v1/reports/vat.csv?from&to` — one row per invoice and credit note with the number, date, customer, net, VAT and gross in AED, credits signed negative, a TOTAL row and "VAT due", behind `report.view` |

Live on the deployed Worker, real D1:

    till_sessions  applied      float 300.00
    expenses       applied      courier 45.00 cash
    till_sessions  applied      counted 255.00
    till float 30000 expected 25500 counted 25500 variance 0
    csv rows: 7   TOTAL 174.38 net / 8.72 VAT / 183.10 gross

61 worker tests (4 new), typecheck clean, migration 0009 applied remotely.

Still to do: the **expense entry sheet in the app** (the backend path is live, the counter has no
button yet), till history/month-end, and the Arabic UI pass.

### Phase 4F — the expense sheet

From the Cash drawer, open or closed: **Record an expense**. Amount, what it was for, a category
(Courier / Taxi / Materials / Refreshments / Rent / Other), who it was paid to, the VAT inside the
amount if the receipt carries it, cash / card / transfer, and an optional receipt link. Cash is the
default because it is what most of these are.

The sheet says it plainly: *cash comes out of the open drawer; card and transfer do not*. While a
shift is open, the drawer also shows **paid out since the shift began** so the cashier is never
surprised by the expected figure at close.

State: drift `schemaVersion 8` (`expenses` plus `_upsertExpense`), 27 sync tests (1 new — the expense
is queued as one insert and an amount of zero is refused before it reaches the outbox), 6 app tests,
analyzer clean, Windows release build green.

Remaining: till history and the month-end list, expenses list/export by category, and the Arabic UI
pass.

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

