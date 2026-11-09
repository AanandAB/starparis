"""Restore a D1 backup into a scratch database and prove it round-trips.

The one step of the backup drill that used to be "documented, not executed".
Run it against any fresh scratch database and it will:

1. Create the scratch database if it does not exist.
2. Execute the backup .sql against it (remote).
3. Re-export the scratch database and compare the table list and per-table row
   counts (counted as INSERT statements) against the source export.
4. Exit non-zero and print a diff if anything does not match.

Usage (from the repo root):

    python tools/restore_d1.py backups/starparis-dev-<ts>.sql starparis-restore-scratch

Why it counts INSERT statements rather than running COUNT(*) queries: wrangler
splits a --command argument containing spaces when invoked through bunx on
Windows, so we avoid --command entirely and work with --file / --output paths
instead, which need no spaces.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORKER = ROOT / "backend" / "worker"

INSERT_RE = re.compile(r'INSERT INTO "([^"]+)"')
TABLE_RE = re.compile(r'CREATE TABLE (?:IF NOT EXISTS )?"?([a-z_0-9]+)"?')


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    for line in (ROOT / ".env.local").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip().strip('"')
    return env


def run(*args: str) -> subprocess.CompletedProcess:
    env = os.environ.copy()
    secrets = load_env()
    env["CLOUDFLARE_API_TOKEN"] = secrets["CF_API_TOKEN"]
    env["CLOUDFLARE_ACCOUNT_ID"] = secrets["CF_ACCOUNT_ID"]
    return subprocess.run(
        ["bunx", "wrangler", *args],
        cwd=WORKER,
        env=env,
        capture_output=True,
        text=True,
    )


def parse(sql: str) -> tuple[set[str], dict[str, int]]:
    """Table set and per-table row (INSERT) counts from an export."""
    tables = set(TABLE_RE.findall(sql))
    rows: dict[str, int] = {}
    for table in INSERT_RE.findall(sql):
        rows[table] = rows.get(table, 0) + 1
    return tables, rows


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    backup_arg, scratch = sys.argv[1], sys.argv[2]
    backup_path = (ROOT / backup_arg).resolve()
    if not backup_path.exists():
        raise SystemExit(f"backup file not found: {backup_path}")

    # 1. Create the scratch database (an existing one is fine).
    created = run("d1", "create", scratch)
    print(f"[1/4] create {scratch}: rc={created.returncode}")

    # 2. Restore the backup into it.
    rel = Path(os.path.relpath(backup_path, WORKER))
    restored = run("d1", "execute", scratch, "--remote", "--file", rel.as_posix())
    print(f"[2/4] restore into {scratch}: rc={restored.returncode}")
    if restored.returncode != 0:
        print(restored.stderr[-2000:])
        return 1

    # 3. Re-export the scratch database.
    export_rel = Path(f"../../backups/{scratch}-verify.sql")
    exported = run(
        "d1", "export", scratch, "--remote",
        "--output", export_rel.as_posix(), "--skip-confirmation",
    )
    print(f"[3/4] re-export {scratch}: rc={exported.returncode}")
    if exported.returncode != 0:
        print(exported.stderr[-2000:])
        return 1

    # 4. Compare table list and row counts.
    src_tables, src_rows = parse(backup_path.read_text(encoding="utf-8", errors="replace"))
    dst_file = ROOT / "backups" / f"{scratch}-verify.sql"
    dst_tables, dst_rows = parse(dst_file.read_text(encoding="utf-8", errors="replace"))

    missing = src_tables - dst_tables
    mismatched = {
        t: (src_rows.get(t, 0), dst_rows.get(t, 0))
        for t in set(src_rows) | set(dst_rows)
        if src_rows.get(t, 0) != dst_rows.get(t, 0)
    }

    print()
    print(f"[4/4] source tables: {len(src_tables)}  restored tables: {len(dst_tables)}")
    if missing:
        print("MISSING tables:", sorted(missing))
    if mismatched:
        print("ROW COUNT MISMATCH:")
        for t, (s, d) in sorted(mismatched.items()):
            print(f"  {t}: source={s} restored={d}")
    if not missing and not mismatched:
        print("VERIFIED: every table and row count came back.")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
