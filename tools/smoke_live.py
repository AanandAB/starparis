"""Live smoke test against a deployed Worker.

Exercises the same path a phone takes: health, login, head, push, pull. It is
deliberately a plain script with no dependencies so it can be run from any
machine, including a shop PC during installation.

Usage:
    python tools/smoke_live.py [base-url]

Exit code 0 means every step passed. Exit code 1 prints which step failed and
what the server said.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys

DEFAULT_BASE = "https://starparis-api.theblacklightstudio.workers.dev"
PHONE = "+971500000001"
PASSWORD = "starparis-demo"


def call(base: str, path: str, body: dict | None = None, token: str | None = None,
         method: str | None = None) -> tuple[int, dict]:
    """Uses curl because some Windows Python builds ship a stale CA bundle and
    reject Cloudflare's certificate while the OS — and the app — accept it."""
    curl = shutil.which("curl")
    if curl is None:
        raise SystemExit("curl is required but was not found on PATH")

    command = [curl, "-sS", "-m", "30", "-X", method or ("POST" if body else "GET")]
    command += ["-H", "content-type: application/json"]
    if token:
        command += ["-H", f"authorization: Bearer {token}"]
    if body is not None:
        command += ["--data", json.dumps(body)]
    command += ["-w", "\n%{http_code}", base + path]

    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        raise SystemExit(f"curl failed: {completed.stderr.strip()}")

    head, _, status_text = completed.stdout.rpartition("\n")
    payload = head.strip()
    try:
        return int(status_text.strip() or 0), (json.loads(payload) if payload else {})
    except json.JSONDecodeError:
        return int(status_text.strip() or 0), {"raw": payload}


def main() -> int:
    base = (sys.argv[1] if len(sys.argv) > 1 else DEFAULT_BASE).rstrip("/")

    status, health = call(base, "/v1/health")
    print(f"health           {status} {health}")
    if status != 200:
        return 1

    status, login = call(base, "/v1/auth/login", {
        "phone": PHONE,
        "password": PASSWORD,
        "device": {"name": "Smoke test", "platform": "windows", "app_version": "0.1.0"},
    })
    print(f"login            {status} role={login.get('user', {}).get('role')}")
    if status != 200:
        print(json.dumps(login, indent=2))
        return 1

    token = login["access_token"]
    device_id = login["device_id"]

    status, head = call(base, "/v1/head", token=token)
    print(f"head             {status} {head}")
    if status != 200:
        return 1

    status, pushed = call(base, "/v1/push", {
        "device_id": device_id,
        "mutations": [{
            "mutation_id": "smoke-00000000-0000-7000-8000-000000000001",
            "entity": "customers",
            "row_id": "0193f0b1-0000-7000-8000-0000000000a1",
            "op": "insert",
            "base_version": 0,
            "device_ts": "2026-11-03T09:00:00+04:00",
            "fields": {"name": "Smoke Test Customer", "tier": "retail"},
        }],
    }, token=token)
    result = (pushed.get("results") or [{}])[0]
    print(f"push             {status} status={result.get('status')} head={pushed.get('head')}")
    if status != 200 or result.get("status") not in {"applied", "duplicate"}:
        print(json.dumps(pushed, indent=2))
        return 1

    status, pulled = call(base, "/v1/pull?since=0&limit=50", token=token)
    count = len(pulled.get("rows") or [])
    print(f"pull             {status} rows={count} cursor={pulled.get('next_cursor')}")
    if status != 200:
        return 1

    print("OK — the live API answers, authenticates, syncs and scopes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
