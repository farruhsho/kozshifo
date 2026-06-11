# KO'Z SHIFO — Medical ERP Platform

Medical **ERP + HIS + CRM + Inventory + Finance** platform for eye clinics.
Monorepo: a **FastAPI** backend (system of record) and a **Flutter** client.

> **Status:** Phase 0–1 foundation. The core **Patient Journey** works end-to-end
> on the backend, and a Flutter client (auth · director dashboard · patients) is
> wired to it. Runs locally with **zero external services**.
> Full architecture, module status and roadmap: **[PLATFORM.md](PLATFORM.md)**.

```
kozshifo/
├── backend/          FastAPI · SQLAlchemy · JWT · dynamic RBAC · audit   (see backend/README.md)
├── lib/              Flutter app — Riverpod · GoRouter · Dio · Freezed
│   ├── app/          entrypoint, theme, router (auth-guarded)
│   ├── core/         network (Dio+JWT), storage, widgets, utils
│   └── features/     auth · dashboard · patients  (Clean Architecture)
├── test/             Flutter unit tests
└── PLATFORM.md       architecture decisions, module matrix, phased roadmap
```

## Run it (two terminals)

### 1 — Backend (Python 3.11+)

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```
→ API at http://127.0.0.1:8000 · Swagger at http://127.0.0.1:8000/docs
First run auto-creates the schema and seeds the director account
**`director@kozshifo.uz` / `Director!2026`** (+ starter roles, a branch, demo services).

### 2 — Flutter client (Flutter 3.29+)

```powershell
flutter pub get
flutter run -d chrome          # or windows / android / ios
```
Log in with the director credentials above. In development the backend accepts
any `localhost` port, so the random Chrome dev-server port works out of the box.

> Android emulator: the backend isn't on `127.0.0.1` from inside the emulator —
> run with `flutter run -d <emulator> --dart-define=API_BASE_URL=http://10.0.2.2:8000`.

## What works today

```
Register patient → open Visit → add billed Services → take Payment
        → receipt → auto-issue Queue ticket → call to room → TV board → Director KPIs
```
Backed by **JWT auth**, **fully dynamic RBAC** (no hardcoded roles), an **audit log**
on every mutation, and **multi-branch** support.

## Tests

```powershell
cd backend && .\.venv\Scripts\python.exe -m pytest -q   # backend: 6 passed (full journey + RBAC)
flutter test                                            # client: 4 passed
```

See **[backend/README.md](backend/README.md)** for the API surface and
**[PLATFORM.md](PLATFORM.md)** for the roadmap (Diagnostics, EMR, Operations,
Inventory, device integrations, full KPI suite — phased).
