# Star Paris — Screen flow and guide

What this document is: the map of the software as it stands, who uses which screen, and where the
gaps are. Anything marked **TO BUILD** does not exist yet — it is not hidden behind a permission, it
is simply not written.

Legend: **BUILT** · **PARTIAL** (works, but not the whole job) · **TO BUILD**

---

## 1. Who signs in

| Person | Sees | Why |
|---|---|---|
| **Owner** | Everything | Prices, reports, tills, staff, vendors |
| **Manager** | Board, orders, invoices, reports (not price edits) | Runs the floor, cannot rewrite the rate card |
| **Counter / Sales** | Customers, orders, quotes, invoices, cash drawer | Sells and takes money, cannot see the books |
| **Designer** | My work (design stage) | Draws, uploads proofs, marks the design done |
| **Operator** | My work (print, finish, QC where allowed) | Runs the machines, logs time |
| **Driver** | My work (delivery stage) | Takes the job out, marks it delivered |

Sign-in: phone + password (PBKDF2). A PIN pad unlocks a signed-in device for speed at the counter.
Roles are enforced **by the server** on every write; the app hides what a role cannot do, but hiding
is cosmetic — the refusal is real.

Status today: **PARTIAL**. Owner and Counter exist and are enforced. Manager, Designer, Operator and
Driver are defined in the task workflow (`required_role` on each stage) but there is no screen to
create staff, set their role, or reset a password — **TO BUILD** (`Staff`).

---

## 2. The navigation

### Desktop (Windows) — navigation rail, always visible

```
┌──────────────┬──────────────────────────────────────────────────────────────┐
│  Star Paris  │  Today · Customers · Orders · Production · [Prices] · Reports │  ← top bar
│              ├──────────────────────────────────────────────────────────────┤
│ ▸ Today      │                                                              │
│ ▸ Customers  │                     the screen you chose                     │
│ ▸ Orders     │                                                              │
│ ▸ Production │                                                              │
│ ▸ Prices 🔒  │                                                              │
│ ▸ Reports 🔒 │                                                              │
│              │                                                              │
│ ── bottom ── │                                                              │
│ Staff 🔒     │                                                              │
│ Vendors 🔒   │                                                              │
│ Settings     │                                                              │
└──────────────┴──────────────────────────────────────────────────────────────┘
```

🔒 = hidden from roles that cannot use it. Keyboard: `Ctrl+K` search and track, `Ctrl+N` new order,
`F5` sync now, `Esc` close a sheet.

### Android (phone / tablet) — bottom navigation, four items plus "More"

```
[ Today ]  [ Orders ]  [ Work ]  [ More ▾ ]
                                  ├ Customers
                                  ├ Prices 🔒
                                  ├ Reports 🔒
                                  ├ Staff 🔒
                                  ├ Vendors 🔒
                                  └ Cash drawer
```

A tablet in landscape switches to the same rail as the desktop — the layout follows the width, not
the operating system.

---

## 3. The journey a job takes

```
  Enquiry ─────────────────────────────────────────────────────────────────────┐
     │  "500 cards, matt lamination, Monday"                                   │
     ▼                                                                        │
  Quote (QT-…)          parameters: size, paper, GSM, sides, lamination, qty  │
     │  price computed on the device from the owner's rate card               │
     │  PDF + WhatsApp to the customer                                        │
     ▼                                                                        │
  Order (JOB-…)         quote converted, deposit taken, deadline set           │
     │                                                                        │
     ├─ vendor? ──► Vendor job (PO-…) — an outside shop does part of it,      │
     │              the shop keeps the record and the commission              │
     │                                                   **TO BUILD**         │
     ▼                                                                        │
  Production            one task per stage, opened by the previous one        │
     │  design → print → finish → qc → delivery                               │
     │  each stage: claim, start, pause, finish, rework (with a reason)       │
     │  proofs go out as links and come back approved or rejected             │
     ▼                                                                        │
  Invoice (INV-…)       issued once, never edited                            │
     │  part payments, credit notes, refunds — each its own document          │
     ▼                                                                        │
  Cash drawer           the shift that took the money, counted and closed      │
     ▼                                                                        │
  Reports               VAT (sales − credits − purchases), ageing, variances   │
```

**Tracking**: the customer quotes a job number or gives their phone number and staff see the stage.
Search exists on Customers only — **TO BUILD** (`Track`, `Ctrl+K`).

---

## 4. Every screen

### 4.1 Login — BUILT
Phone, password, device name. Fails offline with "sign in once with a connection"; after that the
device works offline until the refresh token expires.

### 4.2 PIN — BUILT
Four digits for a signed-in device. Five wrong attempts drop back to the password screen.

