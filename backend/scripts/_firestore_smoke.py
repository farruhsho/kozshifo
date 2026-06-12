"""Smoke-test: write/read test data in Firestore (project kozshifo-32e6f).

Proves the Firebase project + Firestore are alive. The clinic app itself
talks to our FastAPI backend, NOT Firestore — this is a connectivity check.
"""
from __future__ import annotations

import os
import subprocess
import sys

import httpx

PROJECT = "kozshifo-32e6f"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
GCLOUD = os.path.expandvars(
    r"%LOCALAPPDATA%\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd")


def token() -> str:
    return subprocess.run([GCLOUD, "auth", "print-access-token"],
                          capture_output=True, text=True, check=True).stdout.strip()


def s(v: str) -> dict:
    return {"stringValue": v}


def main() -> int:
    c = httpx.Client(headers={"Authorization": f"Bearer {token()}"}, timeout=30)

    docs = [
        ("smoke_test", "status", {
            "platform": s("KO'Z SHIFO Medical ERP"),
            "checked_by": s("Claude (orchestrator)"),
            "note": s("Firebase/Firestore связь работает. Боевые данные живут в "
                      "PostgreSQL за нашим API — это только смоук-тест."),
        }),
        ("test_patients", "P-TEST-001", {
            "mrn": s("P-TEST-001"), "last_name": s("Алимов"), "first_name": s("Бек"),
            "phone": s("+998901112233"), "flow_status": s("waiting_diagnostic"),
        }),
        ("test_patients", "P-TEST-002", {
            "mrn": s("P-TEST-002"), "last_name": s("Каримова"), "first_name": s("Дилноза"),
            "phone": s("+998907775566"), "flow_status": s("in_doctor"),
        }),
        ("test_branches", "MAIN", {
            "name": s("Главный филиал"), "code": s("MAIN"), "city": s("Toshkent"),
        }),
    ]

    for collection, doc_id, fields in docs:
        r = c.patch(f"{BASE}/{collection}/{doc_id}", json={"fields": fields})
        assert r.status_code == 200, f"{collection}/{doc_id}: {r.status_code} {r.text}"
        print(f"[w] {collection}/{doc_id} OK")

    for collection in ("smoke_test", "test_patients", "test_branches"):
        r = c.get(f"{BASE}/{collection}")
        got = [d["name"].split("/")[-1] for d in r.json().get("documents", [])]
        print(f"[r] {collection}: {got}")

    print("Firestore smoke-test: PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
