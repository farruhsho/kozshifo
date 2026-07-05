"""Role-management guards surfaced by the Wave-3 «Роли» admin UI (backend guards
are needed independent of the UI):

- PATCH on a system role is refused (mirror of the existing DELETE guard).
- DELETE of a role still assigned to users is refused (409) so user_roles CASCADE
  cannot silently strip everyone's access; only after the назначение is removed.
- DELETE of an unassigned custom role succeeds (204).
"""
from __future__ import annotations

import uuid

from tests.conftest import (
    API,
    DIRECTOR_EMAIL,
    DIRECTOR_PASSWORD,
)


def _first_system_role(client, auth) -> dict:
    roles = client.get(f"{API}/roles", headers=auth).json()
    return next(r for r in roles if r["is_system"])


def _uniq(prefix: str) -> str:
    return f"{prefix}-{uuid.uuid4().hex[:8]}"


def _create_role(client, auth, *, name: str, codes: list[str]) -> dict:
    resp = client.post(
        f"{API}/roles",
        headers=auth,
        json={"name": name, "permission_codes": codes},
    )
    assert resp.status_code == 201, resp.text
    return resp.json()


def _create_user_and_login(client, auth, *, role_names: list[str], password: str = "Passw0rd!") -> tuple[dict, str]:
    """Create a non-owner staff user (as the god account) with the given roles and
    return (auth-header, user_id) for acting AS that user."""
    email = f"{_uniq('user')}@kozshifo.uz"
    resp = client.post(
        f"{API}/users",
        headers=auth,
        json={
            "email": email,
            "full_name": "Wave3 Actor",
            "password": password,
            "role_names": role_names,
        },
    )
    assert resp.status_code == 201, resp.text
    user_id = resp.json()["id"]
    login = client.post(f"{API}/auth/login", data={"username": email, "password": password})
    assert login.status_code == 200, login.text
    token = login.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}, user_id


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


# ---------------------------------------------------------------------------
# BUG 1 — privilege escalation via role permissions is blocked.
# ---------------------------------------------------------------------------
def test_priv_escalation_via_role_permissions_is_blocked(client, auth):
    """A non-owner delegate with roles.update + users.update may NOT inflate a role
    with rights they lack, nor assign themselves such a role."""
    # Delegate holds ONLY a limited set incl. the two management rights, but NOT
    # users.delete / payments.refund.
    delegate_codes = ["roles.read", "roles.create", "roles.update",
                      "users.read", "users.create", "users.update"]
    manager_role = _create_role(client, auth, name=_uniq("OpsManager"), codes=delegate_codes)
    delegate, my_id = _create_user_and_login(client, auth, role_names=[manager_role["name"]])

    # A custom role the delegate may edit.
    editable = _create_role(client, auth, name=_uniq("Editable"), codes=["patients.read"])

    # (a) Delegate tries to write a right they do not hold into the role → 403.
    escalate = client.patch(
        f"{API}/roles/{editable['id']}",
        headers=delegate,
        json={"permission_codes": ["patients.read", "users.delete", "payments.refund"]},
    )
    assert escalate.status_code == 403, escalate.text
    assert "которых у вас нет" in escalate.json()["detail"]

    # Role unchanged (still just patients.read).
    after = client.get(f"{API}/roles/{editable['id']}", headers=auth).json()
    assert {p["code"] for p in after["permissions"]} == {"patients.read"}

    # (b) A privileged role already exists (created by the owner). The delegate
    # tries to assign it to THEMSELVES via users.update → 403.
    privileged = _create_role(client, auth, name=_uniq("Privileged"),
                              codes=["users.delete", "payments.refund"])
    grab = client.patch(
        f"{API}/users/{my_id}",
        headers=delegate,
        json={"role_names": [manager_role["name"], privileged["name"]]},
    )
    assert grab.status_code == 403, grab.text
    assert "которых у вас нет" in grab.json()["detail"]

    # (c) Sanity: the delegate CAN edit within their OWN rights (subset holds).
    # users.read + roles.read are both in delegate_codes.
    ok = client.patch(
        f"{API}/roles/{editable['id']}",
        headers=delegate,
        json={"permission_codes": ["users.read", "roles.read"]},
    )
    assert ok.status_code == 200, ok.text


