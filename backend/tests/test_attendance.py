"""Attendance (TZ Modul 1): Face ID punch seam, manual punches, timesheet math.

The punch endpoint is an unattended-hardware seam: shared-secret header, no
JWT — 503 while the key is unset, 401 on mismatch. Report math is exercised
over a crafted week keyed to *local* dates (last week's Mon/Tue/Wed) so the
assertions are stable regardless of when the suite runs.
"""
from __future__ import annotations

from datetime import date, datetime, time, timedelta, timezone

import pytest

from tests.conftest import API

PUNCH_KEY = "test-faceid-key"
_PASSWORD = "Att!2026aa"


def _make_user(client, auth, email: str, full_name: str, role: str = "Administrator") -> dict:
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": full_name,
              "password": _PASSWORD, "role_names": [role]},
    )
    assert created.status_code == 201, created.text
    return created.json()


def _local_utc_iso(day: date, hh: int, mm: int) -> str:
    """ISO UTC instant for a *local* wall-clock time on `day`.

    Mirrors the server convention: lateness/day-bucketing use server-local
    time, storage is UTC.
    """
    return datetime.combine(day, time(hh, mm)).astimezone(timezone.utc).isoformat()


@pytest.fixture
def faceid_key(monkeypatch) -> str:
    from app.core.config import settings

    monkeypatch.setattr(settings, "attendance_api_key", PUNCH_KEY)
    return PUNCH_KEY


# ------------------------------------------------------- live status (director)

def test_status_roster_present_and_integration_flag(client, auth, monkeypatch):
    from app.core.config import settings

    user = _make_user(client, auth, "att.now@kozshifo.uz", "Статус Тест")
    # A punch-in earlier today → this user is "present" in the live roster.
    punch_in = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    ev = client.post(f"{API}/attendance/events", headers=auth,
                     json={"user_id": user["id"], "direction": "in",
                           "occurred_at": punch_in})
    assert ev.status_code == 201, ev.text

    monkeypatch.setattr(settings, "attendance_api_key", "set")  # Face ID wired
    resp = client.get(f"{API}/attendance/status", headers=auth)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["integration_enabled"] is True
    assert body["present_count"] >= 1
    me = next(s for s in body["staff"] if s["user_id"] == user["id"])
    assert me["status"] == "present"
    assert me["last_direction"] == "in"
    # Counts reconcile with the roster.
    assert body["present_count"] == sum(1 for s in body["staff"] if s["status"] == "present")

    # Integration flag follows the key.
    monkeypatch.setattr(settings, "attendance_api_key", None)
    off = client.get(f"{API}/attendance/status", headers=auth).json()
    assert off["integration_enabled"] is False


