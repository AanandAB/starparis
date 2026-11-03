# Production backlog

Ordered by what stops the shop using the software, not by what is fun to build. Each entry is one
sitting: it names the outcome, the files, and how it is proved.

---

## 1. Catalogue editor — products and price breaks
**Outcome.** The owner adds a product or service and sets its price, without a developer.
**Where.** New `CatalogueScreen` under BUSINESS (`price.edit`), tabs: Products · Price breaks ·
Paper & materials · Finishing operations · Machines.
**Build.**
- `POST /v1/catalogue/products` (create), `PATCH` already accepts `machine_id`,
  `operation_codes_json`, `markup_bps`, rates, rounding, spoilage.
- Product form: code, name EN/AR, kind, pricing mode, workflow, press, finishing steps,
  sizes, quantity presets.
- Price breaks per product: quantity → amount, editable grid, feed `price_table` mode.
- Deactivate rather than delete (history must survive).
**Prove.** Worker test: create a product, set a break, price it; app widget test: form validates and
saves; live probe: new product appears in `/v1/catalogue` and prices on a device.

## 2. Paper, operations and machines in the same editor
**Outcome.** A new stock (say 400 gsm board), a new finishing step (foil), or a new press are data.
**Build.** `POST/PATCH /v1/catalogue/materials`, `/operations`, `/machines`; three list editors with
add/edit/deactivate; GSM, micron, sheet *or* roll width, cost basis.
**Prove.** Tests per endpoint; engine test that a new operation row changes a quote.

## 3. Quantity breaks and customer tier in the calculator
**Outcome.** "What for 1000?" answers itself; trade customers see trade prices.
**Build.** Engine consults breaks when `pricing_mode = price_table`; `tier` (retail/trade) selects a
break set or a markup delta; builder shows a price ladder (100 / 500 / 1000).
**Prove.** Pricing tests on a ladder; snapshot shows which break was used.

## 4. Number prefixes from Settings, not from code
**Outcome.** Changing `INV` to `BILL` in Settings changes the next invoice number.
**Build.** `NumberSeries` takes the prefix from `shopSettingsProvider`; series string becomes
`{prefix}-{branch}-{device}`.
**Prove.** Unit test on `formatNumber`; live lease returns a `BILL-…` number.

## 5. Login rate limiting
**Outcome.** A stolen phone number cannot be brute-forced.
**Build.** `login_attempts` table keyed by phone + IP window; 5 failures → 15-minute lock, constant
response time; audit row on lock.
**Prove.** Worker test: 6th attempt returns 429 with `LOCKED`; success resets the counter.

## 6. Backup, restore drill and staging
**Outcome.** A day of data can be lost and recovered, and it has been rehearsed.
**Build.** `wrangler d1 export` job (cron), documented restore into staging; migrate and seed staging;
`tools/verify_restore.py` comparing row counts and a known invoice.
**Prove.** Run the drill, record the timings and the recovered invoice number in `docs/runbook.md`.

## 7. Offset plates, ink coverage and colour count
**Outcome.** An offset quote stops being optimistic.
**Build.** `plateCostFils × colours × sides` line; colour count and coverage on the request; press
speed factor by coverage on the machine row.
**Prove.** Golden vector with 4/4 process colour; breakdown shows the plate line.

## 8. Grain, gripper and trim allowance
**Outcome.** Imposition stops over-promising on some stocks.
**Build.** `grain_locked` on material, `gripper_mm` and `trim_mm` on the sheet spec; layout refuses the
better rotation when grain is locked.
**Prove.** Layout tests: a grain-locked 90×55 yields the lower up-count and the higher price.

## 9. Operation waste applied
**Outcome.** Finishing waste is costed, not ignored.
**Build.** `waste_bps` on each operation feeds the sheet requirement, not just the money.
**Prove.** Engine test: a 2 % fold loss raises the sheet count and the material line.

## 10. Vendor jobs on the board and in margin
**Outcome.** Outsourced work is visible in the shop, and its cost shows against the job.
**Build.** Board column or badge for open vendor jobs; order sheet shows total − vendor cost.
**Prove.** Widget test for the badge; sync test for margin arithmetic.

## 11. Statement PDF and credit enforcement
**Outcome.** A customer can be handed a statement; terms mean something.
**Build.** `buildStatementPdf` in `packages/documents`; credit limit and terms checked when issuing an
invoice, with an override that needs a manager and a reason.
**Prove.** Document test on totals; worker test refusing an over-limit invoice.

## 12. Audit log viewer
**Outcome.** "Who changed this rate, and to what" is answerable in the app.
**Build.** `GET /v1/audit?entity&id`, owner-only; a sheet on the Prices screen per rule.
**Prove.** Worker test returns old → new; screen test renders it.

## 13. Arabic strings, completion and persistence
**Outcome.** The interface is Arabic for a shop that wants it, and it stays that way after a restart.
**Build.** Remaining ~149 strings into `strings.dart`; locale persisted in settings (server) or secure
storage; vocabulary confirmed with the owner first.
**Prove.** Test that no screen contains a bare English literal; restart test keeps the locale.

## 14. Arabic documents (decision first)
**Outcome.** An Arabic tax invoice that does not look broken.
**Decision.** Either embed an Arabic OTF with a shaping text engine, or render Arabic documents as
HTML → PDF. `package:pdf` shapes nothing, so this cannot be solved by a font alone.
**Prove.** Sample invoice in Arabic, read by an Arabic speaker, checked for joined letters.

## 15. 80 mm till slip
**Outcome.** A receipt comes out of the counter printer.
**Build.** 80 mm PDF layout in `packages/documents`; Windows raw spooler or driver print; Android
print intent.
**Prove.** Printed on the client's printer, photographed into `docs/samples/`.

## 16. Android on a device, and a real keystore
**Outcome.** The app is installed and used on the counter tablet.
**Build.** Generate `starparis-release.jks` (owner keeps it), wire signing in `build.gradle.kts`,
version code strategy; run the release build on a device and press every screen.
**Prove.** Screenshots from the device; encrypted DB header checked on-device.

## 17. CI, integration test and load test
**Outcome.** A broken commit cannot be merged, and sync is proven at volume.
**Build.** GitHub Actions: `dart test` per package, worker tests, `flutter analyze`, `flutter build`;
one integration test app ↔ deployed worker; a seed of 10k orders measuring pull time.
**Prove.** Green CI run; recorded pull timings.

## 18. Interface consistency, dark mode, bulk actions
**Outcome.** The last hand-rolled headers are gone; the theme can be dark; lists can be acted on in bulk.
**Build.** `ScreenHeader` on Board, Prices, Reports, Order builder, Track; theme toggle persisted;
multi-select on Orders with status and delete.
**Prove.** Widget tests on the header; a screenshot of each screen in both themes.

---

### Small housekeeping
- Migrations skip `0010` — renumber when the schema next changes, so the sequence reads clean.
- `README.md` phase table stops at Phase 5A; bring it up to date with settings, customers, vendors,
  staff, machines.
- `docs/screen-flow.md` marks Staff/Vendors/Track built; add the Catalogue screen once it exists.
