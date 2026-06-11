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
- **Phase 1 — Flutter client: 🚧 in progress** (auth + dashboard + patients done).
- **Everything else: ⬜ planned** — see `PLATFORM.md` §4 matrix.

**Works end-to-end today:**
`Register patient → open Visit → add billed Services → take Payment → receipt →
auto-issue Queue ticket → call to room → TV board → Director KPIs`,
on top of **JWT auth · dynamic RBAC (no hardcoded roles) · audit log on every
mutation · multi-branch**.

**Verified green:** backend `pytest` = 6 passed · Flutter `flutter test` = 4 passed
· `flutter analyze` = no issues · `flutter build web` = builds.

## 2. Repo map (where things live)

```
backend/                     FastAPI service (system of record)
  app/
    core/      config, database, security (JWT/bcrypt), deps (auth+RBAC),
               repository, audit, permissions catalog, id sequences
    models/    SQLAlchemy 2.0 ORM (user, rbac, branch, patient, catalog,
               visit, payment, queue, audit)
    schemas/   Pydantic v2 DTOs
    features/  one router+service per feature (auth, users, roles, permissions,
               branches, patients, catalog, visits, payments, queue, dashboard)
    api.py     aggregates routers under /api/v1
    seed.py    idempotent bootstrap (permissions, roles, branch, director, services)
    main.py    app factory, CORS, lifespan (create schema + seed)
  tests/       pytest — test_patient_journey.py is the executable spec
lib/                         Flutter app
  app/         entrypoint (main.dart), theme, router (auth-guarded)
  core/        network (Dio+JWT, ApiException, Page), storage, widgets, utils
  features/<x>/{domain,data,application,presentation}   ← Clean Architecture
               auth · dashboard · patients · splash
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
./.venv/Scripts/python.exe -m pytest -q                         # 6 passed

# Flutter  (separate terminal, from repo root)
flutter pub get
flutter run -d chrome                                           # dev: any localhost port OK
flutter test                                                    # 4 passed
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
- **DB:** SQLite by default; the app runs `create_all()` + idempotent `seed` on startup. Switch to Postgres by setting `DATABASE_URL`. **No Alembic yet** (Phase 1).

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

## 7. What to do next (two specified tracks)

**Track A — finish the visible journey (Phase 1):**
1. Flutter **Visits API client** + **Reception screen** (register → add services → pay → receipt + ticket).
2. Flutter **Queue** screen + full-screen **TV board** (backend endpoints exist: `/queue`, `/queue/tv-board/{branch}`).
3. Backend hardening: **Alembic** migrations, **Docker Compose** (+Postgres), **refresh tokens**.

**Track B — clinical core (Phase 2), FULLY SPECIFIED & ready to build:**
Ophthalmology **EMR / patient card** (the clinic's legal **MoH Form 025-8**) +
**Medical Devices** (seeded with the clinic's two real instruments — Supore
**RMK-700** auto-refractometer and **CAS-2000BER** A/B ultrasound; refractometer
auto-fills the exam, A/B scan attaches to the visit).
→ Ground-truth domain data: **`docs/DOMAIN.md`**.
→ Ready-to-execute prompt: **`docs/prompts/02-emr-and-medical-devices.md`**.

Full roadmap: `PLATFORM.md` §6.

## 8. Rules for agents

- Reuse the established patterns above; **don't duplicate** existing code.
- **Run the tests** (§3) before claiming something works; add tests for new behavior.
- When you finish a slice, **update §1 here and the matrix in `PLATFORM.md`** so the next agent stays oriented.
- Keep `CLAUDE.md` (vision) and `PLATFORM.md` (status) consistent if scope changes.
- Confirm before destructive or outward-facing actions (force-push, deleting data, etc.).
