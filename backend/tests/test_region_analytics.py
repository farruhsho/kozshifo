"""Patient region capture + the director's patients-by-region marketing report."""
from __future__ import annotations

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _patient(client, auth, *, last_name, region=None, district=None) -> dict:
    return client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": last_name, "branch_id": _branch(client, auth),
              "region": region, "district": district},
    ).json()


def _visit(client, auth, patient_id) -> None:
    client.post(f"{API}/visits", headers=auth,
                json={"patient_id": patient_id, "branch_id": _branch(client, auth)})


def test_region_and_district_round_trip(client, auth):
    p = _patient(client, auth, last_name="Регион", region="Ферганская", district="Коканд")
    assert p["region"] == "Ферганская"
    assert p["district"] == "Коканд"


def test_patients_by_region_new_vs_returning(client, auth):
    # Test-unique region labels keep counts exact despite the shared session DB.
    # Зона-Альфа: one returning (2 visits) + one new (0 visits).
    ret = _patient(client, auth, last_name="ЗонаПовтор", region="Зона-Альфа", district="Риштан")
    _visit(client, auth, ret["id"])
    _visit(client, auth, ret["id"])
    _patient(client, auth, last_name="ЗонаНовый", region="Зона-Альфа")
    # Зона-Бета: one new (single visit).
    beta = _patient(client, auth, last_name="ЗонаБета", region="Зона-Бета")
    _visit(client, auth, beta["id"])
    # No region → folds into «Не указано».
    _patient(client, auth, last_name="БезРегиона")

    report = client.get(f"{API}/dashboard/patients-by-region", headers=auth)
    assert report.status_code == 200, report.text
    by_region = {r["region"]: r for r in report.json()["regions"]}

    assert by_region["Зона-Альфа"]["returning_count"] == 1
    assert by_region["Зона-Альфа"]["new_count"] == 1
    assert by_region["Зона-Альфа"]["total"] == 2
    assert by_region["Зона-Бета"]["new_count"] == 1
    assert by_region["Зона-Бета"]["returning_count"] == 0
    assert "Не указано" in by_region

    # Sorted by total desc, and the synthetic total adds up.
    totals = [r["total"] for r in report.json()["regions"]]
    assert totals == sorted(totals, reverse=True)
    assert report.json()["total"] == sum(totals)


def test_patients_by_region_requires_dashboard_view(client, auth):
    # A reception account lacks dashboard.view → 403.
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "region.reception@kozshifo.uz", "full_name": "Рег Ресепшен",
              "password": "Passw0rd!", "role_names": ["Reception"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "region.reception@kozshifo.uz", "password": "Passw0rd!"},
    ).json()["access_token"]
    denied = client.get(f"{API}/dashboard/patients-by-region",
                        headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
