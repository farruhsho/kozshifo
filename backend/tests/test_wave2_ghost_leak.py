"""Ghost owner (Superadmin) must not leak to a non-owner Director through the
admin observability surfaces: /admin/monitoring & /admin/sessions (name / IP /
online), /admin/audit-logs (the owner's own actions) and
/access-control/enrollment (the full staff list). The owner still sees himself
everywhere.
"""
from __future__ import annotations

from tests.conftest import API, SUPERADMIN_EMAIL, SUPERADMIN_PASSWORD


def _superadmin_id(client, owner_headers) -> str:
    rows = client.get(f"{API}/users", headers=owner_headers, params={"limit": 200}).json()["items"]
    return next(u["id"] for u in rows if u["email"] == SUPERADMIN_EMAIL)


def test_ghost_owner_hidden_from_director_but_visible_to_owner(client, auth, director_auth):
    su_id = _superadmin_id(client, auth)

    # The owner performs a mutation → an audit row with actor = the owner exists.
    branch = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    created = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Гост", "last_name": "Тест", "branch_id": branch},
    )
    assert created.status_code == 201, created.text

    # The owner logs in → is «online» + has a session touched on this request.
    assert client.get(f"{API}/admin/monitoring", headers=auth).status_code == 200

    # --- Director (non-owner) must NOT see the ghost anywhere -----------------
    mon = client.get(f"{API}/admin/monitoring", headers=director_auth)
    assert mon.status_code == 200, mon.text
    assert all(u["user_id"] != su_id for u in mon.json()["online_users"])

    sess = client.get(f"{API}/admin/sessions", headers=director_auth)
    assert sess.status_code == 200, sess.text
    assert all(r["user_id"] != su_id for r in sess.json())

    audit = client.get(f"{API}/admin/audit-logs", headers=director_auth,
                       params={"limit": 200})
    assert audit.status_code == 200, audit.text
    assert all(r["actor_id"] != su_id for r in audit.json()["items"])

    enroll = client.get(f"{API}/access-control/enrollment", headers=director_auth,
                        params={"only_active": False})
    assert enroll.status_code == 200, enroll.text
    assert all(r["user_id"] != su_id for r in enroll.json())

    # --- The owner sees himself in every surface ------------------------------
    owner_mon = client.get(f"{API}/admin/monitoring", headers=auth).json()
    assert any(u["user_id"] == su_id for u in owner_mon["online_users"])

    owner_sess = client.get(f"{API}/admin/sessions", headers=auth).json()
    assert any(r["user_id"] == su_id for r in owner_sess)

    owner_audit = client.get(f"{API}/admin/audit-logs", headers=auth,
                             params={"actor_id": su_id, "limit": 200}).json()
    assert owner_audit["total"] >= 1
    assert all(r["actor_id"] == su_id for r in owner_audit["items"])

    owner_enroll = client.get(f"{API}/access-control/enrollment", headers=auth,
                              params={"only_active": False}).json()
    assert any(r["user_id"] == su_id for r in owner_enroll)


def test_monitoring_counters_exclude_ghost_owner_for_director(client, auth, director_auth):
    # The owner logs in → a session for the ghost owner exists / is touched.
    assert client.get(f"{API}/admin/monitoring", headers=auth).status_code == 200

    owner_mon = client.get(f"{API}/admin/monitoring", headers=auth).json()
    director_mon = client.get(f"{API}/admin/monitoring", headers=director_auth).json()

    # The owner sees his own sessions in the aggregate counters; the Director
    # must not — his counts exclude every ghost-owner session, so they are
    # strictly smaller (owner has ≥1 session today and in total).
    assert owner_mon["total_sessions"] > director_mon["total_sessions"]
    assert owner_mon["logins_today"] > director_mon["logins_today"]
