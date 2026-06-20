"""IP-telephony call log (TZ Modul 9).

Covers: the PBX webhook shared-secret gate (503 unset / 401 wrong / 200 right),
auto-linking a formatted PBX number to a patient registered with a bare local
number (last-9-digits match), the no-match and short-number paths, payload
validation, and the staff journal (calls.read RBAC, q by digits fragment and
by patient name, newest-first ordering).
"""
from __future__ import annotations

import pytest

from tests.conftest import API

PBX_KEY = "test-pbx-secret"


@pytest.fixture
def pbx_key(monkeypatch) -> str:
    from app.core.config import settings

    monkeypatch.setattr(settings, "pbx_api_key", PBX_KEY)
    return PBX_KEY


def _ingest_body(**overrides) -> dict:
    body = {
        "phone": "+998 90 555-44-33",
        "started_at": "2026-06-12T09:30:00+00:00",
        "duration_seconds": 42,
    }
    body.update(overrides)
    return body


def _make_patient(client, auth, **overrides) -> dict:
    payload = {"first_name": "Алиса", "last_name": "Телефонова", "phone": "905554433"}
    payload.update(overrides)
    resp = client.post(f"{API}/patients", headers=auth, json=payload)
    assert resp.status_code == 201, resp.text
    return resp.json()


def test_ingest_non_ascii_key_returns_401_not_500(client, pbx_key):
    """A non-ASCII X-PBX-Key must 401, not crash compare_digest with a 500.

    Sent as raw bytes — that's how a junk key reaches Starlette, which
    latin-1-decodes header bytes into a non-ASCII str that the naive
    ``compare_digest(str, str)`` would choke on (TypeError → 500)."""
    resp = client.post(
        f"{API}/calls/ingest", json=_ingest_body(),
        headers={"X-PBX-Key": b"\x6b\xe9\x79"},  # b"key" with a non-ASCII middle byte
    )
    assert resp.status_code == 401, resp.text


def test_call_started_at_serializes_with_utc_offset(client, auth, pbx_key):
    """started_at must carry a timezone offset so the Flutter journal can .toLocal()."""
    client.post(f"{API}/calls/ingest", json=_ingest_body(), headers={"X-PBX-Key": PBX_KEY})
    rows = client.get(f"{API}/calls", headers=auth).json()["items"]
    assert rows, "expected at least one call"
    started = rows[0]["started_at"]
    assert started.endswith("Z") or "+00:00" in started, started


# ---------------------------------------------------------------- ingest gate

def test_ingest_503_when_key_unset(client, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "pbx_api_key", None)
    resp = client.post(f"{API}/calls/ingest", json=_ingest_body(),
                       headers={"X-PBX-Key": "anything"})
    assert resp.status_code == 503, resp.text


def test_ingest_401_on_wrong_or_missing_key(client, pbx_key):
    wrong = client.post(f"{API}/calls/ingest", json=_ingest_body(),
                        headers={"X-PBX-Key": "not-the-key"})
    assert wrong.status_code == 401, wrong.text

    missing = client.post(f"{API}/calls/ingest", json=_ingest_body())
    assert missing.status_code == 401, missing.text


# ------------------------------------------------------------ ingest + linking

