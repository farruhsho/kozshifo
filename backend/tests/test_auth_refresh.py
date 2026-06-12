"""Refresh tokens: login issues a pair, /auth/refresh rotates it, misuse -> 401."""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

import jwt

from tests.conftest import API, DIRECTOR_EMAIL, DIRECTOR_PASSWORD


def _login(client) -> dict:
    resp = client.post(
        f"{API}/auth/login",
        data={"username": DIRECTOR_EMAIL, "password": DIRECTOR_PASSWORD},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()


def test_login_returns_access_and_refresh_pair(client):
    body = _login(client)
    assert body["access_token"]
    assert body["refresh_token"]
    assert body["token_type"] == "bearer"
    # The two tokens are distinct credentials with distinct claims.
    assert body["access_token"] != body["refresh_token"]


def test_refresh_rotates_and_new_access_works(client):
    original = _login(client)

    resp = client.post(f"{API}/auth/refresh", json={"refresh_token": original["refresh_token"]})
    assert resp.status_code == 200, resp.text
    pair = resp.json()

    # Rotation: a brand-new refresh token is issued (jti makes it unique).
    assert pair["refresh_token"] != original["refresh_token"]
    assert pair["access_token"]

    # The new access token is a working credential.
    me = client.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {pair['access_token']}"})
    assert me.status_code == 200, me.text
    assert me.json()["email"] == DIRECTOR_EMAIL

    # And the new refresh token can itself be exchanged again.
    again = client.post(f"{API}/auth/refresh", json={"refresh_token": pair["refresh_token"]})
    assert again.status_code == 200, again.text


def test_access_token_rejected_by_refresh_endpoint(client):
    body = _login(client)
    resp = client.post(f"{API}/auth/refresh", json={"refresh_token": body["access_token"]})
    assert resp.status_code == 401


def test_refresh_token_rejected_as_access_token(client):
    body = _login(client)
    resp = client.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {body['refresh_token']}"})
    assert resp.status_code == 401


def test_garbage_refresh_token_rejected(client):
    resp = client.post(f"{API}/auth/refresh", json={"refresh_token": "not-a-jwt-at-all"})
    assert resp.status_code == 401


def test_expired_refresh_token_rejected(client):
    from app.core.config import settings

    past = datetime.now(timezone.utc) - timedelta(days=1)
    expired = jwt.encode(
        {"sub": str(uuid.uuid4()), "iat": past - timedelta(days=30), "exp": past, "type": "refresh"},
        settings.secret_key,
        algorithm=settings.algorithm,
    )
    resp = client.post(f"{API}/auth/refresh", json={"refresh_token": expired})
    assert resp.status_code == 401


def test_refresh_token_for_unknown_user_rejected(client):
    from app.core.security import create_refresh_token

    resp = client.post(
        f"{API}/auth/refresh",
        json={"refresh_token": create_refresh_token(str(uuid.uuid4()))},
    )
    assert resp.status_code == 401
