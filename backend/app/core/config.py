"""Application configuration via pydantic-settings (12-factor, env-driven)."""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_DEV_SECRET_KEY = "dev-insecure-change-me-please-0123456789abcdef"
_DEV_DIRECTOR_PASSWORD = "Director!2026"
# backend/ — anchor file paths here so the SQLite DB / uploads are the SAME
# regardless of the process working directory (uvicorn from repo root vs backend,
# preview, scripts). A CWD-relative default silently opens a different, stale DB.
_BACKEND_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    app_name: str = "KO'Z SHIFO API"
    environment: str = "development"
    debug: bool = True
    api_prefix: str = "/api/v1"

    # Security — placeholder is >=32 bytes so local dev runs warning-free.
    # Generate a real one for production: python -c "import secrets;print(secrets.token_urlsafe(48))"
    secret_key: str = _DEV_SECRET_KEY
    access_token_expire_minutes: int = 480
    refresh_token_expire_days: int = 30
    algorithm: str = "HS256"

    # Database — SQLite by default so the platform runs with zero external setup.
    # Anchored to backend/ (not CWD) so every launcher opens the same file.
    database_url: str = f"sqlite:///{(_BACKEND_DIR / 'kozshifo.db').as_posix()}"

    # File storage for device-result binaries (B-scans etc.).
    # In the Docker image point this at the writable volume: /app/data/uploads.
    upload_dir: str = str(_BACKEND_DIR / "uploads")

    # Notifications — Telegram is optional; without a token events are only
    # logged to the notifications table.
    telegram_bot_token: str | None = None
    telegram_chat_id: str | None = None

    # Integration seams — shared-secret keys for unattended hardware.
    # Endpoints answer 503 while the key is unset (integration disabled).
    attendance_api_key: str | None = None  # Face ID terminal -> POST /attendance/punch
    pbx_api_key: str | None = None  # PBX/Asterisk -> POST /calls/ingest
    # Hikvision face terminal -> POST /access-control/event/{token}. The secret
    # lives in the push URL (the device can't set custom auth headers). Unset =
    # webhook answers 503 (integration disabled). See features/access_control.
    hikvision_event_token: str | None = None
    # Optional source-IP allowlist for the webhook (device LAN IPs). Empty =
    # accept any source that knows the token.
    hikvision_allowed_ips: list[str] = []
    # Workday start "HH:MM" (clinic local time) — first punch-in after this is "late".
    work_day_start: str = "09:00"

    # CORS — local dev ports only. In production the Firebase Hosting frontend
    # (kozshifo-prod, Blaze) reaches /api via same-origin rewrites to Cloud Run,
    # so no cross-origin Firebase entry is needed. Override with CORS_ORIGINS env
    # if a cross-origin client is ever added.
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8080", "http://localhost:5173"]

    # Seed
    seed_director_email: str = "director@kozshifo.uz"
    seed_director_password: str = _DEV_DIRECTOR_PASSWORD
    seed_on_startup: bool = True
    # Demo accounts (superadmin/vrach/reception/diagnost/kassa/sklad + the
    # director password) are (re)seeded to KNOWN values on every startup so the
    # one-click quick-login buttons always work — in any environment. Set
    # SEED_DEMO_STAFF=false for a hardened deploy (then the owner manages real
    # staff via /admin and only the director bootstrap account is created).
    seed_demo_staff: bool = True

    @field_validator("cors_origins", "hikvision_allowed_ips", mode="before")
    @classmethod
    def _split_csv(cls, v: object) -> object:
        if isinstance(v, str):
            return [o.strip() for o in v.split(",") if o.strip()]
        return v

    @field_validator("database_url", mode="before")
    @classmethod
    def _normalize_db_url(cls, v: object) -> object:
        """Pin managed-Postgres URLs to the installed driver (psycopg v3).

        Hosts like Railway/Render/Heroku inject ``postgres://`` or
        ``postgresql://`` — SQLAlchemy maps the bare scheme to psycopg2 (not
        installed), so connect fails. We ship psycopg3, so rewrite to the
        explicit ``+psycopg`` dialect. SQLite and already-qualified URLs pass
        through untouched.
        """
        if isinstance(v, str):
            if v.startswith("postgres://"):
                return "postgresql+psycopg://" + v[len("postgres://"):]
            if v.startswith("postgresql://"):
                return "postgresql+psycopg://" + v[len("postgresql://"):]
        return v

    @model_validator(mode="after")
    def _production_guards(self) -> "Settings":
        """Fail fast instead of running production with repo-public secrets.

        Both values are committed to the repository — running a JWT issuer or
        seeding an is_superuser account with them in production would let
        anyone who can read the repo forge tokens / log in as the owner.
        """
        if self.environment == "production":
            if self.secret_key == _DEV_SECRET_KEY or len(self.secret_key) < 32:
                raise ValueError(
                    "SECRET_KEY must be a unique value of at least 32 chars in production "
                    "(generate: python -c \"import secrets;print(secrets.token_urlsafe(48))\")"
                )
            if self.seed_on_startup and self.seed_director_password == _DEV_DIRECTOR_PASSWORD:
                raise ValueError(
                    "SEED_DIRECTOR_PASSWORD must be changed from the repo default in production"
                )
        return self

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