def test_ingest_links_patient_by_last_9_digits(client, auth, pbx_key):
    # Reception registered the patient with a bare local number…
    patient = _make_patient(client, auth, phone="901112233")

    # …the PBX reports the same line in full international format.
    resp = client.post(
        f"{API}/calls/ingest",
        json=_ingest_body(phone="+998 90 111-22-33", note="спросил про лазер"),
        headers={"X-PBX-Key": PBX_KEY},
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["direction"] == "in"
    assert body["phone"] == "+998 90 111-22-33"
    assert body["duration_seconds"] == 42
    assert body["note"] == "спросил про лазер"
    assert body["started_at"].startswith("2026-06-12T09:30:00")
    assert body["patient"] is not None
    assert body["patient"]["id"] == patient["id"]
    assert body["patient"]["last_name"] == "Телефонова"
    assert body["patient"]["first_name"] == "Алиса"


def test_ingest_no_match_leaves_patient_null(client, pbx_key):
    resp = client.post(
        f"{API}/calls/ingest",
        json=_ingest_body(phone="+998 71 999-88-77", direction="out"),
        headers={"X-PBX-Key": PBX_KEY},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["patient"] is None
    assert resp.json()["direction"] == "out"


def test_ingest_short_number_skips_matching(client, auth, pbx_key):
    # 6 digits < the 7-digit matching threshold — never auto-link.
    _make_patient(client, auth, phone="123456", first_name="Кор",
                  last_name="Откий")
    resp = client.post(f"{API}/calls/ingest", json=_ingest_body(phone="12-34-56"),
                       headers={"X-PBX-Key": PBX_KEY})
    assert resp.status_code == 200, resp.text
    assert resp.json()["patient"] is None


def test_ingest_negative_duration_422(client, pbx_key):
    resp = client.post(f"{API}/calls/ingest",
                       json=_ingest_body(duration_seconds=-5),
                       headers={"X-PBX-Key": PBX_KEY})
    assert resp.status_code == 422, resp.text


def test_ingest_phone_without_digits_422(client, pbx_key):
    resp = client.post(f"{API}/calls/ingest", json=_ingest_body(phone="++--"),
                       headers={"X-PBX-Key": PBX_KEY})
    assert resp.status_code == 422, resp.text


# -------------------------------------------------------------------- journal

def test_list_requires_calls_read(client, auth):
    # Doctor role has no calls.read -> 403.
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "calls.wh@kozshifo.uz", "full_name": "Тест Врач",
              "password": "Wh!2026call", "role_names": ["Doctor"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "calls.wh@kozshifo.uz", "password": "Wh!2026call"},
    ).json()["access_token"]

    denied = client.get(f"{API}/calls", headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403, denied.text
    assert "calls.read" in denied.json()["detail"]


def test_list_search_and_ordering(client, auth, pbx_key):
    patient = _make_patient(client, auth, phone="+998 93 777 66 55",
                            first_name="Журнал", last_name="Қўнғироқов")
    first = client.post(
        f"{API}/calls/ingest",
        json=_ingest_body(phone="+998937776655",
                          started_at="2026-06-12T10:00:00+00:00"),
        headers={"X-PBX-Key": PBX_KEY},
    )
    assert first.status_code == 200, first.text
    later = client.post(
        f"{API}/calls/ingest",
        json=_ingest_body(phone="93 777-66-55",
                          started_at="2026-06-12T11:00:00+00:00"),
        headers={"X-PBX-Key": PBX_KEY},
    )
    assert later.status_code == 200, later.text

    # q by digits fragment — query itself arrives formatted, must be normalized.
    by_digits = client.get(f"{API}/calls", headers=auth,
                           params={"q": "777-66-55"})
    assert by_digits.status_code == 200, by_digits.text
    page = by_digits.json()
    ids = [row["id"] for row in page["items"]]
    assert first.json()["id"] in ids
    assert later.json()["id"] in ids
    assert page["total"] >= 2

    # Newest first by started_at.
    assert ids.index(later.json()["id"]) < ids.index(first.json()["id"])
    for row in page["items"]:
        assert row["patient"]["id"] == patient["id"]

    # q by patient last name (ilike; case-exact fragment — SQLite's LIKE
    # folds case for ASCII only, so Cyrillic case-insensitivity is a
    # PostgreSQL-only nicety we don't assert here).
    by_name = client.get(f"{API}/calls", headers=auth,
                         params={"q": "ўнғироқов"})
    assert by_name.status_code == 200, by_name.text
    assert later.json()["id"] in [r["id"] for r in by_name.json()["items"]]

    # Rows carry the documented shape.
    sample = by_name.json()["items"][0]
    for key in ("id", "direction", "phone", "started_at", "duration_seconds",
                "recording_url", "note", "patient"):
        assert key in sample
