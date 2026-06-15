"""Scheduling: book / overlap-guard / reschedule / status state-machine /
day list / staff columns. Additive feature — mirrors the queue-routing harness.
"""
from __future__ import annotations

from datetime import datetime, timezone

from tests.conftest import API

_TODAY = datetime.now(timezone.utc).date().isoformat()


def _at(hhmm: str) -> str:
    return f"{_TODAY}T{hhmm}:00+00:00"


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _make_doctor(client, auth, branch_id, slug) -> str:
    resp = client.post(
        f"{API}/users", headers=auth,
        json={"email": f"sched.{slug}@kozshifo.uz", "full_name": f"Доктор {slug}",
              "password": "Sched!2026", "role_names": ["Doctor"], "branch_id": branch_id},
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


def _patient(client, auth, branch_id, last) -> str:
    return client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Запись", "last_name": last, "branch_id": branch_id},
    ).json()["id"]


def _book(client, auth, branch_id, pid, did, hhmm, dur=30):
    return client.post(f"{API}/appointments", headers=auth, json={
        "branch_id": branch_id, "patient_id": pid, "doctor_id": did,
        "starts_at": _at(hhmm), "duration_min": dur, "service": "Консультация",
    })


def test_book_then_overlap_rejected(client, auth):
    branch_id = _branch_id(client, auth)
    doc = _make_doctor(client, auth, branch_id, "alfa")
    p1 = _patient(client, auth, branch_id, "Первый")
    p2 = _patient(client, auth, branch_id, "Второй")

    first = _book(client, auth, branch_id, p1, doc, "10:00", 30)
    assert first.status_code == 201, first.text
    assert first.json()["appointment_no"].startswith("AP-")
    assert first.json()["status"] == "booked"
    assert first.json()["patient_name"]
    assert first.json()["doctor_name"]

    # 10:15 overlaps 10:00–10:30 for the same doctor → 409.
    clash = _book(client, auth, branch_id, p2, doc, "10:15", 30)
    assert clash.status_code == 409, clash.text

    # 10:30 is back-to-back (no overlap) → ok.
    ok = _book(client, auth, branch_id, p2, doc, "10:30", 30)
    assert ok.status_code == 201, ok.text


def test_reschedule_overlap_guard_excludes_self(client, auth):
    branch_id = _branch_id(client, auth)
    doc = _make_doctor(client, auth, branch_id, "beta")
    p = _patient(client, auth, branch_id, "Перенос")
    appt = _book(client, auth, branch_id, p, doc, "12:00", 30).json()
    other = _book(client, auth, branch_id, p, doc, "13:00", 30).json()

    # Move the first onto the same slot (excludes self) — allowed.
    same = client.post(f"{API}/appointments/{appt['id']}/reschedule", headers=auth,
                       json={"starts_at": _at("12:00")})
    assert same.status_code == 200, same.text

    # Move it onto the OTHER appointment's slot → overlap 409.
    clash = client.post(f"{API}/appointments/{appt['id']}/reschedule", headers=auth,
                        json={"starts_at": _at("13:10")})
    assert clash.status_code == 409, clash.text

    # Move it to a free slot → ok, time updated.
    moved = client.post(f"{API}/appointments/{appt['id']}/reschedule", headers=auth,
                        json={"starts_at": _at("15:00"), "duration_min": 45})
    assert moved.status_code == 200, moved.text
    assert moved.json()["starts_at"].startswith(_TODAY)
    assert other  # keep ref


def test_status_state_machine(client, auth):
    branch_id = _branch_id(client, auth)
    doc = _make_doctor(client, auth, branch_id, "gamma")
    p = _patient(client, auth, branch_id, "Статус")
    appt = _book(client, auth, branch_id, p, doc, "09:00", 30).json()

    def setst(s):
        return client.post(f"{API}/appointments/{appt['id']}/status", headers=auth,
                           json={"status": s})

    assert setst("arrived").status_code == 200
    assert setst("done").status_code == 200
    # done is terminal — cannot go back.
    assert setst("arrived").status_code == 409


def test_day_list_and_staff(client, auth):
    branch_id = _branch_id(client, auth)
    doc = _make_doctor(client, auth, branch_id, "delta")
    p = _patient(client, auth, branch_id, "Деньсписок")
    appt = _book(client, auth, branch_id, p, doc, "16:00", 30).json()

    # default day = today → our appointment is present.
    day = client.get(f"{API}/appointments", headers=auth, params={"branch_id": branch_id})
    assert day.status_code == 200, day.text
    assert any(a["id"] == appt["id"] for a in day.json())

    staff = client.get(f"{API}/appointments/staff", headers=auth, params={"branch_id": branch_id})
    assert staff.status_code == 200, staff.text
    mine = next(s for s in staff.json() if s["id"] == doc)
    assert "Doctor" in mine["roles"]


def test_unknown_patient_rejected(client, auth):
    import uuid
    branch_id = _branch_id(client, auth)
    doc = _make_doctor(client, auth, branch_id, "epsilon")
    resp = client.post(f"{API}/appointments", headers=auth, json={
        "branch_id": branch_id, "patient_id": str(uuid.uuid4()), "doctor_id": doc,
        "starts_at": _at("17:00"), "duration_min": 30,
    })
    assert resp.status_code == 422, resp.text
