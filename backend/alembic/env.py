"""Alembic environment — wired to the application's settings and metadata.

The database URL is NOT stored in alembic.ini. It comes from the app's
pydantic-settings (``app.core.config.settings.database_url``), so the same
``DATABASE_URL`` environment variable / ``backend/.env`` file that drives the
FastAPI app also drives migrations: SQLite for local dev, Postgres in
production — no Alembic-specific configuration needed.

``render_as_batch`` is enabled on SQLite so future ALTER-style migrations
(add/drop/alter column) work despite SQLite's limited ALTER TABLE support;
on Postgres normal ALTER statements are emitted.
"""
from __future__ import annotations

from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

import app.models  # noqa: F401  — imports every model so all tables register on Base.metadata
from app.core.config import settings
from app.core.database import Base
from app.core.types import UTCDateTime

# Alembic Config object — provides access to values in alembic.ini.
config = context.config

# Set up Python logging from the ini file.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Metadata autogenerate compares against.
target_metadata = Base.metadata


def render_item(type_: str, obj: object, autogen_context: object) -> object:
    """Render the UTCDateTime TypeDecorator as its DB-identical sa.DateTime.

    Without this, autogenerate emits ``app.core.types.UTCDateTime(...)`` into the
    migration file but never imports it → ``NameError: name 'app'`` on upgrade
    (which only hides in dev because create_all builds the tables). UTCDateTime
    is schema-identical to DateTime(timezone=True), so rendering the impl is safe.
    """
    if type_ == "type" and isinstance(obj, UTCDateTime):
        return "sa.DateTime(timezone=True)"
    return False  # fall back to alembic's default rendering


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode (emit SQL to stdout, no DB connection)."""
    url = settings.database_url
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        render_item=render_item,
        render_as_batch=url.startswith("sqlite"),
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode (connect and execute)."""
    # configparser treats '%' as interpolation syntax — escape it so URLs with
    # percent-encoded characters (e.g. passwords) survive the round-trip.
    config.set_main_option("sqlalchemy.url", settings.database_url.replace("%", "%%"))

    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            render_item=render_item,
            render_as_batch=connection.dialect.name == "sqlite",
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
