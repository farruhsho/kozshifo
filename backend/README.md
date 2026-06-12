# KO'Z SHIFO — Backend (FastAPI)

Medical ERP / HIS / CRM / Inventory / Finance platform for eye clinics.
This service is the **system of record** and the API the Flutter clients talk to.

> **Status:** Foundation + core Patient Journey vertical slice. Runs locally with
> **zero external services** (SQLite). Production swaps in PostgreSQL via one env var.

---

## What works today

The complete core loop of the Patient Journey, end-to-end and tested:

```
Register patient → open Visit → add billed Services → take Payment
        → receipt → auto-issue Queue ticket → call to room → TV board → Director KPIs
```

Cross-cutting foundations in place:

- **JWT auth** (OAuth2 password flow).
- **Dynamic RBAC** — `Users · Roles · Permissions` resolved to permission *codes*.
  No role is hardcoded in logic; roles are editable data.
- **Audit log** — every mutation (create/update/delete/payment/refund/login) is recorded.
- **Multi-branch** from day one.
- **Clean layered architecture** — `core → models → schemas → features`, generic
  Repository, service logic per feature.

## Quick start (Windows / PowerShell)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

(macOS/Linux: `source .venv/bin/activate` then `uvicorn app.main:app --reload`.)

Then open:

- **Swagger UI:** http://127.0.0.1:8000/docs
- **Health:** http://127.0.0.1:8000/health

On first start the app creates the schema and seeds: the permission catalog,
starter roles (`Director`, `Reception`, `Cashier`, `Doctor`), a `MAIN` branch,
5 demo services, and the **director** bootstrap account:

| field    | value                     |
|----------|---------------------------|
| email    | `director@kozshifo.uz`    |
| password | `Director!2026`           |

> Change these via `.env` (`SEED_DIRECTOR_EMAIL` / `SEED_DIRECTOR_PASSWORD`) before
> any real deployment, and set a strong `SECRET_KEY`.

### Try the flow from Swagger

1. `POST /api/v1/auth/login` with the director credentials → copy `access_token`.
2. Click **Authorize**, paste the token.
3. `POST /api/v1/patients` → `POST /api/v1/visits` (with a service) →
   `POST /api/v1/payments` → watch a queue ticket appear in `GET /api/v1/queue`
   and on `GET /api/v1/queue/tv-board/{branch_id}`.

## Tests

```powershell
.\.venv\Scripts\python.exe -m pytest -q
```

`tests/test_patient_journey.py` is the executable specification of the core flow
plus auth/RBAC guards (e.g. a `Doctor`-role user is denied `patients.create`).
`tests/test_eye_exam.py` covers the Form 025-8 exam (upsert, validation, RBAC,
history, `card.pdf`); `tests/test_devices.py` covers the device registry, result
ingestion and the refraction→exam hand-off. `scripts/manual_happy_path.py`
exercises the full clinical path against a live server.

## Configuration

Copy `.env.example` → `.env`. Key settings:

| var | default | notes |
|-----|---------|-------|
| `DATABASE_URL` | `sqlite:///./kozshifo.db` | Set a `postgresql+psycopg://…` DSN for prod |
| `SECRET_KEY` | dev placeholder | **Must** be replaced in production |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `480` | |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `30` | refresh-token lifetime (rotation on each use) |
| `UPLOAD_DIR` | `./uploads` | device-result binaries; in Docker use `/app/data/uploads` |
| `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` | unset | enable Telegram notifications (otherwise log-only) |
| `CORS_ORIGINS` | localhost dev ports | comma-separated |
| `SEED_ON_STARTUP` | `true` | idempotent; safe to leave on |

## Project layout

```
backend/app/
  core/        config, database, security (JWT/bcrypt), deps (auth+RBAC),
               repository, audit, permissions catalog, id sequences,
               print_forms (Form 025-8 PDF), devices/ (adapter seam)
  models/      SQLAlchemy 2.0 typed ORM (users, rbac, branches, patients,
               catalog, visits, payments, queue, audit, exam, device)
  schemas/     Pydantic v2 request/response DTOs
  features/    one router (+ service logic) per feature
  api.py       aggregates routers under /api/v1
  seed.py      idempotent bootstrap data
  main.py      app factory, CORS, lifespan (create schema + seed)
tests/
```

