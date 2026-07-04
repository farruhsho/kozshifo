"""Wave 1 security hardening: no demo god-account in production + admin password reset.

1. _production_guards must refuse to boot with SEED_DEMO_STAFF on in EVERY
   non-development environment (fail-closed: prod/staging/typos included) — the
   demo staff includes an is_superuser account with a repo-public password.
2. POST /users/{id}/set-password: the only post-creation password change, gated
   by users.update, audited WITHOUT the password itself.
3. Seed re-runs (every app restart) must never overwrite owner changes: a
   changed director password and a revoked superuser flag both survive restarts.
"""
from __future__ import annotations

import json

import pytest
from pydantic import ValidationError

from app.core.config import Settings
from tests.conftest import API

_STRONG_KEY = "k" * 48


# ── Production guard ──────────────────────────────────────────────────────────

def test_production_rejects_demo_staff_seed():
    with pytest.raises(ValidationError, match="SEED_DEMO_STAFF"):
        Settings(environment="production", secret_key=_STRONG_KEY,
                 seed_director_password="Unique#2026!", seed_demo_staff=True)


def test_production_boots_with_demo_staff_disabled():
    s = Settings(environment="production", secret_key=_STRONG_KEY,
                 seed_director_password="Unique#2026!", seed_demo_staff=False)
    assert s.seed_demo_staff is False


def test_development_allows_demo_staff_default():
    assert Settings(environment="development").seed_demo_staff is True


@pytest.mark.parametrize("env", ["prod", "Production ", "PRODUCTION", "staging"])
def test_non_dev_environment_names_reject_demo_staff_seed(env):
    # Fail-closed: aliases, case/whitespace variants and staging get the same
    # guard as the exact "production" string.
    with pytest.raises(ValidationError, match="SEED_DEMO_STAFF"):
        Settings(environment=env, secret_key=_STRONG_KEY,
                 seed_director_password="Unique#2026!", seed_demo_staff=True)


# ── POST /users/{id}/set-password ─────────────────────────────────────────────

def _create_user(client, auth, email: str, password: str, roles: list[str] | None = None) -> str:
    resp = client.post(f"{API}/users", headers=auth,
                       json={"email": email, "full_name": "Тест Сброс-Пароля",
                             "password": password, "role_names": roles or []})
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


def _login(client, email: str, password: str):
    return client.post(f"{API}/auth/login", data={"username": email, "password": password})


def test_set_password_happy_path(client, auth):
    old, new = "OldPass!2026", "NewPass!2026"
    uid = _create_user(client, auth, "pwreset.happy@kozshifo.uz", old)
    assert _login(client, "pwreset.happy@kozshifo.uz", old).status_code == 200

    resp = client.post(f"{API}/users/{uid}/set-password", headers=auth,
                       json={"password": new})
    assert resp.status_code == 204, resp.text

    assert _login(client, "pwreset.happy@kozshifo.uz", old).status_code == 401
    assert _login(client, "pwreset.happy@kozshifo.uz", new).status_code == 200


def test_set_password_rejects_short_password(client, auth):
    uid = _create_user(client, auth, "pwreset.short@kozshifo.uz", "OldPass!2026")
    resp = client.post(f"{API}/users/{uid}/set-password", headers=auth,
                       json={"password": "short7!"})
    assert resp.status_code == 422


def test_set_password_requires_users_update(client, auth):
    # A roleless user has no users.update → 403 (same gate as PATCH /users/{id}).
    _create_user(client, auth, "pwreset.noperm@kozshifo.uz", "NoPerm!2026")
    token = _login(client, "pwreset.noperm@kozshifo.uz", "NoPerm!2026").json()["access_token"]
    victim = _create_user(client, auth, "pwreset.victim@kozshifo.uz", "Victim!2026")

    denied = client.post(f"{API}/users/{victim}/set-password",
                         headers={"Authorization": f"Bearer {token}"},
                         json={"password": "Hacked!2026"})
    assert denied.status_code == 403
    assert "users.update" in denied.json()["detail"]
    # The victim's password is untouched.
    assert _login(client, "pwreset.victim@kozshifo.uz", "Victim!2026").status_code == 200


