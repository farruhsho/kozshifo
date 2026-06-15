# ── KO'Z SHIFO — single-image deploy (Railway / any Docker host) ──────────────
# Builds the Flutter web client AND serves it from the FastAPI backend, so one
# container is the whole app at ONE url: UI + API + TV board on the same origin
# (no CORS, no separate hosting). FastAPI auto-mounts /build/web when present
# (see backend/app/main.py), which this image populates from the build stage.
#
# Local development still uses backend/Dockerfile via docker-compose; THIS root
# image is the cloud / single-service target that Railway builds on every push.

# ── Stage 1: compile the Flutter web client ───────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS web

WORKDIR /src
# pubspec first: this layer is rebuilt only when dependencies change, not on
# every source edit.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# The rest of the Flutter project (lib/, web/, assets, build config…).
COPY . .
# No --dart-define=API_BASE_URL: on web the client falls back to Uri.base.origin
# (see lib/core/constants/api_constants.dart), i.e. the very URL this container
# is served from — so the same image is correct on Railway, a LAN server, etc.
RUN flutter build web --release

# ── Stage 2: FastAPI backend that also serves the compiled web client ─────────
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Business timezone needs the tzdata DB for local-date logic (cash reports,
# attendance day/lateness). Override TZ per deployment via env if needed.
RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata \
    && rm -rf /var/lib/apt/lists/*
ENV TZ=Asia/Tashkent

WORKDIR /app

# Dependencies first — cached until requirements.txt changes.
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Non-root runtime user; /app/data is the one writable spot (uploads / SQLite).
RUN groupadd --system --gid 10001 appuser \
    && useradd --system --uid 10001 --gid appuser --home-dir /app --no-create-home appuser \
    && mkdir -p /app/data \
    && chown appuser:appuser /app/data

# Application code + migrations (alembic.ini must sit in WORKDIR for the CLI).
COPY backend/alembic.ini ./
COPY backend/alembic/ ./alembic/
COPY backend/app/ ./app/

# main.py resolves the web client at <repo-root>/build/web — that is
# parents[2] of /app/app/main.py, i.e. "/" — so place the compiled client at
# /build/web for the StaticFiles mount to pick it up.
COPY --from=web /src/build/web /build/web

USER appuser

EXPOSE 8000

# Railway injects $PORT; the :-8000 default keeps non-Railway hosts working.
# Migrate, then serve. `exec` hands PID 1 to uvicorn so SIGTERM reaches it
# directly (graceful shutdown).
CMD ["/bin/sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
