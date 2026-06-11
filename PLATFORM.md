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

## 3. Database (implemented core — 15 tables)

```
branches ─┬─< users >──< user_roles >──┬─ roles ──< role_permissions >── permissions
          │             user_permissions ──────────────────────────────────┘
          ├─< patients ─< visits ─< visit_items >── services >── service_categories
          │                 │
          │                 ├─< payments
          │                 └─< queue_tickets
          └─ (branch scoping on patients/visits/payments/queue)
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
| 5 | Queue | ✅ | Tickets, call/serve/skip |
| 6 | TV Queue | ✅ | Privacy-safe board endpoint; needs display UI |
| 7 | Service Catalog | ✅ | Categories, priced services |
| 8 | Director Dashboard | 🚧 | Revenue/avg-check/counts; full KPI suite ⬜ |
| 9 | Audit | ✅ | Append-only log on all mutations; viewer UI ⬜ |
| 10 | Branches | ✅ | Multi-branch CRUD |
| 11 | Diagnostics | ⬜ | Phase 2 — folded into the EMR eye exam |
| 12 | Medical Devices (HL7/DICOM/serial…) | 🚧 spec | 2 real devices + integration approach captured in `docs/DOMAIN.md`; build queued (`docs/prompts/02`) |
| 13 | Doctors / EMR | 🚧 spec | Official **Form 025-8** fields captured in `docs/DOMAIN.md`; ready-to-build prompt `docs/prompts/02` |
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
- **UI/UX 🚧:** Flutter app per the brief's stack (Riverpod · GoRouter · Freezed ·
  Dio), Feature-First + Clean Architecture. **Built:** JWT auth + auth-guarded
  routing, Director KPI dashboard, Patients (list/search/register), and
  permission-aware navigation. **Next:** Reception (register→bill→pay→print),
  Doctor (patient card), and a full-screen TV board.

## 6. Roadmap (phased)

- **Phase 0 — Foundation ✅ (done):** backend core, auth, RBAC, audit, Patient
  Journey slice, tests.
- **Phase 1 — Hardening & Flutter client 🚧 (in progress):**
  ✅ Flutter foundation (Riverpod · GoRouter · Dio · Freezed, Clean Architecture)
  with auth-guarded routing, a director **dashboard** (live KPIs) and **patients**
  (list/search/register) wired to the API — analyzes clean, compiles to web, unit-tested.
  ▫ Remaining: Reception billing/payment + Queue/TV-board screens, Alembic
  migrations, Docker Compose (+Postgres), refresh tokens.
- **Phase 2 — Clinical:** Diagnostics, Doctor EMR / patient card, results
  attached to visits.
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

- **Testing:** pytest end-to-end Patient Journey + RBAC denial (`6 passed`).
  Expand per module; target the executable-spec style already established.
- **Deployment:** app is 12-factor/env-driven. Phase 1 adds Dockerfile +
  docker-compose (api + Postgres), Alembic migrations, and CI. Until then it runs
  with `uvicorn app.main:app` on SQLite.

---

*See `CLAUDE.md` for the full product brief and `backend/README.md` to run it.*
