"""Phase 4: the doctor chooses the surgeon at operation referral, and the surgeon
picker includes visiting/external (Tashkent) surgeons."""
from __future__ import annotations

from tests.conftest import API

PWD = "Surg!2026"


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _user(client, auth, *, email, full_name, role=None, is_external_surgeon=False) -> str:
    body = {"email": email, "full_name": full_name, "password": PWD,
            "role_names": [role] if role else [], "is_external_surgeon": is_external_surgeon}
    r = client.post(f"{API}/users", headers=auth, json=body)
    assert r.status_code == 201, r.text
    return r.json()["id"]


def test_surgeon_list_includes_external_and_referral_sets_surgeon(client, auth):
    branch = _branch(client, auth)
    ext = _user(client, auth, email="surg.ext@kozshifo.uz",
                full_name="Хирург Ташкентский", is_external_surgeon=True)
    doc = _user(client, auth, email="surg.doc@kozshifo.uz",
                full_name="Доктор Хирург", role="Doctor")  # Doctor → operations.perform

    surgeons = client.get(f"{API}/operations/surgeons", headers=auth)
    assert surgeons.status_code == 200, surgeons.text
    by_id = {s["id"]: s for s in surgeons.json()}
    assert ext in by_id          # visiting surgeon listed (no operations.perform needed)
    assert doc in by_id          # operations.perform listed
    assert by_id[ext]["is_external_surgeon"] is True

    # Refer an operation choosing the external surgeon.
    op_type = client.get(f"{API}/operation-types", headers=auth).json()[0]
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Опер", "last_name": "Хирург", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch}).json()
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": op_type["id"], "eye": "od", "surgeon_id": ext})
    assert op.status_code == 201, op.text
    assert op.json()["surgeon_id"] == ext
    assert op.json()["surgeon_name"] == "Хирург Ташкентский"


def test_referral_rejects_unknown_surgeon(client, auth):
    branch = _branch(client, auth)
    op_type = client.get(f"{API}/operation-types", headers=auth).json()[0]
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Опер", "last_name": "Плохой", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch}).json()
    bad = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                      json={"operation_type_id": op_type["id"],
                            "surgeon_id": "00000000-0000-0000-0000-000000000000"})
    assert bad.status_code == 422
    assert "surgeon" in bad.json()["detail"].lower()
