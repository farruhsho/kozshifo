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

## 3. Database (implemented core — 18 tables)

```
branches ─┬─< users >──< user_roles >──┬─ roles ──< role_permissions >── permissions
          │             user_permissions ──────────────────────────────────┘
          ├─< patients ─< visits ─< visit_items >── services >── service_categories
          │                 │
          │                 ├─< payments
          │                 ├─< queue_tickets
          │                 ├── eye_exams   (1:1, Form 025-8: refraction/IOP/structures/diagnosis)
          │                 └─< device_results >── devices  (RMK-700, CAS-2000BER seeded)
          └─ (branch scoping on patients/visits/payments/queue/devices)
audit_logs  (actor, entity_type, entity_id, action, changes JSON, ip, ts)
```

## 4. Module status matrix

Legend: ✅ foundation built & tested · 🚧 partial · ⬜ planned (phase)

| # | Module | Status | Notes |
|---|--------|--------|-------|
| 1 | Identity & Access | ✅ | JWT, users, dynamic roles/permissions, RBAC guard |
| 2 | Patients | ✅ | CRUD, MRN, search |
| 3 | Reception / Visits | ✅ | Visit + billed items, totals/balance |
| 4 | Finance (Payments) | 🚧 | Take/refund payment, receipts; full ledger/cashflow ⬜ |
| 5 | Queue | ✅ | Tickets, call/serve/skip + Flutter management screen |
| 6 | TV Queue | ✅ | Public privacy-safe endpoint + standalone TV page `GET /tv/{branch}` (self-contained HTML, 4s polling) |
| 7 | Service Catalog | ✅ | Categories, priced services |
| 8 | Director Dashboard | 🚧 | Revenue/avg-check/counts; full KPI suite ⬜ |
| 9 | Audit | ✅ | Append-only log on all mutations; viewer UI ⬜ |
| 10 | Branches | ✅ | Multi-branch CRUD |
| 11 | Diagnostics | ✅ | Folded into the EMR eye exam (refraction, IOP, biomicroscopy, A/B-scan note) |
| 12 | Medical Devices (HL7/DICOM/serial…) | ✅ | Registry + results + adapter seam; 2 real devices seeded (RMK-700, CAS-2000BER); manual/file adapters live, serial/HL7/DICOM = Phase-4 stubs |
| 13 | Doctors / EMR | ✅ | **Form 025-8** exam (1:1 visit) + printable `card.pdf`; Flutter doctor card with refractometer auto-fill; treatment plans ⬜ Phase 3 |
| 14 | Treatment | ⬜ | Phase 3 |
| 15 | Operations | ⬜ | Phase 3 |
| 16 | Inventory / Warehouse | ⬜ | Phase 3 (auto write-off ties to Operations) |
| 17 | Purchasing / Suppliers | ⬜ | Phase 3 |
| 18 | Payroll | ⬜ | Phase 5 |
| 19 | CRM | ⬜ | Phase 5 |
| 20 | Reports / Analytics | 🚧 | KPI summary live; reporting engine ⬜ Phase 5 |
| 21 | Notifications | ⬜ | Phase 4 |
| 22 | Settings | 🚧 | Env config + seed; settings UI/API ⬜ |
| 23 | Director Control Center | 🚧 | Dashboard + identity/catalog mgmt; full center ⬜ |

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
- **Phase 3 — Operations & Inventory:** Operations, Treatment plans, Warehouse
  with batches/expiry/barcodes, auto write-off on operations, Purchasing/Suppliers.
- **Phase 4 — Integrations:** Medical device gateway (REST/TCP/serial/HL7/DICOM),
  Notifications (SMS/Telegram), printing/PDF.
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

- **Testing:** pytest end-to-end Patient Journey + EMR exam (upsert/validation/
  RBAC/history/PDF) + devices (seed/results/apply-refraction/RBAC) + TV board
  (public/privacy/page) + reception abort & queue state machine — `23 passed`;
  Flutter `12 passed`. Target the executable-spec style already established.
- **Deployment:** 12-factor/env-driven. `docker compose up --build` runs
  api + Postgres 16; the image applies `alembic upgrade head` before uvicorn.
  Dev still runs `uvicorn app.main:app` on SQLite with `create_all()` + seed.
  CI is the remaining ops gap.

---

*See `CLAUDE.md` for the full product brief and `backend/README.md` to run it.*
