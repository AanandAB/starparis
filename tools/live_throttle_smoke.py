"""Live proof that a counter account locks after eight wrong passwords.

Creates a throwaway user, fails the password eight times, expects the ninth try
to be refused even with the right password, then disables the user again. The
demo owner and counter accounts are never touched, so this is safe to run
against the dev Worker at any time.

    python tools/live_throttle_smoke.py
"""

from __future__ import annotations

import json
import re
import ssl
import urllib.error
import urllib.request
from pathlib import Path

API = "https://starparis-api.theblacklightstudio.workers.dev"
ROOT = Path(__file__).resolve().parent.parent

PHONE = "+971 5 0000 0098"
TEMP_PASSWORD = "throttle-smoke-1"


def password_from_seed() -> str:
    """The demo password lives in the seed script, not in this file."""
    text = (ROOT / "tools" / "seed_demo.py").read_text(encoding="utf-8")
    match = re.search(r"""^PASSWORD\s*=\s*["\']([^"\']+)["\']""", text, re.M)
    if not match:
        raise SystemExit("could not find the demo password in tools/seed_demo.py")
    return match.group(1)


# This machine's Python does not see the Windows certificate store, so the chain
# cannot be verified here. The same calls are covered by the Worker tests; this
# script exists to prove the deployed build behaves, so a failed handshake should
# not stop the probe. It is a dev tool and never ships in the app.
_SSL = ssl.create_default_context()
_SSL.check_hostname = False
_SSL.verify_mode = ssl.CERT_NONE


def call(
    path: str, body: dict | None = None, token: str | None = None, method: str | None = None
) -> tuple[int, dict]:
    data = None if body is None else json.dumps(body).encode()
    verb = method or ("POST" if body else "GET")
    request = urllib.request.Request(API + path, data=data, method=verb)
    # Cloudflare's browser-signature rule rejects the stock Python user agent
    # with error 1010, so the probe introduces itself.
    request.add_header("user-agent", "starparis-smoke/1.0 (+shop management)")
    if data:
        request.add_header("content-type", "application/json")
    if token:
        request.add_header("authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(request, timeout=30, context=_SSL) as response:
            raw = response.read()
            return response.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as error:
        raw = error.read()
        try:
            return error.code, json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            print(f"  {path} -> {error.code}: {raw[:120]!r}")
            return error.code, {}


def main() -> None:
    owner_phone = re.search(
        r"""USER_OWNER,[^
]*?(["']\+[0-9 ]+["'])""",
        (ROOT / "tools" / "seed_demo.py").read_text(encoding="utf-8"),
    )
    if not owner_phone:
        raise SystemExit("could not find the owner phone in tools/seed_demo.py")

    status, body = call(
        "/v1/auth/login",
        {
            "phone": owner_phone.group(1).strip("'\""),
            "password": password_from_seed(),
            "device": {"name": "Throttle smoke", "platform": "windows", "app_version": "0.1.0"},
        },
    )
    if status != 200:
        raise SystemExit(f"owner sign-in failed: {status} {body}")
    token = body["access_token"]

    status, body = call(
        "/v1/staff",
        {"name": "Throttle Smoke", "phone": PHONE, "role": "counter", "password": TEMP_PASSWORD},
        token,
    )
    if status not in (201, 409):
        raise SystemExit(f"could not create the throwaway user: {status} {body}")
    print(f"throwaway user ready ({status})")

    codes = []
    for _ in range(8):
        attempt, _ = call(
            "/v1/auth/login",
            {"phone": PHONE, "password": "wrong-password", "device": {"name": "Smoke", "platform": "windows"}},
        )
        codes.append(attempt)
    print("eight wrong passwords ->", codes)

    locked, body = call(
        "/v1/auth/login",
        {"phone": PHONE, "password": TEMP_PASSWORD, "device": {"name": "Smoke", "platform": "windows"}},
    )
    print(f"ninth try with the RIGHT password -> {locked} {body.get('error', {}).get('code')}")

    if locked != 429:
        raise SystemExit("the account was not locked — the brake is not working")

    # Leave nothing behind that can sign in: disable the throwaway user. The id
    # comes from the staff list rather than the create response, so a second run
    # (which gets 409 instead of 201) still cleans up.
    _, listing = call("/v1/staff", None, token)
    rows = listing.get("results") or listing.get("staff") or listing.get("users") or []
    for row in rows:
        if str(row.get("phone_e164", "")).replace(" ", "").endswith("0098"):
            disabled, _ = call("/v1/staff/" + row["id"], {"active": False}, token, method="PATCH")
            print(f"throwaway user disabled ({disabled})")

    print("OK — the account locks, the shop stays open")


if __name__ == "__main__":
    main()
