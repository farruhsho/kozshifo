"""Phase-6 backend: cancelling a visit auto-cancels its not-yet-performed
operations (the slot frees up); diagnostic records capture the diagnostician
name + the room (cabinet)."""
from __future__ import annotations

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _op_type(client, auth, code):
    types = client.get(f"{API}/operation-types", headers=auth).json()
    return next(t for t in types if t["code"] == code)


def _new_visit(client, auth, branch):
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    cons = next(s for s in services if s["code"] == "CONS")
    patient = client.post(f"{API}/patients", headers=auth, json={
        "first_name": "Фаза6", "last_name": "Тестов", "branch_id": branch,
    }).json()
    return client.post(f"{API}/visits", headers=auth, json={
        "patient_id": patient["id"], "branch_id": branch,
        "items": [{"service_id": cons["id"], "quantity": 1}],
    }).json()


def test_cancel_visit_cancels_open_operations(client, auth):
    branch = _branch(client, auth)
    visit = _new_visit(client, auth, branch)
    phaco = _op_type(client, auth, "PHACO")
    client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                json={"operation_type_id": phaco["id"]})  # referral, not billed
    cancelled = client.post(f"{API}/visits/{visit['id']}/cancel", headers=auth)
    assert cancelled.status_code == 200, cancelled.text
    ops = client.get(f"{API}/visits/{visit['id']}/operations", headers=auth).json()
    assert ops and ops[0]["status"] == "cancelled"


def test_diagnostic_conclusion_records_doctor_and_cabinet(client, auth):
    branch = _branch(client, auth)
    visit = _new_visit(client, auth, branch)
    resp = client.post(f"{API}/visits/{visit['id']}/diagnostic-conclusion",
                       headers=auth, json={"diagnosis": "УЗИ: без патологии"})
    assert resp.status_code in (200, 201), resp.text
    body = resp.json()
    assert "cabinet" in body          # room field exposed (None for the owner)
    assert body["doctor_name"]        # the recorder's name is populated
