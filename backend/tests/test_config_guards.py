"""Production fail-fast guards: repo-public secrets must never boot production."""
from __future__ import annotations

import pytest
from pydantic import ValidationError

from app.core.config import Settings

_STRONG_KEY = "k" * 48


def test_production_rejects_default_secret_key():
    with pytest.raises(ValidationError, match="SECRET_KEY"):
        Settings(environment="production",
                 secret_key="dev-insecure-change-me-please-0123456789abcdef",
                 seed_director_password="Unique#2026!")


def test_production_rejects_short_secret_key():
    with pytest.raises(ValidationError, match="SECRET_KEY"):
        Settings(environment="production", secret_key="too-short",
                 seed_director_password="Unique#2026!")


def test_production_rejects_default_director_password():
    with pytest.raises(ValidationError, match="SEED_DIRECTOR_PASSWORD"):
        Settings(environment="production", secret_key=_STRONG_KEY,
                 seed_director_password="Director!2026")


def test_production_boots_with_proper_secrets():
    s = Settings(environment="production", secret_key=_STRONG_KEY,
                 seed_director_password="Unique#2026!")
    assert s.environment == "production"


def test_development_keeps_convenient_defaults():
    s = Settings(environment="development")
    assert s.secret_key  # dev defaults stay permissive for zero-setup runs
