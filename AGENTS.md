# AGENTS.md — START HERE (handoff for AI agents & developers)

**Read this file first.** It tells you the goal, what's already built, what's in
progress, the conventions to follow, and what to do next — so you don't burn
tokens re-deriving the project from scratch.

## 0. 60-second orientation

- **What this is:** a medical **ERP + HIS + CRM + Inventory + Finance** platform
  for an eye clinic. Monorepo: `backend/` (FastAPI) + Flutter app at repo root.
- **The four docs and what each is for:**
  | File | Purpose |
  |------|---------|
  | **`AGENTS.md`** (this) | Practical map: status, conventions, gotchas, next tasks. |
  | **`PLATFORM.md`** | Architecture decisions, **module status matrix**, phased roadmap. |
  | **`README.md`** | How to run backend + Flutter, credentials. |
  | **`CLAUDE.md`** | The **aspirational product brief** (the *whole* vision). It describes the target, **not** what's built yet. |
  | **`backend/README.md`** | Backend API surface, run/test, production notes. |

> ⚠️ **Do not assume a module exists just because `CLAUDE.md` mentions it.**
> Check the status matrix in `PLATFORM.md` first.

## 1. Status at a glance (2026-06)

- **Phase 0 — Backend core: ✅ done & tested.**
- **Phase 1 — Flutter client + hardening: ✅ done** (all screens live; Alembic
  baseline, Dockerfile + Compose with Postgres, JWT refresh-token rotation —
  ⚠️ Docker artifacts are authored but **untested locally**: this machine has no Docker).
- **Phase 2 — Clinical core (EMR + Devices): ✅ done & tested** (Epic 2, `docs/prompts/02`).
- **Phase 3 — Operations & Inventory: ✅ core done & tested** (warehouse with
  batches/expiry + FEFO engine, operations bill the visit and auto-write-off
  consumables on perform, treatment prescriptions with dispensing).
- **Everything else: ⬜ planned** — see `PLATFORM.md` §4 matrix.

**Works end-to-end today (all clickable in the app):**
`Reception screen: register patient → service cart → open Visit → take Payment →
receipt + auto Queue ticket → Queue screen: call to room / serve / done →
standalone TV board at /tv/{branch} (no login, privacy-safe) → Director KPIs`,
plus the clinical loop `Doctor opens patient card (Form 025-8) → fills/edits eye
exam → pulls refraction from the RMK-700 device result → prints official
card.pdf`, on top of **JWT auth · dynamic RBAC (no hardcoded roles) · audit log
on every mutation · multi-branch**.

**Verified green:** backend `pytest` = 46 passed · Flutter `flutter test` = 22 passed
· `flutter analyze` = no issues · `flutter build web` = builds ·
`alembic upgrade head` + `alembic check` = clean (3 revisions).

## 2. Repo map (where things live)

```
backend/                     FastAPI service (system of record)
  app/
    core/      config, database, security (JWT/bcrypt), deps (auth+RBAC),
               repository, audit, permissions catalog, id sequences,
               print_forms (Form 025-8 PDF), devices/adapters (integration seam),
               stock (FEFO write-off engine)
    models/    SQLAlchemy 2.0 ORM (user, rbac, branch, patient, catalog,
               visit, payment, queue, audit, exam, device, inventory, operation)
    schemas/   Pydantic v2 DTOs
    features/  one router+service per feature (auth, users, roles, permissions,
               branches, patients, catalog, visits, payments, queue, dashboard,
               exams, devices, inventory, operations, treatments)
    api.py     aggregates routers under /api/v1
    seed.py    idempotent bootstrap (permissions, roles, branch, director, services)
    main.py    app factory, CORS, lifespan (create schema + seed)
  tests/       pytest — test_patient_journey.py is the executable spec
lib/                         Flutter app
  app/         entrypoint (main.dart), theme, router (auth-guarded)
  core/        network (Dio+JWT, ApiException, Page), storage, widgets, utils
  features/<x>/{domain,data,application,presentation}   ← Clean Architecture
               auth · dashboard · patients · reception · queue ·
               doctor (card 025-8) · clinical (operations/treatments) ·
               devices · inventory (Склад) · splash
test/          Flutter unit tests
PLATFORM.md · README.md · CLAUDE.md
```

