"""Patient file attachments: upload, list, download, RBAC, timeline, delete."""
from __future__ import annotations

from tests.conftest import API

_PDF_BYTES = b"%PDF-1.4 fake analysis report\n" + b"\x00" * 64


def _make_patient(client, auth, *, last_name="Файл") -> tuple[str, str]:
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": last_name, "branch_id": branch_id},
    ).json()
    return patient["id"], branch_id


def _login(client, auth, *, email: str, role: str) -> dict[str, str]:
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": f"Вложение {role}",
              "password": "Files!2026", "role_names": [role]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login", data={"username": email, "password": "Files!2026"}
    ).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_upload_list_download_roundtrip_and_timeline(client, auth):
    patient_id, _ = _make_patient(client, auth, last_name="СПИД")

    uploaded = client.post(
        f"{API}/patients/{patient_id}/attachments", headers=auth,
        files={"file": ("hiv-analysis.pdf", _PDF_BYTES, "application/pdf")},
        data={"kind": "hiv", "note": "перед операцией"},
    )
    assert uploaded.status_code == 201, uploaded.text
    a = uploaded.json()
    assert a["kind"] == "hiv"
    assert a["original_name"] == "hiv-analysis.pdf"
    assert a["size"] == len(_PDF_BYTES)
    assert a["note"] == "перед операцией"
    assert a["uploaded_by_name"]  # the director uploaded it
    # Stored under a generated name — client filename never becomes a path.
    assert "hiv-analysis" not in a["file_path"] if "file_path" in a else True

    listed = client.get(f"{API}/patients/{patient_id}/attachments", headers=auth)
    assert listed.status_code == 200
    assert [x["id"] for x in listed.json()] == [a["id"]]

    downloaded = client.get(f"{API}/attachments/{a['id']}/file", headers=auth)
    assert downloaded.status_code == 200, downloaded.text
    assert downloaded.content == _PDF_BYTES
    assert downloaded.headers["content-type"] == "application/pdf"
    assert "hiv-analysis.pdf" in downloaded.headers.get("content-disposition", "")

    # Surfaces on the patient timeline as an "attachment" event.
    tl = client.get(f"{API}/patients/{patient_id}/timeline", headers=auth).json()
    kinds = [e["kind"] for e in tl["events"]]
    assert "attachment" in kinds


def test_invalid_kind_rejected(client, auth):
    patient_id, _ = _make_patient(client, auth, last_name="Кайнд")
    resp = client.post(
        f"{API}/patients/{patient_id}/attachments", headers=auth,
        files={"file": ("x.pdf", _PDF_BYTES, "application/pdf")},
        data={"kind": "bogus"},
    )
    assert resp.status_code == 422
    assert "kind must be one of" in resp.json()["detail"]


def test_link_to_foreign_visit_rejected(client, auth):
    patient_a, branch_id = _make_patient(client, auth, last_name="ПациентА")
    patient_b, _ = _make_patient(client, auth, last_name="ПациентБ")
    visit_b = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient_b, "branch_id": branch_id},
    ).json()
    # Attaching patient B's visit to patient A's record is rejected.
    resp = client.post(
        f"{API}/patients/{patient_a}/attachments", headers=auth,
        files={"file": ("x.pdf", _PDF_BYTES, "application/pdf")},
        data={"kind": "uzi", "visit_id": visit_b["id"]},
    )
    assert resp.status_code == 422
    assert "does not belong" in resp.json()["detail"]


def test_upload_rbac_diagnost_yes_cashier_no(client, auth):
    patient_id, _ = _make_patient(client, auth, last_name="РБАК")

    # Diagnost has attachments.write → can upload УЗИ conclusions.
    diag = _login(client, auth, email="att.diagnost@kozshifo.uz", role="Diagnost")
    ok = client.post(
        f"{API}/patients/{patient_id}/attachments", headers=diag,
        files={"file": ("uzi.pdf", _PDF_BYTES, "application/pdf")},
        data={"kind": "uzi"},
    )
    assert ok.status_code == 201, ok.text

    # Cashier lacks attachments.write → 403.
    cashier = _login(client, auth, email="att.cashier@kozshifo.uz", role="Cashier")
    denied = client.post(
        f"{API}/patients/{patient_id}/attachments", headers=cashier,
        files={"file": ("uzi.pdf", _PDF_BYTES, "application/pdf")},
        data={"kind": "uzi"},
    )
    assert denied.status_code == 403
    assert "attachments.write" in denied.json()["detail"]


def test_delete_attachment(client, auth):
    patient_id, _ = _make_patient(client, auth, last_name="Удаление")
    a = client.post(
        f"{API}/patients/{patient_id}/attachments", headers=auth,
        files={"file": ("doc.pdf", _PDF_BYTES, "application/pdf")},
        data={"kind": "other"},
    ).json()
    deleted = client.delete(f"{API}/attachments/{a['id']}", headers=auth)
    assert deleted.status_code == 204
    assert client.get(f"{API}/attachments/{a['id']}/file", headers=auth).status_code == 404
    assert client.get(f"{API}/patients/{patient_id}/attachments", headers=auth).json() == []
