"""Binary device-result files: upload, download, validation, RBAC, traversal."""
from __future__ import annotations

import pytest

from tests.conftest import API

_PNG_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 128  # fake-but-recognizable PNG content
_CAS_SERIAL = "53789467"  # seeded CAS-2000BER A/B ultrasound


def _make_visit(client, auth, *, last_name="Файлы") -> tuple[str, str]:
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


def _login(client, auth, *, email: str, role: str) -> dict[str, str]:
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": f"Файлы {role}",
              "password": "Files!2026", "role_names": [role]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login", data={"username": email, "password": "Files!2026"}
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_upload_bscan_and_download_roundtrip(client, auth):
    patient_id, visit_id = _make_visit(client, auth, last_name="БСканФайл")
    cas = _device_by_serial(client, auth, _CAS_SERIAL)

    uploaded = client.post(
        f"{API}/devices/{cas['id']}/results/file", headers=auth,
        files={"file": ("bscan-od.png", _PNG_BYTES, "image/png")},
        data={"visit_id": visit_id},
    )
    assert uploaded.status_code == 201, uploaded.text
    result = uploaded.json()
    assert result["result_type"] == "bscan_image"  # inferred from .png
    assert result["patient_id"] == patient_id      # derived from the visit
    assert result["source"] == "import"
    assert result["payload"]["original_name"] == "bscan-od.png"
    assert result["payload"]["size"] == len(_PNG_BYTES)
    # Stored under a generated name — the client filename never becomes a path.
    assert result["file_path"]
    assert "bscan-od" not in result["file_path"]
    assert "/" not in result["file_path"] and "\\" not in result["file_path"]

    downloaded = client.get(f"{API}/device-results/{result['id']}/file", headers=auth)
    assert downloaded.status_code == 200, downloaded.text
    assert downloaded.content == _PNG_BYTES
    assert downloaded.headers["content-type"] == "image/png"
    assert "bscan-od.png" in downloaded.headers.get("content-disposition", "")


def test_upload_disallowed_extension_rejected(client, auth):
    cas = _device_by_serial(client, auth, _CAS_SERIAL)
    resp = client.post(
        f"{API}/devices/{cas['id']}/results/file", headers=auth,
        files={"file": ("malware.exe", b"MZ\x90\x00", "application/octet-stream")},
    )
    assert resp.status_code == 422
    assert "not allowed" in resp.json()["detail"]


def test_explicit_result_type_kept_and_validated(client, auth):
    cas = _device_by_serial(client, auth, _CAS_SERIAL)

    kept = client.post(
        f"{API}/devices/{cas['id']}/results/file", headers=auth,
        files={"file": ("axial-length.pdf", b"%PDF-1.4 fake", "application/pdf")},
        data={"result_type": "biometry"},
    )
    assert kept.status_code == 201, kept.text
    assert kept.json()["result_type"] == "biometry"

    # Refraction is numeric-payload only — not a valid upload type.
    bad = client.post(
        f"{API}/devices/{cas['id']}/results/file", headers=auth,
        files={"file": ("x.png", _PNG_BYTES, "image/png")},
        data={"result_type": "refraction"},
    )
    assert bad.status_code == 422


def test_upload_rbac(client, auth):
    cas = _device_by_serial(client, auth, _CAS_SERIAL)

    # Doctor has device_results.create → can upload.
    doc_auth = _login(client, auth, email="files.doctor@kozshifo.uz", role="Doctor")
    ok = client.post(
        f"{API}/devices/{cas['id']}/results/file", headers=doc_auth,
        files={"file": ("doc-bscan.jpg", b"\xff\xd8\xff fake jpeg", "image/jpeg")},
    )
    assert ok.status_code == 201, ok.text

    # Cashier lacks device_results.create → 403.
    cashier_auth = _login(client, auth, email="files.cashier@kozshifo.uz", role="Cashier")
    denied = client.post(
        f"{API}/devices/{cas['id']}/results/file", headers=cashier_auth,
        files={"file": ("cash-bscan.jpg", b"\xff\xd8\xff fake jpeg", "image/jpeg")},
    )
    assert denied.status_code == 403
    assert "device_results.create" in denied.json()["detail"]


def test_resolve_stored_rejects_traversal():
    from app.core.files import resolve_stored

    for evil in ("..\\evil", "../evil", "sub/dir.png", "sub\\dir.png",
                 "..", "C:evil.png", ""):
        with pytest.raises(ValueError):
            resolve_stored(evil)
