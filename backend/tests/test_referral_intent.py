"""Phase-3 two-option registration (owner brief 2026-06-19).

After registration, on full payment reception chooses:
  • «Ожидает назначения» (hold)   → no ticket, flow_status = awaiting_assignment
  • «Направлен к врачу» (doctor)   → doctor ticket minted directly, flow = waiting_doctor
  • default «На диагностику»        → existing D-… diagnostics ticket, flow = waiting_diagnostic
A held patient can later be sent to a doctor via POST /queue/refer-to-doctor.
"""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _setup_visit(client, auth):
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    consult = next(s for s in services if s["code"] == "CONS")
    patient = client.post(f"{API}/patients", headers=auth, json={
        "first_name": "Тест", "last_name": "Назначение", "phone": "+998900000001",
        "branch_id": branch_id,
    }).json()
    visit = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": patient["id"], "branch_id": branch_id,
        "items": [{"service_id": consult["id"], "quantity": 1}],
    }).json()
    return branch_id, visit, Decimal(consult["price"])


def test_hold_then_refer_to_doctor(client, auth):
    branch_id, visit, price = _setup_visit(client, auth)
    res = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": str(price), "method": "cash",
        "referral_intent": "hold",
    })
    assert res.status_code == 201, res.text
    assert res.json()["queue_ticket_number"] is None  # Вариант 1: nothing minted
    v = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert v["flow_status"] == "awaiting_assignment"

    # Reception later assigns the held patient to a doctor.
    referred = client.post(f"{API}/queue/refer-to-doctor", headers=auth,
                           json={"visit_id": visit["id"]})
    assert referred.status_code == 201, referred.text
    assert referred.json()["track"] == "doctor"
    v = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert v["flow_status"] == "waiting_doctor"


def test_refer_to_doctor_at_payment(client, auth):
    branch_id, visit, price = _setup_visit(client, auth)
    res = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": str(price), "method": "cash",
        "referral_intent": "doctor",
    })
    assert res.status_code == 201, res.text
    tn = res.json()["queue_ticket_number"]
    assert tn is not None and not tn.startswith("D-")  # doctor track, not diagnostic
    v = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert v["flow_status"] == "waiting_doctor"
    queue = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch_id, "track": "doctor"}).json()
    assert any(t["ticket_number"] == tn for t in queue)


def test_default_intent_keeps_diagnostic_flow(client, auth):
    _, visit, price = _setup_visit(client, auth)
    res = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": str(price), "method": "cash",
    })  # no referral_intent → diagnostic default (unchanged legacy behaviour)
    assert res.status_code == 201, res.text
    assert res.json()["queue_ticket_number"].startswith("D-")
    v = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert v["flow_status"] == "waiting_diagnostic"
