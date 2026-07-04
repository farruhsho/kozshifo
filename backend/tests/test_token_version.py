"""Token-version session revocation: an admin password reset kills every
previously-issued access/refresh token (a stolen refresh token dies at once)."""
from __future__ import annotations

import uuid

from tests.conftest import API

_OLD_PASSWORD = "OldPass!2026"
_NEW_PASSWORD = "NewPass!2026"


def _create_staff(client, auth) -> tuple[str, str]:
    email = f"revoke_{uuid.uuid4().hex[:8]}@kozshifo.uz"
    resp = client.post(
        f"{API}/users",
        headers=auth,
        json={"email": email, "full_name": "Revoke Target", "password": _OLD_PASSWORD},
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"], email


def _login(client, email: str, password: str):
    return client.post(f"{API}/auth/login", data={"username": email, "password": password})


def test_reset_revokes_old_refresh_and_access_tokens(client, auth):
    user_id, email = _create_staff(client, auth)

    # The staff member logs in — captures a valid access + refresh pair.
    pair = _login(client, email, _OLD_PASSWORD).json()
    access, refresh = pair["access_token"], pair["refresh_token"]

    # Both tokens work before the reset.
    assert client.get(f"{API}/auth/me",
                      headers={"Authorization": f"Bearer {access}"}).status_code == 200
    assert client.post(f"{API}/auth/refresh",
                       json={"refresh_token": refresh}).status_code == 200

    # Admin resets the password.
    reset = client.post(f"{API}/users/{user_id}/set-password", headers=auth,
                        json={"password": _NEW_PASSWORD})
    assert reset.status_code == 204, reset.text

    # The stolen refresh token is now dead — no new pair can be minted from it.
    assert client.post(f"{API}/auth/refresh",
                       json={"refresh_token": refresh}).status_code == 401

    # The old access token is likewise rejected on a protected endpoint.
    assert client.get(f"{API}/auth/me",
                      headers={"Authorization": f"Bearer {access}"}).status_code == 401


def test_fresh_token_after_reset_works_and_new_password_logs_in(client, auth):
    user_id, email = _create_staff(client, auth)
    _login(client, email, _OLD_PASSWORD)  # pre-reset session (now to be revoked)

    reset = client.post(f"{API}/users/{user_id}/set-password", headers=auth,
                        json={"password": _NEW_PASSWORD})
    assert reset.status_code == 204, reset.text

    # The old password no longer logs in; the new one does.
    assert _login(client, email, _OLD_PASSWORD).status_code == 401
    fresh = _login(client, email, _NEW_PASSWORD)
    assert fresh.status_code == 200, fresh.text

    # A token minted after the reset carries the bumped version and works.
    body = fresh.json()
    assert client.get(f"{API}/auth/me",
                      headers={"Authorization": f"Bearer {body['access_token']}"}).status_code == 200
    assert client.post(f"{API}/auth/refresh",
                       json={"refresh_token": body["refresh_token"]}).status_code == 200
