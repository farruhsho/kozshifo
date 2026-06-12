"""Devices: real-device seed, result ingestion, EMR hand-off, RBAC."""
from __future__ import annotations

from tests.conftest import API

_REFRACTION_PAYLOAD = {
    "od": {"sph": "-1.25", "cyl": "-0.50", "axis": 170},
    "os": {"sph": "-1.00", "cyl": "-0.25", "axis": 10},
}


def _make_visit(client, auth, *, last_name="Приборы") -> tuple[str, str]:
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


def _device_by_serial(client, auth, serial: str) -> dict:
    devices = client.get(f"{API}/devices", headers=auth).json()["items"]
    return next(d for d in devices if d["serial_no"] == serial)


def test_two_real_devices_seeded(client, auth):
    rmk = _device_by_serial(client, auth, "2103540749")
    assert rmk["model"] == "RMK-700"
    assert rmk["device_type"] == "refractometer"
    assert rmk["asset_code"] == "CP-RMK-700A00749"

    cas = _device_by_serial(client, auth, "53789467")
    assert cas["model"] == "CAS-2000BER"
    assert cas["device_type"] == "ab_ultrasound"
    assert cas["eu_rep"].startswith("LUXUS LEBENSWELT")


def test_post_refraction_result_and_apply_to_exam(client, auth):
    _, visit_id = _make_visit(client, auth, last_name="Рефракция")
    rmk = _device_by_serial(client, auth, "2103540749")

    posted = client.post(
        f"{API}/devices/{rmk['id']}/results", headers=auth,
        json={"result_type": "refraction", "payload": _REFRACTION_PAYLOAD, "visit_id": visit_id},
    )
    assert posted.status_code == 201, posted.text
    result = posted.json()
    assert result["patient_id"]  # derived from the visit

    applied = client.post(
        f"{API}/visits/{visit_id}/exam/apply-refraction",
        headers=auth, params={"result_id": result["id"]},
    )
    assert applied.status_code == 200, applied.text
    exam = applied.json()
    assert exam["od_sph"] == "-1.25"
    assert exam["od_cyl"] == "-0.50"
    assert exam["od_axis"] == 170
    assert exam["os_sph"] == "-1.00"
    assert exam["os_axis"] == 10

    # The result is listed under the visit.
    listed = client.get(f"{API}/visits/{visit_id}/device-results", headers=auth).json()
    assert any(r["id"] == result["id"] for r in listed)


def test_apply_non_refraction_result_rejected(client, auth):
    _, visit_id = _make_visit(client, auth, last_name="БСкан")
    cas = _device_by_serial(client, auth, "53789467")

    posted = client.post(
        f"{API}/devices/{cas['id']}/results", headers=auth,
        json={"result_type": "file", "file_path": "scans/bscan-001.jpg",
              "visit_id": visit_id, "source": "import"},
    )
    assert posted.status_code == 201, posted.text
    assert posted.json()["result_type"] == "bscan_image"  # inferred from extension

    resp = client.post(
        f"{API}/visits/{visit_id}/exam/apply-refraction",
        headers=auth, params={"result_id": posted.json()["id"]},
    )
    assert resp.status_code == 422
    assert "not a refraction" in resp.json()["detail"]


def test_malformed_refraction_payload_rejected(client, auth):
    rmk = _device_by_serial(client, auth, "2103540749")
    resp = client.post(
        f"{API}/devices/{rmk['id']}/results", headers=auth,
        json={"result_type": "refraction", "payload": {"od": {"sph": "-1.25", "axis": 999}}},
    )
    assert resp.status_code == 422


def test_devices_rbac(client, auth):
    # A Doctor can read devices but lacks devices.manage.
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "dev.doctor@kozshifo.uz", "full_name": "Доктор Приборов",
              "password": "Dev!2026", "role_names": ["Doctor"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login", data={"username": "dev.doctor@kozshifo.uz", "password": "Dev!2026"}
    ).json()["access_token"]
    doc_auth = {"Authorization": f"Bearer {token}"}

    assert client.get(f"{API}/devices", headers=doc_auth).status_code == 200

    denied = client.post(
        f"{API}/devices", headers=doc_auth,
        json={"name": "X", "serial_no": "SN-X-1", "device_type": "other"},
    )
    assert denied.status_code == 403
    assert "devices.manage" in denied.json()["detail"]

    rmk = _device_by_serial(client, auth, "2103540749")
    denied_patch = client.patch(
        f"{API}/devices/{rmk['id']}", headers=doc_auth, json={"status": "maintenance"}
    )
    assert denied_patch.status_code == 403

    # Director (superuser) can create and patch.
    created_dev = client.post(
        f"{API}/devices", headers=auth,
        json={"name": "Тестовый прибор", "serial_no": "SN-TEST-1", "device_type": "other"},
    )
    assert created_dev.status_code == 201, created_dev.text
    patched = client.patch(
        f"{API}/devices/{created_dev.json()['id']}", headers=auth, json={"status": "maintenance"}
    )
    assert patched.status_code == 200
    assert patched.json()["status"] == "maintenance"