### 4.3 Today (Home) — BUILT
Greeting, then four figures that are all doors: **in production**, **overdue**, **due today**,
**waiting for you**. Below them: overdue and due-today task lists, unclaimed work for your role,
proofs waiting on the customer, and cash in the drawer while a shift is open. Everything is read from
the local database, so it is right on a dead connection.

Still missing from Today: money taken today (needs the payments roll-up), and a "pick up where you
left off" list.

### 4.4 Customers — BUILT
List, search by name/phone, add a customer with two phone numbers (WhatsApp + landline). Opens a
customer's orders and their balance.
The customer sheet shows address, TRN, notes, jobs and the statement of account; a **Statement PDF**
writes that statement to the shop's documents folder. An **Export** button writes the customer list to
`Documents/StarParis/StarParis_Customers_<date>_<time>.xlsx` (frozen header, filterable columns, offline).
The sheet also shows the customer's credit limit and deposit balance, and a **Take deposit** action
records an advance; issuing an invoice that would push a customer past a non-zero credit limit is
refused for a counter clerk (owner/manager override), with the over-limit balance flagged in red.

### 4.5 Orders — BUILT
List of orders with status, total, due date. Actions per order: quote PDF, job ticket PDF, invoice,
WhatsApp the customer, open the order sheet (proofs, time, payments).
Missing: search by job number or phone — **TO BUILD** (`Track`).

### 4.6 Order builder — BUILT
Product → size → paper and GSM → sides → lamination → quantity → rush / discount. The price is
computed on the device by the same engine the tests pin to five golden vectors, then stored as a
frozen breakdown so an old quote can always be reproduced.

### 4.7 Production board — BUILT
Two modes: **Board** (one column per stage, all work) and **My work** (only what you may touch).
Cards show status, quantity, due date, overdue marker, rework reason. The task sheet offers only the
legal next moves: claim, start, pause, finish, rework (reason required), cancel (manager only).

### 4.8 Prices — BUILT (owner only)
Edit a rate and see the effect on a sample quote before saving; bulk adjust in basis points; both
writes go to `audit_log` with the old and new value. No developer needed, which was the promise.

The catalogue's paper (materials), presses (machines) and finishing steps (operations) are edited the
same way on **Production setup** (owner only): each write is audited old → new and bumps
`catalogue_version`, so every device picks the change up on its next sync.

### 4.9 Reports — BUILT (owner, manager, accountant)
VAT for the month (sales, output VAT, credits, VAT due), ageing by customer, cash drawer history with
variances, purchases by category with input VAT. Server-side by design: a VAT return spans branches.

### 4.10 Cash drawer — BUILT
Open a shift with a float, see cash taken, close on a count. The server computes expected and
variance; the device only reports the count.

### 4.11 Proofs (inside an order) — BUILT
Versions as links, sent / approved / rejected with a mandatory note, revision numbers that the
customer sees, and a WhatsApp send that opens with the message written.
Proof files are now stored in D1 (256 KB chunks) and the customer approves on a no-login page that
records who decided, when, and the channel; files are kept 60 days (the purge job is documented, not yet built).

### 4.12 Time — BUILT
Start/pause on a task; the server owns the clock, so a device with a wrong time cannot bill an hour
that did not happen.

### 4.13 Diagnostics — BUILT
Outbox depth, last sync, pending conflicts. For support, not for customers.

### 4.14 Staff — BUILT
Owner only, and it needs a connection on purpose: rights are a shop-wide fact, so a tablet that has
been offline for a week must not be able to hand out an owner role. Add a person with a name, phone
(this is their login), role, first password and optional counter PIN. Tap a person to change their
role, switch them off, reset the password or set a new PIN.

Two rules the server enforces: nobody can change their own role or deactivate themselves, and the last
active owner cannot be demoted or switched off — a shop with no owner cannot be recovered from inside
the app. Roles are created on first use, so a designer can be added before anyone thinks about seeding.

### 4.15 Vendors — BUILT
A vendor record (name, trade, phone) and **vendor jobs**: work handed out against an order, with what
the vendor charges, the promised date and a four-state flow — draft → sent → back → closed. The margin
is the order total less the cost, which is why the cost is asked for when the work goes out rather than
discovered at month end. `sent_at` and `received_at` are stamped by the server, so a device with a
wrong clock cannot claim a job came back on time.

### 4.16 Track — BUILT
`Ctrl K`, or the box in the top bar: job number, invoice number, phone number or customer name.
Results come back grouped — **Jobs**, **Invoices**, **Customers** — and opening a job shows its sheet
with the stage, proofs, payments and the WhatsApp link. Invoices show what is outstanding and open the
job they belong to. Everything is answered from the local database, so it works with no connection.

