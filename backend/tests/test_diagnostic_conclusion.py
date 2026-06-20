"""Phase 4: a diagnostician records a conclusion (заключение) scoped to their
allowed diagnoses (user_diagnoses); GET /diagnoses/mine feeds the «Приём» picker."""
from __future__ import annotations

from tests.conftest import API

PWD = "Concl!2026"


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _login(client, email) -> dict:
    t = client.post(f"{API}/auth/login",
                    data={"username": email, "password": PWD}).json()["access_token"]
    return {"Authorization": f"Bearer {t}"}


def _visit(client, auth, branch, last_name) -> str:
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Закл", "last_name": last_name, "branch_id": branch}).json()
    return client.post(f"{API}/visits", headers=auth,
                       json={"patient_id": patient["id"], "branch_id": branch}).json()["id"]


def test_diagnostician_records_conclusion_from_allowed_list(client, auth):
    branch = _branch(client, auth)
    catalog = client.get(f"{API}/diagnoses", headers=auth).json()
    allowed = next(d for d in catalog if d["category"] == "УЗИ")
    other = next(d for d in catalog if d["id"] != allowed["id"])

    # A УЗИ diagnostician allowed ONLY `allowed`.
    client.post(f"{API}/users", headers=auth,
                json={"email": "concl.dx@kozshifo.uz", "full_name": "УЗИ Диагност",
                      "password": PWD, "role_names": ["Diagnost"], "branch_id": branch,
                      "diagnosis_ids": [allowed["id"]]})
    dx = _login(client, "concl.dx@kozshifo.uz")

    # The picker shows only their allowed list.
    mine = client.get(f"{API}/diagnoses/mine", headers=dx)
    assert mine.status_code == 200, mine.text
    assert [d["id"] for d in mine.json()] == [allowed["id"]]

    visit_id = _visit(client, auth, branch, "Разрешён")

    # Records the allowed conclusion → 201, stored under the catalog name.
    ok = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=dx,
                     json={"diagnosis_id": allowed["id"]})
    assert ok.status_code == 201, ok.text
    assert ok.json()["diagnosis"] == allowed["name"]

    # A diagnosis NOT in their allowed list → 403.
    denied = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=dx,
                         json={"diagnosis_id": other["id"]})
    assert denied.status_code == 403

    # A restricted user can't free-type — must pick from the list → 403.
    free = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=dx,
                       json={"diagnosis": "что-то своё"})
    assert free.status_code == 403

    # The conclusion shows on the visit's diagnoses list.
    listed = client.get(f"{API}/visits/{visit_id}/diagnoses", headers=auth).json()
    assert any(d["diagnosis"] == allowed["name"] for d in listed)


def test_unrestricted_user_may_free_type(client, auth):
    # A Doctor with no allowed-diagnoses restriction can type a conclusion freely.
    branch = _branch(client, auth)
    client.post(f"{API}/users", headers=auth,
                json={"email": "concl.doc@kozshifo.uz", "full_name": "Доктор Закл",
                      "password": PWD, "role_names": ["Doctor"], "branch_id": branch})
    doc = _login(client, "concl.doc@kozshifo.uz")
    visit_id = _visit(client, auth, branch, "Свободный")
    ok = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=doc,
                     json={"diagnosis": "Заключение врача", "icd10": "H25"})
    assert ok.status_code == 201, ok.text
    assert ok.json()["diagnosis"] == "Заключение врача"
    assert ok.json()["icd10"] == "H25"


def test_conclusion_requires_diagnoses_record_permission(client, auth):
    branch = _branch(client, auth)
    client.post(f"{API}/users", headers=auth,
                json={"email": "concl.cash@kozshifo.uz", "full_name": "Кассир Закл",
                      "password": PWD, "role_names": ["Administrator"], "branch_id": branch})
    cash = _login(client, "concl.cash@kozshifo.uz")
    visit_id = _visit(client, auth, branch, "Касса")
    denied = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=cash,
                         json={"diagnosis": "x"})
    assert denied.status_code == 403
    assert "diagnoses.record" in denied.json()["detail"]
