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

# Prove the deployed API end to end
python tools/smoke_live.py
```

Credentials live in `.env.local` (git-ignored). The demo login is
`+971500000001` / `starparis-demo` — development only; change it before the
client sees this environment.

## Why Flutter

The app is Flutter/Dart on Windows and Android. The Worker is TypeScript
because Cloudflare's runtime executes JavaScript/WASM, not Dart. Pricing,
validation and document generation all happen on the device in pure Dart, so
the backend can fall over and the counter keeps quoting.

