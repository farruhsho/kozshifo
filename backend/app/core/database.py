"""SQLAlchemy engine, session factory, and declarative Base.

Sync SQLAlchemy 2.0 is used deliberately: FastAPI runs path operations in a
threadpool, so sync sessions are safe, simpler, and have fewer foot-guns than
async for this scale. Swapping `DATABASE_URL` to a Postgres DSN is the only
change needed to move off SQLite — no code changes.
"""
from __future__ import annotations

from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

# SQLite needs check_same_thread=False because FastAPI's threadpool hands the
# connection across threads. Postgres ignores connect_args entirely.
_connect_args = {"check_same_thread": False} if settings.is_sqlite else {}

engine = create_engine(
    settings.database_url,
    echo=False,
    future=True,
    connect_args=_connect_args,
    pool_pre_ping=not settings.is_sqlite,
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)


class Base(DeclarativeBase):
    """Declarative base for all ORM models."""


def get_db() -> Iterator[Session]:
    """FastAPI dependency yielding a request-scoped session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_all() -> None:
    """Create tables from metadata (dev convenience; production uses migrations)."""
    # Import models so they register on Base.metadata before create_all.
    import app.models  # noqa: F401

    Base.metadata.create_all(bind=engine)