def test_status_requires_attendance_read(client):
    # The doctor has no attendance.read → 403 (it's an admin/director screen).
    resp = client.post(f"{API}/auth/login",
                       data={"username": "vrach@kozshifo.uz", "password": "Vrach!2026"})
    assert resp.status_code == 200, resp.text
    token = resp.json()["access_token"]
    denied = client.get(f"{API}/attendance/status",
                        headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403


# ------------------------------------------------------------------ punch auth

def test_punch_503_when_integration_disabled(client, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "attendance_api_key", None)
    resp = client.post(
        f"{API}/attendance/punch",
        json={"email": "whoever@kozshifo.uz"},
        headers={"X-Attendance-Key": "anything"},
    )
    assert resp.status_code == 503, resp.text


def test_punch_401_on_wrong_or_missing_key(client, faceid_key):
    wrong = client.post(
        f"{API}/attendance/punch",
        json={"email": "whoever@kozshifo.uz"},
        headers={"X-Attendance-Key": "wrong-key"},
    )
    assert wrong.status_code == 401, wrong.text

    missing = client.post(f"{API}/attendance/punch", json={"email": "whoever@kozshifo.uz"})
    assert missing.status_code == 401, missing.text


def test_punch_unknown_user_404(client, faceid_key):
    resp = client.post(
        f"{API}/attendance/punch",
        json={"email": "ghost.nobody@kozshifo.uz"},
        headers={"X-Attendance-Key": faceid_key},
    )
    assert resp.status_code == 404, resp.text


def test_punch_requires_user_id_or_email(client, faceid_key):
    resp = client.post(
        f"{API}/attendance/punch", json={}, headers={"X-Attendance-Key": faceid_key}
    )
    assert resp.status_code == 422, resp.text


# --------------------------------------------------------------- punch toggle

def test_punch_auto_toggles_in_then_out(client, auth, faceid_key):
    user = _make_user(client, auth, "faceid.punch@kozshifo.uz", "Face Пунчев")
    headers = {"X-Attendance-Key": faceid_key}

    first = client.post(
        f"{API}/attendance/punch", json={"email": "faceid.punch@kozshifo.uz"}, headers=headers
    )
    assert first.status_code == 201, first.text
    body = first.json()
    assert body["direction"] == "in"  # no events today -> "in"
    assert body["source"] == "faceid"
    assert body["user_id"] == user["id"]
    assert body["recorded_by_id"] is None
    assert body["user_full_name"] == "Face Пунчев"

    second = client.post(
        f"{API}/attendance/punch", json={"user_id": user["id"]}, headers=headers
    )
    assert second.status_code == 201, second.text
    assert second.json()["direction"] == "out"  # last today is "in" -> toggles

    # Explicit direction wins over the toggle.
    third = client.post(
        f"{API}/attendance/punch",
        json={"user_id": user["id"], "direction": "out"},
        headers=headers,
    )
    assert third.status_code == 201, third.text
    assert third.json()["direction"] == "out"

    # Raw log defaults to today, newest first, filterable by user.
    listed = client.get(
        f"{API}/attendance/events", headers=auth, params={"user_id": user["id"]}
    )
    assert listed.status_code == 200, listed.text
    page = listed.json()
    assert page["total"] == 3
    stamps = [e["occurred_at"] for e in page["items"]]
    assert stamps == sorted(stamps, reverse=True)
    # occurred_at must carry a UTC offset (UTCDateTime) so the journal tab can
    # .toLocal() — otherwise SQLite returns it naive and times show 5h early.
    assert all(s.endswith("Z") or "+00:00" in s for s in stamps), stamps


# --------------------------------------------------------------- manual + RBAC

def test_manual_event_requires_manage_permission(client, auth):
    target = _make_user(client, auth, "att.target@kozshifo.uz", "Цель Табеля")
    _make_user(client, auth, "att.warehouse@kozshifo.uz", "Врач Бесправный", role="Doctor")
    token = client.post(
        f"{API}/auth/login",
        data={"username": "att.warehouse@kozshifo.uz", "password": _PASSWORD},
    ).json()["access_token"]

    payload = {
        "user_id": target["id"],
        "direction": "in",
        "occurred_at": datetime.now(timezone.utc).isoformat(),
        "note": "забыл отметиться",
    }
    denied = client.post(
        f"{API}/attendance/events", json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert denied.status_code == 403, denied.text
    assert "attendance.manage" in denied.json()["detail"]

    ok = client.post(f"{API}/attendance/events", json=payload, headers=auth)
    assert ok.status_code == 201, ok.text
    body = ok.json()
    assert body["source"] == "manual"
    assert body["direction"] == "in"
    assert body["note"] == "забыл отметиться"
    assert body["recorded_by_id"] is not None  # the director keyed it in

    # And reading the log is also permission-gated.
    read_denied = client.get(
        f"{API}/attendance/events", headers={"Authorization": f"Bearer {token}"}
    )
    assert read_denied.status_code == 403


def test_manual_event_unknown_user_404(client, auth):
    resp = client.post(
        f"{API}/attendance/events", headers=auth,
        json={"user_id": "00000000-0000-0000-0000-000000000001", "direction": "in",
              "occurred_at": datetime.now(timezone.utc).isoformat()},
    )
    assert resp.status_code == 404, resp.text


# --------------------------------------------------------------------- report

def test_report_math_pairs_late_open_day_and_absence(client, auth, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "work_day_start", "09:00")
    user = _make_user(client, auth, "att.report@kozshifo.uz", "Табель Расчётов")

    today = date.today()
    day1 = today - timedelta(days=today.weekday() + 7)  # last week's Monday
    day2 = day1 + timedelta(days=1)                     # Tuesday
    day3 = day1 + timedelta(days=2)                     # Wednesday — no events

    def add(day: date, hh: int, mm: int, direction: str) -> None:
        resp = client.post(
            f"{API}/attendance/events", headers=auth,
            json={"user_id": user["id"], "direction": direction,
                  "occurred_at": _local_utc_iso(day, hh, mm)},
        )
        assert resp.status_code == 201, resp.text

    add(day1, 9, 5, "in");  add(day1, 13, 0, "out")   # 235 min (lunch split)
    add(day1, 14, 0, "in"); add(day1, 18, 0, "out")   # 240 min
    add(day2, 8, 55, "in")                            # open day -> 0 min, on time

    resp = client.get(
        f"{API}/attendance/report", headers=auth,
        params={"date_from": day1.isoformat(), "date_to": day3.isoformat()},
    )
    assert resp.status_code == 200, resp.text
    report = resp.json()
    assert report["work_day_start"] == "09:00"
    row = next(u for u in report["users"] if u["user_id"] == user["id"])

    assert row["days_present"] == 2
    assert row["days_absent"] == 1            # Wednesday: zero events, not Sunday
    assert row["total_minutes"] == 235 + 240
    assert row["late_count"] == 1
    assert len(row["days"]) == 2

    d1 = next(d for d in row["days"] if d["day"] == day1.isoformat())
    assert d1["worked_minutes"] == 475
    assert d1["late"] is True                 # 09:05 local > 09:00
    assert d1["first_in"] and d1["last_out"]

    d2 = next(d for d in row["days"] if d["day"] == day2.isoformat())
    assert d2["worked_minutes"] == 0          # unpaired trailing "in"
    assert d2["late"] is False                # 08:55 local
    assert d2["first_in"] is not None
    assert d2["last_out"] is None             # day still open


def test_report_csv_excel_friendly(client, auth):
    user = _make_user(client, auth, "att.csv@kozshifo.uz", "Эксель Выгрузкин")
    today = date.today()
    day = today - timedelta(days=today.weekday() + 7)  # last week's Monday
    created = client.post(
        f"{API}/attendance/events", headers=auth,
        json={"user_id": user["id"], "direction": "in",
              "occurred_at": _local_utc_iso(day, 9, 0)},
    )
    assert created.status_code == 201, created.text

    resp = client.get(
        f"{API}/attendance/report.csv", headers=auth,
        params={"date_from": day.isoformat(), "date_to": day.isoformat()},
    )
    assert resp.status_code == 200, resp.text
    assert resp.content.startswith(b"\xef\xbb\xbf")  # UTF-8 BOM for Excel
    assert resp.headers["content-type"].startswith("text/csv")
    assert "attachment" in resp.headers["content-disposition"]
    assert "Эксель Выгрузкин" in resp.text
    assert "Сотрудник" in resp.text
