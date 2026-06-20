"""Phase-1 RBAC overhaul (owner brief 2026-06-19):

- Director is NOT a superuser and cannot change system settings (staff / roles /
  branches / cabinets) but keeps full operational + analytics visibility.
- The Super Admin is a ghost: absent from every clinical picker (specialists,
  assignable doctors, surgeons).
- A dedicated «Лечебный кабинет» (TreatmentRoom) role runs only the treatment
  track — no general queue board, no doctor/diagnost personal workstation.
"""
from __future__ import annotations

from tests.conftest import API, SUPERADMIN_EMAIL, SUPERADMIN_PASSWORD


def _login(client, email: str, password: str) -> dict[str, str]:
    resp = client.post(f"{API}/auth/login", data={"username": email, "password": password})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


def _branch_id(client, headers) -> str:
    return client.get(f"{API}/branches", headers=headers).json()[0]["id"]


def test_director_is_not_superuser_and_cannot_admin(client, director_auth):
    me = client.get(f"{API}/auth/me", headers=director_auth).json()
    assert me["is_superuser"] is False
    perms = set(me["permissions"])
    # Cannot change system settings.
    for code in ("users.create", "users.update", "users.delete",
                 "roles.create", "roles.update", "roles.delete",
                 "branches.create", "branches.update"):
        assert code not in perms, f"director must NOT have {code}"
    # But sees everything operational + analytics.
    for code in ("queue.admin", "dashboard.view", "reports.view", "audit.read",
                 "operations.read", "payments.read", "patients.read", "users.read"):
        assert code in perms, f"director should have {code}"
    # The endpoint guard actually bites (not just a UI hint).
    created = client.post(f"{API}/users", headers=director_auth, json={
        "email": "nope@kozshifo.uz", "full_name": "N", "password": "Passw0rd!",
        "role_names": ["Doctor"],
    })
    assert created.status_code == 403, created.text


def test_ghost_superadmin_absent_from_pickers(client, director_auth):
    owner = _login(client, SUPERADMIN_EMAIL, SUPERADMIN_PASSWORD)
    rows = client.get(f"{API}/users", headers=owner, params={"limit": 200}).json()["items"]
    su_id = next(u["id"] for u in rows if u["email"] == SUPERADMIN_EMAIL)
    branch = _branch_id(client, director_auth)

    specialists = client.get(f"{API}/queue/specialists", headers=director_auth,
                             params={"branch_id": branch}).json()
    assert all(s["id"] != su_id for s in specialists)

    doctors = client.get(f"{API}/services/assignable-doctors", headers=director_auth).json()
    assert all(d["id"] != su_id for d in doctors)

    surgeons = client.get(f"{API}/operations/surgeons", headers=director_auth).json()
    assert all(s["id"] != su_id for s in surgeons)


def test_treatment_room_role_scope(client):
    tr = _login(client, "treatment@kozshifo.uz", "Treatment!2026")
    me = client.get(f"{API}/auth/me", headers=tr).json()
    assert me["is_superuser"] is False
    perms = set(me["permissions"])
    assert "treatments.perform" in perms
    assert "queue.manage" in perms
    # No general two-track board, no doctor/diagnost personal workstation, no
    # clinical authoring.
    assert "queue.admin" not in perms
    assert "device_results.create" not in perms
    assert "exams.write" not in perms
