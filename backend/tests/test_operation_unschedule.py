"""Phase 5: detach a scheduled operation back to the referred pool (force-majeure)
— de-bills the visit, keeps the operation referable for another day."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API

_SCHED = "2026-07-01T09:00:00+00:00"
_SCHED2 = "2026-07-05T10:00:00+00:00"


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _op_type(client, auth, code) -> dict:
    return next(t for t in client.get(f"{API}/operation-types", headers=auth).json() if t["code"] == code)


def _visit(client, auth, branch, last_name) -> str:
    p = client.post(f"{API}/patients", headers=auth,
                    json={"first_name": "Откреп", "last_name": last_name, "branch_id": branch}).json()
    return client.post(f"{API}/visits", headers=auth,
                       json={"patient_id": p["id"], "branch_id": branch}).json()["id"]


def _refer_and_schedule(client, auth, branch, last_name, code="PHACO") -> tuple[str, str]:
    visit_id = _visit(client, auth, branch, last_name)
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": _op_type(client, auth, code)["id"]}).json()
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": _SCHED}).status_code == 200
    return visit_id, op["id"]


def _total(client, auth, visit_id) -> Decimal:
    return Decimal(client.get(f"{API}/visits/{visit_id}", headers=auth).json()["total_amount"])


def test_unschedule_detaches_to_pool_and_debills(client, auth):
    branch = _branch(client, auth)
    visit_id, op_id = _refer_and_schedule(client, auth, branch, "Пул")
    assert _total(client, auth, visit_id) == Decimal("5000000.00")

    detached = client.post(f"{API}/operations/{op_id}/unschedule", headers=auth)
    assert detached.status_code == 200, detached.text
    assert detached.json()["status"] == "referred"
    assert detached.json()["scheduled_at"] is None
    assert _total(client, auth, visit_id) == Decimal("0.00")  # de-billed

    # It's back in the referred pool…
    referred = client.get(f"{API}/operations", headers=auth, params={"status": "referred"}).json()
    assert op_id in [o["id"] for o in referred]

    # …and can be re-scheduled to another day (re-bills).
    again = client.post(f"{API}/operations/{op_id}/schedule", headers=auth,
                        json={"scheduled_at": _SCHED2})
    assert again.status_code == 200, again.text
    assert again.json()["status"] == "scheduled"
    assert _total(client, auth, visit_id) == Decimal("5000000.00")


def test_unschedule_referred_is_409(client, auth):
    branch = _branch(client, auth)
    visit_id = _visit(client, auth, branch, "Голый")
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": _op_type(client, auth, "IVI")["id"]}).json()
    # A bare referral was never scheduled → nothing to detach.
    resp = client.post(f"{API}/operations/{op['id']}/unschedule", headers=auth)
    assert resp.status_code == 409


def test_unschedule_paid_requires_refund_first(client, auth):
    branch = _branch(client, auth)
    visit_id, op_id = _refer_and_schedule(client, auth, branch, "Оплачен")
    visit = client.get(f"{API}/visits/{visit_id}", headers=auth).json()
    client.post(f"{API}/payments", headers=auth,
                json={"visit_id": visit_id, "amount": visit["balance"], "issue_queue_ticket": False})
    denied = client.post(f"{API}/operations/{op_id}/unschedule", headers=auth)
    assert denied.status_code == 409
    assert "refund" in denied.json()["detail"].lower()
