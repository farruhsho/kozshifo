"""Phase 2 data model: patient primary doctor, queue prefix, external surgeon,
diagnosis catalog + per-user allowed diagnoses."""
from __future__ import annotations

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _make_user(client, auth, *, email, full_name, role="Doctor", **extra) -> dict:
    resp = client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": full_name, "password": "Passw0rd!",
              "role_names": [role], **extra},
    )
    assert resp.status_code == 201, resp.text
    return resp.json()


def _login(client, *, email, password="Passw0rd!") -> dict[str, str]:
    token = client.post(
        f"{API}/auth/login", data={"username": email, "password": password}
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_queue_prefix_defaults_from_name_and_override(client, auth):
    derived = _make_user(client, auth, email="prefix.derive@kozshifo.uz",
                         full_name="Сарвар Алиев")
    assert derived["queue_prefix"] == "С"  # first letter of the name

    explicit = _make_user(client, auth, email="prefix.explicit@kozshifo.uz",
                          full_name="Сардор Усмонов", queue_prefix="Сд")
    assert explicit["queue_prefix"] == "Сд"  # director override wins


def test_external_surgeon_flag(client, auth):
    surgeon = _make_user(client, auth, email="tashkent.surgeon@kozshifo.uz",
                         full_name="Хирург Ташкентский", is_external_surgeon=True)
    assert surgeon["is_external_surgeon"] is True


def test_diagnosis_catalog_and_rbac(client, auth):
    # Seeded catalog is non-empty (УЗИ conclusions).
    listed = client.get(f"{API}/diagnoses", headers=auth)
    assert listed.status_code == 200
    assert any(d["category"] == "УЗИ" for d in listed.json())

    # Director (diagnoses.manage) creates a new conclusion.
    created = client.post(
        f"{API}/diagnoses", headers=auth,
        json={"code": "UZI-CUSTOM", "name": "УЗИ: оболочечная киста", "category": "УЗИ"},
    )
    assert created.status_code == 201, created.text

    # A diagnostician can read but not manage the catalog.
    _make_user(client, auth, email="dx.reader@kozshifo.uz",
               full_name="Диагност Тест", role="Diagnost")
    dx = _login(client, email="dx.reader@kozshifo.uz")
    assert client.get(f"{API}/diagnoses", headers=dx).status_code == 200
    denied = client.post(
        f"{API}/diagnoses", headers=dx,
        json={"code": "X", "name": "X"},
    )
    assert denied.status_code == 403
    assert "diagnoses.manage" in denied.json()["detail"]


def test_user_allowed_diagnoses_assignment(client, auth):
    dx = next(d for d in client.get(f"{API}/diagnoses", headers=auth).json()
              if d["category"] == "УЗИ")
    user = _make_user(client, auth, email="dx.scoped@kozshifo.uz",
                      full_name="УЗИ Диагност", role="Diagnost",
                      diagnosis_ids=[dx["id"]])
    assert [d["id"] for d in user["diagnoses"]] == [dx["id"]]


def test_patient_primary_doctor_and_last_visit_fallback(client, auth):
    branch_id = _branch(client, auth)
    doc_a = _make_user(client, auth, email="doc.a@kozshifo.uz", full_name="Доктор Алишер")
    doc_b = _make_user(client, auth, email="doc.b@kozshifo.uz", full_name="Доктор Бобур")

    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": "Лечащий", "branch_id": branch_id,
              "primary_doctor_id": doc_a["id"]},
    ).json()
    assert patient["primary_doctor_id"] == doc_a["id"]
    assert patient["primary_doctor_name"] == "Доктор Алишер"

    # A visit handled by a different doctor populates the last-visit fallback.
    client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "doctor_id": doc_b["id"]},
    )
    summary = client.get(f"{API}/patients/{patient['id']}/summary", headers=auth).json()
    assert summary["primary_doctor_id"] == doc_a["id"]
    assert summary["last_visit_doctor_id"] == doc_b["id"]
    assert summary["last_visit_doctor_name"] == "Доктор Бобур"


def test_first_visit_doctor_becomes_primary(client, auth):
    """A patient with no лечащий врач: the first visit's doctor auto-becomes the
    primary doctor, so a returning patient routes back to «their» doctor."""
    branch_id = _branch(client, auth)
    doc = _make_user(client, auth, email="doc.first@kozshifo.uz",
                     full_name="Доктор Первый")

    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": "Безврача", "branch_id": branch_id},
    ).json()
    assert patient["primary_doctor_id"] is None

    client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "doctor_id": doc["id"]},
    )
    summary = client.get(f"{API}/patients/{patient['id']}/summary", headers=auth).json()
    assert summary["primary_doctor_id"] == doc["id"]
    assert summary["primary_doctor_name"] == "Доктор Первый"

    # A second visit by a DIFFERENT doctor must NOT overwrite the established
    # лечащий врач (only the empty→first transition auto-assigns).
    other = _make_user(client, auth, email="doc.second@kozshifo.uz",
                       full_name="Доктор Второй")
    client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "doctor_id": other["id"]},
    )
    summary2 = client.get(f"{API}/patients/{patient['id']}/summary", headers=auth).json()
    assert summary2["primary_doctor_id"] == doc["id"]


def test_unknown_primary_doctor_rejected(client, auth):
    branch_id = _branch(client, auth)
    resp = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": "Плохой", "branch_id": branch_id,
              "primary_doctor_id": "00000000-0000-0000-0000-000000000000"},
    )
    assert resp.status_code == 422
    assert "primary_doctor_id" in resp.json()["detail"]
