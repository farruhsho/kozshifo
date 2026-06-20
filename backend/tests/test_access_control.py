"""Access control / Face ID: terminal CRUD, enrollment mapping, event webhook.

The device-facing calls (test/enroll/face) are exercised against an unreachable
terminal (127.0.0.1:1 — connection refused fast) to prove the graceful-offline
contract: the local mapping is saved, the device push is best-effort, nothing
500s. The webhook is the inbound seam (secret in the path, no JWT).
"""
from __future__ import annotations

import pytest

from tests.conftest import API

# A terminal that is guaranteed offline (port 1 refuses immediately).
OFFLINE = {"host": "127.0.0.1", "port": 1, "username": "admin", "password": "Device!2026"}
EVENT_TOKEN = "test-faceid-event-token"
_PASSWORD = "Acl!2026aa"


def _make_user(client, auth, email, full_name, role="Administrator") -> dict:
    resp = client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": full_name, "password": _PASSWORD, "role_names": [role]},
    )
    assert resp.status_code == 201, resp.text
    return resp.json()


def _make_terminal(client, auth, name="Главный вход") -> dict:
    resp = client.post(f"{API}/access-control/terminals", headers=auth, json={"name": name, **OFFLINE})
    assert resp.status_code == 201, resp.text
    return resp.json()


@pytest.fixture
def event_token(monkeypatch) -> str:
    from app.core.config import settings

    monkeypatch.setattr(settings, "hikvision_event_token", EVENT_TOKEN)
    return EVENT_TOKEN


# ----------------------------------------------------------------- terminal CRUD

def test_terminal_crud_never_leaks_password(client, auth):
    created = _make_terminal(client, auth, "Тестовый терминал")
    assert "password" not in created  # write-only — never serialized
    assert created["host"] == "127.0.0.1"
    assert created["online"] is False

    listed = client.get(f"{API}/access-control/terminals", headers=auth)
    assert listed.status_code == 200, listed.text
    row = next(t for t in listed.json() if t["id"] == created["id"])
    assert "password" not in row

    patched = client.patch(
        f"{API}/access-control/terminals/{created['id']}", headers=auth,
        json={"name": "Переименован", "password": "NewSecret!1"},
    )
    assert patched.status_code == 200, patched.text
    assert patched.json()["name"] == "Переименован"
    assert "password" not in patched.json()

    deleted = client.delete(f"{API}/access-control/terminals/{created['id']}", headers=auth)
    assert deleted.status_code == 204, deleted.text


def test_test_connection_offline_is_graceful(client, auth):
    terminal = _make_terminal(client, auth, "Оффлайн терминал")
    resp = client.post(f"{API}/access-control/terminals/{terminal['id']}/test", headers=auth)
    assert resp.status_code == 200, resp.text  # not a 500 — the device is just down
    body = resp.json()
    assert body["online"] is False
    assert body["error"]


def test_configure_push_requires_token(client, auth, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "hikvision_event_token", None)
    terminal = _make_terminal(client, auth, "Терминал без токена")
    resp = client.post(
        f"{API}/access-control/terminals/{terminal['id']}/configure-push",
        headers=auth, json={},
    )
    assert resp.status_code == 422, resp.text  # webhook secret not configured


def test_configure_push_offline_is_graceful(client, auth, event_token):
    terminal = _make_terminal(client, auth, "Терминал автоотправки")
    resp = client.post(
        f"{API}/access-control/terminals/{terminal['id']}/configure-push",
        headers=auth, json={"server_host": "10.0.0.5", "server_port": 8000},
    )
    assert resp.status_code == 200, resp.text  # offline device != 500
    body = resp.json()
    assert body["configured"] is False
    assert body["error"]
    assert "10.0.0.5:8000" in body["url"] and "****" in body["url"]  # token masked


# ------------------------------------------------------------------- enrollment

def test_enroll_assigns_employee_no_and_persists_offline(client, auth):
    terminal = _make_terminal(client, auth, "Терминал учёта")
    user = _make_user(client, auth, "acl.enroll@kozshifo.uz", "Лицо Распознаев")

    # Initially not enrolled.
    rows = client.get(f"{API}/access-control/enrollment", headers=auth).json()
    me = next(r for r in rows if r["user_id"] == user["id"])
    assert me["enrolled"] is False and me["faceid_employee_no"] is None

    enrolled = client.post(
        f"{API}/access-control/terminals/{terminal['id']}/enroll/{user['id']}", headers=auth
    )
    assert enrolled.status_code == 200, enrolled.text
    body = enrolled.json()
    emp_no = body["faceid_employee_no"]
    assert emp_no and emp_no.isdigit()
    assert body["pushed_to_device"] is False  # device offline → best-effort push failed
    assert body["error"]

    # Mapping survived the offline push.
    rows = client.get(f"{API}/access-control/enrollment", headers=auth).json()
    me = next(r for r in rows if r["user_id"] == user["id"])
    assert me["enrolled"] is True and me["faceid_employee_no"] == emp_no

    # Re-enrolling keeps the same employeeNo (idempotent mapping).
    again = client.post(
        f"{API}/access-control/terminals/{terminal['id']}/enroll/{user['id']}", headers=auth
    )
    assert again.json()["faceid_employee_no"] == emp_no


