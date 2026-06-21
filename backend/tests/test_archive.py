"""Super Admin → архив (owner brief 2026-06-20): auto-archive old finished records
by stamping archived_at; summary of archived vs archivable; RBAC (archive.manage)."""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def test_archive_old_completed_visit(client, auth):
    branch = _branch(client, auth)
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Архив", "last_name": "Тестов",
                                "phone": "+998900000005", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch,
                              "items": []}).json()
    assert client.post(f"{API}/visits/{visit['id']}/close", headers=auth).status_code == 200

    # Backdate it past the retention window (no API can set opened_at).
    from app.core.database import SessionLocal
    from app.models.visit import Visit
    db = SessionLocal()
    try:
        row = db.get(Visit, uuid.UUID(visit["id"]))
        row.opened_at = datetime.now(timezone.utc) - timedelta(days=400)
        db.commit()
    finally:
        db.close()

    summ = client.get(f"{API}/admin/archive", headers=auth,
                      params={"older_than_days": 365}).json()
    assert summ["visits"]["archivable"] >= 1
    for key in ("visits", "operations", "notifications"):
        assert {"archived", "archivable"} <= set(summ[key])

    run = client.post(f"{API}/admin/archive/run", headers=auth,
                      params={"older_than_days": 365}).json()
    assert run["visits"] >= 1

    db = SessionLocal()
    try:
        assert db.get(Visit, uuid.UUID(visit["id"])).archived_at is not None
    finally:
        db.close()

    summ2 = client.get(f"{API}/admin/archive", headers=auth,
                       params={"older_than_days": 365}).json()
    assert summ2["visits"]["archived"] >= 1


def test_archive_rbac(client, auth):
    client.post(f"{API}/users", headers=auth,
                json={"email": "arch.recep@kozshifo.uz", "full_name": "Рецепшн Архив",
                      "password": "Passw0rd!", "role_names": ["Reception"]})
    token = client.post(f"{API}/auth/login",
                        data={"username": "arch.recep@kozshifo.uz", "password": "Passw0rd!"}
                        ).json()["access_token"]
    h = {"Authorization": f"Bearer {token}"}
    assert client.get(f"{API}/admin/archive", headers=h).status_code == 403
    assert client.post(f"{API}/admin/archive/run", headers=h).status_code == 403
