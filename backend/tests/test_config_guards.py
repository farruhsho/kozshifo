"""Production fail-fast guards: repo-public secrets must never boot production.

The guards are FAIL-CLOSED: any ENVIRONMENT outside the explicit dev allow-list
(development/dev/local/test/testing, after strip().lower() normalization) is
treated as production — "prod", "staging" or a typo must not silently disable
the checks.
"""
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
                 seed_director_password="Unique#2026!", seed_demo_staff=False)
    assert s.environment == "production"


def test_development_keeps_convenient_defaults():
    s = Settings(environment="development")
    assert s.secret_key  # dev defaults stay permissive for zero-setup runs


# ── Fail-closed environment matching ─────────────────────────────────────────

@pytest.mark.parametrize("env", ["prod", "Production ", "PRODUCTION", "staging",
                                 "Staging", "produktion", "live", "qa"])
def test_non_dev_environment_names_are_guarded(env):
    # Aliases, case/whitespace variants, typos, unknown names → all fail closed.
    with pytest.raises(ValidationError, match="SECRET_KEY"):
        Settings(environment=env,
                 secret_key="dev-insecure-change-me-please-0123456789abcdef",
                 seed_director_password="Unique#2026!", seed_demo_staff=False)


@pytest.mark.parametrize("env", ["development", "dev", "local", "test",
                                 "testing", "Development", " DEV "])
def test_dev_environment_names_keep_defaults(env):
    s = Settings(environment=env)  # repo defaults boot fine in dev-only envs
    assert s.secret_key
    assert s.seed_demo_staff is True


def test_environment_is_normalized():
    s = Settings(environment=" Production ", secret_key=_STRONG_KEY,
                 seed_director_password="Unique#2026!", seed_demo_staff=False)
    assert s.environment == "production"
    assert Settings(environment="DEV").environment == "dev"


def test_staging_requires_real_secrets():
    # staging is NOT a free pass — same bar as production.
    with pytest.raises(ValidationError, match="SEED_DIRECTOR_PASSWORD"):
        Settings(environment="staging", secret_key=_STRONG_KEY,
                 seed_director_password="Director!2026", seed_demo_staff=False)
    s = Settings(environment="staging", secret_key=_STRONG_KEY,
                 seed_director_password="Unique#2026!", seed_demo_staff=False)
    assert s.environment == "staging"
