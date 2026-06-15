"""Smart Search (one global endpoint, RBAC-gated sections) + doctor favorites.

Builds one searchable bundle (patient with unique name/MRN/phone -> visit ->
full payment WITHOUT a queue ticket, so the queue tests are not disturbed),
then asserts each search section, the min-length guard, per-role section
visibility and the per-doctor frequent-diagnoses list.
"""
from __future__ import annotations

import pytest

from tests.conftest import API

_PASSWORD = "Sr!2026aa"


def _make_user(client, auth: dict, email: str, role: str) -> dict:
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": f"Search {role}",
              "password": _PASSWORD, "role_names": [role]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login", data={"username": email, "password": _PASSWORD}
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(scope="module")
def seeded(client, director_token) -> dict:
    """Patient + paid visit + receipt with unique searchable values."""
    auth = {"Authorization": f"Bearer {director_token}"}
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]

    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Глобал", "last_name": "Поисков",
              "phone": "+998771234567", "mrn": "SRCH-000777",
              "branch_id": branch_id},
    )
    assert patient.status_code == 201, patient.text
    patient = patient.json()

    services = client.get(f"{API}/services", headers=auth).json()["items"]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": services[0]["id"], "quantity": 1}]},
    )
    assert visit.status_code == 201, visit.text
    visit = visit.json()

    # No queue ticket: the session DB is shared with the queue tests — a stray
    # waiting ticket would hijack their call-next.
    paid = client.post(
        f"{API}/payments", headers=auth,
        json={"visit_id": visit["id"], "amount": visit["balance"],
              "issue_queue_ticket": False},
    )
    assert paid.status_code == 201, paid.text

    return {
        "auth": auth,
        "branch_id": branch_id,
        "service_id": services[0]["id"],
        "patient": patient,
        "visit": visit,
        "receipt": paid.json()["payment"],
    }


def test_search_finds_patient_by_name_mrn_and_spaced_phone(client, auth, seeded):
    pid = seeded["patient"]["id"]

    by_name = client.get(f"{API}/search", headers=auth, params={"q": "Поиск"})
    assert by_name.status_code == 200, by_name.text
    assert pid in [p["id"] for p in by_name.json()["patients"]]

    by_mrn = client.get(f"{API}/search", headers=auth, params={"q": "RCH-0007"})
    assert by_mrn.status_code == 200, by_mrn.text
    found = [p for p in by_mrn.json()["patients"] if p["id"] == pid]
    assert found, by_mrn.text
    assert found[0]["mrn"] == "SRCH-000777"
    assert found[0]["full_name"] == "Поисков Глобал"
    assert found[0]["phone"] == "+998771234567"

    # Typed WITH spaces — must still find the normalized stored phone.
    by_phone = client.get(f"{API}/search", headers=auth, params={"q": "+998 77 123"})
    assert by_phone.status_code == 200, by_phone.text
    assert pid in [p["id"] for p in by_phone.json()["patients"]]


def test_search_finds_visit_and_receipt_by_number_fragment(client, auth, seeded):
    visit, receipt = seeded["visit"], seeded["receipt"]

    vfrag = visit["visit_no"][2:]  # drop the "V-" prefix, keep the unique tail
    res = client.get(f"{API}/search", headers=auth, params={"q": vfrag})
    assert res.status_code == 200, res.text
    mine = next(v for v in res.json()["visits"] if v["id"] == visit["id"])
    assert mine["visit_no"] == visit["visit_no"]
    assert mine["patient_id"] == seeded["patient"]["id"]
    assert mine["patient_name"] == "Поисков Глобал"
    assert mine["flow_status"]
    assert mine["status"]

    rfrag = receipt["receipt_no"][2:]
    res = client.get(f"{API}/search", headers=auth, params={"q": rfrag})
    assert res.status_code == 200, res.text
    rec = next(r for r in res.json()["receipts"] if r["payment_id"] == receipt["id"])
    assert rec["receipt_no"] == receipt["receipt_no"]
    assert rec["amount"] == receipt["amount"]  # decimal string, e.g. "150000.00"
    assert rec["visit_id"] == visit["id"]
    assert rec["patient_id"] == seeded["patient"]["id"]


