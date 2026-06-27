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
    # Schedule for a FUTURE date → not hanging.
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": "2026-07-01T09:00:00+00:00"}).status_code == 200
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
