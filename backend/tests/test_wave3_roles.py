"""Role-management guards surfaced by the Wave-3 «Роли» admin UI (backend guards
are needed independent of the UI):

- PATCH on a system role is refused (mirror of the existing DELETE guard).
- DELETE of a role still assigned to users is refused (409) so user_roles CASCADE
  cannot silently strip everyone's access; only after the назначение is removed.
- DELETE of an unassigned custom role succeeds (204).
"""
from __future__ import annotations

from tests.conftest import API


def _first_system_role(client, auth) -> dict:
    roles = client.get(f"{API}/roles", headers=auth).json()
    return next(r for r in roles if r["is_system"])


def test_patch_system_role_is_refused(client, auth):
    role = _first_system_role(client, auth)
    resp = client.patch(
        f"{API}/roles/{role['id']}",
        headers=auth,
        json={"description": "hacked"},
    )
    assert resp.status_code == 409, resp.text
    # Unchanged.
    after = client.get(f"{API}/roles/{role['id']}", headers=auth).json()
    assert after["description"] == role["description"]


def test_delete_role_assigned_to_users_is_refused(client, auth):
    # Custom (deletable) role, then a user holding it.
    created = client.post(
        f"{API}/roles",
        headers=auth,
        json={"name": "Wave3 Assigned Role", "permission_codes": ["patients.read"]},
    )
    assert created.status_code == 201, created.text
    role = created.json()

    user = client.post(
        f"{API}/users",
        headers=auth,
        json={
            "email": "wave3-assigned@kozshifo.uz",
            "full_name": "Wave3 Holder",
            "password": "Passw0rd!",
            "role_names": [role["name"]],
        },
    )
    assert user.status_code == 201, user.text

    # Assigned → cannot delete (would orphan the user via CASCADE).
    blocked = client.delete(f"{API}/roles/{role['id']}", headers=auth)
    assert blocked.status_code == 409, blocked.text

    # Role is still there.
    still = client.get(f"{API}/roles/{role['id']}", headers=auth)
    assert still.status_code == 200


def test_delete_unassigned_custom_role_succeeds(client, auth):
    created = client.post(
        f"{API}/roles",
        headers=auth,
        json={"name": "Wave3 Orphan Role", "permission_codes": ["patients.read"]},
    )
    assert created.status_code == 201, created.text
    role = created.json()

    resp = client.delete(f"{API}/roles/{role['id']}", headers=auth)
    assert resp.status_code == 204, resp.text
    assert client.get(f"{API}/roles/{role['id']}", headers=auth).status_code == 404