## 3. Run & test (copy-paste)

```bash
# Backend  → http://127.0.0.1:8000 (Swagger at /docs)
cd backend
python -m venv .venv
./.venv/Scripts/python.exe -m pip install -r requirements.txt   # Windows path
./.venv/Scripts/python.exe -m uvicorn app.main:app --reload
./.venv/Scripts/python.exe -m pytest -q                         # 46 passed
./.venv/Scripts/alembic.exe upgrade head                        # migrations (prod path)

# Docker (on a Docker-capable host; dev machine has none)
docker compose up --build                                       # api :8000 + Postgres 16

# Flutter  (separate terminal, from repo root)
flutter pub get
flutter run -d chrome                                           # dev: any localhost port OK
flutter test                                                    # 22 passed

# TV board (waiting-room screen): open in any browser, no login required
#   http://127.0.0.1:8000/tv/<branch_id>   (link dialog: Queue screen → TV icon)
```
Login: **`director@kozshifo.uz` / `Director!2026`** (auto-seeded on first backend run).

## 4. Backend conventions — how to extend

**To add a feature (copy `patients` as the template):**
1. ORM model in `app/models/<x>.py`; export it in `app/models/__init__.py`.
2. DTOs in `app/schemas/<x>.py` (Pydantic v2, `ConfigDict(from_attributes=True)`).
3. Router + service logic in `app/features/<x>.py`; register it in `app/api.py`.
4. Add permission codes to `app/core/permissions.py` (`PERMISSIONS` + role templates).
5. Guard endpoints with `Depends(require_permission("<code>"))`.
6. Call `record_audit(db, ...)` for every create/update/delete/payment in the same transaction.
7. Add a pytest in `backend/tests/`.

**Hard rules:**
- **RBAC is data-driven.** Never hardcode role names in logic — check permission *codes*. Director user is `is_superuser` (bypasses checks).
- **Money** = `Numeric(12,2)`; it is serialized to the client as a **decimal string** (`"150000.00"`). Never use float for money.
- **Human IDs** (MRN, visit/receipt/ticket no) come from `app/core/sequences.py` (count-based; replace with Postgres `SEQUENCE` for production concurrency).
- **DB:** SQLite by default; dev startup still runs `create_all()` + idempotent `seed`. **Alembic now owns schema evolution**: after changing models run `alembic revision --autogenerate -m "…"`; prod (and the Docker image) applies `alembic upgrade head`. Adopt an existing dev DB with `alembic stamp head`.

## 5. Frontend conventions — how to extend

- **Structure:** `features/<x>/{domain,data,application,presentation}`.
- **State:** Riverpod (`Notifier` for auth, `FutureProvider.autoDispose` for reads).
- **Routing:** GoRouter in `lib/app/router.dart`, auth-guarded via `_RouterNotifier.redirect`. Add a route there + a nav destination in `lib/core/widgets/app_shell.dart`.
- **HTTP:** use `dioProvider` (JWT auto-attached). Wrap calls in `try/on DioException → ApiException.from(e)`.
- **Models:** Freezed + json_serializable. JSON is **snake_case**, auto-mapped from camelCase Dart fields via `build.yaml` (`field_rename: snake`). **After editing any `@freezed` model, run:** `dart run build_runner build --delete-conflicting-outputs`.
- **Money fields are Strings** on the client; format with `lib/core/utils/formatters.dart`.
- **Permission-aware UI:** `ref.watch(authControllerProvider).user?.can("<code>")`.

## 6. Critical gotchas (knowing these saves real tokens)

