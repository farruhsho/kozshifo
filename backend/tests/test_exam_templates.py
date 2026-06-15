"""Exam-conclusion templates — a doctor saves and reuses назначения."""
from __future__ import annotations

from tests.conftest import API

_T = f"{API}/exam-templates"


def _login(client, email: str, password: str) -> dict[str, str]:
    r = client.post(f"{API}/auth/login", data={"username": email, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def test_save_list_reuse_and_delete(client, auth):
    doctor = _login(client, "vrach@kozshifo.uz", "Vrach!2026")

    made = client.post(_T, headers=doctor, json={
        "name": "Катаракта — стандарт",
        "diagnosis": "Возрастная катаракта OD",
        "icd10": "H25.0",
        "recommendations": "Факоэмульсификация с ИОЛ; контроль через 1 мес.",
    })
    assert made.status_code == 201, made.text
    tpl = made.json()
    assert tpl["name"] == "Катаракта — стандарт"
    assert tpl["icd10"] == "H25.0"

    # It appears in the doctor's list.
    listed = client.get(_T, headers=doctor).json()
    assert any(t["id"] == tpl["id"] for t in listed)

    # Saving the same name REPLACES (no duplicate).
    again = client.post(_T, headers=doctor, json={
        "name": "Катаракта — стандарт",
        "diagnosis": "Возрастная катаракта OS",
        "recommendations": "Наблюдение",
    })
    assert again.status_code == 201
    after = client.get(_T, headers=doctor).json()
    same_name = [t for t in after if t["name"] == "Катаракта — стандарт"]
    assert len(same_name) == 1
    assert same_name[0]["diagnosis"] == "Возрастная катаракта OS"

    # Owner deletes it.
    assert client.delete(f"{_T}/{tpl['id']}", headers=doctor).status_code == 200
    assert not any(t["id"] == tpl["id"] for t in client.get(_T, headers=doctor).json())


def test_empty_template_rejected(client, auth):
    doctor = _login(client, "vrach@kozshifo.uz", "Vrach!2026")
    r = client.post(_T, headers=doctor, json={"name": "Пустой"})
    assert r.status_code == 422


def test_templates_are_per_doctor_and_ownership_enforced(client, auth):
    doctor = _login(client, "vrach@kozshifo.uz", "Vrach!2026")
    mine = client.post(_T, headers=doctor, json={
        "name": "Глаукома", "recommendations": "Тимолол 0.5% 2р/д",
    }).json()

    # A second doctor sees their OWN list (not the first doctor's template)…
    other = client.post(f"{API}/users", headers=auth, json={
        "email": "vrach2.tpl@kozshifo.uz", "full_name": "Доктор Второй",
        "password": "Vrach!2026", "role_names": ["Doctor"],
    })
    assert other.status_code == 201, other.text
    other_h = _login(client, "vrach2.tpl@kozshifo.uz", "Vrach!2026")
    assert not any(t["id"] == mine["id"] for t in client.get(_T, headers=other_h).json())

    # …and cannot delete someone else's template (403).
    assert client.delete(f"{_T}/{mine['id']}", headers=other_h).status_code == 403
    # The director (superuser) can.
    assert client.delete(f"{_T}/{mine['id']}", headers=auth).status_code == 200


def test_templates_require_exams_write(client):
    # Reception has no exams.write → cannot list/save templates.
    reception = _login(client, "reception@kozshifo.uz", "Reception!2026")
    assert client.get(_T, headers=reception).status_code == 403
