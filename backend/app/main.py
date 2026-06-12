"""FastAPI application factory for the KO'Z SHIFO platform."""
from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from uuid import UUID

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from sqlalchemy.exc import IntegrityError

from app import __version__
from app.api import api_router
from app.core.config import settings
from app.core.database import create_all
from app.seed import run_seed

_STATIC_DIR = Path(__file__).parent / "static"


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Dev convenience only: build schema on startup. In production the schema
    # is owned exclusively by Alembic (the Docker CMD runs `alembic upgrade
    # head` before uvicorn) — an unconditional create_all() here would
    # silently mask missing migrations and corrupt the alembic lineage.
    if settings.environment == "development":
        create_all()
    if settings.seed_on_startup:
        run_seed()
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=__version__,
        summary="Medical ERP / HIS / CRM / Inventory / Finance platform for eye clinics.",
        lifespan=lifespan,
    )

    cors_kwargs: dict = {
        "allow_origins": settings.cors_origins,
        "allow_credentials": True,
        "allow_methods": ["*"],
        "allow_headers": ["*"],
    }
    if settings.environment == "development":
        # Let any localhost port through so `flutter run -d chrome` (random port) works.
        cors_kwargs["allow_origin_regex"] = r"http://(localhost|127\.0\.0\.1):\d+"
    app.add_middleware(CORSMiddleware, **cors_kwargs)

    @app.exception_handler(IntegrityError)
    async def _integrity_handler(_: Request, exc: IntegrityError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"detail": "Database constraint violated (duplicate or invalid reference)."},
        )

    @app.get("/health", tags=["System"])
    def health() -> dict:
        return {"status": "ok", "app": settings.app_name, "version": __version__, "env": settings.environment}

    @app.get("/tv/{branch_id}", response_class=HTMLResponse, tags=["System"])
    def tv_board_page(branch_id: UUID) -> HTMLResponse:
        """Standalone waiting-room TV board (no auth — shows privacy-safe data only).

        Open this URL fullscreen in the TV browser; the page polls
        /api/v1/queue/tv-board/{branch_id}. The branch_id path segment also
        validates as a UUID here so typos fail fast with a 422.
        """
        html = (_STATIC_DIR / "tv_board.html").read_text(encoding="utf-8")
        return HTMLResponse(html)

    app.include_router(api_router, prefix=settings.api_prefix)
    return app


app = create_app()
