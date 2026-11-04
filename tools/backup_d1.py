"""Off-platform D1 backup drill.

Exports every remote D1 database to a timestamped .sql file under backups/,
verifies each export is non-empty, and reminds the operator to copy the file
off-platform (Google Drive, the shop's backup drive). Run from the repo root:

    python tools/backup_d1.py

Why this exists: D1 Time Travel gives point-in-time restore, but a restore
window is not a backup. A scheduled export copied off-platform is the thing that
survives an account lockout, a region outage, or a deleted database. Keep 90
days and copy daily — see docs/backup.md.
"""

from __future__ import annotations

import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATABASES = ("starparis-dev", "starparis-staging")


def load_env() -> dict[str, str]:
    """Secrets live in .env.local, never in this script or in git."""
    env: dict[str, str] = {}
    path = ROOT / ".env.local"
    if not path.exists():
        raise SystemExit("missing .env.local at the repo root")
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip().strip('"')
    return env


def main() -> int:
    secrets = load_env()
    token = secrets.get("CF_API_TOKEN", "")
    account = secrets.get("CF_ACCOUNT_ID", "")
    if not token or not account:
        raise SystemExit("CF_API_TOKEN or CF_ACCOUNT_ID missing from .env.local")

    backup_dir = ROOT / "backups"
    backup_dir.mkdir(exist_ok=True)

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%SZ")
    env = os.environ.copy()
    env["CLOUDFLARE_API_TOKEN"] = token
    env["CLOUDFLARE_ACCOUNT_ID"] = account

    failures = 0
    for name in DATABASES:
        output = backup_dir / f"{name}-{stamp}.sql"
        # Wrangler rejects a backslash Windows path on this host; pass a
        # forward-slash path relative to the worker directory where wrangler runs.
        relative = Path(os.path.relpath(output, ROOT / "backend" / "worker"))
        command = [
            "bunx", "wrangler", "d1", "export", name,
            "--remote", "--output", relative.as_posix(), "--skip-confirmation",
        ]
        result = subprocess.run(command, env=env, cwd=ROOT / "backend" / "worker")
        if result.returncode != 0:
            print(f"FAILED  {name}: wrangler exited {result.returncode}")
            failures += 1
            continue

        # A zero-byte export is a failure, but an empty database (schema only)
        # is a legitimate state — staging has never been seeded. Rows absent is
        # a WARNING for the operator to judge, not a failed drill.
        text = output.read_text(encoding="utf-8", errors="replace")
        has_rows = "INSERT INTO" in text
        if len(text) == 0:
            print(f"FAILED  {name}: export is empty")
            failures += 1
        elif has_rows:
            print(f"OK      {name} -> {output.name} ({len(text)} bytes, rows present)")
        else:
            print(f"WARN    {name} -> {output.name} (schema only, no rows — expected if unused)")

    print()
    print("Next: copy backups/ to Google Drive or the shop backup drive.")
    print("Retention: 90 days. See docs/backup.md.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
