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


def _reg_auth(client, auth, *, email: str, role: str) -> dict[str, str]:
    created = client.post(f"{API}/users", headers=auth, json={
        "email": email, "full_name": f"Отвязка {role}",
        "password": "Unlink!2026", "role_names": [role]})
    assert created.status_code == 201, created.text
    token = client.post(f"{API}/auth/login",
                        data={"username": email, "password": "Unlink!2026"}).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_unlink_wrong_link_then_relink_to_correct_visit(client, auth):
    """Medical safety: a result attached to the WRONG visit is detached (becomes an
    orphan again) and re-linked to the CORRECT visit."""
    branch = _branch(client, auth)
    rmk = _rmk(client, auth)
    wrong = _visit(client, auth, branch, "Ошибочный")

    # Orphan → linked to the WRONG visit.
    posted = client.post(f"{API}/devices/{rmk['id']}/results", headers=auth,
                         json={"result_type": "refraction", "payload": _REFRACTION})
    rid = posted.json()["id"]
    linked = client.post(f"{API}/device-results/{rid}/link", headers=auth,
                         json={"visit_id": wrong["id"]})
    assert linked.status_code == 200, linked.text
    assert linked.json()["visit_id"] == wrong["id"]

    # Unlink → orphan again (visit/patient cleared), re-appears in the unlinked list.
    unlinked = client.post(f"{API}/device-results/{rid}/unlink", headers=auth)
    assert unlinked.status_code == 200, unlinked.text
    assert unlinked.json()["visit_id"] is None
    assert unlinked.json()["patient_id"] is None
    orphans = client.get(f"{API}/device-results/unlinked", headers=auth).json()
    assert any(r["id"] == rid for r in orphans)
    wrong_results = client.get(f"{API}/visits/{wrong['id']}/device-results", headers=auth).json()
    assert all(r["id"] != rid for r in wrong_results)

    # Now link to the CORRECT visit — inherits its patient.
    correct = _visit(client, auth, branch, "Правильный")
    relinked = client.post(f"{API}/device-results/{rid}/link", headers=auth,
                          json={"visit_id": correct["id"]})
    assert relinked.status_code == 200, relinked.text
    assert relinked.json()["visit_id"] == correct["id"]
    assert relinked.json()["patient_id"] == correct["patient_id"]


def test_cannot_unlink_an_orphan(client, auth):
    rmk = _rmk(client, auth)
    posted = client.post(f"{API}/devices/{rmk['id']}/results", headers=auth,
                         json={"result_type": "refraction", "payload": _REFRACTION})
    rid = posted.json()["id"]
    resp = client.post(f"{API}/device-results/{rid}/unlink", headers=auth)
    assert resp.status_code == 409, resp.text
    assert "not linked" in resp.json()["detail"].lower()


def test_unlink_missing_result_404(client, auth):
    resp = client.post(f"{API}/device-results/00000000-0000-0000-0000-000000000000/unlink",
                       headers=auth)
    assert resp.status_code == 404, resp.text


def test_unlink_requires_device_results_create(client, auth):
    branch = _branch(client, auth)
    rmk = _rmk(client, auth)
    visit = _visit(client, auth, branch, "РБАК")
    posted = client.post(f"{API}/devices/{rmk['id']}/results", headers=auth,
                         json={"result_type": "refraction", "payload": _REFRACTION,
                               "visit_id": visit["id"]})
    rid = posted.json()["id"]
    # Administrator lacks device_results.create → 403.
    admin = _reg_auth(client, auth, email="unlink.admin@kozshifo.uz", role="Administrator")
    denied = client.post(f"{API}/device-results/{rid}/unlink", headers=admin)
    assert denied.status_code == 403, denied.text


def test_uploaded_file_exposes_original_name(client, auth):
    """The orphan-linking picker needs to see WHAT a file result is, not its stored UUID."""
    cas = next(d for d in client.get(f"{API}/devices", headers=auth).json()["items"]
               if d["serial_no"] == "53789467")
    posted = client.post(f"{API}/devices/{cas['id']}/results/file", headers=auth,
                         files={"file": ("bscan-od.png", b"\x89PNG\r\n", "image/png")})
    assert posted.status_code == 201, posted.text
    assert posted.json()["original_name"] == "bscan-od.png"