- **build_runner breaks on packages with native build hooks (Dart 3.10).**
  `flutter_secure_storage` pulls `objective_c`, whose `hook/build.dart` makes
  `dart run build_runner` fail with *"'dart compile' does not support build hooks"*.
  We removed it and use `shared_preferences`. **Don't re-add a hook-using package**
  without solving this.
- **Token is in `shared_preferences`, not OS secure storage** — a known Phase-1
  hardening item (see `PLATFORM.md` §7), a direct consequence of the above.
- **No Docker / no Postgres on the dev machine.** Backend runs on SQLite. Don't
  assume containers exist.
- **Backend auto-seeds on startup** (idempotent) — you don't need a manual seed step.
- **Dev CORS allows any `localhost` port** (only when `ENVIRONMENT=development`).

## 7. What to do next

**✅ Track B (Phase 2, clinical core) is DONE** — EMR Form 025-8 exam + printable
`card.pdf` + device registry/results/adapters with the 2 real instruments seeded
and refractometer→exam auto-fill (built per `docs/prompts/02`, 2026-06).
Deferred from it (note before building adjacent code): binary upload/serving of
B-scan files (only `file_path` strings are recorded today), serial/HL7/DICOM
transports (stubs in `core/devices/adapters.py`), IOL-power calculation.

**✅ Track A UI is DONE (2026-06)** — Reception screen (register → cart → pay →
receipt + ticket), Queue management screen, and the **standalone TV board**:
`GET /tv/{branch_id}` serves a self-contained HTML page (no login; consumes the
now-public privacy-safe `/queue/tv-board/{branch}`); the Queue screen's TV icon
shows/opens the link.

**✅ Phase-1 hardening is DONE (2026-06)** — Alembic baseline (18 tables,
`alembic check` clean), `backend/Dockerfile` + root `docker-compose.yml`
(api + Postgres 16; ⚠️ authored statically, first real `docker compose up`
must happen on a Docker-capable host), JWT **refresh-token rotation**
(`POST /auth/refresh`, 30-day refresh JWT with `jti`; Flutter Dio interceptor
retries one 401 transparently).

**✅ Phase 3 core is DONE (2026-06)** — warehouse (products/batches/expiry,
FEFO engine in `core/stock.py`, movement ledger, goods receipts, min-stock),
operations (types with consumable templates; prescribe bills the visit's
linked service, perform auto-writes-off FEFO atomically), treatments
(prescribe/dispense/complete). Flutter: Склад screen + Операции/Назначения
sections in the doctor card. Deferred from it: purchase orders, inter-branch
transfers, stocktake, barcode-scanning UI, treatment courses/schedules.

**Next (Phase 4–5 candidates), plus known leftovers:**
1. Device gateway transports (serial/HL7/DICOM stubs in `core/devices/adapters.py`), binary B-scan upload/serving, notifications (SMS/Telegram).
2. Full Director KPI suite + Reports engine; double-entry ledger.
3. Tokens still live in `shared_preferences` — secure-storage hardening pending the build_runner/native-hooks issue (§6).
4. Refresh tokens are stateless — add a `jti` revocation list when Postgres/Redis lands.
5. First real `docker compose up --build` on a Docker-capable host; CI.
6. Searchable product pickers (dropdowns load one 500-item page today) and an
   expired-stock disposal UI (backend `include_expired` write-off exists).

Full roadmap: `PLATFORM.md` §6.

## 8. Rules for agents

- Reuse the established patterns above; **don't duplicate** existing code.
- **Run the tests** (§3) before claiming something works; add tests for new behavior.
- When you finish a slice, **update §1 here and the matrix in `PLATFORM.md`** so the next agent stays oriented.
- Keep `CLAUDE.md` (vision) and `PLATFORM.md` (status) consistent if scope changes.
- Confirm before destructive or outward-facing actions (force-push, deleting data, etc.).
