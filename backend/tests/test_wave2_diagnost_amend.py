"""Wave 2 — медбезопасность: диагност может удалить/исправить ИМЕННО СВОЁ
недавнее заключение на визите под правом `diagnoses.record` (без exams.write),
но не может трогать чужие/врачебные заключения.

DELETE /visits/{visit_id}/diagnostic-conclusion/{id}:
  * автор своей записи → удаляет (204), запись исчезает, аудит `delete`;
  * чужую/врачебную запись → 404 (скрыта как «не найдена»);
  * завершённый визит → 409.
"""
from __future__ import annotations

from tests.conftest import API

PWD = "Amend!2026"


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _login(client, email) -> dict:
    t = client.post(f"{API}/auth/login",
                    data={"username": email, "password": PWD}).json()["access_token"]
    return {"Authorization": f"Bearer {t}"}


def _visit(client, auth, branch, last_name) -> str:
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Правка", "last_name": last_name,
                                "branch_id": branch}).json()
    return client.post(f"{API}/visits", headers=auth,
                       json={"patient_id": patient["id"], "branch_id": branch}).json()["id"]


def _make_diagnost(client, auth, branch, email, allowed_ids) -> dict:
    client.post(f"{API}/users", headers=auth,
                json={"email": email, "full_name": "Диагност Правка", "password": PWD,
                      "role_names": ["Diagnost"], "branch_id": branch,
                      "diagnosis_ids": allowed_ids})
    return _login(client, email)


def test_diagnostician_deletes_own_conclusion(client, auth):
    branch = _branch(client, auth)
    catalog = client.get(f"{API}/diagnoses", headers=auth).json()
    allowed = next(d for d in catalog if d["category"] == "УЗИ")

    dx = _make_diagnost(client, auth, branch, "amend.dx1@kozshifo.uz", [allowed["id"]])
    visit_id = _visit(client, auth, branch, "Свой")

    rec = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=dx,
                      json={"diagnosis_id": allowed["id"]})
    assert rec.status_code == 201, rec.text
    conclusion_id = rec.json()["id"]

    # Диагност удаляет СВОЮ запись под diagnoses.record (без exams.write) → 204.
    gone = client.delete(
        f"{API}/visits/{visit_id}/diagnostic-conclusion/{conclusion_id}", headers=dx)
    assert gone.status_code == 204, gone.text

    # Запись исчезла из списка визита.
    listed = client.get(f"{API}/visits/{visit_id}/diagnoses", headers=auth).json()
    assert all(d["id"] != conclusion_id for d in listed)

    # Аудит delete на visit_diagnosis есть.
    logs = client.get(f"{API}/admin/audit-logs", headers=auth,
                      params={"entity_type": "visit_diagnosis", "action": "delete",
                              "limit": 200}).json()
    assert any(x["entity_id"] == conclusion_id for x in logs["items"]), \
        "удаление заключения должно попасть в аудит"


def test_diagnostician_cannot_delete_others_conclusion(client, auth):
    branch = _branch(client, auth)
    catalog = client.get(f"{API}/diagnoses", headers=auth).json()
    allowed = next(d for d in catalog if d["category"] == "УЗИ")

    dx1 = _make_diagnost(client, auth, branch, "amend.dx.a@kozshifo.uz", [allowed["id"]])
    dx2 = _make_diagnost(client, auth, branch, "amend.dx.b@kozshifo.uz", [allowed["id"]])
    visit_id = _visit(client, auth, branch, "Чужой")

    rec = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=dx1,
                      json={"diagnosis_id": allowed["id"]})
    conclusion_id = rec.json()["id"]

    # Другой диагност НЕ может удалить чужую запись → 404 (скрыта).
    denied = client.delete(
        f"{API}/visits/{visit_id}/diagnostic-conclusion/{conclusion_id}", headers=dx2)
    assert denied.status_code == 404, denied.text

    # Запись всё ещё на месте.
    listed = client.get(f"{API}/visits/{visit_id}/diagnoses", headers=auth).json()
    assert any(d["id"] == conclusion_id for d in listed)


def test_diagnostician_cannot_delete_doctor_conclusion(client, auth):
    branch = _branch(client, auth)
    # Doctor (unrestricted) records a free-form conclusion.
    client.post(f"{API}/users", headers=auth,
                json={"email": "amend.doc@kozshifo.uz", "full_name": "Врач Правка",
                      "password": PWD, "role_names": ["Doctor"], "branch_id": branch})
    doc = _login(client, "amend.doc@kozshifo.uz")

    catalog = client.get(f"{API}/diagnoses", headers=auth).json()
    allowed = next(d for d in catalog if d["category"] == "УЗИ")
    dx = _make_diagnost(client, auth, branch, "amend.dx2@kozshifo.uz", [allowed["id"]])

    visit_id = _visit(client, auth, branch, "Врачебный")
    rec = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=doc,
                      json={"diagnosis": "Заключение врача"})
    conclusion_id = rec.json()["id"]

    # Диагност не может удалить врачебное заключение → 404.
    denied = client.delete(
        f"{API}/visits/{visit_id}/diagnostic-conclusion/{conclusion_id}", headers=dx)
    assert denied.status_code == 404, denied.text


def test_cannot_delete_conclusion_after_visit_completed(client, auth):
    branch = _branch(client, auth)
    catalog = client.get(f"{API}/diagnoses", headers=auth).json()
    allowed = next(d for d in catalog if d["category"] == "УЗИ")
    dx = _make_diagnost(client, auth, branch, "amend.dx3@kozshifo.uz", [allowed["id"]])

    visit_id = _visit(client, auth, branch, "Закрытый")
    rec = client.post(f"{API}/visits/{visit_id}/diagnostic-conclusion", headers=dx,
                      json={"diagnosis_id": allowed["id"]})
    conclusion_id = rec.json()["id"]

    # Close the visit via the till/reception path.
    closed = client.post(f"{API}/visits/{visit_id}/close", headers=auth)
    assert closed.status_code in (200, 204), closed.text

    denied = client.delete(
        f"{API}/visits/{visit_id}/diagnostic-conclusion/{conclusion_id}", headers=dx)
    assert denied.status_code == 409, denied.text
