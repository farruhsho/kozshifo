"""Foundation Ф1: a doctor's cabinet + the doctor↔service M2M.

The director sets a doctor's cabinet and the services they provide; reception
sets a service's eligible doctors. The cabinet is the queue's routing target,
so it lives on the doctor (never picked at payment time).
"""
from __future__ import annotations

import uuid

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _make_service(client, auth, code, name, **extra) -> dict:
    resp = client.post(
        f"{API}/services", headers=auth,
        json={"code": code, "name": name, "price": "100000.00", **extra},
    )
    assert resp.status_code == 201, resp.text
    return resp.json()


def test_doctor_carries_cabinet_and_services(client, auth):
    branch_id = _branch_id(client, auth)
    svc = _make_service(client, auth, "DSVC-1", "Консультация офтальмолога")

    resp = client.post(f"{API}/users", headers=auth, json={
        "email": "doc.cabinet@kozshifo.uz",
        "full_name": "Доктор Кабинетов",
        "password": "Doctor!2026",
        "branch_id": branch_id,
        "cabinet": "Каб. 1",
        "service_ids": [svc["id"]],
    })
    assert resp.status_code == 201, resp.text
    doc = resp.json()
    assert doc["cabinet"] == "Каб. 1"
    assert [s["id"] for s in doc["services"]] == [svc["id"]]
    assert doc["services"][0]["code"] == "DSVC-1"

    # Clearing the doctor's services via PATCH empties the M2M.
    patched = client.patch(f"{API}/users/{doc['id']}", headers=auth,
                           json={"service_ids": []})
    assert patched.status_code == 200, patched.text
    assert patched.json()["services"] == []


def test_service_carries_eligible_doctors_with_cabinet(client, auth):
    branch_id = _branch_id(client, auth)
    doc = client.post(f"{API}/users", headers=auth, json={
        "email": "doc.eligible@kozshifo.uz",
        "full_name": "Доктор Услугин",
        "password": "Doctor!2026",
        "branch_id": branch_id,
        "cabinet": "Офтальмолог",
    }).json()

    # Reception creates a service and picks the eligible doctor(s).
    svc = _make_service(client, auth, "DSVC-2", "ОКТ макулы", doctor_ids=[doc["id"]])
    assert len(svc["doctors"]) == 1
    assert svc["doctors"][0]["id"] == doc["id"]
    assert svc["doctors"][0]["cabinet"] == "Офтальмолог"

    # The doctor now lists the service from their side too (M2M is bidirectional).
    me = client.get(f"{API}/users/{doc['id']}", headers=auth).json()
    assert "DSVC-2" in [s["code"] for s in me["services"]]

    # Re-route the service to the open pool (no specific doctor).
    patched = client.patch(f"{API}/services/{svc['id']}", headers=auth,
                           json={"doctor_ids": []})
    assert patched.status_code == 200, patched.text
    assert patched.json()["doctors"] == []


def test_unknown_service_id_is_rejected(client, auth):
    branch_id = _branch_id(client, auth)
    resp = client.post(f"{API}/users", headers=auth, json={
        "email": "doc.badsvc@kozshifo.uz",
        "full_name": "Доктор Ошибкин",
        "password": "Doctor!2026",
        "branch_id": branch_id,
        "service_ids": [str(uuid.uuid4())],
    })
    assert resp.status_code == 422, resp.text


def test_assignable_doctors_listed_for_reception_without_users_read(client, auth):
    """The service-form doctor picker must work for RECEPTION (services.read,
    no users.read): GET /services/assignable-doctors is the dedicated source."""
    branch_id = _branch_id(client, auth)
    client.post(f"{API}/users", headers=auth, json={
        "email": "doc.assignable@kozshifo.uz",
        "full_name": "Доктор Списочный",
        "password": "Doctor!2026",
        "branch_id": branch_id,
        "cabinet": "Каб. 7",
    })
    rec = client.post(f"{API}/users", headers=auth, json={
        "email": "rec.assignable@kozshifo.uz",
        "full_name": "Админ Тест",
        "password": "Reception!2026",
        "branch_id": branch_id,
        "role_names": ["Administrator"],
    })
    assert rec.status_code == 201, rec.text
    rec_token = client.post(f"{API}/auth/login", data={
        "username": "rec.assignable@kozshifo.uz",
        "password": "Reception!2026",
    }).json()["access_token"]
    rec_auth = {"Authorization": f"Bearer {rec_token}"}

    # The administrator CAN list assignable doctors...
    resp = client.get(f"{API}/services/assignable-doctors", headers=rec_auth)
    assert resp.status_code == 200, resp.text
    mine = [r for r in resp.json() if r["full_name"] == "Доктор Списочный"]
    assert mine and mine[0]["cabinet"] == "Каб. 7"
    assert mine[0]["is_active"] is True
    # ...even though the administrator genuinely lacks users.read (owner-only).
    assert client.get(f"{API}/users", headers=rec_auth).status_code == 403
