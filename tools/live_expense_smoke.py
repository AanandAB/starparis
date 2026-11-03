"""Live probe: open a till, pay a courier from it, close it, then read the VAT CSV."""

import json
import ssl
import urllib.request
from datetime import datetime, timezone

# Windows' Python here ships no CA bundle, so the probe trusts the endpoint
# directly; the Dart smoke tools use the platform store instead.
_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE

API = "https://starparis-api.theblacklightstudio.workers.dev"


def call(path, body=None, token=None, raw=False):
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(
        API + path,
        data=data,
        headers={"content-type": "application/json", "user-agent": "starparis-smoke/1.0", **({"authorization": f"Bearer {token}"} if token else {})},
    )
    with urllib.request.urlopen(request, context=_CTX) as response:
        text = response.read().decode()
        return text if raw else json.loads(text)


login = call(
    "/v1/auth/login",
    {
        "phone": "+971500000001",
        "password": "starparis-demo",
        "device": {"name": "expense probe", "platform": "windows", "app_version": "0.1.0"},
    },
)
token, device = login["access_token"], login["device_id"]
now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def push(mutation_id, entity, row_id, fields, op="insert", base=0):
    body = {
        "device_id": device,
        "mutations": [
            {
                "mutation_id": mutation_id,
                "entity": entity,
                "op": op,
                "row_id": row_id,
                "base_version": base,
                "device_ts": now,
                "fields": fields,
            }
        ],
    }
    result = call("/v1/push", body, token)["results"][0]
    print(f"{entity:14} {result['status']:9} {result.get('error', {}).get('code', '')}")
    return result


push("probe-till-open3", "till_sessions", "018f0000-0000-7000-8000-00000000d001", {"opening_float_fils": 30000})
push(
    "probe-expense-2",
    "expenses",
    "018f0000-0000-7000-8000-00000000d002",
    {"category": "Courier", "description": "Proof delivery to Dubai", "amount_fils": 4500, "method": "cash"},
)
push(
    "probe-till-close3",
    "till_sessions",
    "018f0000-0000-7000-8000-00000000d001",
    {"status": "closed", "counted_fils": 25500},
    op="patch",
    base=1,
)

rows = call("/v1/pull?since=0&limit=900", None, token)["rows"]
till = [row for row in rows if row["entity"] == "till_sessions"][-1]["data"]
print(
    f"till float {till['opening_float_fils']} expected {till['expected_fils']} "
    f"counted {till['counted_fils']} variance {till['variance_fils']}"
)

csv = call("/v1/reports/vat.csv?from=2020-01-01&to=2030-01-01", None, token, raw=True)
print("csv rows:", len(csv.splitlines()))
print("\n".join(csv.splitlines()[-3:]))
