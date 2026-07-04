"""Finish-appointment by VISIT (owner brief 2026-06-20): the doctor closes the
appointment off the visit, not off an active queue ticket — the «Нет активного
талона» blocker is gone. If a doctor ticket happens to be active it's closed too
(leaves the TV board); its absence never blocks."""
from __future__ import annotations

import uuid

from sqlalchemy import select

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _open_visit(client, auth, branch: str, suffix: str) -> dict:
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Приём", "last_name": f"Тестов-{suffix}",
              "phone": "+998900000003", "branch_id": branch},
    ).json()
    return client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch, "items": []},
    ).json()


def test_finish_without_active_ticket_advances_flow(client, auth):
    branch = _branch_id(client, auth)
    v = _open_visit(client, auth, branch, "noticket")
    # The OLD client errored «Нет активного талона» here; now it just works.
    resp = client.post(f"{API}/visits/{v['id']}/finish-appointment", headers=auth)
    assert resp.status_code == 200, resp.text
    # Flow advanced off the visit (registered + no plan → completed).
    listed = client.get(f"{API}/visits", headers=auth,
                        params={"flow_status": "completed,follow_up"})
    assert v["id"] in {r["id"] for r in listed.json()["items"]}
    # finish-appointment MUST NOT auto-close the visit: the doctor may still add a
    # late referral/prescription after marking the ticket done (see
    # flow._is_locked). The billing status stays 'open'; reception closes it.
    assert resp.json()["status"] == "open"


def test_finish_without_assignment_lets_doctor_refer_late_then_close(client, auth):
    """Регрессия контракта late-prescribe: голая консультация (finish без
    назначений) остаётся open → врач может ПОСЛЕ этого направить на операцию
    (не 409), а ресепшен затем закрывает визит вручную."""
    branch = _branch_id(client, auth)
    v = _open_visit(client, auth, branch, "late-refer")

    fin = client.post(f"{API}/visits/{v['id']}/finish-appointment", headers=auth, json={})
    assert fin.status_code == 200, fin.text
    assert fin.json()["flow_status"] == "completed"
    assert fin.json()["status"] == "open"  # NOT auto-closed

    # Doctor dictates a late referral — would 409 «Cannot refer on a completed
    # visit» if finish had auto-closed the visit.
    op_type = client.get(f"{API}/operation-types", headers=auth).json()[0]
    refer = client.post(
        f"{API}/visits/{v['id']}/operations", headers=auth,
        json={"operation_type_id": op_type["id"], "eye": "od"},
    )
    assert refer.status_code == 201, refer.text

    # Cancel the referral so nothing blocks, then reception closes manually
    # (no balance → 200).
    assert client.post(f"{API}/operations/{refer.json()['id']}/cancel",
                       headers=auth).status_code == 200
    closed = client.post(f"{API}/visits/{v['id']}/close", headers=auth)
    assert closed.status_code == 200, closed.text
    assert closed.json()["status"] == "completed"


def test_finish_closes_active_doctor_ticket(client, auth):
    branch = _branch_id(client, auth)
    v = _open_visit(client, auth, branch, "ticket")

    from app.core.database import SessionLocal
    from app.models.queue import QueueTicket
    db = SessionLocal()
    try:
        db.add(QueueTicket(
            ticket_number="FIN-С-1", track="doctor", status="called",
            patient_id=uuid.UUID(v["patient_id"]),
            branch_id=uuid.UUID(branch), visit_id=uuid.UUID(v["id"]),
        ))
        db.commit()
    finally:
        db.close()

    assert client.post(f"{API}/visits/{v['id']}/finish-appointment",
                       headers=auth).status_code == 200

    db = SessionLocal()
    try:
        ticket = db.execute(
            select(QueueTicket).where(QueueTicket.visit_id == uuid.UUID(v["id"]))
        ).scalars().first()
        assert ticket.status == "done"
        assert ticket.done_at is not None
    finally:
        db.close()


def test_finish_on_closed_visit_409(client, auth):
    branch = _branch_id(client, auth)
    v = _open_visit(client, auth, branch, "closed")
    assert client.post(f"{API}/visits/{v['id']}/close", headers=auth).status_code == 200
    r = client.post(f"{API}/visits/{v['id']}/finish-appointment", headers=auth)
    assert r.status_code == 409


def test_finish_appointment_rbac(client, auth):
    # A roleless user has no permissions → 403 (before any 404).
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "finish.wh@kozshifo.uz", "full_name": "Склад Приём",
              "password": "Wh!2026fin", "role_names": []},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "finish.wh@kozshifo.uz", "password": "Wh!2026fin"},
    ).json()["access_token"]
    denied = client.post(f"{API}/visits/{uuid.uuid4()}/finish-appointment",
                         headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
