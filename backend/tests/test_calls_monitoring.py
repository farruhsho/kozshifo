"""Reception-phone call monitoring (TZ Modul 9, Android-agent path).

Covers: device registration + key issued once, the per-device agent ingest
(idempotent batch, patient auto-link, missed/answered status), the bad-key gate,
heartbeat → online, and the director KPI summary (answered/missed/wait + offline
phones).
"""
from __future__ import annotations

from tests.conftest import API


def _register_device(client, auth, label="Ресепшн 1", **extra) -> dict:
    resp = client.post(f"{API}/calls/devices", headers=auth,
                       json={"label": label, **extra})
    assert resp.status_code == 201, resp.text
    return resp.json()


def _call(external_id, **over) -> dict:
    body = {
        "external_id": external_id,
        "direction": "in",
        "status": "answered",
        "phone": "+998 90 222-33-44",
        "started_at": "2026-03-10T09:30:00+00:00",
        "wait_seconds": 8,
        "duration_seconds": 60,
    }
    body.update(over)
    return body


# ----------------------------------------------------------------- device CRUD

def test_register_device_returns_key_once_and_starts_offline(client, auth):
    dev = _register_device(client, auth, label="Ресепшн A")
    assert dev["api_key"], "plaintext key must be returned on create"
    assert dev["online"] is False
    assert dev["last_seen_at"] is None

    # The key is never returned again by the list endpoint.
    listed = client.get(f"{API}/calls/devices", headers=auth)
    assert listed.status_code == 200, listed.text
    row = next(d for d in listed.json() if d["id"] == dev["id"])
    assert "api_key" not in row


def test_device_management_requires_calls_manage(client, auth):
    # Doctor role has neither calls.read nor calls.manage.
    client.post(f"{API}/users", headers=auth,
                json={"email": "mon.doc@kozshifo.uz", "full_name": "Док Тест",
                      "password": "Doc!2026mon", "role_names": ["Doctor"]})
    token = client.post(f"{API}/auth/login",
                        data={"username": "mon.doc@kozshifo.uz", "password": "Doc!2026mon"}
                        ).json()["access_token"]
    denied = client.post(f"{API}/calls/devices",
                        headers={"Authorization": f"Bearer {token}"},
                        json={"label": "Hack"})
    assert denied.status_code == 403, denied.text


# -------------------------------------------------------------- agent ingest

def test_agent_ingest_is_idempotent_and_links_patient(client, auth):
    patient = client.post(f"{API}/patients", headers=auth,
                         json={"first_name": "Звон", "last_name": "Тестов",
                               "phone": "902223344"}).json()
    dev = _register_device(client, auth, label="Ресепшн B")
    key = {"X-Device-Key": dev["api_key"]}

    first = client.post(f"{API}/calls/agent/ingest", headers=key,
                       json=[_call("c-1"), _call("c-2", status="missed", wait_seconds=20)])
    assert first.status_code == 200, first.text
    assert first.json() == {"received": 2, "ingested": 2, "duplicates": 0}

    # Resend the same batch — nothing new, both are duplicates.
    again = client.post(f"{API}/calls/agent/ingest", headers=key,
                       json=[_call("c-1"), _call("c-2", status="missed")])
    assert again.json() == {"received": 2, "ingested": 0, "duplicates": 2}

    # The answered call links to the patient and carries status/wait.
    rows = client.get(f"{API}/calls", headers=auth, params={"q": "222-33-44"}).json()["items"]
    answered = next(r for r in rows if r["status"] == "answered")
    assert answered["patient"]["id"] == patient["id"]
    assert answered["wait_seconds"] == 8
    assert answered["device"]["label"] == "Ресепшн B"


def test_agent_ingest_rejects_bad_key(client, auth):
    _register_device(client, auth, label="Ресепшн C")
    bad = client.post(f"{API}/calls/agent/ingest",
                     headers={"X-Device-Key": "totally-wrong"}, json=[_call("x-1")])
    assert bad.status_code == 401, bad.text
    missing = client.post(f"{API}/calls/agent/ingest", json=[_call("x-2")])
    assert missing.status_code == 401, missing.text


# ---------------------------------------------------------------- heartbeat

def test_heartbeat_brings_device_online(client, auth):
    dev = _register_device(client, auth, label="Ресепшн D")
    key = {"X-Device-Key": dev["api_key"]}
    hb = client.post(f"{API}/calls/agent/heartbeat", headers=key,
                    json={"app_version": "1.0.0"})
    assert hb.status_code == 200, hb.text
    assert hb.json()["ok"] is True

    row = next(d for d in client.get(f"{API}/calls/devices", headers=auth).json()
               if d["id"] == dev["id"])
    assert row["online"] is True
    assert row["app_version"] == "1.0.0"


# ------------------------------------------------------------------- summary

def test_summary_counts_answered_missed_and_wait(client, auth):
    dev = _register_device(client, auth, label="Ресепшн E")
    key = {"X-Device-Key": dev["api_key"]}
    client.post(f"{API}/calls/agent/ingest", headers=key, json=[
        _call("s-1", status="answered", wait_seconds=5),
        _call("s-2", status="answered", wait_seconds=15),
        _call("s-3", status="missed", wait_seconds=30),
        _call("s-4", status="rejected"),
    ])
    summary = client.get(f"{API}/calls/summary", headers=auth,
                        params={"date_from": "2026-03-10", "date_to": "2026-03-10"})
    assert summary.status_code == 200, summary.text
    data = summary.json()
    assert data["answered"] >= 2
    assert data["missed"] >= 1
    assert data["rejected"] >= 1
    # Average wait over answered incoming includes our 5s & 15s calls.
    assert data["avg_wait_seconds"] > 0
    assert data["max_wait_seconds"] >= 15
    assert len(data["by_hour"]) == 24
    assert any(d["label"] == "Ресепшн E" for d in data["by_device"])


def test_summary_lists_offline_phones(client, auth):
    # A freshly registered phone that never beat shows up as offline.
    dev = _register_device(client, auth, label="Ресепшн Offline")
    summary = client.get(f"{API}/calls/summary", headers=auth).json()
    assert any(d["id"] == dev["id"] and d["online"] is False
               for d in summary["offline_devices"])
