"""Phase-4 cabinets: a managed list of consulting rooms, Super-Admin-only to
create/edit, readable by everyone who calls patients (for the login picker)."""
from __future__ import annotations

from tests.conftest import API


def _login(client, email: str, password: str) -> dict[str, str]:
    resp = client.post(f"{API}/auth/login", data={"username": email, "password": password})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


def _branch_id(client, headers) -> str:
    return client.get(f"{API}/branches", headers=headers).json()[0]["id"]


def test_seeded_cabinets_listed(client, auth):
    branch = _branch_id(client, auth)
    rows = client.get(f"{API}/cabinets", headers=auth, params={"branch_id": branch}).json()
    names = {c["name"] for c in rows}
    assert "Кабинет №1" in names
    assert "Кабинет УЗИ" in names


def test_reception_can_read_cabinets(client):
    rec = _login(client, "reception@kozshifo.uz", "Reception!2026")
    branch = _branch_id(client, rec)
    rows = client.get(f"{API}/cabinets", headers=rec, params={"branch_id": branch})
    assert rows.status_code == 200, rows.text
    assert any(c["name"] == "Кабинет №1" for c in rows.json())


def test_only_superadmin_creates_cabinets(client, auth, director_auth):
    branch = _branch_id(client, auth)
    rec = _login(client, "reception@kozshifo.uz", "Reception!2026")
    body = {"branch_id": branch, "name": "Кабинет №7", "kind": "приём"}

    # Reception and Director cannot create (no cabinets.manage).
    assert client.post(f"{API}/cabinets", headers=rec, json=body).status_code == 403
    assert client.post(f"{API}/cabinets", headers=director_auth, json=body).status_code == 403

    # Super Admin can.
    created = client.post(f"{API}/cabinets", headers=auth, json=body)
    assert created.status_code == 201, created.text
    cab = created.json()
    assert cab["name"] == "Кабинет №7"

    # Duplicate name in the same branch → 409.
    assert client.post(f"{API}/cabinets", headers=auth, json=body).status_code == 409

    # Rename works.
    patched = client.patch(f"{API}/cabinets/{cab['id']}", headers=auth,
                           json={"name": "Кабинет №7 (новый)"})
    assert patched.status_code == 200, patched.text
    assert patched.json()["name"] == "Кабинет №7 (новый)"


def test_inactive_cabinet_hidden_by_default(client, auth):
    branch = _branch_id(client, auth)
    cab = client.post(f"{API}/cabinets", headers=auth,
                      json={"branch_id": branch, "name": "Кабинет временный"}).json()
    client.patch(f"{API}/cabinets/{cab['id']}", headers=auth, json={"is_active": False})
    active = client.get(f"{API}/cabinets", headers=auth, params={"branch_id": branch}).json()
    assert all(c["id"] != cab["id"] for c in active)
    allc = client.get(f"{API}/cabinets", headers=auth,
                      params={"branch_id": branch, "include_inactive": True}).json()
    assert any(c["id"] == cab["id"] for c in allc)
