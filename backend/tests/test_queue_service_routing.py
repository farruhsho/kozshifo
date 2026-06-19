"""Ф3b: a paid visit's doctor (V-) ticket auto-routes to the service's single
eligible doctor and lands in that doctor's cabinet; call-next defaults the room
to the caller's own cabinet (so a doctor's «Моя очередь» needn't repeat it).
"""
from __future__ import annotations

from tests.conftest import API

PWD = "Svc!2026"


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _make_doctor(client, auth, branch_id, slug, cabinet) -> str:
    resp = client.post(
        f"{API}/users", headers=auth,
        json={
            "email": f"svc.{slug}@kozshifo.uz",
            "full_name": f"Доктор {slug}",
            "password": PWD,
            "role_names": ["Doctor"],
            "branch_id": branch_id,
            "cabinet": cabinet,
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


def _make_service(client, auth, code, doctor_ids) -> str:
    resp = client.post(
        f"{API}/services", headers=auth,
        json={"code": code, "name": f"Услуга {code}", "price": "150000",
              "doctor_ids": doctor_ids},
    )
    assert resp.status_code in (200, 201), resp.text
    return resp.json()["id"]


def _doctor_ticket_for(client, auth, branch_id, service_id, last_name) -> dict:
    """Register + open a visit on `service_id` + pay + complete diagnostics ->
    return the auto-issued waiting V (doctor) ticket for the visit."""
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Услуга", "last_name": last_name, "branch_id": branch_id},
    ).json()
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": service_id, "quantity": 1}]},
    ).json()
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert paid.status_code == 201, paid.text
    drows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch_id, "track": "diagnostic"}).json()
    [d] = [t for t in drows if t["visit_id"] == visit["id"]]
    assert client.post(f"{API}/queue/{d['id']}/call", headers=auth,
                       json={"room": "Каб. Д"}).status_code == 200
    assert client.post(f"{API}/queue/{d['id']}/done", headers=auth).status_code == 200
    vrows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch_id, "track": "doctor"}).json()
    [v] = [t for t in vrows if t["visit_id"] == visit["id"]]
    return v


def _login(client, email) -> dict:
    resp = client.post(f"{API}/auth/login", data={"username": email, "password": PWD})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


def test_single_eligible_doctor_autoroutes_v_ticket_into_cabinet(client, auth):
    branch_id = _branch_id(client, auth)
    doc = _make_doctor(client, auth, branch_id, "solo", "Каб. 7")
    svc = _make_service(client, auth, "RT-SOLO", [doc])
    v = _doctor_ticket_for(client, auth, branch_id, svc, "Один")
    # Exactly one eligible doctor -> the V ticket is pre-routed to them and the
    # room is pre-filled with their cabinet (TV board shows it immediately).
    assert v["assigned_user_id"] == doc
    assert v["room"] == "Каб. 7"
    client.post(f"{API}/queue/{v['id']}/skip", headers=auth)  # cleanup


def test_no_eligible_doctor_open_pool_and_call_next_uses_caller_cabinet(client, auth):
    branch_id = _branch_id(client, auth)
    svc = _make_service(client, auth, "RT-OPEN", [])  # no eligible doctors -> open pool
    _make_doctor(client, auth, branch_id, "open", "Каб. 8")
    v = _doctor_ticket_for(client, auth, branch_id, svc, "Открытый")
    # No eligible doctor -> open pool, no pre-filled room.
    assert v["assigned_user_id"] is None
    assert v["room"] is None

    # Park other waiting doctor tickets so our doctor deterministically claims it.
    vrows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch_id, "track": "doctor"}).json()
    for t in vrows:
        if t["status"] == "waiting" and t["id"] != v["id"]:
            client.post(f"{API}/queue/{t['id']}/skip", headers=auth)

    # Calling WITHOUT a room -> the backend fills it from the caller's cabinet.
    c_auth = _login(client, "svc.open@kozshifo.uz")
    resp = client.post(f"{API}/queue/call-next", headers=c_auth,
                       json={"branch_id": branch_id, "track": "doctor"})
    assert resp.status_code == 200, resp.text
    assert resp.json()["id"] == v["id"]
    assert resp.json()["room"] == "Каб. 8"

    client.post(f"{API}/queue/{v['id']}/skip", headers=auth)  # cleanup


def test_multiple_doctors_load_balance_to_least_loaded(client, auth):
    branch_id = _branch_id(client, auth)
    doc_b = _make_doctor(client, auth, branch_id, "bal-b", "Каб. 8")
    doc_c = _make_doctor(client, auth, branch_id, "bal-c", "Каб. 9")
    svc = _make_service(client, auth, "RT-BAL", [doc_b, doc_c])
    # Both doctors start at 0 waiting -> tie broken by name (bal-b < bal-c).
    v1 = _doctor_ticket_for(client, auth, branch_id, svc, "Баланс1")
    assert v1["assigned_user_id"] == doc_b
    # doc_b now has 1 waiting, doc_c has 0 -> the next patient balances to doc_c.
    v2 = _doctor_ticket_for(client, auth, branch_id, svc, "Баланс2")
    assert v2["assigned_user_id"] == doc_c
    for v in (v1, v2):
        client.post(f"{API}/queue/{v['id']}/skip", headers=auth)  # cleanup


def test_doctor_role_now_has_queue_manage(client, auth):
    """The Doctor template gained queue.manage (runs their own queue)."""
    branch_id = _branch_id(client, auth)
    doc = _make_doctor(client, auth, branch_id, "perm", "Каб. 5")
    d_auth = _login(client, "svc.perm@kozshifo.uz")
    # call-next with nothing waiting is a 404 (NOT 403) -> the permission passed.
    resp = client.post(f"{API}/queue/call-next", headers=d_auth,
                       json={"branch_id": branch_id, "track": "doctor",
                             "for_user_id": doc})
    assert resp.status_code in (200, 404), resp.text
