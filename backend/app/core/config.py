"""Application configuration via pydantic-settings (12-factor, env-driven)."""
from __future__ import annotations

from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    app_name: str = "KO'Z SHIFO API"
    environment: str = "development"
    debug: bool = True
    api_prefix: str = "/api/v1"

    # Security — placeholder is >=32 bytes so local dev runs warning-free.
    # Generate a real one for production: python -c "import secrets;print(secrets.token_urlsafe(48))"
    secret_key: str = "dev-insecure-change-me-please-0123456789abcdef"
    access_token_expire_minutes: int = 480
    refresh_token_expire_days: int = 30
    algorithm: str = "HS256"

    # Database — SQLite by default so the platform runs with zero external setup.
    database_url: str = "sqlite:///./kozshifo.db"

    # CORS
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8080", "http://localhost:5173"]

    # Seed
    seed_director_email: str = "director@kozshifo.uz"
    seed_director_password: str = "Director!2026"
    seed_on_startup: bool = True

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _split_origins(cls, v: object) -> object:
        if isinstance(v, str):
            return [o.strip() for o in v.split(",") if o.strip()]
        return v

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
