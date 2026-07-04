"""Hanging-visit detection (owner brief 2026-06-20): GET /dashboard/hanging-visits
returns the actual stuck visits in five categories, with per-state freshness
thresholds. flow_status is engine-driven, so the setups backdate / set it via a
direct DB session (no API can — nor should — write flow_status), mirroring
test_insights' stale-visit approach. Each test asserts on its OWN visit id, so
the shared session DB / leftover rows never make assertions flaky."""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _new_visit(client, auth, branch_id: str, suffix: str) -> dict:
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Завис", "last_name": f"Тестов-{suffix}",
              "phone": "+998900000001", "branch_id": branch_id},
    ).json()
    return client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "items": []},
    ).json()


def _hanging(client, auth) -> list[dict]:
    resp = client.get(f"{API}/dashboard/hanging-visits", headers=auth)
    assert resp.status_code == 200, resp.text
    return resp.json()


def _cat(data: list[dict], category: str) -> dict | None:
    return next((c for c in data if c["category"] == category), None)


def _visit_ids(cat: dict | None) -> set[str]:
    return {v["visit_id"] for v in cat["visits"]} if cat else set()


def _tweak_visit(visit_id: str, *, flow_status: str | None = None,
                 opened_hours_ago: float | None = None) -> None:
    from app.core.database import SessionLocal
    from app.models.visit import Visit
    db = SessionLocal()
    try:
        row = db.get(Visit, uuid.UUID(visit_id))
        if flow_status is not None:
            row.flow_status = flow_status
        if opened_hours_ago is not None:
            row.opened_at = datetime.now(timezone.utc) - timedelta(hours=opened_hours_ago)
        db.commit()
    finally:
        db.close()


def test_cat1_registered_not_reached_doctor(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "nodoc")["id"]

    # Fresh registered visit (<4h) is normal — not yet hanging.
    _tweak_visit(v, flow_status="registered", opened_hours_ago=1)
    assert v not in _visit_ids(_cat(_hanging(client, auth), "no_doctor"))

    # Stale (>4h) and never reached a doctor → critical hanging case.
    _tweak_visit(v, flow_status="registered", opened_hours_ago=6)
    cat = _cat(_hanging(client, auth), "no_doctor")
    assert cat is not None and v in _visit_ids(cat)
    assert cat["severity"] == "critical"


def test_cat2_at_doctor_not_finished(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "indoc")["id"]

    _tweak_visit(v, flow_status="in_doctor", opened_hours_ago=1)  # fresh → no
    assert v not in _visit_ids(_cat(_hanging(client, auth), "in_doctor"))

    _tweak_visit(v, flow_status="in_doctor", opened_hours_ago=5)  # stale → yes
    cat = _cat(_hanging(client, auth), "in_doctor")
    assert cat is not None and v in _visit_ids(cat)


def test_cat3_diagnostic_without_result(client, auth):
    branch = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch, "diag")
    v = visit["id"]

    # A completed diagnostic ticket with NO attached result file = stuck.
    from app.core.database import SessionLocal
    from app.models.queue import QueueTicket
    db = SessionLocal()
    try:
        db.add(QueueTicket(
            ticket_number="HANG-D-1", track="diagnostic", status="done",
            patient_id=uuid.UUID(visit["patient_id"]),
            branch_id=uuid.UUID(branch), visit_id=uuid.UUID(v),
        ))
        db.commit()
    finally:
        db.close()

    cat = _cat(_hanging(client, auth), "diag_no_result")
    assert cat is not None and v in _visit_ids(cat)


def test_cat4_operation_not_closed(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "op")["id"]
    ivi = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
               if t["code"] == "IVI")
    op = client.post(f"{API}/visits/{v}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"], "eye": "od"}).json()
    # Schedule for a FUTURE date → not hanging. (Dynamic — a fixed date would
    # rot into the past and turn this into a hanging op.)
    future = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": future}).status_code == 200
    assert v not in _visit_ids(_cat(_hanging(client, auth), "op_not_closed"))

    # Backdate the scheduled date to the past → a no-show/forgotten surgery.
    from app.core.database import SessionLocal
    from app.models.operation import Operation
    db = SessionLocal()
    try:
        row = db.get(Operation, uuid.UUID(op["id"]))
        row.scheduled_at = datetime.now(timezone.utc) - timedelta(days=1)
        db.commit()
    finally:
        db.close()

    cat = _cat(_hanging(client, auth), "op_not_closed")
    assert cat is not None and v in _visit_ids(cat)


def _tweak_operation(op_id: str, *, status: str | None = None,
                     created_hours_ago: float | None = None,
                     performed_hours_ago: float | None = None) -> None:
    from app.core.database import SessionLocal
    from app.models.operation import Operation
    db = SessionLocal()
    try:
        row = db.get(Operation, uuid.UUID(op_id))
        now = datetime.now(timezone.utc)
        if status is not None:
            row.status = status
        if created_hours_ago is not None:
            row.created_at = now - timedelta(hours=created_hours_ago)
        if performed_hours_ago is not None:
            row.performed_at = now - timedelta(hours=performed_hours_ago)
        db.commit()
    finally:
        db.close()


def _refer_operation(client, auth, visit_id: str) -> str:
    ivi = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
               if t["code"] == "IVI")
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"], "eye": "od"})
    assert op.status_code == 201, op.text
    return op.json()["id"]


