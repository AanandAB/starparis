# Backup and restore drill

A restore window is not a backup. D1 Time Travel gives point-in-time restore
within its retention window; the drill below is what survives an account
lockout, a region outage, or a deleted database.

## Export (daily)

```bash
python tools/backup_d1.py
```

Exports every remote D1 database (`starparis-dev`, `starparis-staging`) to
`backups/<db>-<UTC timestamp>.sql`, verifies each file is non-empty, and prints
the off-platform copy reminder. `backups/` is git-ignored — these files hold
shop data and must never be committed.

Secrets are read from `.env.local` (`CF_API_TOKEN`, `CF_ACCOUNT_ID`); nothing
credential-shaped lives in the script or in git.

## Off-platform copy

Copy `backups/` to Google Drive or the shop's backup drive immediately after
the export. Keep 90 days. Schedule the export + copy on the owner's PC (or the
CI job that owns this account) — the script has no scheduler of its own.

## Restore

To restore a database from an export into a fresh or empty D1 database:

```bash
wrangler d1 execute <db> --remote --file backups/<file>.sql
```

Run this against a scratch database first (create one with
`wrangler d1 create <name>`), then confirm the tables and row counts before
touching the real database.

## Honest status

- Export: **verified working** (2026-11-04) — dev exports with rows; staging is
  schema-only because it has never been seeded.
- Restore into a scratch database: **documented, not yet executed** — that is
  the one step of the drill still to prove.
- There is no scheduled job yet; the script runs by hand until the client's
  Cloudflare account owns this and a CI/scheduler is set up.