def test_face_upload_requires_enrollment(client, auth):
    terminal = _make_terminal(client, auth, "Терминал лиц")
    user = _make_user(client, auth, "acl.face@kozshifo.uz", "Фото Незагружен")
    resp = client.post(
        f"{API}/access-control/terminals/{terminal['id']}/enroll/{user['id']}/face",
        headers=auth, files={"file": ("face.jpg", b"\xff\xd8\xff\xe0fakejpeg", "image/jpeg")},
    )
    assert resp.status_code == 422, resp.text  # not enrolled yet


def test_remove_enrollment_clears_mapping(client, auth):
    terminal = _make_terminal(client, auth, "Терминал снятия")
    user = _make_user(client, auth, "acl.remove@kozshifo.uz", "Снятый Сучётаев")
    client.post(f"{API}/access-control/terminals/{terminal['id']}/enroll/{user['id']}", headers=auth)

    removed = client.delete(
        f"{API}/access-control/terminals/{terminal['id']}/enroll/{user['id']}", headers=auth
    )
    assert removed.status_code == 200, removed.text
    rows = client.get(f"{API}/access-control/enrollment", headers=auth).json()
    me = next(r for r in rows if r["user_id"] == user["id"])
    assert me["enrolled"] is False and me["faceid_employee_no"] is None


# ---------------------------------------------------------------------- webhook

def test_webhook_503_when_token_unset(client, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "hikvision_event_token", None)
    resp = client.post(f"{API}/access-control/event/anything", json={})
    assert resp.status_code == 503, resp.text


def test_webhook_401_on_wrong_token(client, event_token):
    resp = client.post(f"{API}/access-control/event/wrong-token", json={})
    assert resp.status_code == 401, resp.text


def test_webhook_ip_allowlist(client, auth, event_token, monkeypatch):
    from app.core.config import settings

    monkeypatch.setattr(settings, "hikvision_allowed_ips", ["10.0.0.99"])  # not the test client IP
    resp = client.post(
        f"{API}/access-control/event/{event_token}",
        json={"AccessControllerEvent": {"employeeNoString": "1"}},
    )
    assert resp.status_code == 403, resp.text


def test_webhook_records_recognition_and_toggles(client, auth, event_token):
    terminal = _make_terminal(client, auth, "Терминал событий")
    user = _make_user(client, auth, "acl.event@kozshifo.uz", "Событие Зафиксиров")
    emp_no = client.post(
        f"{API}/access-control/terminals/{terminal['id']}/enroll/{user['id']}", headers=auth
    ).json()["faceid_employee_no"]

    def push(attendance_status: str | None) -> dict:
        ace = {"majorEventType": 5, "subEventType": 75, "employeeNoString": emp_no,
               "name": "Событие Зафиксиров"}
        if attendance_status:
            ace["attendanceStatus"] = attendance_status
        resp = client.post(
            f"{API}/access-control/event/{event_token}",
            json={"dateTime": "2026-06-13T09:01:07+05:00", "AccessControllerEvent": ace},
        )
        assert resp.status_code == 200, resp.text
        return resp.json()

    assert push("checkIn")["direction"] == "in"
    assert push("checkOut")["direction"] == "out"

    # The recognitions show up in the events feed as faceid punches.
    events = client.get(f"{API}/access-control/events", headers=auth).json()
    mine = [e for e in events if e["user_id"] == user["id"]]
    assert len(mine) >= 2
    assert all(e["source"] == "faceid" for e in mine)
    assert mine[0]["user_full_name"] == "Событие Зафиксиров"


def test_webhook_ignores_heartbeat_and_unknown(client, event_token):
    # No employeeNoString -> ignored (heartbeat / non-auth event).
    heartbeat = client.post(
        f"{API}/access-control/event/{event_token}",
        json={"eventType": "heartBeat", "AccessControllerEvent": {}},
    )
    assert heartbeat.status_code == 200 and heartbeat.json()["status"] == "ignored"

    unknown = client.post(
        f"{API}/access-control/event/{event_token}",
        json={"AccessControllerEvent": {"employeeNoString": "999999"}},
    )
    assert unknown.status_code == 200 and unknown.json()["status"] == "unknown_employee"


# ---------------------------------------------------------------------- RBAC

def test_access_control_requires_permissions(client, auth):
    _make_user(client, auth, "acl.warehouse@kozshifo.uz", "Врач Бесправный", role="Doctor")
    token = client.post(
        f"{API}/auth/login",
        data={"username": "acl.warehouse@kozshifo.uz", "password": _PASSWORD},
    ).json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    read = client.get(f"{API}/access-control/terminals", headers=headers)
    assert read.status_code == 403 and "access_control.read" in read.json()["detail"]

    manage = client.post(
        f"{API}/access-control/terminals", headers=headers, json={"name": "x", **OFFLINE}
    )
    assert manage.status_code == 403 and "access_control.manage" in manage.json()["detail"]
