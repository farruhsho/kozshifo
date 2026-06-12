"""EMR eye exam (Form 025-8): upsert semantics, validation, RBAC, history, PDF."""
from __future__ import annotations

from tests.conftest import API

_EXAM_PAYLOAD = {
    "exam_date": "2026-06-12",
    "complaints": "Снижение зрения вдаль",
    "anamnesis": "Миопия с детства",
    "od_va": "0.6", "od_sph": "-1.25", "od_cyl": "-0.50", "od_axis": 170, "od_va_cc": "1.0",
    "os_va": "0.7", "os_sph": "-1.00", "os_cyl": "-0.25", "os_axis": 10, "os_va_cc": "1.0",
    "iop_od": "16.0", "iop_os": "17.0",
    "cornea": "прозрачная", "lens": "прозрачный",
    "fundus": "ДЗН бледно-розовый, границы чёткие",
    "diagnosis": "Миопия слабой степени OU",
    "icd10": "H52.1",
    "recommendations": "очковая коррекция",
}


def _make_visit(client, auth, *, last_name="Экзамен", first_name="Тест") -> tuple[str, str]:
    """Returns (patient_id, visit_id) created by the director."""
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": first_name, "last_name": last_name, "branch_id": branch_id,
              "workplace": "Школа №12", "dispensary_here": "Уч. №3"},
    ).json()
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id},
    ).json()
    return patient["id"], visit["id"]


def test_upsert_creates_then_updates_exam(client, auth):
    _, visit_id = _make_visit(client, auth)

    created = client.put(f"{API}/visits/{visit_id}/exam", headers=auth, json=_EXAM_PAYLOAD)
    assert created.status_code == 200, created.text
    body = created.json()
    assert body["visit_id"] == visit_id
    assert body["od_sph"] == "-1.25"
    assert body["od_axis"] == 170
    assert body["iop_os"] == "17.0"
    assert body["diagnosis"] == "Миопия слабой степени OU"
    assert body["doctor_id"]  # defaulted to the current user
    exam_id = body["id"]

    updated = client.put(
        f"{API}/visits/{visit_id}/exam", headers=auth,
        json={"diagnosis": "Миопия средней степени OU", "od_sph": "-2.75"},
    )
    assert updated.status_code == 200, updated.text
    body2 = updated.json()
    assert body2["id"] == exam_id  # updated in place, not a second exam
    assert body2["diagnosis"] == "Миопия средней степени OU"
    assert body2["od_sph"] == "-2.75"
    assert body2["complaints"] == _EXAM_PAYLOAD["complaints"]  # untouched fields survive

    fetched = client.get(f"{API}/visits/{visit_id}/exam", headers=auth).json()
    assert fetched["id"] == exam_id


def test_exam_404_for_missing_visit_or_exam(client, auth):
    missing = "00000000-0000-0000-0000-000000000000"
    assert client.put(f"{API}/visits/{missing}/exam", headers=auth, json={}).status_code == 404

    _, visit_id = _make_visit(client, auth, last_name="БезОсмотра")
    assert client.get(f"{API}/visits/{visit_id}/exam", headers=auth).status_code == 404


def test_axis_out_of_range_rejected(client, auth):
    _, visit_id = _make_visit(client, auth, last_name="Валидация")
    resp = client.put(f"{API}/visits/{visit_id}/exam", headers=auth, json={"od_axis": 200})
    assert resp.status_code == 422
    resp = client.put(f"{API}/visits/{visit_id}/exam", headers=auth, json={"os_sph": "-45.00"})
    assert resp.status_code == 422


def test_exam_requires_permission(client, auth):
    _, visit_id = _make_visit(client, auth, last_name="Доступ")

    for email, role, expected in (
        ("emr.cashier@kozshifo.uz", "Cashier", 403),
        ("emr.doctor@kozshifo.uz", "Doctor", 200),
    ):
        created = client.post(
            f"{API}/users", headers=auth,
            json={"email": email, "full_name": f"EMR {role}", "password": "Emr!2026",
                  "role_names": [role]},
        )
        assert created.status_code == 201, created.text
        token = client.post(
            f"{API}/auth/login", data={"username": email, "password": "Emr!2026"}
        ).json()["access_token"]
        resp = client.put(
            f"{API}/visits/{visit_id}/exam",
            headers={"Authorization": f"Bearer {token}"},
            json={"complaints": "тест"},
        )
        assert resp.status_code == expected, resp.text
        if expected == 403:
            assert "exams.write" in resp.json()["detail"]


def test_patient_exam_history_orders_newest_first(client, auth):
    patient_id, visit1 = _make_visit(client, auth, last_name="История")
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    visit2 = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient_id, "branch_id": branch_id},
    ).json()["id"]

    client.put(f"{API}/visits/{visit1}/exam", headers=auth,
               json={"exam_date": "2026-06-01", "diagnosis": "старый осмотр"})
    client.put(f"{API}/visits/{visit2}/exam", headers=auth,
               json={"exam_date": "2026-06-12", "diagnosis": "новый осмотр"})

    history = client.get(f"{API}/patients/{patient_id}/exams", headers=auth).json()
    assert len(history) == 2
    assert history[0]["exam_date"] == "2026-06-12"
    assert history[1]["exam_date"] == "2026-06-01"


def test_card_pdf_returns_pdf(client, auth):
    _, visit_id = _make_visit(client, auth, last_name="Печать")
    client.put(f"{API}/visits/{visit_id}/exam", headers=auth, json=_EXAM_PAYLOAD)

    resp = client.get(f"{API}/visits/{visit_id}/exam/card.pdf", headers=auth)
    assert resp.status_code == 200, resp.text
    assert resp.headers["content-type"].startswith("application/pdf")
    assert len(resp.content) > 1000
    assert resp.content[:5] == b"%PDF-"