def test_cat4_referral_not_scheduled_over_24h(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "refstale")["id"]
    op = _refer_operation(client, auth, v)
    _tweak_visit(v, flow_status="surgery_assigned")

    # Fresh referral (<24h) without a date is still normal reception workflow.
    assert v not in _visit_ids(_cat(_hanging(client, auth), "op_not_closed"))

    # Referral issued >24h ago and STILL not scheduled → hanging.
    _tweak_operation(op, created_hours_ago=25)
    cat = _cat(_hanging(client, auth), "op_not_closed")
    assert cat is not None and v in _visit_ids(cat)
    row = next(r for r in cat["visits"] if r["visit_id"] == v)
    assert "не назначена" in row["detail"]


def test_cat4_overdue_scheduled_survives_fresh_referral(client, auth):
    # Визит с ДВУМЯ операциями: свежее направление (referred без даты) и
    # запланированная на прошедшую дату (просрочка). Просрочка должна быть
    # показана независимо от порядка сортировки NULL scheduled_at в БД, и
    # визит должен появиться в op_not_closed ровно один раз.
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "twoops")["id"]
    op_sched = _refer_operation(client, auth, v)
    op_ref = _refer_operation(client, auth, v)
    _tweak_visit(v, flow_status="surgery_assigned")

    from app.core.database import SessionLocal
    from app.models.operation import Operation
    db = SessionLocal()
    try:
        s = db.get(Operation, uuid.UUID(op_sched))
        s.status = "scheduled"
        s.scheduled_at = datetime.now(timezone.utc) - timedelta(days=1)
        r = db.get(Operation, uuid.UUID(op_ref))
        r.status = "referred"
        r.created_at = datetime.now(timezone.utc) - timedelta(hours=25)
        db.commit()
    finally:
        db.close()

    cat = _cat(_hanging(client, auth), "op_not_closed")
    assert cat is not None
    rows = [r for r in cat["visits"] if r["visit_id"] == v]
    assert len(rows) == 1
    assert "дата прошла" in rows[0]["detail"]
    assert "не назначена" not in rows[0]["detail"]


def test_performed_surgery_completed_single_category(client, auth):
    # performed-операция + flow_status=surgery_completed раньше попадала и в
    # op_not_closed, и в post_op_not_finished. Должна быть ровно в одной.
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "single")["id"]
    op = _refer_operation(client, auth, v)
    _tweak_operation(op, status="performed", performed_hours_ago=4)
    _tweak_visit(v, flow_status="surgery_completed")

    data = _hanging(client, auth)
    assert v not in _visit_ids(_cat(data, "op_not_closed"))
    assert v in _visit_ids(_cat(data, "post_op_not_finished"))


def test_post_op_not_finished(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "postop")["id"]
    op = _refer_operation(client, auth, v)

    # Surgery done 1h ago → within the grace window, not hanging yet.
    _tweak_operation(op, status="performed", performed_hours_ago=1)
    _tweak_visit(v, flow_status="surgery_completed")
    assert v not in _visit_ids(_cat(_hanging(client, auth), "post_op_not_finished"))

    # Done >3h ago, visit still open in surgery_completed → hanging.
    _tweak_operation(op, performed_hours_ago=4)
    cat = _cat(_hanging(client, auth), "post_op_not_finished")
    assert cat is not None and v in _visit_ids(cat)
    assert cat["severity"] == "warning"


def test_done_not_closed_only_with_debt(client, auth):
    branch = _branch_id(client, auth)

    # No debt: flow completed on an open visit is normal (auto-close handles it).
    clean = _new_visit(client, auth, branch, "donefree")["id"]
    _tweak_visit(clean, flow_status="completed")
    assert clean not in _visit_ids(_cat(_hanging(client, auth), "done_not_closed"))

    # With debt: unpaid billed item + finished flow + open visit → hanging.
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Завис", "last_name": "Тестов-долг",
              "phone": "+998900000001", "branch_id": branch},
    ).json()
    cons = next(s for s in client.get(f"{API}/services", headers=auth).json()["items"]
                if s["code"] == "CONS")
    debtor = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch,
              "items": [{"service_id": cons["id"], "quantity": 1}]},
    ).json()["id"]
    _tweak_visit(debtor, flow_status="completed")
    cat = _cat(_hanging(client, auth), "done_not_closed")
    assert cat is not None and debtor in _visit_ids(cat)
    assert cat["severity"] == "info"
    row = next(r for r in cat["visits"] if r["visit_id"] == debtor)
    assert "долг" in row["detail"]


def test_cat5_treatment_unfinished(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "treat")["id"]
    assert client.post(f"{API}/visits/{v}/treatments", headers=auth,
                       json={"kind": "procedure", "name": "Перевязка"}).status_code == 201

    cat = _cat(_hanging(client, auth), "treatment_unfinished")
    assert cat is not None and v in _visit_ids(cat)


def test_visits_flow_status_filter(client, auth):
    branch = _branch_id(client, auth)
    v = _new_visit(client, auth, branch, "flowfilter")["id"]
    _tweak_visit(v, flow_status="in_doctor")

    resp = client.get(f"{API}/visits", headers=auth, params={"flow_status": "in_doctor"})
    assert resp.status_code == 200, resp.text
    ids = {row["id"] for row in resp.json()["items"]}
    assert v in ids
    # A non-matching filter excludes it.
    other = client.get(f"{API}/visits", headers=auth, params={"flow_status": "completed"})
    assert v not in {row["id"] for row in other.json()["items"]}


def test_hanging_visits_rbac(client, auth):
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "hang.wh@kozshifo.uz", "full_name": "Тест Склад",
              "password": "Wh!2026hang", "role_names": []},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "hang.wh@kozshifo.uz", "password": "Wh!2026hang"},
    ).json()["access_token"]
    denied = client.get(f"{API}/dashboard/hanging-visits",
                        headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
    assert "dashboard.view" in denied.json()["detail"]
