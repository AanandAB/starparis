# Backup and restore drill

A restore window is not a backup. D1 Time Travel gives point-in-time restore
within its retention window; the drill below is what survives an account
lockout, a region outage, or a deleted database.

## Export (automatic — daily + weekly)

One script, two schedules, both running on the owner's PC via Windows Task
Scheduler (installed with `tools\install_schedule.bat`):

| Task                  | When               | Writes to         | Retention                  |
| --------------------- | ------------------ | ----------------- | -------------------------- |
| StarParisBackupDaily  | every day 02:30    | `backups/daily/`  | deletes files > 30 days old |
| StarParisBackupWeekly | every Sunday 03:30 | `backups/weekly/` | kept indefinitely          |

The scheduler runs `tools\backup_scheduled.bat`, which cds to the repo, puts
bun on PATH, and calls the script. Output is appended to `backups/backup.log`.
Run it by hand with:

```bash
python tools/backup_d1.py --type daily     # keeps 30 days
python tools/backup_d1.py --type weekly    # kept indefinitely
```

Each export is verified non-empty. `backups/` is git-ignored — these files hold
shop data and must never be committed. Secrets are read from `.env.local`
(`CF_API_TOKEN`, `CF_ACCOUNT_ID`); nothing credential-shaped lives in the
script or in git.

## Off-platform copy

Copy `backups/weekly/` (and the recent dailies) to Google Drive or the shop's
backup drive on a regular cadence. A local copy is not off-platform storage; it
does not survive the PC failing. See the note in `.github/workflows/backup.yml`
for the CI-artifact path (short-term only).

## Restore (verified)

Restore is a one-command drill now, and it is proven, not just documented:

```bash
python tools/restore_d1.py backups/daily/<file>.sql <scratch-db>
```

`tools/restore_d1.py` creates the scratch database, executes the backup into
it, re-exports it, and compares the table list and per-table row counts against
the source export — exiting non-zero on any mismatch. Verified 2026-11-09:
46 tables restored, 470 data rows, every table and count matched.

For a real restore into the live database, run the raw export as before:

```bash
wrangler d1 execute <db> --remote --file backups/daily/<file>.sql
```

Always restore into a scratch database first and confirm the counts before
touching the live database.
