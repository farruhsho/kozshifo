"""FastAPI application factory for the KO'Z SHIFO platform."""
from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from uuid import UUID

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.exc import IntegrityError

import time

from app import __version__
from app.api import api_router
from app.core import monitoring
from app.core.audit import set_request_context
from app.core.config import settings
from app.core.database import create_all
from app.seed import run_seed

_STATIC_DIR = Path(__file__).parent / "static"
# Compiled Flutter web app (repo `build/web`), if present. When it exists the
# backend serves the whole client itself, so the clinic LAN has a single URL
# (http://<server-ip>:8000) for both the UI and the API — same origin, no CORS,
# and reachable from any device on the network including the TV board.
_WEB_DIR = Path(__file__).resolve().parents[2] / "build" / "web"


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

    # Cheap first line against oversized uploads: uvicorn has no body limit and
    # Starlette spools multipart parts to disk before handlers run. The upload
    # endpoint additionally enforces its own per-file cap with a chunked read.
    max_body = 25 * 1024 * 1024

    # Capture the client IP + User-Agent into the request-scoped audit context so
    # every mutation's audit row records «с какого устройства» (read by
    # core.audit.record_audit). Set before the handler runs; the value is copied
    # into the threadpool that executes sync endpoints.
    @app.middleware("http")
    async def _audit_context(request: Request, call_next):
        client_ip = request.client.host if request.client else None
        set_request_context(ip=client_ip, user_agent=request.headers.get("user-agent"))
        return await call_next(request)

    # System monitoring: time every request; record slow ones + server errors
    # into the in-memory ring buffers (Super Admin → системный мониторинг).
    @app.middleware("http")
    async def _monitor(request: Request, call_next):
        start = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception:
            monitoring.record_request(request.method, request.url.path, 500,
                                      (time.perf_counter() - start) * 1000)
            raise
        monitoring.record_request(request.method, request.url.path, response.status_code,
                                  (time.perf_counter() - start) * 1000)
        return response

    @app.middleware("http")
    async def _limit_request_body(request: Request, call_next):
        length = request.headers.get("content-length")
        if length and length.isdigit() and int(length) > max_body:
            return JSONResponse(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                content={"detail": "Request body too large"},
            )
        return await call_next(request)

    # The backend self-hosts the compiled Flutter app (build/web). Tell the
    # browser NOT to cache it, so a fresh `flutter build web` is always picked up
    # — a stale cached main.dart.js (e.g. one built against a different API URL)
    # is a classic cause of a phantom "нет связи" after the build changed.
    _NO_CACHE_EXEMPT = (settings.api_prefix, "/health", "/tv", "/docs", "/redoc", "/openapi")

    @app.middleware("http")
    async def _no_store_static(request: Request, call_next):
        response = await call_next(request)
        if not request.url.path.startswith(_NO_CACHE_EXEMPT):
            response.headers["Cache-Control"] = "no-store"
        return response

    @app.get("/health", tags=["System"])
    def health() -> dict:
        return {"status": "ok", "app": settings.app_name, "version": __version__, "env": settings.environment}

    def _tv_board_html() -> HTMLResponse:
        return HTMLResponse((_STATIC_DIR / "tv_board.html").read_text(encoding="utf-8"))

    @app.get("/tv", response_class=HTMLResponse, tags=["System"])
    def tv_board_picker() -> HTMLResponse:
        """TV board WITHOUT a branch — the page shows a branch picker (no UUID
        to remember): open http://<server>:8000/tv and tap the branch."""
        return _tv_board_html()

    @app.get("/tv/{branch_id}", response_class=HTMLResponse, tags=["System"])
    def tv_board_page(branch_id: UUID) -> HTMLResponse:
        """Standalone waiting-room TV board (no auth — shows privacy-safe data only).

        Open this URL fullscreen in the TV browser; the page polls
        /api/v1/queue/tv-board/{branch_id}. The branch_id path segment also
        validates as a UUID here so typos fail fast with a 422.
        """
        return _tv_board_html()

    app.include_router(api_router, prefix=settings.api_prefix)

    # Serve the Flutter web client at the root. Mounted LAST so the API,
    # /health, /tv and the auto-docs routes (registered above) always win;
    # the static mount only catches everything else. `html=True` serves
    # index.html at "/" — the client uses hash routing, so the server only
    # ever sees "/" and no SPA path fallback is needed.
    if _WEB_DIR.is_dir():
        app.mount("/", StaticFiles(directory=str(_WEB_DIR), html=True), name="web")

    return app


app = create_app()
