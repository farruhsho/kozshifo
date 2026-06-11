"""FastAPI application factory for the KO'Z SHIFO platform."""
from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError

from app import __version__
from app.api import api_router
from app.core.config import settings
from app.core.database import create_all
from app.seed import run_seed


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Dev convenience: build schema and seed bootstrap data on startup.
    # Production replaces create_all() with Alembic migrations (see README).
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

    app.include_router(api_router, prefix=settings.api_prefix)
    return app


app = create_app()