# ---------------------------------------------------------------------------
# BUG 2 — the owner (Superadmin) role is a ghost to non-owners.
# ---------------------------------------------------------------------------
def test_superadmin_role_hidden_from_non_owner(client, auth):
    director_login = client.post(
        f"{API}/auth/login",
        data={"username": DIRECTOR_EMAIL, "password": DIRECTOR_PASSWORD},
    )
    assert director_login.status_code == 200, director_login.text
    director_auth = {"Authorization": f"Bearer {director_login.json()['access_token']}"}

    # Owner sees the Superadmin role and can resolve its id.
    owner_roles = client.get(f"{API}/roles", headers=auth).json()
    superadmin = next(r for r in owner_roles if r["name"] == "Superadmin")

    # Director (roles.read, non-owner) never sees it in the list…
    director_roles = client.get(f"{API}/roles", headers=director_auth)
    assert director_roles.status_code == 200, director_roles.text
    assert all(r["name"] != "Superadmin" for r in director_roles.json())

    # …and cannot fetch it by id — 404, as if it does not exist (not 403).
    hidden = client.get(f"{API}/roles/{superadmin['id']}", headers=director_auth)
    assert hidden.status_code == 404, hidden.text

    # Owner still fetches it fine.
    assert client.get(f"{API}/roles/{superadmin['id']}", headers=auth).status_code == 200


# ---------------------------------------------------------------------------
# BUG 3 — the last owner cannot demote themselves out of ownership.
# ---------------------------------------------------------------------------
def _owner_accounts(client, auth) -> list[dict]:
    """Every account that is currently an owner (Superadmin-role holder or bare
    superuser). The owner/god account sees all of them. Uses the max page size so
    a busy shared-session DB (many users from other tests) doesn't hide owners on
    a later page."""
    users = client.get(f"{API}/users?limit=200", headers=auth).json()["items"]
    return [u for u in users if u["is_superuser"] or any(r["name"] == "Superadmin" for r in u["roles"])]


def test_last_owner_cannot_be_demoted_but_transfer_works(client, auth):
    # The god account (superadmin@) is the identity behind `auth` — resolve it via
    # /auth/me (not the paginated user list, where it can fall off the first page).
    god = client.get(f"{API}/auth/me", headers=auth).json()
    assert god["is_superuser"], god

    # This session's DB is shared: other tests may have minted extra owners and
    # left them behind. Drive the owner set down to exactly the god account so the
    # "last owner" premise is deterministic. Each demotion here succeeds because
    # >1 owner still remains at that moment (guard only bites the LAST one).
    for other in _owner_accounts(client, auth):
        if other["id"] == god["id"]:
            continue
        demote = client.patch(
            f"{API}/users/{other['id']}",
            headers=auth,
            json={"role_names": ["Director"], "is_active": False},
        )
        assert demote.status_code == 200, demote.text

    # Now the god account is the SOLE Superadmin-role owner. Dropping that role
    # from it → 409 (would orphan the org). The god keeps is_superuser (schema
    # cannot clear it), but losing the role still breaks the role-based owner set,
    # which is what the guard protects.
    blocked = client.patch(
        f"{API}/users/{god['id']}",
        headers=auth,
        json={"role_names": ["Director"]},
    )
    assert blocked.status_code == 409, blocked.text
    assert "без владельца" in blocked.json()["detail"]
    # The block happened before any mutation — the god is still an owner.
    still = client.get(f"{API}/users/{god['id']}", headers=auth).json()
    assert any(r["name"] == "Superadmin" for r in still["roles"])

    # Ownership transfer: with a SECOND owner present, demoting the first succeeds.
    second_email = f"{_uniq('owner2')}@kozshifo.uz"
    second_pw = "Passw0rd!"
    second = client.post(
        f"{API}/users",
        headers=auth,
        json={
            "email": second_email,
            "full_name": "Second Owner",
            "password": second_pw,
            "is_superuser": True,
            "role_names": ["Superadmin"],
        },
    )
    assert second.status_code == 201, second.text

    # 2 owners now → the god account may drop the Superadmin role (transfer).
    ok = client.patch(
        f"{API}/users/{god['id']}",
        headers=auth,
        json={"role_names": ["Director"]},
    )
    assert ok.status_code == 200, ok.text

    # Restore the seed invariant. The god just lost the Superadmin role, so it can
    # no longer grant it — act as the SECOND owner to hand ownership back.
    second_login = client.post(
        f"{API}/auth/login", data={"username": second_email, "password": second_pw}
    )
    assert second_login.status_code == 200, second_login.text
    second_auth = {"Authorization": f"Bearer {second_login.json()['access_token']}"}
    restore = client.patch(
        f"{API}/users/{god['id']}",
        headers=second_auth,
        json={"role_names": ["Superadmin"]},
    )
    assert restore.status_code == 200, restore.text


# ---------------------------------------------------------------------------
# BUG 6 — a warehouse role without branches.read can still list branches.
# ---------------------------------------------------------------------------
def test_branches_listable_by_inventory_role_without_branches_read(client, auth):
    warehouse_role = _create_role(
        client, auth, name=_uniq("WarehouseOnly"),
        codes=["inventory.read", "inventory.manage"],  # no branches.read
    )
    warehouse, _ = _create_user_and_login(client, auth, role_names=[warehouse_role["name"]])

    resp = client.get(f"{API}/branches", headers=warehouse)
    assert resp.status_code == 200, resp.text
    # At least the seeded MAIN branch exists.
    assert len(resp.json()) >= 1
