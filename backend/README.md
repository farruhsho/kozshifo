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
| Auth | `POST /auth/login`, `GET /auth/me` |
| Identity | `GET /permissions`, `CRUD /roles`, `CRUD /users` |
| Branches | `GET/POST/PATCH /branches` |
| Patients | `GET/POST/PATCH/DELETE /patients` (search by name/MRN/phone) |
| Catalog | `GET/POST /service-categories`, `GET/POST/PATCH /services` |
| Visits | `GET/POST /visits`, `POST /visits/{id}/items`, `POST /visits/{id}/cancel` (unpaid only), `POST /visits/{id}/close` |
| Finance | `GET/POST /payments`, `POST /payments/{id}/refund` |
| Queue | `GET /queue`, `POST /queue/call-next`, serve/done/skip, `GET /queue/tv-board/{branch}` (**public**, privacy-safe) |
| TV board | `GET /tv/{branch_id}` — standalone waiting-room page (self-contained HTML, no auth) |
| Director | `GET /dashboard/summary` |
| EMR | `PUT/GET /visits/{id}/exam`, `GET /visits/{id}/exam/card.pdf` (Form 025-8), `GET /patients/{id}/exams` |
| Devices | `GET/POST/PATCH /devices`, `POST/GET /devices/{id}/results`, `GET /visits/{id}/device-results`, `POST /visits/{id}/exam/apply-refraction?result_id=…` |

## Production notes (deliberately deferred)

- **Migrations:** dev uses `create_all()`. For production, add **Alembic**
  (`alembic init`) and replace the startup `create_all()` with migrations.
- **Sequences:** MRN/visit/receipt/ticket numbers are count-based for the
  foundation. Under high concurrency, move to Postgres `SEQUENCE`s or a locked
  counters table (see `core/sequences.py`).
- **Money** is serialized as a decimal **string** (e.g. `"150000.00"`) to avoid
  float precision loss — parse with `Decimal` on the client.
- **Containerization** (Docker/Compose with Postgres) is a Phase-1 task; the app
  is already 12-factor / env-driven and ready for it.
```