def test_search_query_min_length(client, auth):
    resp = client.get(f"{API}/search", headers=auth, params={"q": "a"})
    assert resp.status_code == 422


def test_search_rbac_sections(client, auth, seeded):
    # Doctor: patients.read + visits.read, NO payments.read — the receipts
    # section must be empty even when the query matches a receipt number.
    doctor = _make_user(client, auth, "search.doctor@kozshifo.uz", "Doctor")
    rfrag = seeded["receipt"]["receipt_no"][2:]
    res = client.get(f"{API}/search", headers=doctor, params={"q": rfrag})
    assert res.status_code == 200, res.text
    assert res.json()["receipts"] == []

    vfrag = seeded["visit"]["visit_no"][2:]
    res = client.get(f"{API}/search", headers=doctor, params={"q": vfrag})
    assert seeded["visit"]["id"] in [v["id"] for v in res.json()["visits"]]
    res = client.get(f"{API}/search", headers=doctor, params={"q": "Поиск"})
    assert seeded["patient"]["id"] in [p["id"] for p in res.json()["patients"]]

    # Cashier: patients.read + visits.read + payments.read — sees receipts.
    cashier = _make_user(client, auth, "search.cashier@kozshifo.uz", "Cashier")
    res = client.get(f"{API}/search", headers=cashier, params={"q": rfrag})
    assert res.status_code == 200, res.text
    assert seeded["receipt"]["id"] in [r["payment_id"] for r in res.json()["receipts"]]

    # Warehouse: no patients.read — the base gate denies the whole search.
    warehouse = _make_user(client, auth, "search.sklad@kozshifo.uz", "Warehouse")
    denied = client.get(f"{API}/search", headers=warehouse, params={"q": "Поиск"})
    assert denied.status_code == 403
    assert "patients.read" in denied.json()["detail"]


def test_frequent_diagnoses_are_per_doctor(client, auth, seeded):
    # Dedicated doctor users: the director already authored exams in other test
    # files (shared session DB), so their list would not be deterministic.
    doctor = _make_user(client, auth, "freq.doctor@kozshifo.uz", "Doctor")
    other = _make_user(client, auth, "freq.other@kozshifo.uz", "Doctor")

    def _new_visit_id() -> str:
        v = client.post(
            f"{API}/visits", headers=auth,
            json={"patient_id": seeded["patient"]["id"],
                  "branch_id": seeded["branch_id"],
                  "items": [{"service_id": seeded["service_id"], "quantity": 1}]},
        )
        assert v.status_code == 201, v.text
        return v.json()["id"]

    # Diagnoses now accumulate as their own rows (TZ §7.1.5); the frequent list
    # aggregates VisitDiagnosis rows authored by the current doctor.
    for diagnosis in ("Миопия", "Миопия", "Катаракта"):
        resp = client.post(
            f"{API}/visits/{_new_visit_id()}/diagnoses", headers=doctor,
            json={"diagnosis": diagnosis},
        )
        assert resp.status_code == 201, resp.text
    # A visit with an exam but no diagnosis must not pollute the list.
    blank = client.put(f"{API}/visits/{_new_visit_id()}/exam", headers=doctor,
                       json={"complaints": "без диагноза"})
    assert blank.status_code == 200, blank.text

    top = client.get(f"{API}/exams/frequent-diagnoses", headers=doctor)
    assert top.status_code == 200, top.text
    assert top.json() == [
        {"diagnosis": "Миопия", "count": 2},
        {"diagnosis": "Катаракта", "count": 1},
    ]

    # Favorites are personal: a second doctor sees an empty list.
    empty = client.get(f"{API}/exams/frequent-diagnoses", headers=other)
    assert empty.status_code == 200, empty.text
    assert empty.json() == []
