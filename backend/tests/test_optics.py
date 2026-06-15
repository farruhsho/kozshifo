"""Optics salon: create / list / status state-machine / branch scope.

Additive feature — mirrors the appointments harness. `auth` is the director.
"""
from __future__ import annotations

import uuid

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _patient(client, auth, branch_id, last) -> str:
    return client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Оптика", "last_name": last, "branch_id": branch_id},
    ).json()["id"]


def _order(client, auth, branch_id, pid, **extra):
    body = {"branch_id": branch_id, "patient_id": pid, "kind": "glasses",
            "rx": "OD sph -2.5 / OS sph -2.0", "frame": "Ray-Ban RB5154",
            "price": "1290000.00"}
    body.update(extra)
    return client.post(f"{API}/optics", headers=auth, json=body)


def test_create_and_list(client, auth):
    branch_id = _branch_id(client, auth)
    pid = _patient(client, auth, branch_id, "Первый")
    resp = _order(client, auth, branch_id, pid)
    assert resp.status_code == 201, resp.text
    order = resp.json()
    assert order["order_no"].startswith("OPT-")
    assert order["status"] == "ordered"
    assert order["patient_name"]
    assert order["price"] == "1290000.00"

    listed = client.get(f"{API}/optics", headers=auth, params={"branch_id": branch_id})
    assert listed.status_code == 200, listed.text
    assert any(o["id"] == order["id"] for o in listed.json())

    # status filter
    ready = client.get(f"{API}/optics", headers=auth,
                       params={"branch_id": branch_id, "status": "ready"})
    assert all(o["status"] == "ready" for o in ready.json())


def test_status_state_machine(client, auth):
    branch_id = _branch_id(client, auth)
    pid = _patient(client, auth, branch_id, "Статус")
    order = _order(client, auth, branch_id, pid).json()

    def setst(s):
        return client.post(f"{API}/optics/{order['id']}/status", headers=auth,
                           json={"status": s})

    assert setst("in_progress").status_code == 200
    assert setst("ready").status_code == 200
    assert setst("issued").status_code == 200
    # issued is terminal — cannot cancel afterwards.
    assert setst("cancelled").status_code == 409


def test_unknown_patient_rejected(client, auth):
    branch_id = _branch_id(client, auth)
    resp = _order(client, auth, branch_id, str(uuid.uuid4()))
    assert resp.status_code == 422, resp.text
