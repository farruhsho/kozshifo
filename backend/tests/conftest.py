"""Pytest fixtures: isolated SQLite DB, app under test client, director auth.

Environment is set *before* importing the app so the engine binds to the test
database. The app's lifespan creates the schema and runs the idempotent seed.
"""
from __future__ import annotations

import os
import pathlib
import tempfile

import pytest

_DB_PATH = pathlib.Path(tempfile.gettempdir()) / "kozshifo_test.db"
os.environ["DATABASE_URL"] = f"sqlite:///{_DB_PATH.as_posix()}"
os.environ["SECRET_KEY"] = "test-secret-key"
os.environ["SEED_ON_STARTUP"] = "true"

API = "/api/v1"
DIRECTOR_EMAIL = "director@kozshifo.uz"
DIRECTOR_PASSWORD = "Director!2026"


@pytest.fixture(scope="session")
def client():
    from fastapi.testclient import TestClient

    if _DB_PATH.exists():
        _DB_PATH.unlink()
    from app.main import app

    with TestClient(app) as c:
        yield c
    if _DB_PATH.exists():
        try:
            _DB_PATH.unlink()
        except OSError:
            pass


@pytest.fixture(scope="session")
def director_token(client) -> str:
    resp = client.post(
        f"{API}/auth/login",
        data={"username": DIRECTOR_EMAIL, "password": DIRECTOR_PASSWORD},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]


@pytest.fixture
def auth(director_token) -> dict[str, str]:
    return {"Authorization": f"Bearer {director_token}"}
