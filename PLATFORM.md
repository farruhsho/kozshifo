# KO'Z SHIFO — Platform Architecture & Roadmap

Medical **ERP + HIS + CRM + Inventory + Finance** platform for eye clinics.
Engineered for scale from day one: ~100k patients, ~500 staff, ~10 branches,
millions of records.

This document is the strategic map: what's built, how it's built, and the
sequenced plan to reach the full vision in the project brief (`CLAUDE.md`).

---

## 1. Analysis — approach

The brief describes a multi-module enterprise program. The professional path is
**not** 23 shallow stubs — it is one **proven foundation** plus a **complete
vertical slice** that every later module copies. We built the slice that is the
spine of the whole system: the **Patient Journey** core
(`Patient → Visit → Services → Payment → Queue → TV board → KPIs`), with the
cross-cutting concerns the entire platform depends on (auth, dynamic RBAC, audit,
multi-branch) done *properly*, so they're never retrofitted.

## 2. Architecture

```
┌─────────────────────────── Clients ───────────────────────────┐
│  Flutter (Reception · Doctor · Director · TV board)  ·  Web    │
└───────────────────────────────┬───────────────────────────────┘
                                 │  REST /api/v1  (JWT)
┌───────────────────────────────▼───────────────────────────────┐
│                       FastAPI backend                          │
│  features/ (routers + service logic)   ← Feature-First         │
│  schemas/  (Pydantic v2 DTOs)          ← API contracts         │
│  core/     (auth, RBAC, audit, repo, config, sequences)        │
│  models/   (SQLAlchemy 2.0 ORM)        ← Repository pattern    │
└───────────────────────────────┬───────────────────────────────┘
                                 │
                    SQLite (dev) ─┴─ PostgreSQL (prod)   ← one env var
```

**Decisions & rationale**

| Decision | Why |
|----------|-----|
| Sync SQLAlchemy 2.0 (typed) | FastAPI threadpools sync handlers; simpler, fewer foot-guns at this scale |
| SQLite dev / Postgres prod | Zero-setup local run; DSN swap with no code change |
| Permission **codes**, not roles, in checks | Spec mandates dynamic permissions, no hardcoded roles |
| Money as `Numeric(12,2)` / decimal-string on the wire | No float precision loss in finance |
| Audit written in the same transaction as the change | Trail can't drift from reality |
| UUID primary keys | Safe to merge across branches; non-guessable |

## 3. Database (implemented core — 27 tables)

```
branches ─┬─< users >──< user_roles >──┬─ roles ──< role_permissions >── permissions
          │             user_permissions ──────────────────────────────────┘
          ├─< patients ─< visits ─< visit_items >── services >── service_categories
          │                 │
          │                 ├─< payments
          │                 ├─< queue_tickets
          │                 ├── eye_exams   (1:1, Form 025-8: refraction/IOP/structures/diagnosis)
          │                 ├─< device_results >── devices  (RMK-700, CAS-2000BER seeded)
          │                 ├─< operations >── operation_types ─< type_consumables >─┐
          │                 └─< treatments ──────────────────────────┐               │
          ├─< stock_batches / stock_movements >── products <─────────┴───────────────┘
          │       (FEFO by expiry; signed-qty ledger)    └── inventory_categories · suppliers
          └─ (branch scoping on patients/visits/payments/queue/devices/stock)
audit_logs  (actor, entity_type, entity_id, action, changes JSON, ip, ts)
```

## 4. Module status matrix

Legend: ✅ foundation built & tested · 🚧 partial · ⬜ planned (phase)

