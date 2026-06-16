"""RBAC per ТЗ: the Superadmin owner is invisible to (and unmanageable by) the
Director, and only the owner may mint owner-tier accounts. Reception can also
maintain the service price list (add / edit)."""
from __future__ import annotations

from tests.conftest import API

SUPERADMIN_EMAIL = "superadmin@kozshifo.uz"
RECEPTION_EMAIL = "reception@kozshifo.uz"


def _login(client, email: str, password: str) -> dict[str, str]:
    resp = client.post(f"{API}/auth/login", data={"username": email, "password": password})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


def _superadmin_id(client, owner_headers) -> str:
    rows = client.get(f"{API}/users", headers=owner_headers, params={"limit": 200}).json()["items"]
    return next(u["id"] for u in rows if u["email"] == SUPERADMIN_EMAIL)


def test_director_cannot_see_or_manage_superadmin(client, auth):
    owner = _login(client, SUPERADMIN_EMAIL, "Superadmin!2026")
    su_id = _superadmin_id(client, owner)

    # Director's user list hides the owner but shows ordinary staff.
    rows = client.get(f"{API}/users", headers=auth, params={"limit": 200}).json()["items"]
    assert all(u["email"] != SUPERADMIN_EMAIL for u in rows)
    assert any(u["email"] == RECEPTION_EMAIL for u in rows)

    # The owner's existence is not even leaked (404, not 403).
    assert client.get(f"{API}/users/{su_id}", headers=auth).status_code == 404
    assert client.patch(f"{API}/users/{su_id}", headers=auth,
                        json={"full_name": "hacked"}).status_code == 404

    # The owner can see the owner.
    assert client.get(f"{API}/users/{su_id}", headers=owner).status_code == 200


def test_only_owner_can_grant_superadmin_or_superuser(client, auth):
    owner = _login(client, SUPERADMIN_EMAIL, "Superadmin!2026")

    # Director may not create an owner-tier account (by role or by superuser flag).
    by_role = client.post(f"{API}/users", headers=auth, json={
        "email": "wannabe.super@kozshifo.uz", "full_name": "X", "password": "Passw0rd!",
        "role_names": ["Superadmin"],
    })
    assert by_role.status_code == 403, by_role.text
    by_flag = client.post(f"{API}/users", headers=auth, json={
        "email": "wannabe.god@kozshifo.uz", "full_name": "Y", "password": "Passw0rd!",
        "is_superuser": True,
    })
    assert by_flag.status_code == 403, by_flag.text

    # The owner can.
    ok = client.post(f"{API}/users", headers=owner, json={
        "email": "second.super@kozshifo.uz", "full_name": "Z", "password": "Passw0rd!",
        "role_names": ["Superadmin"],
    })
    assert ok.status_code == 201, ok.text


def test_reception_can_add_and_edit_services(client):
    rec = _login(client, RECEPTION_EMAIL, "Reception!2026")
    cats = client.get(f"{API}/service-categories", headers=rec).json()
    category_id = cats[0]["id"] if cats else None

    created = client.post(f"{API}/services", headers=rec, json={
        "code": "RCPT-SVC", "name": "Услуга от ресепшена", "price": "75000.00",
        "category_id": category_id,
    })
    assert created.status_code == 201, created.text
    sid = created.json()["id"]

    edited = client.patch(f"{API}/services/{sid}", headers=rec, json={"price": "80000.00"})
    assert edited.status_code == 200, edited.text
    assert edited.json()["price"] == "80000.00"
