"""Reception abort path + queue state-machine guarantees (Epic-3 review fixes)."""
from __future__ import annotations

from tests.conftest import API


def _make_visit(client, auth, *, last_name, pay=False):
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": last_name, "branch_id": branch_id},
    ).json()
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": services[0]["id"], "quantity": 1}]},
    ).json()
    if pay:
        client.post(f"{API}/payments", headers=auth,
                    json={"visit_id": visit["id"], "amount": visit["balance"]})
    return branch_id, visit


def test_cancel_unpaid_visit(client, auth):
    _, visit = _make_visit(client, auth, last_name="Отмена")
    resp = client.post(f"{API}/visits/{visit['id']}/cancel", headers=auth)
    assert resp.status_code == 200, resp.text
    assert resp.json()["status"] == "cancelled"
    # Idempotence guard: a cancelled visit cannot be cancelled again or paid.
    assert client.post(f"{API}/visits/{visit['id']}/cancel", headers=auth).status_code == 409
    pay = client.post(f"{API}/payments", headers=auth,
                      json={"visit_id": visit["id"], "amount": "1.00"})
    assert pay.status_code == 409


def test_cancel_paid_visit_rejected(client, auth):
    _, visit = _make_visit(client, auth, last_name="Оплачен", pay=True)
    resp = client.post(f"{API}/visits/{visit['id']}/cancel", headers=auth)
    assert resp.status_code == 409
    assert "refund" in resp.json()["detail"].lower()


def test_queue_state_machine_enforced(client, auth):
    branch_id, visit = _make_visit(client, auth, last_name="Машина", pay=True)
    queue = client.get(f"{API}/queue", headers=auth, params={"branch_id": branch_id}).json()
    ticket = next(t for t in queue if t["visit_id"] == visit["id"])

    # waiting -> serving is forbidden (must be called first).
    assert client.post(f"{API}/queue/{ticket['id']}/serve", headers=auth).status_code == 409

    called = client.post(f"{API}/queue/call-next", headers=auth,
                         json={"branch_id": branch_id, "room": "Каб. 9"}).json()
    done = client.post(f"{API}/queue/{called['id']}/done", headers=auth)
    assert done.status_code == 200  # called -> done is the allowed shortcut

    # A finished ticket cannot be resurrected or re-completed.
    assert client.post(f"{API}/queue/{called['id']}/serve", headers=auth).status_code == 409
    assert client.post(f"{API}/queue/{called['id']}/done", headers=auth).status_code == 409
    assert client.post(f"{API}/queue/{called['id']}/skip", headers=auth).status_code == 409
