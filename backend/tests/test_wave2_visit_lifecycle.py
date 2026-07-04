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


def test_finish_appointment_without_assignment_still_saves_follow_up_date(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "nofu")
    # No plan (registered) -> flow completed, but the doctor may ALWAYS set a
    # recall date; it is saved regardless of terminal flow. finish-appointment does
    # NOT auto-close the visit (late-prescribe contract) -> it stays 'open'; the
    # recall date is still persisted and returned.
    fu = date.today() + timedelta(days=3)
    resp = client.post(
        f"{API}/visits/{v['id']}/finish-appointment", headers=auth,
        json={"follow_up_date": fu.isoformat()},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["flow_status"] == "completed"
    assert resp.json()["follow_up_date"] == fu.isoformat()
    assert resp.json()["status"] == "open"

    # recall still returns it (завязан на follow_up_date, не на статусе визита).
    recall = client.get(f"{API}/visits/recall", headers=auth,
                        params={"due_by": fu.isoformat()})
    assert v["id"] in {e["visit_id"] for e in recall.json()}

    # Reception can close the paid-ahead consultation manually (balance 0 -> 200).
    closed = client.post(f"{API}/visits/{v['id']}/close", headers=auth)
    assert closed.status_code == 200, closed.text
    assert closed.json()["status"] == "completed"


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


# --- (а) full payment -> auto-close -> refund unfreezes the visit --------------

def test_refund_reopens_auto_closed_visit_and_makes_it_editable(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "refund")
    _seed(v["id"], flow_status="follow_up", add_item_total=Decimal("100000.00"))

    pay = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": v["id"], "amount": "100000.00", "issue_queue_ticket": False})
    assert pay.status_code == 201, pay.text
    assert _visit(client, auth, v["id"])["status"] == "completed"
    payment_id = pay.json()["payment"]["id"]

    # Refund re-opens a balance -> the auto-closed visit must thaw back to open.
    ref = client.post(f"{API}/payments/{payment_id}/refund", headers=auth)
    assert ref.status_code == 200, ref.text
    after = _visit(client, auth, v["id"])
    assert after["status"] == "open"
    assert after["closed_at"] is None
    assert Decimal(after["balance"]) == Decimal("100000.00")

    # Editable again: a service line can be added (would 409 on a completed visit).
    add = client.post(f"{API}/visits/{v['id']}/items", headers=auth,
                      json={"service_id": client.get(f"{API}/services", headers=auth)
                            .json()["items"][0]["id"], "quantity": 1})
    assert add.status_code == 200, add.text


# --- (б) prepaid consultation, finish without assignment -> stays OPEN ----------

def test_prepaid_consultation_finish_without_assignment_stays_open(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "prepaid")
    # Paid-ahead consultation (no balance), no assignment -> flow completed, but the
    # visit deliberately stays OPEN: finish-appointment must not auto-close, so the
    # doctor can still add a late referral/prescription (flow._is_locked contract).
    resp = client.post(f"{API}/visits/{v['id']}/finish-appointment", headers=auth, json={})
    assert resp.status_code == 200, resp.text
    assert resp.json()["flow_status"] == "completed"
    assert resp.json()["status"] == "open"

    # A late prescription is still possible (would be 409 on a completed visit).
    op_type = client.get(f"{API}/operation-types", headers=auth).json()[0]
    refer = client.post(f"{API}/visits/{v['id']}/operations", headers=auth,
                        json={"operation_type_id": op_type["id"], "eye": "os"})
    assert refer.status_code == 201, refer.text


# --- (г) recall drops a patient who came back (a newer visit exists) -----------

def test_recall_drops_patient_with_a_newer_visit(client, auth):
    branch = _branch_id(client, auth)
    v1 = _new_visit(client, auth, branch, "came-back")
    fu = date.today() + timedelta(days=5)
    _seed(v1["id"], flow_status="follow_up", follow_up_date=fu)

    # Before returning: recall lists the visit.
    r1 = client.get(f"{API}/visits/recall", headers=auth, params={"due_by": fu.isoformat()})
    assert v1["id"] in {e["visit_id"] for e in r1.json()}

    # Patient comes back — a newer visit for the SAME patient is opened. Bump its
    # opened_at forward so it is unambiguously later than v1 (both are otherwise
    # created within the same clock tick in the test).
    v2 = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": v1["patient_id"], "branch_id": branch, "items": []}).json()
    from app.core.database import SessionLocal
    from app.models.visit import Visit as _V
    from datetime import datetime as _dt, timezone as _tz, timedelta as _td
    db = SessionLocal()
    try:
        db.get(_V, uuid.UUID(v2["id"])).opened_at = _dt.now(_tz.utc) + _td(hours=1)
        db.commit()
    finally:
        db.close()

    # The recall entry «goes dark»: the older visit is no longer the latest.
    r2 = client.get(f"{API}/visits/recall", headers=auth, params={"due_by": fu.isoformat()})
    assert v1["id"] not in {e["visit_id"] for e in r2.json()}


def test_recall_survives_other_branch_and_cancelled_later_visit(client, auth):
    """Recall судит «пациент вернулся» ПО ФИЛИАЛУ и игнорирует отменённые поздние
    визиты: визит в другом филиале и отменённый поздний визит в том же филиале
    НЕ должны гасить recall (defect 2)."""
    branches = client.get(f"{API}/branches", headers=auth).json()
    branch_a = branches[0]["id"]
    # A second branch is needed for the cross-branch case; skip that leg if the
    # seed only has one branch (the core same-branch cancelled case still runs).
    branch_b = branches[1]["id"] if len(branches) > 1 else None

    v1 = _new_visit(client, auth, branch_a, "branch-recall")
    fu = date.today() + timedelta(days=5)
    _seed(v1["id"], flow_status="follow_up", follow_up_date=fu)

    def _in_recall() -> bool:
        r = client.get(f"{API}/visits/recall", headers=auth, params={"due_by": fu.isoformat()})
        return v1["id"] in {e["visit_id"] for e in r.json()}

    assert _in_recall()

    from app.core.database import SessionLocal
    from app.models.visit import Visit as _V
    from datetime import datetime as _dt, timezone as _tz, timedelta as _td

    # (a) A LATER visit for the same patient in ANOTHER branch must NOT dim the
    # recall of branch A (multi-branch isolation).
    if branch_b is not None:
        v_other = client.post(f"{API}/visits", headers=auth, json={
            "patient_id": v1["patient_id"], "branch_id": branch_b, "items": []}).json()
        db = SessionLocal()
        try:
            db.get(_V, uuid.UUID(v_other["id"])).opened_at = _dt.now(_tz.utc) + _td(hours=1)
            db.commit()
        finally:
            db.close()
        assert _in_recall(), "a later visit in another branch must not kill recall"

    # (b) A LATER but CANCELLED visit in the SAME branch must NOT dim recall
    # (a no-show / aborted return is not a real return).
    v_cancel = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": v1["patient_id"], "branch_id": branch_a, "items": []}).json()
    db = SessionLocal()
    try:
        row = db.get(_V, uuid.UUID(v_cancel["id"]))
        row.opened_at = _dt.now(_tz.utc) + _td(hours=2)
        row.status = "cancelled"
        db.commit()
    finally:
        db.close()
    assert _in_recall(), "a later cancelled visit must not kill recall"

    # (c) Sanity: a later OPEN visit in the SAME branch DOES dim it.
    v_real = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": v1["patient_id"], "branch_id": branch_a, "items": []}).json()
    db = SessionLocal()
    try:
        db.get(_V, uuid.UUID(v_real["id"])).opened_at = _dt.now(_tz.utc) + _td(hours=3)
        db.commit()
    finally:
        db.close()
    assert not _in_recall(), "a later live visit in the same branch must dim recall"


# --- (д) manual close with an outstanding balance -> 409 -----------------------

def test_manual_close_with_outstanding_balance_rejected(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "closedebt")
    _seed(v["id"], flow_status="follow_up", add_item_total=Decimal("50000.00"))
    resp = client.post(f"{API}/visits/{v['id']}/close", headers=auth)
    assert resp.status_code == 409, resp.text
    assert "outstanding balance" in resp.json()["detail"]
    assert _visit(client, auth, v["id"])["status"] == "open"


# --- (е) Administrator (front office) may close a visit (RBAC) ------------------

def test_administrator_can_close_visit(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "admclose")
    _seed(v["id"], flow_status="follow_up")
    login = client.post(f"{API}/auth/login",
                        data={"username": "reception@kozshifo.uz", "password": "Reception!2026"})
    assert login.status_code == 200, login.text
    adm = {"Authorization": f"Bearer {login.json()['access_token']}"}
    resp = client.post(f"{API}/visits/{v['id']}/close", headers=adm)
    assert resp.status_code == 200, resp.text
    assert resp.json()["status"] == "completed"


# --- (ж) performed-but-not-financially-closed operation blocks auto-close -------

def test_performed_operation_not_financially_closed_blocks_auto_close(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "perf")
    op_type = client.get(f"{API}/operation-types", headers=auth).json()[0]

    from app.core.database import SessionLocal
    from app.core.flow import close_visit_if_done
    from app.models.operation import Operation
    from app.models.visit import Visit
    db = SessionLocal()
    try:
        row = db.get(Visit, uuid.UUID(v["id"]))
        row.flow_status = "follow_up"
        op = Operation(
            visit_id=row.id, patient_id=row.patient_id,
            operation_type_id=uuid.UUID(op_type["id"]),
            eye="od", status="performed",  # done but financially_closed_at is NULL
        )
        db.add(op)
        db.commit()
        # performed + not financially closed = active work -> no auto-close.
        close_visit_if_done(db, row)
        db.commit()
        assert row.status == "open"
        # Freeze the finances -> now it may close.
        op.financially_closed_at = __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc)
        db.commit()
        close_visit_if_done(db, row)
        db.commit()
        assert row.status == "completed"
    finally:
        db.close()
