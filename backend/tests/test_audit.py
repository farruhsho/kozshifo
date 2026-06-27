"""Super Admin audit trail (owner brief 2026-06-20): every mutation records who /
what / when / from which device (ip + user-agent), readable via GET /admin/audit-logs
with filters + RBAC (audit.read — director/superadmin only)."""
from __future__ import annotations

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def test_audit_captures_device_and_lists_with_actor(client, auth):
    branch = _branch(client, auth)
    ua = "PyTest-Device/9.9 (KOZSHIFO audit test)"
    # A mutation carrying a custom User-Agent → the audit row must capture it.
    created = client.post(
        f"{API}/patients", headers={**auth, "User-Agent": ua},
        json={"first_name": "Аудит", "last_name": "Тестов", "branch_id": branch},
    )
    assert created.status_code == 201, created.text
    pid = created.json()["id"]

    logs = client.get(f"{API}/admin/audit-logs", headers=auth,
                      params={"entity_type": "patient", "limit": 100})
    assert logs.status_code == 200, logs.text
    body = logs.json()
    assert {"items", "total", "offset", "limit"} <= set(body)
    row = next((x for x in body["items"] if x["entity_id"] == pid), None)
    assert row is not None, "the patient-create must be in the audit trail"
    assert row["user_agent"] == ua          # с какого устройства
    assert row["actor_email"]               # кто (joined from users)
    assert row["entity_type"] == "patient"
    assert row["action"]                    # что
    assert "ip_address" in row              # откуда (testclient host)


def test_audit_filters_by_action(client, auth):
    resp = client.get(f"{API}/admin/audit-logs", headers=auth,
                      params={"action": "no_such_action_xyz"})
    assert resp.status_code == 200
    assert resp.json()["items"] == []

    bad = client.get(f"{API}/admin/audit-logs", headers=auth,
                     params={"date_from": "2026-06-30", "date_to": "2026-06-01"})
    assert bad.status_code == 422


def test_audit_rbac(client, auth):
    # Reception has no audit.read → 403 (audit is director/superadmin-only).
    client.post(f"{API}/users", headers=auth,
                json={"email": "audit.recep@kozshifo.uz", "full_name": "Рецепшн Аудит",
                      "password": "Passw0rd!", "role_names": []})
    token = client.post(f"{API}/auth/login",
                        data={"username": "audit.recep@kozshifo.uz", "password": "Passw0rd!"}
                        ).json()["access_token"]
    denied = client.get(f"{API}/admin/audit-logs",
                        headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
    assert "audit.read" in denied.json()["detail"]
