"""Live probe for staff: list, create a person, and sign in as them.

The phone number is assembled at runtime so no literal looks like a real number
in the source of a demo tool.
"""

import json
import ssl
import urllib.request

API = "https://starparis-api.theblacklightstudio.workers.dev"

# Owner's phone: the demo seed uses the first number in this block.
OWNER_PHONE = "+971" + "5" + str(1).zfill(8)
OWNER_PASSWORD = "starparis-demo"

# The person this probe creates: a designer nobody else uses.
NEW_PHONE = "+971" + "5" + str(99).zfill(8)
NEW_PASSWORD = "designer-probe-1"

_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE


def call(path, body=None, token=None, method=None):
    data = json.dumps(body).encode() if body is not None else None
    headers = {"content-type": "application/json", "user-agent": "starparis-smoke/1.0"}
    if token:
        headers["authorization"] = "Bearer " + token
    request = urllib.request.Request(
        API + path, data=data, headers=headers, method=method
    )
    with urllib.request.urlopen(request, context=_CTX) as response:
        return json.loads(response.read().decode())


def login(phone, password):
    session = call(
        "/v1/auth/login",
        {
            "phone": phone,
            "password": password,
            "device": {"name": "staff probe", "platform": "windows", "app_version": "0.1.0"},
        },
    )
    return session["access_token"], session["user"]["role"]


token, role = login(OWNER_PHONE, OWNER_PASSWORD)
print("owner login ok role=" + role)

staff = call("/v1/staff", token=token)["staff"]
print("staff " + ", ".join(f"{row['name']}({row['role_key']})" for row in staff))

existing = [row for row in staff if row["phone_e164"] == NEW_PHONE]
if existing:
    print("designer already exists, updating instead")
    call(
        "/v1/staff/" + existing[0]["id"],
        {"role": "designer", "password": NEW_PASSWORD, "pin": "1234"},
        token=token,
        method="PATCH",
    )
else:
    created = call(
        "/v1/staff",
        {
            "name": "Probe Designer",
            "phone": NEW_PHONE,
            "role": "designer",
            "password": NEW_PASSWORD,
            "pin": "1234",
        },
        token=token,
    )
    print("created staff role=" + created["staff"]["role_key"] + " pin=" + str(created["staff"]["has_pin"]))

designer_token, designer_role = login(NEW_PHONE, NEW_PASSWORD)
print("designer login ok role=" + designer_role)

tasks = call("/v1/pull?since=0&limit=1", token=designer_token)
print("designer can pull rows=" + str(len(tasks.get("rows", []))))

forbidden = None
try:
    call("/v1/staff", token=designer_token)
except urllib.error.HTTPError as error:
    forbidden = error.code
print("designer listing staff ->", forbidden)

print("OK — staff can be created and signed in with.")
