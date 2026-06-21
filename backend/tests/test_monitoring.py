"""Super Admin → системный мониторинг: online users + login sessions + uptime
(+ slow/error ring buffers). Online is in-memory (touched per authenticated
request); login history is the persisted UserSession table. Gated by audit.read."""
from __future__ import annotations

from tests.conftest import API


def test_monitoring_reports_online_and_sessions(client, auth):
    mon = client.get(f"{API}/admin/monitoring", headers=auth)
    assert mon.status_code == 200, mon.text
    body = mon.json()
    assert body["uptime_seconds"] >= 0
    assert body["online_count"] >= 1          # the caller is online (touched on auth)
    assert body["logins_today"] >= 1          # the test logged in
    assert body["total_sessions"] >= 1
    assert isinstance(body["recent_slow"], list)
    assert isinstance(body["recent_errors"], list)
    assert any(u["name"] for u in body["online_users"])

    sessions = client.get(f"{API}/admin/sessions", headers=auth)
    assert sessions.status_code == 200, sessions.text
    rows = sessions.json()
    assert len(rows) >= 1
    assert any(r["online"] for r in rows)     # at least the current user is online
    assert all({"started_at", "user_id", "online"} <= set(r) for r in rows)


def test_monitoring_rbac(client, auth):
    client.post(f"{API}/users", headers=auth,
                json={"email": "mon.recep@kozshifo.uz", "full_name": "Рецепшн Монитор",
                      "password": "Passw0rd!", "role_names": ["Reception"]})
    token = client.post(f"{API}/auth/login",
                        data={"username": "mon.recep@kozshifo.uz", "password": "Passw0rd!"}
                        ).json()["access_token"]
    h = {"Authorization": f"Bearer {token}"}
    assert client.get(f"{API}/admin/monitoring", headers=h).status_code == 403
    assert client.get(f"{API}/admin/sessions", headers=h).status_code == 403