## API surface (v1)

| Area | Endpoints |
|------|-----------|
| Auth | `POST /auth/login` (access+refresh pair), `POST /auth/refresh` (rotation), `GET /auth/me` |
| Identity | `GET /permissions`, `CRUD /roles`, `CRUD /users` |
| Branches | `GET/POST/PATCH /branches` |
| Patients | `GET/POST/PATCH/DELETE /patients` (search by name/MRN/phone) |
| Catalog | `GET/POST /service-categories`, `GET/POST/PATCH /services` |
| Visits | `GET/POST /visits`, `POST /visits/{id}/items`, `POST /visits/{id}/cancel` (unpaid only), `POST /visits/{id}/close` |
| Finance | `GET/POST /payments`, `POST /payments/{id}/refund` |
| Queue | `GET /queue?track=`, `POST /queue/call-next` (per track), serve/done/skip; diagnostics `done` auto-issues the doctor V-ticket; `GET /queue/tv-board/{branch}` (**public**, two-track) |
| TV board | `GET /tv/{branch_id}` — standalone waiting-room page (self-contained HTML, no auth) |
| Director | `GET /dashboard/summary` |
| EMR | `PUT/GET /visits/{id}/exam`, `GET /visits/{id}/exam/card.pdf` (Form 025-8), `GET /patients/{id}/exams` |
| Inventory | `/inventory/{categories,suppliers,products,receipts,stock,write-off}` — batches/expiry, FEFO, min-stock |
| Operations | `GET/POST /operation-types`, `GET /operation-types/{id}/availability` (consumables pre-check), `POST /visits/{id}/operations` (bills the visit, priority), `/operations/{id}/perform` (FEFO auto write-off) / `cancel` |
| Treatment | `POST/GET /visits/{id}/treatments`, `/treatments/{id}/dispense` (stock write-off) / `complete` / `cancel` |
| Notifications | `GET /notifications` — log/Telegram ledger (low-stock alerts fire on every write-off path) |
| Timeline | `GET /patients/{id}/timeline` — automatic chronological history (visits, payments, exams, devices, operations, treatments) |
| Insights | `GET /dashboard/insights` — owner attention list (criticals auto-notify, 24h debounce). Visits carry an auto-managed `flow_status` (event-driven, no manual writes) |
| Devices | `GET/POST/PATCH /devices`, `POST/GET /devices/{id}/results`, `POST /devices/{id}/results/file` (multipart B-scan), `GET /device-results/{id}/file`, `GET /visits/{id}/device-results`, `POST /visits/{id}/exam/apply-refraction?result_id=…` |

## Migrations (Alembic)

Dev still auto-creates the schema on startup (`create_all()` + idempotent seed).
Alembic owns schema evolution from here on:

```powershell
.\.venv\Scripts\alembic.exe upgrade head      # apply migrations (uses DATABASE_URL)
.\.venv\Scripts\alembic.exe revision --autogenerate -m "describe change"
.\.venv\Scripts\alembic.exe stamp head        # adopt an existing dev kozshifo.db
```

The baseline revision captures all 18 tables. The Docker image runs
`alembic upgrade head` before starting uvicorn.

## Docker / Compose

```bash
docker compose up --build        # api on :8000 + Postgres 16 (named volume)
```

A repo-root `.env` **must** define `SECRET_KEY` and `SEED_DIRECTOR_PASSWORD`
(compose fails fast without them, and the app re-validates at boot — the
repo-committed defaults never run in production). `POSTGRES_PASSWORD` is
optional but must be URL-safe (it is spliced into the DSN). See
`backend/.env.example`. **Note:** authored statically; the dev machine has no
Docker, so run the first real build on a Docker-capable host.

## Production notes (remaining)

- **Sequences:** MRN/visit/receipt/ticket numbers are count-based for the
  foundation. Under high concurrency, move to Postgres `SEQUENCE`s or a locked
  counters table (see `core/sequences.py`).
- **Money** is serialized as a decimal **string** (e.g. `"150000.00"`) to avoid
  float precision loss — parse with `Decimal` on the client.
- **Refresh tokens** rotate but are stateless — old ones stay valid until expiry;
  the `jti` claim is the hook for a future revocation list.
```