### 4.17 Settings — **TO BUILD**
Company profile for documents (name, TRN, address), VAT rate, number series, backup/export.
The number prefixes (`INV`, `QT`, `JOB`) are saved here and used for every number issued from then on; a document already issued keeps the number it was printed with.

### 4.18 Quick sale (POS) — BUILT
A walk-in sale at the counter: quick-service chips (Copy, Print, Scan, Laminate, Binding) and typed
lines, optional customer name, VAT at the shop's rate, cash/card/transfer with cash change, and a
`QS-…` number. It syncs offline-first like every other entity. Till-session integration is deferred:
cash from a quick sale is recorded on the sale row but does not yet attach to a till session or open
the cash drawer.

---

## 5. What the requirements asked for, and where it is

| Requirement | State | Where |
|---|---|---|
| Process an order end to end | BUILT | Orders → builder → board → invoice |
| Design parameters (size, paper, GSM, quality) | BUILT | Builder, price rules |
| Owner sets every price, no developer | BUILT | Prices |
| Role-based logins and access | BUILT | Staff screen, server-enforced |
| Staff pick up work, status visible | BUILT | Board → My work |
| Everything centralised by job id | BUILT | Orders, board, money |
| Track by job id or phone | BUILT | Track (`Ctrl K`) |
| Quotes and invoices | BUILT | Documents, order sheet |
| WhatsApp messages | PARTIAL | Click-to-chat on quote/invoice/proof; no templates |
| Vendor / commission work | BUILT | Vendors screen, vendor jobs |
| Cloudflare Workers + D1, offline first | BUILT | Worker, sync engine |
| Windows + Android | BUILT | Release builds |
| Bilingual EN/AR with RTL | TO BUILD | Documents are English-only for now |
| 80 mm till slip | TO BUILD | A4 and job ticket PDFs exist |

Roughly: the operational core (price → sell → make → bill → collect → report) is built and tested;
the shop-floor extras (staff admin, vendors, tracking, slips) are not, and the interface needs the
redesign set out in the next section.

---

## 6. Interface redesign — the plan

The complaint is fair. What exists is tidy Material 3 but plainly default: one level of tabs, cards
that all look the same, no dashboard, no search, and the desktop layout wastes the width a counter PC
actually has.

**Principles**
1. **The job is the object.** Every screen can be read as "which job, what stage, whose turn".
2. **One action per screen.** The thing you came to do is the largest, most obvious control.
3. **Density for the desk, thumb for the phone.** Same data: a rail and a table on Windows, a list and
   a sheet on Android.
4. **Colour never alone.** Status is always colour + icon + word.
5. **Nothing decorative that costs a tap.**

**Phase A — foundation (no new features)**
- Type scale and spacing tokens with real hierarchy (today most text sits at body size).
- Shell: rail with grouped sections, a top bar that carries the customer search, sync state and the
  user's name; mobile bottom bar with five items.
- A real empty state and a real loading state on every screen (skeletons, not spinners).
- Keyboard: `Ctrl+K`, `Ctrl+N`, `F5`, `Esc`; and focus rings that a keyboard user can follow.

**Phase B — Today**
The screen the owner opens first: today's jobs by stage, overdue, cash taken, unclaimed work, proofs
waiting. Every number is a link to the list behind it.

**Phase C — Track + search**
`Ctrl+K` from anywhere: job number, invoice number, phone, customer. Opens the job sheet.

**Phase D — Staff and Vendors**
The two missing modules, in that order: staff first because every stage already names a role, then
vendors because the schema needs a table before the screens can exist.

**Phase E — Arabic and RTL** — *under way*
Locale switch wired (`en`, `ar-AE`), layout mirrors in Arabic, and the first screens are translated:
navigation, the user menu, and every figure and heading on Today. Strings live in
`lib/src/l10n/strings.dart` as plain en/ar pairs — not generated ARB — because the shop's Arabic is the
owner's Arabic (عميل or زبون, وديعة or دفعة مقدمة) and that conversation is cheaper when the pairs sit
in one file. A missing key falls back to English, never to a blank.

Not done: the rest of the screens (Orders, Customers, Board, Prices, Reports, Staff, Vendors, the
sheets), and Arabic PDFs — `package:pdf` shapes nothing, so documents need either an embedded Arabic
font with a shaping text engine or HTML rendering. That decision is still open.

**Cross-screen consistency** — *in progress*
`ScreenHeader` is now the one header for a list screen (title, subtitle, actions), applied to Orders
and Customers. Staff and Vendors still hand-roll theirs; converting them is the next small pass, then
the same for the sheets.

Each phase ships behind the same gates as everything else: unit tests, worker tests, a live smoke
against the deployed API, `flutter analyze`, a release build, and a screenshot.