| # | Module | Status | Notes |
|---|--------|--------|-------|
| 1 | Identity & Access | ✅ | JWT, users, dynamic roles/permissions, RBAC guard |
| 2 | Patients | ✅ | CRUD, MRN, search |
| 3 | Reception / Visits | ✅ | Visit + billed items, totals/balance |
| 4 | Finance (Payments) | ✅ | Take/refund payment (cash/card/QR/transfer), receipts, **visit discounts** (percent XOR amount + reason, payable-based balance), **expenses (rashod)**, daily/monthly cash reports by method + CSV (`/finance`) |
| 5 | Queue | ✅ | **Two-track** D-diagnostics → auto V-doctor (no receptionist), per-track call-next, day-scoped, race-guarded; **adressed routing** (assign a waiting ticket to a named specialist, opt-in `for_user_id` call-next, `/queue/specialists` picker) |
| 6 | TV Queue | ✅ | 2x2 board (doctor blue / diagnostics green): big called number + cabinet + specialist, next-8 tables, voice announcements |
| 7 | Service Catalog | ✅ | Categories, priced services |
| 8 | Director Dashboard | 🚧 | KPIs + **self-improvement insights** (low stock, revenue drop, queue overload, stale visits, cancellation spikes — criticals auto-notify); conversions/LTV/forecast ⬜ |
| 9 | Audit | ✅ | Append-only log on all mutations; viewer UI ⬜ |
| 10 | Branches | ✅ | Multi-branch CRUD |
| 11 | Diagnostics | ✅ | Folded into the EMR eye exam (refraction, IOP, biomicroscopy, A/B-scan note) |
| 12 | Medical Devices (HL7/DICOM/serial…) | ✅ | Registry + results + adapter seam; 2 real devices seeded; binary upload/serving + Flutter preview for B-scans; serial/HL7/DICOM transports = stubs |
| 12a | IP Cameras | ✅ | Isolated `cameras` table (Hikvision pattern, write-only password); connect-by-IP, ISAPI test, backend JPEG **snapshot proxy** (httpx DigestAuth) → Flutter live view by polling (`Image.memory`); capture-to-disk. RTSP/MJPEG live video = future (needs transcode) |
| 13 | Doctors / EMR | ✅ | **Form 025-8** exam (1:1 visit) + printable `card.pdf`; Flutter doctor card with refractometer auto-fill; treatment plans ⬜ Phase 3 |
| 14 | Treatment | ✅ | Prescriptions (procedure/medication), dispense writes stock off; courses/schedules ⬜ |
| 15 | Operations | ✅ | Types with consumable templates, prescribe→bills the visit, perform→FEFO auto write-off |
| 16 | Inventory / Warehouse | ✅ | Products, batches/expiry, FEFO engine, min-stock alerts, movement ledger; transfers/stocktake ⬜ |
| 17 | Purchasing / Suppliers | 🚧 | Suppliers + goods receipts live; purchase orders ⬜ |
| 18 | Payroll | ✅ | Percent-based doctor pay (`salary_percent`), monthly calc from completed payments, idempotent payout → expense; CSV (`/finance` → Зарплата) |
| 19 | CRM | ⬜ | Phase 5 |
| 24 | Attendance (Face ID) | ✅ | Punch webhook (`X-Attendance-Key`) + manual events, timesheet (late/absent, paired in/out), CSV (`/attendance`); hardware terminal = customer-side |
| 25 | IP Telephony | ✅ | PBX ingest webhook (`X-PBX-Key`), patient autolink by phone, searchable journal (`/calls`); PBX/Asterisk wiring = deploy-time |
| 20 | Reports / Analytics | 🚧 | KPI summary live; reporting engine ⬜ Phase 5 |
| 21 | Notifications | ✅ | Core: log + optional Telegram, low-stock alerts with anti-spam, notification ledger + API; SMS & UI screen ⬜ |
| 22 | Settings | 🚧 | Env config + seed; runtime settings UI ⬜ |
| 23 | Director Control Center | 🚧 | Dashboard + insights + **admin UI** (services/prices, branches, staff via `/admin`); roles editor UI, process builder ⬜ |

## 5. API & UI/UX

- **API:** versioned `/api/v1`, OpenAPI/Swagger auto-generated, consistent
  pagination envelope, RBAC-guarded. See `backend/README.md` for the surface.
