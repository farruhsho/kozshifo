"""TZ §7.1.5 — a visit accumulates MANY diagnoses (add / list / delete / RBAC),
and the per-doctor «frequent diagnoses» list aggregates from them."""
from __future__ import annotations

from tests.conftest import API


def _make_visit(client, auth, *, last_name="Диагноз") -> tuple[str, str]:
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": last_name, "branch_id": branch_id},
    ).json()
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id},
    ).json()
    return patient["id"], visit["id"]


def _doctor_token(client, auth, email="dx.doctor@kozshifo.uz") -> str:
    client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": "Dx Doctor", "password": "Dxtest!2026",
              "role_names": ["Doctor"]},
    )
    return client.post(
        f"{API}/auth/login", data={"username": email, "password": "Dxtest!2026"}
    ).json()["access_token"]


def test_add_list_delete_multiple_diagnoses(client, auth):
    _, visit_id = _make_visit(client, auth)

    d1 = client.post(f"{API}/visits/{visit_id}/diagnoses", headers=auth,
                     json={"diagnosis": "Катаракта OD", "icd10": "H25.0"})
    assert d1.status_code == 201, d1.text
    d2 = client.post(f"{API}/visits/{visit_id}/diagnoses", headers=auth,
                     json={"diagnosis": "Глаукома OS"})
    assert d2.status_code == 201, d2.text

    listed = client.get(f"{API}/visits/{visit_id}/diagnoses", headers=auth)
    assert listed.status_code == 200
    rows = listed.json()
    assert [r["diagnosis"] for r in rows] == ["Катаракта OD", "Глаукома OS"]  # created order
    assert rows[0]["icd10"] == "H25.0"
    assert rows[1]["icd10"] is None
    assert rows[0]["doctor_id"]  # author recorded

    deleted = client.delete(f"{API}/diagnoses/{rows[0]['id']}", headers=auth)
    assert deleted.status_code == 204
    remaining = client.get(f"{API}/visits/{visit_id}/diagnoses", headers=auth).json()
    assert [r["diagnosis"] for r in remaining] == ["Глаукома OS"]


def test_blank_diagnosis_rejected(client, auth):
    _, visit_id = _make_visit(client, auth, last_name="Пустой")
    resp = client.post(f"{API}/visits/{visit_id}/diagnoses", headers=auth,
                       json={"diagnosis": ""})
    assert resp.status_code == 422


def test_diagnoses_require_exams_write(client, auth):
    _, visit_id = _make_visit(client, auth, last_name="Доступ")
    # Cashier lacks exams.write → cannot add; lacks exams.read → cannot list.
    client.post(f"{API}/users", headers=auth,
                json={"email": "dx.cashier@kozshifo.uz", "full_name": "Dx Cashier",
                      "password": "Dxtest!2026", "role_names": ["Cashier"]})
    tok = client.post(f"{API}/auth/login",
                      data={"username": "dx.cashier@kozshifo.uz", "password": "Dxtest!2026"}
                      ).json()["access_token"]
    h = {"Authorization": f"Bearer {tok}"}
    assert client.post(f"{API}/visits/{visit_id}/diagnoses", headers=h,
                       json={"diagnosis": "X"}).status_code == 403
    assert client.get(f"{API}/visits/{visit_id}/diagnoses", headers=h).status_code == 403


def test_frequent_diagnoses_aggregates_per_doctor(client, auth):
    token = _doctor_token(client, auth, "freq.dx@kozshifo.uz")
    h = {"Authorization": f"Bearer {token}"}
    _, v1 = _make_visit(client, auth, last_name="Часто1")
    _, v2 = _make_visit(client, auth, last_name="Часто2")
    # Same diagnosis twice (2 visits) + a different one once.
    client.post(f"{API}/visits/{v1}/diagnoses", headers=h, json={"diagnosis": "Миопия"})
    client.post(f"{API}/visits/{v2}/diagnoses", headers=h, json={"diagnosis": "Миопия"})
    client.post(f"{API}/visits/{v1}/diagnoses", headers=h, json={"diagnosis": "Астигматизм"})

    freq = client.get(f"{API}/exams/frequent-diagnoses", headers=h).json()
    top = {r["diagnosis"]: r["count"] for r in freq}
    assert top.get("Миопия") == 2
    assert top.get("Астигматизм") == 1
    assert freq[0]["diagnosis"] == "Миопия"  # ordered by count desc


def test_card_pdf_lists_all_diagnoses(client, auth):
    _, visit_id = _make_visit(client, auth, last_name="ПечатьДиаг")
    client.put(f"{API}/visits/{visit_id}/exam", headers=auth,
               json={"complaints": "тест", "recommendations": "наблюдение"})
    client.post(f"{API}/visits/{visit_id}/diagnoses", headers=auth,
                json={"diagnosis": "Катаракта OD", "icd10": "H25.0"})
    client.post(f"{API}/visits/{visit_id}/diagnoses", headers=auth,
                json={"diagnosis": "Глаукома OS", "icd10": "H40.1"})

    resp = client.get(f"{API}/visits/{visit_id}/exam/card.pdf", headers=auth)
    assert resp.status_code == 200, resp.text
    assert resp.content[:5] == b"%PDF-"
    assert len(resp.content) > 1000
