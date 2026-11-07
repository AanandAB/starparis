"""Sync pull load test against the DEV D1 database.

Seeds ~10,000 orders (plus the matching change_log rows) into the remote
`starparis-dev` D1 database, then times how long the sync pull endpoint
(`GET /v1/pull`) takes to page through them. The number that matters is the
per-page latency and the total replay time: that is what a real device waits on
when it catches up after a day offline.

Why change_log and not just `orders`: /v1/pull replays the change_log, not the
table, so seeding orders without change_log rows would time an empty result and
report a meaningless "instant". Both are seeded so the endpoint is genuinely
exercised.

Why wrangler rather than the REST API: the repo already drives D1 through
wrangler (tools/backup_d1.py), so this keeps one credential shape
(CF_API_TOKEN + CF_ACCOUNT_ID read from .env.local) and one code path.

Safety: this only ever talks to the DEV database and the DEV worker. It never
touches staging or production. When the credentials are missing — or are the
`***` placeholders this repo ships in .env.local — it prints exactly what it
would do instead of inventing timings.

Usage:
    python tools/load_test.py --dry-run    # print the plan, touch nothing
    python tools/load_test.py              # seed + time the pull (needs creds)
    python tools/load_test.py --skip-seed  # time the pull on already-seeded data

Login uses the demo tenant from tools/seed_demo.py (phone defaults to the demo
owner's number, password `starparis-demo`); override with --phone/--password or
DEMO_PHONE/DEMO_PASSWORD. The demo seed's own docstring warns to change the
phone before anyone outside the build sees the environment — if that happened,
pass the real one.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORKER_DIR = ROOT / "backend" / "worker"
DB_NAME = "starparis-dev"

# Demo tenant identity from tools/seed_demo.py. These are fixed UUIDs, not
# secrets: they are the tenant/branch/user the demo seed inserts into dev.
TENANT = "0193f0b1-0000-7000-8000-000000000001"
BRANCH_SHJ = "0193f0b1-0000-7000-8000-0000000000b1"
OWNER_USER = "0193f0b1-0000-7000-8000-0000000000d1"

DEMO_PHONE = "+971" + "*" * 4 + "0001"  # redacted placeholder; override via --phone/DEMO_PHONE
DEMO_PASSWORD = "starparis-demo"
DEFAULT_BASE_URL = "https://starparis-api.theblacklightstudio.workers.dev"

ORDER_COUNT = 10_000
ORDERS_PER_BATCH = 1_000  # orders per `wrangler d1 execute` call
PULL_PAGE_SIZE = 500
MAX_PULL_PAGES = 100
# D1 binds at most 100 parameters per prepared statement; keep every multi-row
# INSERT comfortably under it.
MAX_BIND_PARAMS = 90

# Rows are prefixed so a re-run can delete exactly what it inserted, and so the
# load-test data is recognisable as disposable.
LOADTEST_DEVICE = "loadtest-device-0001"
LOADTEST_CUSTOMER = "loadtest-customer-0001"

ORDER_COLUMNS = [
    "id", "tenant_id", "branch_id", "number", "number_display",
    "customer_id", "customer_name", "status", "subtotal_fils",
    "vat_fils", "total_fils", "item_count", "created_at", "updated_at",
    "created_by",
]

LOG_COLUMNS = [
    "tenant_id", "entity", "row_id", "op", "branch_id", "actor_id",
    "device_id", "row_version", "row_json", "server_ts",
]


def load_env() -> dict[str, str]:
    """Secrets live in .env.local, never in this script or in git."""
    env: dict[str, str] = {}
    path = ROOT / ".env.local"
    if not path.exists():
        return env
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip().strip('"').strip("'")
    return env


def _usable(value: str) -> bool:
    """A secret is usable only when it is non-empty and not the `***` marker
    this repo ships as a placeholder in .env.local."""
    return bool(value) and value.strip() not in ("", "***")


def _lit(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, int):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def _multi_insert(table: str, columns: list[str], rows: list[list]) -> list[str]:
    """Chunk rows into multi-row INSERT statements that stay under D1's
    100-parameter-per-statement ceiling."""
    per = max(1, MAX_BIND_PARAMS // len(columns))
    header = f"INSERT INTO {table} ({', '.join(columns)}) VALUES "
    statements: list[str] = []
    for i in range(0, len(rows), per):
        block = rows[i:i + per]
        tuples = ", ".join(
            "(" + ", ".join(_lit(v) for v in row) + ")" for row in block
        )
        statements.append(header + tuples + ";")
    return statements


def _order_json(order_id: str, number_display: str, i: int, ts: str) -> str:
    return json.dumps({
        "id": order_id,
        "tenant_id": TENANT,
        "branch_id": BRANCH_SHJ,
        "number": i + 1,
        "number_display": number_display,
        "is_quote": 0,
        "customer_id": LOADTEST_CUSTOMER,
        "customer_name": "Load Test Customer",
        "status": "draft",
        "priority": "normal",
        "delivery_method": "collect",
        "subtotal_fils": 10000,
        "vat_fils": 500,
        "total_fils": 10500,
        "item_count": 1,
        "created_at": ts,
        "updated_at": ts,
        "created_by": OWNER_USER,
        "version": 1,
        "deleted_at": None,
    })


def build_sql_batches(count: int, ts: str) -> list[str]:
    """One SQL string per wrangler call. The first batch also clears any
    previous load-test rows so re-runs are idempotent."""
    preamble = [
        f"DELETE FROM change_log WHERE device_id = {_lit(LOADTEST_DEVICE)};",
        "DELETE FROM orders WHERE number_display LIKE 'LT-%';",
        f"DELETE FROM customers WHERE id = {_lit(LOADTEST_CUSTOMER)};",
        "INSERT INTO customers "
        "(id, tenant_id, branch_id, name, tier, created_at, updated_at) VALUES ("
        f"{_lit(LOADTEST_CUSTOMER)}, {_lit(TENANT)}, {_lit(BRANCH_SHJ)}, "
        f"'Load Test Customer', 'retail', {_lit(ts)}, {_lit(ts)});",
    ]
    batches: list[str] = []
    for start in range(0, count, ORDERS_PER_BATCH):
        end = min(start + ORDERS_PER_BATCH, count)
        order_rows: list[list] = []
        log_rows: list[list] = []
        for i in range(start, end):
            order_id = f"loadtest-order-{i + 1:06d}"
            number_display = f"LT-{i + 1:06d}"
            order_rows.append([
                order_id, TENANT, BRANCH_SHJ, i + 1, number_display,
                LOADTEST_CUSTOMER, "Load Test Customer", "draft",
                10000, 500, 10500, 1, ts, ts, OWNER_USER,
            ])
            log_rows.append([
                TENANT, "orders", order_id, "insert", BRANCH_SHJ,
                OWNER_USER, LOADTEST_DEVICE, 1,
                _order_json(order_id, number_display, i, ts), ts,
            ])
        statements = preamble[:] if start == 0 else []
        statements += _multi_insert("orders", ORDER_COLUMNS, order_rows)
        statements += _multi_insert("change_log", LOG_COLUMNS, log_rows)
        batches.append("\n".join(statements) + "\n")
    return batches


def run_seed(batches: list[str], token: str, account: str) -> float:
    """Write each batch to a temp .sql file and run it through wrangler,
    mirroring tools/backup_d1.py (cwd=backend/worker, creds via env). Returns
    the wall-clock seconds spent executing."""
    env = os.environ.copy()
    env["CLOUDFLARE_API_TOKEN"] = token
    env["CLOUDFLARE_ACCOUNT_ID"] = account

    tmp = Path(tempfile.mkdtemp(prefix="loadtest_sql_"))
    started = time.perf_counter()
    for idx, sql in enumerate(batches):
        path = tmp / f"batch_{idx:03d}.sql"
        path.write_text(sql, encoding="utf-8")
        # Forward-slash absolute path: wrangler rejects backslash Windows paths
        # on this host (same note as tools/backup_d1.py).
        command = [
            "bunx", "wrangler", "d1", "execute", DB_NAME,
            "--remote", "--file", path.as_posix(), "--yes",
        ]
        print(f"  executing {path.name} ({path.stat().st_size} bytes) ...")
        result = subprocess.run(command, env=env, cwd=str(WORKER_DIR))
        if result.returncode != 0:
            print(f"FAILED {path.name}: wrangler exited {result.returncode}")
            raise SystemExit(2)
    return time.perf_counter() - started


def _request_json(method: str, url: str, payload=None, token: str | None = None,
                  timeout: int = 30):
    headers: dict[str, str] = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, (json.loads(raw) if raw.strip() else {})
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            return exc.code, json.loads(raw)
        except json.JSONDecodeError:
            return exc.code, {"raw": raw}
    except urllib.error.URLError as exc:
        # Network/TLS failure (DNS, timeout, expired cert): report it instead of
        # crashing, so a broken local trust store never fabricates a timing.
        return None, {"error": str(exc.reason)}


def login(base_url: str, phone: str, password: str):
    status, body = _request_json(
        "POST", f"{base_url}/v1/auth/login",
        payload={
            "phone": phone,
            "password": password,
            "device": {"name": "load-test", "platform": "windows"},
        },
    )
    if status != 200:
        return None, status, body
    return body.get("access_token"), status, body


def time_pull(base_url: str, token: str, page_size: int, max_pages: int) -> dict:
    """Page /v1/pull from cursor zero, timing each request."""
    latencies: list[float] = []
    rows_total = 0
    pages = 0
    since = 0
    body: dict = {}
    for _ in range(max_pages):
        url = f"{base_url}/v1/pull?since={since}&limit={page_size}"
        start = time.perf_counter()
        status, body = _request_json("GET", url, token=token)
        latencies.append(time.perf_counter() - start)
        pages += 1
        if status != 200:
            return {
                "ok": False, "status": status, "body": body,
                "pages": pages, "rows": rows_total, "latencies": latencies,
            }
        rows = body.get("rows") or []
        rows_total += len(rows)
        next_cursor = body.get("next_cursor")
        if not rows:
            break
        if not isinstance(next_cursor, (int, float)) or next_cursor <= since:
            break
        since = int(next_cursor)
    return {
        "ok": True, "pages": pages, "rows": rows_total,
        "latencies": latencies, "head": body.get("head"),
    }


def _report_latencies(latencies: list[float]) -> str:
    if not latencies:
        return "no requests"
    return (
        f"{len(latencies)} requests, total {sum(latencies):.3f}s, "
        f"min {min(latencies):.3f}s, max {max(latencies):.3f}s, "
        f"mean {sum(latencies) / len(latencies):.3f}s"
    )


def describe_plan(count: int, base_url: str, phone: str) -> str:
    n_batches = math.ceil(count / ORDERS_PER_BATCH)
    return "\n".join([
        "Load test plan (DEV only):",
        f"  1. Seed {count} orders + {count} change_log rows into remote D1 "
        f"'{DB_NAME}'",
        f"     via {n_batches} call(s) of:",
        f"       wrangler d1 execute {DB_NAME} --remote --file <batch_NNN.sql> --yes",
        f"     (idempotent: previous LT-* rows are deleted first)",
        f"  2. Login: POST {base_url}/v1/auth/login  (phone {phone})",
        f"  3. Time the pull, paging until no rows remain:",
        f"       GET {base_url}/v1/pull?since=0&limit={PULL_PAGE_SIZE}",
        f"     ... then since=<next_cursor>, repeating.",
        f"  4. Print per-page latency stats (min/max/mean/total).",
    ])


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Seed the DEV D1 with load-test orders and time /v1/pull.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print the plan and exit without touching anything.")
    parser.add_argument("--skip-seed", action="store_true",
                        help="Skip seeding; only login and time the pull.")
    parser.add_argument("--count", type=int, default=ORDER_COUNT,
                        help=f"Number of orders to seed (default {ORDER_COUNT}).")
    parser.add_argument("--page-size", type=int, default=PULL_PAGE_SIZE,
                        help=f"Rows per pull page (default {PULL_PAGE_SIZE}).")
    parser.add_argument("--base-url", default="",
                        help="Worker base URL (default: DEV workers.dev URL).")
    parser.add_argument("--phone", default="", help="Demo login phone override.")
    parser.add_argument("--password", default="", help="Demo login password override.")
    return parser.parse_args(argv)


def main(argv=None) -> int:
    args = parse_args(argv)

    secrets = load_env()
    token = secrets.get("CF_API_TOKEN", "")
    account = secrets.get("CF_ACCOUNT_ID", "")
    creds_ok = _usable(token) and _usable(account)

    phone = args.phone or os.environ.get("DEMO_PHONE", DEMO_PHONE)
    password = args.password or os.environ.get("DEMO_PASSWORD", DEMO_PASSWORD)
    base_url = args.base_url or os.environ.get("SYNC_BASE_URL", DEFAULT_BASE_URL)
    count = args.count
    seed_needed = not args.skip_seed

    dry_run = args.dry_run or (seed_needed and not creds_ok)

    print(describe_plan(count, base_url, phone))
    print()

    if dry_run:
        if seed_needed and not creds_ok:
            print("Cannot seed: CF_API_TOKEN / CF_ACCOUNT_ID are missing or are")
            print("the `***` placeholders in .env.local. To run for real:")
            print("  1. Fill in .env.local (CF_API_TOKEN, CF_ACCOUNT_ID).")
            print("  2. Seed the demo tenant if it is not already seeded:")
            print("       python tools/seed_demo.py > seeds/demo.sql")
            print("       wrangler d1 execute starparis-dev --remote --file seeds/demo.sql")
            print("  3. Re-run: python tools/load_test.py")
        else:
            print("Dry run — no data written, no requests made.")
        return 0

    ts = datetime.now(timezone.utc).isoformat(timespec="seconds")

    if seed_needed:
        print(f"Generating SQL for {count} orders ...")
        batches = build_sql_batches(count, ts)
        total_bytes = sum(len(b.encode("utf-8")) for b in batches)
        print(f"Seeding {count} orders across {len(batches)} batch(es) "
              f"({total_bytes} bytes total) ...")
        seed_seconds = run_seed(batches, token, account)
        print(f"Seed complete in {seed_seconds:.1f}s.")
    else:
        print("Skipping seed (--skip-seed).")

    print(f"Logging in as {phone} ...")
    access_token, status, body = login(base_url, phone, password)
    if access_token is None:
        print(f"Login failed (HTTP {status}): {json.dumps(body)}")
        if status == 401:
            print("If INVALID_CREDENTIALS: the demo phone may have been changed —")
            print("pass the real one with --phone or DEMO_PHONE.")
        return 1

    print(f"Timing pull from {base_url} (page size {args.page_size}) ...")
    result = time_pull(base_url, access_token, args.page_size, MAX_PULL_PAGES)
    if not result["ok"]:
        print(f"Pull failed (HTTP {result['status']}) after {result['pages']} "
              f"page(s): {json.dumps(result['body'])}")
        return 1

    print()
    print(f"Pull: {result['pages']} page(s), {result['rows']} rows, "
          f"head {result['head']}")
    print(f"Latency: {_report_latencies(result['latencies'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
