"""Wave 2: visit lifecycle — follow_up_date (recall), recall endpoint, and the
auto-close helper (close_visit_if_done).

flow_status / billing are engine-driven; the setups seed them via a direct DB
session (mirroring test_hanging_visits), and each test asserts on its OWN visit
id so the shared session DB never makes assertions flaky.
"""
from __future__ import annotations

import uuid
from datetime import date, timedelta
from decimal import Decimal

from sqlalchemy import select

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _new_visit(client, auth, branch_id: str, suffix: str) -> dict:
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Ресолл", "last_name": f"Тестов-{suffix}",
              "phone": "+998900000009", "branch_id": branch_id},
    ).json()
    return client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "items": []},
    ).json()


def _seed(visit_id: str, *, flow_status: str | None = None,
          status: str | None = None, follow_up_date: date | None = None,
          add_item_total: Decimal | None = None):
    """Directly set flow_status / status / follow_up_date and optionally add a
    billed line (creating a payable balance)."""
    from app.core.database import SessionLocal
    from app.models.catalog import Service
    from app.models.visit import Visit, VisitItem
    db = SessionLocal()
    try:
        row = db.get(Visit, uuid.UUID(visit_id))
        if flow_status is not None:
            row.flow_status = flow_status
        if status is not None:
            row.status = status
        if follow_up_date is not None:
            row.follow_up_date = follow_up_date
        if add_item_total is not None:
            service = db.execute(select(Service).limit(1)).scalars().first()
            row.items.append(VisitItem(
                service_id=service.id, service_name=service.name,
                unit_price=add_item_total, quantity=1, total=add_item_total,
            ))
            row.total_amount = sum((Decimal(i.total) for i in row.items), Decimal("0.00"))
        db.commit()
    finally:
        db.close()


def _visit(client, auth, visit_id: str) -> dict:
    return client.get(f"{API}/visits/{visit_id}", headers=auth).json()


# --- (а) follow_up_date + recall endpoint --------------------------------------

def test_finish_appointment_saves_follow_up_date_and_recall_returns_it(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "recall")
    # Something must be assigned for the appointment to end in follow_up (else it
    # goes straight to completed and no recall date is kept).
    _seed(v["id"], flow_status="treatment_assigned")

    fu = date.today() + timedelta(days=7)
    resp = client.post(
        f"{API}/visits/{v['id']}/finish-appointment", headers=auth,
        json={"follow_up_date": fu.isoformat()},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["flow_status"] == "follow_up"
    assert resp.json()["follow_up_date"] == fu.isoformat()

    # recall with due_by >= the date returns it.
    recall = client.get(f"{API}/visits/recall", headers=auth,
                        params={"due_by": fu.isoformat()})
    assert recall.status_code == 200, recall.text
    entry = next((e for e in recall.json() if e["visit_id"] == v["id"]), None)
    assert entry is not None
    assert entry["follow_up_date"] == fu.isoformat()
    assert entry["patient_id"] == v["patient_id"]

    # recall with due_by < the date does NOT return it.
    before = (fu - timedelta(days=1)).isoformat()
    recall2 = client.get(f"{API}/visits/recall", headers=auth, params={"due_by": before})
    assert v["id"] not in {e["visit_id"] for e in recall2.json()}


def test_finish_appointment_without_assignment_keeps_no_follow_up_date(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "nofu")
    # No plan (registered) -> completed, follow_up_date ignored.
    resp = client.post(
        f"{API}/visits/{v['id']}/finish-appointment", headers=auth,
        json={"follow_up_date": (date.today() + timedelta(days=3)).isoformat()},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["flow_status"] == "completed"
    assert resp.json()["follow_up_date"] is None


# --- (б) auto-close on full payment of a terminal (follow_up) visit -------------

def test_follow_up_visit_with_debt_not_closed_then_closed_on_full_payment(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "debt")
    _seed(v["id"], flow_status="follow_up", add_item_total=Decimal("100000.00"))

    # With an outstanding balance the visit is NOT auto-closed.
    before = _visit(client, auth, v["id"])
    assert before["status"] == "open"
    assert Decimal(before["balance"]) == Decimal("100000.00")

    # Partial payment leaves a balance -> still open.
    r1 = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": v["id"], "amount": "40000.00", "issue_queue_ticket": False})
    assert r1.status_code == 201, r1.text
    assert _visit(client, auth, v["id"])["status"] == "open"

    # Settling to zero auto-closes the visit.
    r2 = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": v["id"], "amount": "60000.00", "issue_queue_ticket": False})
    assert r2.status_code == 201, r2.text
    closed = _visit(client, auth, v["id"])
    assert closed["status"] == "completed"
    assert Decimal(closed["balance"]) <= Decimal("0.00")


# --- (в) an open operation blocks auto-close -----------------------------------

def test_visit_with_open_operation_not_closed_until_operation_done(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "op")

    op_type = client.get(f"{API}/operation-types", headers=auth).json()[0]

    from app.core.database import SessionLocal
    from app.models.operation import Operation
    from app.models.visit import Visit
    db = SessionLocal()
    try:
        row = db.get(Visit, uuid.UUID(v["id"]))
        row.flow_status = "follow_up"
        op = Operation(
            visit_id=row.id, patient_id=row.patient_id,
            operation_type_id=uuid.UUID(op_type["id"]),
            eye="od", status="referred",
        )
        db.add(op)
        db.commit()
        op_id = str(op.id)
    finally:
        db.close()

    # An open operation (referred) must keep the visit open even with no debt.
    from app.core.database import SessionLocal as SL
    from app.core.flow import close_visit_if_done
    from app.models.visit import Visit as V
    db = SL()
    try:
        row = db.get(V, uuid.UUID(v["id"]))
        close_visit_if_done(db, row)
        db.commit()
        assert row.status == "open"
    finally:
        db.close()

    # Cancel the operation, then the helper closes the visit (nothing pending).
    assert client.post(f"{API}/operations/{op_id}/cancel", headers=auth).status_code == 200
    db = SL()
    try:
        row = db.get(V, uuid.UUID(v["id"]))
        close_visit_if_done(db, row)
        db.commit()
        assert row.status == "completed"
    finally:
        db.close()
