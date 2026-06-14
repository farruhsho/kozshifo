"""IP cameras: CRUD (password never leaks), graceful-offline test/snapshot, and a
monkeypatched happy-path snapshot proxy.

Device-facing calls run against an unreachable camera (127.0.0.1:1 — connection
refused fast) to prove the graceful contract: an offline camera yields a 502 on
snapshot and online=false on test, never a 500. The happy path stubs the ISAPI
client so the JPEG-proxy plumbing is covered without real hardware.
"""
from __future__ import annotations

from tests.conftest import API

# A camera that is guaranteed offline (port 1 refuses immediately).
OFFLINE = {"host": "127.0.0.1", "port": 1, "username": "admin", "password": "Cam!2026"}
_FAKE_JPEG = b"\xff\xd8\xff\xe0\x00\x10JFIF fake-jpeg-bytes \xff\xd9"


def _make_camera(client, auth, name="Камера регистратуры") -> dict:
    resp = client.post(f"{API}/cameras", headers=auth, json={"name": name, **OFFLINE})
    assert resp.status_code == 201, resp.text
    return resp.json()


def test_camera_crud_never_leaks_password(client, auth):
    created = _make_camera(client, auth, "Тестовая камера")
    assert "password" not in created  # write-only — never serialized
    assert created["host"] == "127.0.0.1"
    assert created["online"] is False
    assert created["vendor"] == "hikvision"
    assert created["channel_no"] == 1

    listed = client.get(f"{API}/cameras", headers=auth)
    assert listed.status_code == 200, listed.text
    row = next(c for c in listed.json() if c["id"] == created["id"])
    assert "password" not in row

    patched = client.patch(
        f"{API}/cameras/{created['id']}", headers=auth,
        json={"name": "Переименована", "password": "NewCam!1"},
    )
    assert patched.status_code == 200, patched.text
    assert patched.json()["name"] == "Переименована"
    assert "password" not in patched.json()

    deleted = client.delete(f"{API}/cameras/{created['id']}", headers=auth)
    assert deleted.status_code == 204, deleted.text


def test_test_connection_offline_is_graceful(client, auth):
    camera = _make_camera(client, auth, "Оффлайн камера")
    resp = client.post(f"{API}/cameras/{camera['id']}/test", headers=auth)
    assert resp.status_code == 200, resp.text  # not a 500 — the camera is just down
    body = resp.json()
    assert body["online"] is False
    assert body["error"]


def test_snapshot_offline_is_502_not_500(client, auth):
    camera = _make_camera(client, auth, "Снимок оффлайн")
    resp = client.get(f"{API}/cameras/{camera['id']}/snapshot", headers=auth)
    assert resp.status_code == 502, resp.text  # bad gateway, never a 500


def test_snapshot_happy_path_proxies_jpeg(client, auth, monkeypatch):
    camera = _make_camera(client, auth, "Снимок онлайн")
    monkeypatch.setattr(
        "app.features.cameras.HikvisionClient.get_snapshot",
        lambda self, **kwargs: _FAKE_JPEG,
    )
    resp = client.get(f"{API}/cameras/{camera['id']}/snapshot", headers=auth)
    assert resp.status_code == 200, resp.text
    assert resp.headers["content-type"] == "image/jpeg"
    assert resp.headers.get("cache-control") == "no-store"
    assert resp.content == _FAKE_JPEG


def test_test_connection_happy_path(client, auth, monkeypatch):
    camera = _make_camera(client, auth, "Онлайн камера")
    monkeypatch.setattr(
        "app.features.cameras.HikvisionClient.get_device_info",
        lambda self: {"model": "DS-2CD2143", "firmwareVersion": "V5.7", "serialNumber": "SN123",
                      "deviceName": "IP CAMERA"},
    )
    resp = client.post(f"{API}/cameras/{camera['id']}/test", headers=auth)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["online"] is True
    assert body["model"] == "DS-2CD2143"
    assert body["serial"] == "SN123"

    # online + device_info now persisted on the row
    listed = client.get(f"{API}/cameras", headers=auth)
    row = next(c for c in listed.json() if c["id"] == camera["id"])
    assert row["online"] is True
    assert row["device_info"]["model"] == "DS-2CD2143"


def test_snapshot_unknown_camera_404(client, auth):
    import uuid
    resp = client.get(f"{API}/cameras/{uuid.uuid4()}/snapshot", headers=auth)
    assert resp.status_code == 404, resp.text


def test_snapshot_unsupported_digest_is_502_not_500(client, auth, monkeypatch):
    """httpx.DigestAuth raises NotImplementedError/KeyError (NOT HTTPError) for an
    odd-firmware challenge; _request must map those to the graceful path so the
    snapshot yields 502, never a 500."""
    camera = _make_camera(client, auth, "Странная прошивка")
    from app.core.devices import hikvision

    class _BoomClient:
        def __init__(self, *args, **kwargs):
            pass

        def __enter__(self):
            return self

        def __exit__(self, *args):
            return False

        def request(self, *args, **kwargs):
            raise NotImplementedError("Digest auth-int support is not yet implemented")

    monkeypatch.setattr(hikvision.httpx, "Client", _BoomClient)
    resp = client.get(f"{API}/cameras/{camera['id']}/snapshot", headers=auth)
    assert resp.status_code == 502, resp.text  # graceful — not a 500
