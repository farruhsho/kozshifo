# ── KO'Z SHIFO backend image ──────────────────────────────────────────────────
# python:3.12-slim-bookworm pinned (vs bare "3.12-slim") so a Debian base bump
# never lands silently. All deps ship manylinux wheels (psycopg[binary] bundles
# libpq), so no apt build toolchain is required on slim.
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Business timezone. The local-date logic (cash reports, attendance day &
# lateness in app/core/dates.py + features/attendance.py) resolves "local" via
# the process zone. slim defaults to UTC, and even TZ alone can't name a zone
# without the tzdata database — so install BOTH, else a UTC+5 clinic's day
# boundaries silently collapse to UTC. Override TZ per deployment if needed.
RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata \
    && rm -rf /var/lib/apt/lists/*
ENV TZ=Asia/Tashkent

WORKDIR /app

# Dependencies first — this layer is rebuilt only when requirements.txt changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Non-root runtime user. Code stays root-owned (read-only to the app process);
# /app/data is the one writable spot, for anyone running the image with SQLite
# (DATABASE_URL=sqlite:////app/data/kozshifo.db). Compose uses Postgres instead.
RUN groupadd --system --gid 10001 appuser \
    && useradd --system --uid 10001 --gid appuser --home-dir /app --no-create-home appuser \
    && mkdir -p /app/data \
    && chown appuser:appuser /app/data

# Application code + migrations (alembic.ini must sit in WORKDIR for the CLI).
COPY alembic.ini ./
COPY alembic/ ./alembic/
COPY app/ ./app/

USER appuser

EXPOSE 8000

# curl is absent on slim — probe /health with the stdlib instead.
# urlopen raises on any non-2xx/connection error, which fails the check.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request as u; u.urlopen('http://127.0.0.1:8000/health', timeout=4)"

# Migrate, then serve. `exec` hands PID 1 to uvicorn so SIGTERM from
# `docker stop` reaches it directly (graceful shutdown, no 10s kill timeout).
CMD ["/bin/sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port 8000"]
