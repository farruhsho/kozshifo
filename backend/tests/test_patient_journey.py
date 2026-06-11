"""End-to-end: register patient -> visit -> pay -> queue ticket -> TV board -> KPI.

Plus auth/RBAC guards. This is the executable specification of the core flow.
"""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API, DIRECTOR_EMAIL


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_me_has_superuser_and_permissions(client, auth):
    me = client.get(f"{API}/auth/me", headers=auth).json()
    assert me["email"] == DIRECTOR_EMAIL
    assert me["is_superuser"] is True
    assert "patients.create" in me["permissions"]


def test_protected_endpoint_requires_auth(client):
    assert client.get(f"{API}/patients").status_code == 401


def test_full_patient_journey(client, auth):
    # Branch + service come from the seed.
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    consult = next(s for s in services if s["code"] == "CONS")
    price = Decimal(consult["price"])

    # 1) Register a patient (MRN auto-generated).
    patient = client.post(
        f"{API}/patients",
        headers=auth,
        json={"first_name": "Иван", "last_name": "Петров", "phone": "+998901234567", "branch_id": branch_id},
    ).json()
    assert patient["mrn"].startswith("P-")
    assert patient["full_name"].startswith("Петров")

    # 2) Open a visit with the consultation service.
    visit = client.post(
        f"{API}/visits",
        headers=auth,
        json={
            "patient_id": patient["id"],
            "branch_id": branch_id,
            "items": [{"service_id": consult["id"], "quantity": 1}],
        },
    ).json()
    assert visit["visit_no"].startswith("V-")
    assert Decimal(visit["total_amount"]) == price
    assert Decimal(visit["balance"]) == price
    assert visit["items"][0]["status"] == "ordered"

    # 3) Take full payment -> a queue ticket is issued automatically.
    result = client.post(
        f"{API}/payments",
        headers=auth,
        json={"visit_id": visit["id"], "amount": str(price), "method": "cash", "room": "Каб. 1"},
    )
    assert result.status_code == 201, result.text
    body = result.json()
    assert Decimal(body["visit_balance"]) == Decimal("0.00")
    assert body["payment"]["receipt_no"].startswith("R-")
    ticket_number = body["queue_ticket_number"]
    assert ticket_number and ticket_number.startswith("A-")

    # Item should now be marked paid.
    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert refreshed["items"][0]["status"] == "paid"

    # 4) Ticket is waiting in the queue.
    queue = client.get(f"{API}/queue", headers=auth, params={"branch_id": branch_id}).json()
    assert any(t["ticket_number"] == ticket_number and t["status"] == "waiting" for t in queue)

    # 5) Call it to a room.
    called = client.post(
        f"{API}/queue/call-next", headers=auth, json={"branch_id": branch_id, "room": "Каб. 1"}
    ).json()
    assert called["status"] == "called"
    assert called["room"] == "Каб. 1"

    # 6) TV board shows it under "now serving".
    board = client.get(f"{API}/queue/tv-board/{branch_id}", headers=auth).json()
    assert any(e["ticket_number"] == ticket_number for e in board["now_serving"])

    # 7) Director KPI reflects today's revenue.
    kpi = client.get(f"{API}/dashboard/summary", headers=auth).json()
    assert Decimal(kpi["revenue_today"]) >= price
    assert kpi["patients_total"] >= 1


def test_overpayment_is_rejected(client, auth):
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    svc = services[0]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": "Оплата", "branch_id": branch_id},
    ).json()
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": svc["id"], "quantity": 1}]},
    ).json()
    too_much = str(Decimal(visit["total_amount"]) + Decimal("1.00"))
    resp = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": too_much})
    assert resp.status_code == 422


def test_rbac_doctor_cannot_register_patient(client, auth):
    # Director creates a Doctor-role user; that user lacks patients.create.
    created = client.post(
        f"{API}/users",
        headers=auth,
        json={
            "email": "doctor@kozshifo.uz",
            "full_name": "Доктор Хаус",
            "password": "Doctor!2026",
            "role_names": ["Doctor"],
        },
    )
    assert created.status_code == 201, created.text

    token = client.post(
        f"{API}/auth/login", data={"username": "doctor@kozshifo.uz", "password": "Doctor!2026"}
    ).json()["access_token"]
    doc_auth = {"Authorization": f"Bearer {token}"}

    # Allowed: reading patients.
    assert client.get(f"{API}/patients", headers=doc_auth).status_code == 200
    # Denied: creating a patient (403, missing permission).
    denied = client.post(
        f"{API}/patients", headers=doc_auth, json={"first_name": "X", "last_name": "Y"}
    )
    assert denied.status_code == 403
    assert "patients.create" in denied.json()["detail"]