- **UI/UX:** Flutter app per the brief's stack (Riverpod · GoRouter · Freezed ·
  Dio), Feature-First + Clean Architecture. **Built:** JWT auth + auth-guarded
  routing, Director KPI dashboard, Patients (list/search/register), **Reception
  (search/register → service cart → visit → payment → receipt + queue ticket)**,
  **Queue management (call/serve/done/skip, auto-refresh)**, **Doctor patient
  card (Form 025-8: exam editing, history, PDF print, refractometer pull,
  A/B-scan list)**, **Devices registry screen**, permission-aware navigation —
  plus a **standalone TV board** (single HTML at `/tv/{branch}`, no login,
  privacy-safe) for the waiting-room screen.

## 6. Roadmap (phased)

- **Phase 0 — Foundation ✅ (done):** backend core, auth, RBAC, audit, Patient
  Journey slice, tests.
- **Phase 1 — Hardening & Flutter client ✅ (done):**
  Flutter client (auth-guarded routing, dashboard, patients, reception, queue,
  doctor card, devices + standalone TV board) and backend hardening: **Alembic**
  baseline migrations (18 tables, autogenerate-clean), **Dockerfile + Compose**
  with Postgres 16 (authored statically — first build needs a Docker host),
  **JWT refresh-token rotation** with transparent 401 retry on the client.
- **Phase 2 — Clinical ✅ (done):** EMR eye exam (Form 025-8, 1:1 with visit)
  + printable `card.pdf`, medical-device registry with the 2 real instruments
  seeded, device results attached to visits, refractometer → exam auto-fill.
  Deferred to later phases: binary file upload/serving for B-scans (paths are
  recorded now), serial/HL7/DICOM transports (adapter stubs in place),
  IOL-power calculation.
- **Phase 3 — Operations & Inventory ✅ (core done):** Warehouse (products,
  batches/expiry, FEFO write-off engine, min-stock, movement ledger, goods
  receipts, suppliers), Operations (types with consumable templates; prescribe
  bills the visit, perform auto-writes-off FEFO), Treatment prescriptions with
  medication dispensing. Deferred: purchase orders, inter-branch transfers,
  stocktake, barcode-scanning UI.
- **Phase 4 — Integrations 🚧 (core done):** ✅ binary device files (B-scan
  upload/serving + preview), ✅ notification core (log + Telegram, low-stock
  alerts), ✅ extended director KPIs. Remaining: real device transports
  (serial/HL7/DICOM — adapter stubs ready), SMS provider, notification UI.
- **Phase 5 — Intelligence & ops:** full KPI suite, Reports/Analytics engine,
  Payroll, CRM, forecasting.

## 7. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Scope (23 modules) overwhelming quality | Phased delivery; each module reuses the proven slice |
| ID generation under concurrency | Documented; move to Postgres sequences in Phase 1 |
| PHI / data protection (medical data) | RBAC + audit now; encryption-at-rest, backups, retention in Phase 1 |
| Device protocol variety (HL7/DICOM) | Isolated integration service in Phase 4, not in core |
| Financial correctness | Decimal money, audited mutations, refund flow; double-entry ledger Phase 3 |

## 8. Testing & Deployment

- **Testing:** pytest end-to-end Patient Journey, EMR exam, devices, TV board,
  reception/queue state machines, auth refresh, production config guards,
  inventory FEFO atomicity, operations billing + auto write-off, binary device
  files, notifications, dashboard KPIs — `63 passed`; Flutter `24 passed`.
  Target the executable-spec style already established.
- **Deployment:** 12-factor/env-driven. `docker compose up --build` runs
  api + Postgres 16; the image applies `alembic upgrade head` before uvicorn.
  Dev still runs `uvicorn app.main:app` on SQLite with `create_all()` + seed.
  CI is the remaining ops gap.

---

*See `CLAUDE.md` for the full product brief and `backend/README.md` to run it.*
