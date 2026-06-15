"""Lab referrals: refer / list / enter result / status state-machine.

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
        json={"first_name": "Лаб", "last_name": last, "branch_id": branch_id},
    ).json()["id"]


def _refer(client, auth, branch_id, pid, test="ОКТ макулы"):
    return client.post(f"{API}/lab", headers=auth, json={
        "branch_id": branch_id, "patient_id": pid, "test_name": test,
    })


def test_refer_and_list(client, auth):
    branch_id = _branch_id(client, auth)
    pid = _patient(client, auth, branch_id, "Первый")
    resp = _refer(client, auth, branch_id, pid)
    assert resp.status_code == 201, resp.text
    order = resp.json()
    assert order["order_no"].startswith("LAB-")
    assert order["status"] == "referred"
    assert order["result"] is None
    assert order["patient_name"]

    listed = client.get(f"{API}/lab", headers=auth, params={"branch_id": branch_id})
    assert listed.status_code == 200, listed.text
    assert any(o["id"] == order["id"] for o in listed.json())


def test_enter_result_moves_to_ready(client, auth):
    branch_id = _branch_id(client, auth)
    pid = _patient(client, auth, branch_id, "Результат")
    order = _refer(client, auth, branch_id, pid).json()

    resp = client.post(f"{API}/lab/{order['id']}/result", headers=auth,
                       json={"result": "Норма / без патологии"})
    assert resp.status_code == 200, resp.text
    assert resp.json()["status"] == "ready"
    assert resp.json()["result"] == "Норма / без патологии"


def test_status_state_machine(client, auth):
    branch_id = _branch_id(client, auth)
    pid = _patient(client, auth, branch_id, "Статус")
    order = _refer(client, auth, branch_id, pid).json()

    def setst(s):
        return client.post(f"{API}/lab/{order['id']}/status", headers=auth,
                           json={"status": s})

    assert setst("in_progress").status_code == 200
    assert setst("cancelled").status_code == 200
    # cancelled is terminal — cannot move to ready.
    assert setst("ready").status_code == 409


def test_unknown_patient_rejected(client, auth):
    branch_id = _branch_id(client, auth)
    resp = _refer(client, auth, branch_id, str(uuid.uuid4()))
    assert resp.status_code == 422, resp.text