def test_set_password_is_audited_without_password(client, auth):
    new = "Audited!2026-Xy"
    uid = _create_user(client, auth, "pwreset.audit@kozshifo.uz", "OldPass!2026")
    resp = client.post(f"{API}/users/{uid}/set-password", headers=auth,
                       json={"password": new})
    assert resp.status_code == 204, resp.text

    logs = client.get(f"{API}/admin/audit-logs", headers=auth,
                      params={"action": "password_reset", "entity_type": "user",
                              "limit": 100})
    assert logs.status_code == 200, logs.text
    row = next((x for x in logs.json()["items"] if x["entity_id"] == uid), None)
    assert row is not None, "password reset must be in the audit trail"
    assert row["action"] == "password_reset"
    assert row["actor_email"]
    assert new not in json.dumps(row), "the audit row must never contain the password"

    # The audit row is metadata-only in the DB too — no password in changes/summary.
    from app.core.database import SessionLocal
    from app.models.audit import AuditLog
    from sqlalchemy import select
    db = SessionLocal()
    try:
        log = db.execute(
            select(AuditLog).where(AuditLog.action == "password_reset",
                                   AuditLog.entity_id == uid)
        ).scalars().first()
        assert log is not None
        assert new not in (log.summary or "")
        assert new not in json.dumps(log.changes or {})
    finally:
        db.close()


def test_set_password_unknown_user_404(client, auth):
    resp = client.post(f"{API}/users/00000000-0000-0000-0000-000000000000/set-password",
                       headers=auth, json={"password": "Whatever!2026"})
    assert resp.status_code == 404


# ── Seed re-runs must not overwrite owner changes ─────────────────────────────
# run_seed() executes on EVERY app startup — it must set passwords / superuser
# flags only when it CREATES an account, never on existing ones, or an owner's
# change silently reverts to repo-public values at the next restart.

def test_seed_rerun_preserves_changed_director_password(client, auth):
    from sqlalchemy import select, update

    from app.core.database import SessionLocal
    from app.models.user import User
    from app.seed import run_seed
    from tests.conftest import DIRECTOR_EMAIL, DIRECTOR_PASSWORD

    db = SessionLocal()
    try:
        director = db.execute(
            select(User).where(User.email == DIRECTOR_EMAIL)
        ).scalar_one()
        director_id = str(director.id)
        original_token_version = director.token_version
    finally:
        db.close()

    new = "OwnerChanged!2026-Zz"
    resp = client.post(f"{API}/users/{director_id}/set-password", headers=auth,
                       json={"password": new})
    assert resp.status_code == 204, resp.text
    try:
        run_seed()  # simulates an app restart
        # The repo-default password must NOT be silently restored…
        assert _login(client, DIRECTOR_EMAIL, DIRECTOR_PASSWORD).status_code == 401
        # …and the owner's password keeps working.
        assert _login(client, DIRECTOR_EMAIL, new).status_code == 200
    finally:
        # Restore the well-known test password AND the original token_version, so
        # the shared session-scoped director token (minted with the original
        # version) keeps validating for the rest of the suite — set-password bumps
        # token_version to revoke old sessions, which would otherwise 401 every
        # downstream test that reuses `director_auth`.
        restore = client.post(f"{API}/users/{director_id}/set-password", headers=auth,
                              json={"password": DIRECTOR_PASSWORD})
        assert restore.status_code == 204, restore.text
        db = SessionLocal()
        try:
            db.execute(
                update(User).where(User.email == DIRECTOR_EMAIL)
                .values(token_version=original_token_version)
            )
            db.commit()
        finally:
            db.close()
    assert _login(client, DIRECTOR_EMAIL, DIRECTOR_PASSWORD).status_code == 200


def test_seed_rerun_preserves_revoked_superuser_flag(client, auth):
    from sqlalchemy import select

    from app.core.database import SessionLocal
    from app.models.user import User
    from app.seed import run_seed
    from tests.conftest import SUPERADMIN_EMAIL

    def _set_flag(value: bool) -> None:
        db = SessionLocal()
        try:
            user = db.execute(
                select(User).where(User.email == SUPERADMIN_EMAIL)
            ).scalar_one()
            user.is_superuser = value
            db.commit()
        finally:
            db.close()

    def _get_flag() -> bool:
        db = SessionLocal()
        try:
            return db.execute(
                select(User.is_superuser).where(User.email == SUPERADMIN_EMAIL)
            ).scalar_one()
        finally:
            db.close()

    _set_flag(False)  # the owner revokes the demo god flag
    try:
        run_seed()  # a restart must NOT re-elevate the account
        assert _get_flag() is False
    finally:
        _set_flag(True)  # restore the fixture account for the rest of the session
