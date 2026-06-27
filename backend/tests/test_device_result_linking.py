"""Orphan device-result linking: a result that arrives WITHOUT a visit (the прибор
sent a measurement before the patient was matched, or it was posted with no patient)
is stored as an orphan and can be attached to the right visit later — no data loss."""
from __future__ import annotations

from tests.conftest import API

_REFRACTION = {
    "od": {"sph": "-1.25", "cyl": "-0.50", "axis": 170},
    "os": {"sph": "-1.00", "cyl": "-0.25", "axis": 10},
}


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _rmk(client, auth) -> dict:
    devices = client.get(f"{API}/devices", headers=auth).json()["items"]
    return next(d for d in devices if d["serial_no"] == "2103540749")


def _visit(client, auth, branch, last) -> dict:
    patient = client.post(f"{API}/patients", headers=auth, json={
        "first_name": "Прибор", "last_name": last, "branch_id": branch}).json()
    return client.post(f"{API}/visits", headers=auth, json={
        "patient_id": patient["id"], "branch_id": branch}).json()


def test_orphan_result_listed_and_linked(client, auth):
    branch = _branch(client, auth)
    rmk = _rmk(client, auth)

    # A result arrives with NO visit/patient → stored as an orphan (not rejected).
    posted = client.post(f"{API}/devices/{rmk['id']}/results", headers=auth,
                         json={"result_type": "refraction", "payload": _REFRACTION})
    assert posted.status_code == 201, posted.text
    rid = posted.json()["id"]
    assert posted.json()["visit_id"] is None
    assert posted.json()["patient_id"] is None

    # It shows up in the unlinked list.
    unlinked = client.get(f"{API}/device-results/unlinked", headers=auth).json()
    assert any(r["id"] == rid for r in unlinked)

    # Link it to a real visit → it inherits the visit's patient.
    visit = _visit(client, auth, branch, "Связь")
    linked = client.post(f"{API}/device-results/{rid}/link", headers=auth,
                         json={"visit_id": visit["id"]})
    assert linked.status_code == 200, linked.text
    assert linked.json()["visit_id"] == visit["id"]
    assert linked.json()["patient_id"] == visit["patient_id"]

    # No longer an orphan, and now visible under the visit's results.
    unlinked2 = client.get(f"{API}/device-results/unlinked", headers=auth).json()
    assert all(r["id"] != rid for r in unlinked2)
    vis_results = client.get(f"{API}/visits/{visit['id']}/device-results", headers=auth).json()
    assert any(r["id"] == rid for r in vis_results)


def test_cannot_relink_an_already_linked_result(client, auth):
    branch = _branch(client, auth)
    rmk = _rmk(client, auth)
    visit = _visit(client, auth, branch, "Занят")
    posted = client.post(f"{API}/devices/{rmk['id']}/results", headers=auth,
                         json={"result_type": "refraction", "payload": _REFRACTION,
                               "visit_id": visit["id"]})
    assert posted.status_code == 201, posted.text
    rid = posted.json()["id"]

    other = _visit(client, auth, branch, "Другой")
    relink = client.post(f"{API}/device-results/{rid}/link", headers=auth,
                         json={"visit_id": other["id"]})
    assert relink.status_code == 409, relink.text
    assert "already linked" in relink.json()["detail"].lower()
