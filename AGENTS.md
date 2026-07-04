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

## 1. Status at a glance (2026-07)

> **2026-07-04 — Actor-journey audit + 3 build waves (HEAD `95eedd4`, in `main`).**
> An orchestrator pass modelled all 14 actors (`docs/ACTORS.md`), ran a 50-agent
> journey audit against the code, then shipped three reviewed waves. Every actor now
> completes their journey with **no dead-ends**. Gates: **pytest 461 / flutter 218 /
> analyze clean / alembic head `c2b1f4e6d302` (linear, applies clean on a fresh DB)**.
> Migrations added this wave: `b3e7d2a4c916` (visit.follow_up_date), `c1a0f3e5d201`
> (stocktake + inter-branch transfers + supplier returns), `c2b1f4e6d302` (treatment
> multi-day sessions). Owner run `alembic upgrade head` to apply.
> - **Wave 1** — journey-blockers: emergency-priority in call-next, safe Л-ticket
>   auto-bind, `uuid.UUID` bug that broke all of `/openapi.json`, 3 hanging-visit
>   categories, surgeon fee in day-P&L (payroll semantics) hidden without `payroll.read`,
>   exit from the "hold" dead-end, fail-closed prod guard, token_version session revocation.
> - **Wave 2** — dead-end removal: visit auto-close + manual «Закрыть визит», follow-up
>   date + «Повторные приёмы» recall screen, diagnostician can fix own conclusion,
>   device-result unlink/relink, ghost-superadmin no longer leaks in monitoring/audit/
>   sessions/enrollment. Visit-lifecycle invariant hardened over two adversarial rounds
>   (auto-close frozen by `_is_locked`; refund thaws visit **and** its operations; op
>   visits auto-close only after financial-close; debted visit stays open by design).
> - **Prescription print** — doctor prints a рецепт (glasses sph/cyl/ax + Тавсия);
>   `GET /exams/{id}/prescription.pdf`.
> - **Wave 3** (owner-picked enhancements) — **stocktake** (`StockCount`, commit sets
>   the batch to the absolute counted qty via guarded UPDATE), **inter-branch transfer**
>   + **supplier return** (all stock mutations atomic/guarded in `core/stock.py`),
>   **multi-day treatment course** (`Treatment.sessions_total/done`, atomic
>   `mark-session`, sessions procedures-only), **role-management UI** (`/admin` «Роли»
>   tab; backend guards: system roles uneditable, in-use roles undeletable).
> - **Owner decision:** finance revenue semantics left as-is (panels intentionally
>   measure cash-received vs accrued-services). Still deferred (need hardware/creds):
>   real device transports, SMS gateway, Firebase FCM/hosting.

- **Phase 0 — Backend core: ✅ done & tested.**
- **Phase 1 — Flutter client + hardening: ✅ done** (all screens live; Alembic
  baseline, Dockerfile + Compose with Postgres, JWT refresh-token rotation —
  ⚠️ Docker artifacts are authored but **untested locally**: this machine has no Docker).
- **Phase 2 — Clinical core (EMR + Devices): ✅ done & tested** (Epic 2, `docs/prompts/02`).
- **Phase 3 — Operations & Inventory: ✅ core done & tested** (warehouse with
  batches/expiry + FEFO engine, operations bill the visit and auto-write-off
  consumables on perform, treatment prescriptions with dispensing).
- **Phase 4 — Integrations: 🚧 core done** (✅ B-scan binary upload/serving +
  Flutter preview · ✅ notification core: log + optional Telegram, low-stock
  alerts with 24h anti-spam · ✅ extended director KPIs; remaining: real device
  transports, SMS, notification UI).
- **Owner Automation: ✅ core done** (event-driven visit `flow_status` —
  nobody sets it manually, `core/flow.py` advances it from payments/queue/
  operations/treatments events · patient timeline `GET /patients/{id}/timeline`
  · self-improvement insights `GET /dashboard/insights` with debounced
  auto-notify of criticals · Flutter: admin screens `/admin` (services/prices,
  branches, staff), dashboard attention panel, timeline in the doctor card,
  «Завершить приём» button).
- **UX Productivity: ✅ core done** (global smart search `GET /search` +
  Ctrl+K overlay (patients/phone/MRN/visits/receipts, permission-scoped
  sections) · keyboard-first: login enter-flow with remembered email + eye
  toggle, queue F2/F3, doctor Ctrl+S/F7, register-dialog enter-flow ·
  exam autosave drafts every 3s with restore banner · doctor's frequent
  diagnoses as one-tap chips · phone-first reception registration ·
  persisted light/dark/system theme cycle).
- **TZ completion (официальное ТЗ клиники, `Ko'z_Shifo_.docx`): ✅ core done**
  (Modul 1 учёт времени: Face ID punch-webhook `X-Attendance-Key` + ручные
  отметки + табель с опозданиями/пропусками + CSV · Modul 8 финансы: расходы,
  зарплата врача по проценту (`users.salary_percent`, идемпотентная выплата
  по (user, month)), дневной/месячный кассовый отчёт по методам, CSV ·
  Modul 9 журнал звонков: PBX-webhook `X-PBX-Key`, автопривязка пациента по
  последним 9 цифрам · Modul 2.2 скидки на визит (процент XOR сумма + причина,
  `payable` вместо `total` во всех расчётах) + метод оплаты QR · Modul 4 поле
  зрения + Visus своими очками на форме 025-8 · Flutter: `/finance`,
  `/attendance`, `/calls`, диалог скидки, ролевой лендинг + меню по правам.
  Остались железные интеграции: реальный Face ID терминал и PBX → см. ключи
  `ATTENDANCE_API_KEY`/`PBX_API_KEY` в `core/config.py`).
- **Firebase: 🚧 wired** — app linked to project `kozshifo-prod`
  (`lib/firebase_options.dart`, best-effort init in `main.dart`,
  build_runner verified alive). FCM/hosting and the DB-to-own-server
  migration plan live in **`docs/FIREBASE.md`** — read it before touching
  anything Firebase.
- **Everything else: ⬜ planned** — see `PLATFORM.md` §4 matrix.

**Works end-to-end today (all clickable in the app):**
`Reception: register → cart → Visit → Payment → auto DIAGNOSTIC ticket (D-…) →
diagnost calls/serves/completes → system auto-issues the DOCTOR ticket (V-…),
no receptionist → doctor calls → 2x2 TV board at /tv/{branch} (blue doctor
half + green diagnostics half, voice announcements, no login) → Director KPIs`,
plus the clinical loop `Doctor opens patient card (Form 025-8) → fills/edits eye
exam → pulls refraction from the RMK-700 device result → prints official
card.pdf`, on top of **JWT auth · dynamic RBAC (no hardcoded roles) · audit log
on every mutation · multi-branch**.

- **Roles & depth pass: ✅ done** — each role now has a complete, self-sufficient
  workspace (касса/склад no longer funnel through ресепшен): the **Cashier till**
  lives in Финансы (Платежи = open-visit payment queue with split/QR, Возвраты =
  history + guarded refund, Смена = daily cash close + CSV); **Warehouse** gained
  write-off, low-stock «Дефицит» and expiring «Истекает» views; role-aware landing
  + any-of nav permissions (a cashier lands on their till). Plus the adversarial
  review fixes: payroll only pays out a closed month (+ void/correction path),
  discounts can't exceed the bill and a 100% discount enters the journey, all API
  timestamps read back aware-UTC (`UTCDateTime`) so the app shows local time,
  doctor salary % is editable in /admin. Perf: access token cached in memory
  (no SharedPreferences read per API call).
- **Adressed queue routing: ✅ done** — the two-track queue can now route a
  WAITING ticket to a specific specialist (`queue_tickets.assigned_user_id`,
  nullable FK → users, NULL = open pool). `POST /queue/{id}/assign` (guarded by
  `queue.manage`) sets/clears it; `call-next` gained an opt-in `for_user_id`
  filter (claims tickets routed to me OR unassigned — omitted = unchanged legacy
  behaviour, so nothing breaks); `GET /queue/specialists` lists branch staff for
  the picker under `queue.manage` (no `users.read` needed). Flutter queue screen:
  «Направить» action + specialist picker, «Только мои» call-next toggle, assigned
  name on tiles. TV board exposes the routed specialist (waiting list column +
  voice mentions the name when present). Migration `68f53379eef0`.
- **IP cameras (connect by IP, live view): ✅ done** — a new **isolated**
  `cameras` table (mirrors `face_terminals`: host/port/username/password/use_https
  + vendor/channel/snapshot_path; password is **write-only** — absent from
  `CameraOut`, pinned by a never-leaks test). `/cameras` CRUD + `/cameras/{id}/test`
  (ISAPI deviceInfo probe) guarded by `cameras.manage`; `GET /cameras/{id}/snapshot`
  (guarded by `cameras.view`) proxies one JPEG frame via `HikvisionClient.get_snapshot`
  (httpx DigestAuth, the existing terminal transport). Browsers can't play RTSP, so
  the live view is **snapshot polling ~1 fps** rendered with `Image.memory` (Dio
  bytes — `Image.network` can't attach the JWT on web). Down camera → 502, never
  500. Flutter: `/cameras` screen (grid of live cards, «Снимок» capture, «Проверить»,
  add-by-IP dialog) + «Камеры» nav. `cameras.view`+`manage` granted to Reception,
  `cameras.view` to Doctor, all to Director. Migration `a650ccc3e510`. The RMK-700
  serial / CAS-2000BER file adapters remain deferred (hardware path TBD).

- **Структурированная «История визитов»: ✅ done** — the doctor's patient card
  (ПАЦИЕНТ column) now lists every visit as an expandable row: billed services,
  Итого/Скидка/К оплате/Оплачено/Долг, flow status and an ЭКСТРЕННО badge, with
  the form's current visit highlighted and «Открыть осмотр» to switch to it.
  Pure frontend — reuses the existing `GET /visits?patient_id=` payload (no extra
  request, no backend change); the client `VisitSummary` gained optional
  money/items fields (defaulted, so the picker + const fixtures still parse).
- **Queue auto-refresh hardened: ✅** — the live queue's 5s refresh now skips a
  tick while the previous fetch is still in flight, so a slow backend can't
  stack GETs or let a late response clobber a newer list (`queue_screen.dart`;
  regression test `test/queue_screen_test.dart` also pins clean timer disposal).
- **Queue ticket number no longer clips: ✅** — a longer number (V-0003) overflowed
  the round avatar and wrapped/clipped («V-0 / 03»); now FittedBox-scaled to one
  line (`queue_screen.dart`, regression test in `test/queue_screen_test.dart`).
- **Receipt чек — no-tofu font + pretty layout + auto-print: ✅** — the real root
  cause of the «чёрные квадратики» was that Docker slim / Cloud Run ship **no
  system font**, so `_register_fonts()` fell back to Helvetica (zero Cyrillic) and
  the whole receipt tofu'd. We now **bundle DejaVuSans** (Cyrillic-complete,
  redistributable) under `backend/app/assets/fonts/` and register it first, so
  rendering is identical on every host (`COPY app/` already ships it into the
  image — no Dockerfile change). With a guaranteed font the receipt restored real
  `⚠`/`−`/`×` glyphs and got a polished layout (solid header rule, framed ИТОГО,
  framed ЭКСТРЕННЫЙ banner, boxed talon number). Regression guard:
  `tests/test_print_forms.py` fails if FONT ever drops back to Helvetica. Flutter:
  new `printBytes` (web → hidden-iframe print dialog; desktop → OS viewer) and the
  reception flow **auto-prints чек+талон on full payment** (the «Печать чека»
  button stays for re-print).
- **Patient-journey epic — Ф1 foundation (doctor · cabinet · services): ✅ done** —
  groundwork for service-based queue routing and the reception payment flow. A
  doctor now has a `cabinet` (their consulting room) and a many-to-many set of
  `services` they provide; a `Service` exposes its eligible `doctors`. The cabinet
  lives on the doctor — reception never picks one at payment time; the queue will
  route a paid ticket to an eligible doctor, into that doctor's cabinet. Backend:
  `User.cabinet` + `service_doctors` M2M; `/users` accepts `cabinet`/`service_ids`,
  `/services` accepts `doctor_ids`; migration `d3a7c1f4b920`. Flutter `/admin`:
  «Кабинет» + «Услуги врача» on the staff create/edit dialogs, «Принимающие врачи»
  on the service create/edit dialogs (one `_asyncMultiPick` helper; an inactive
  but still-linked item stays visible/removable).
- **Patient-journey Ф2 — reception payment & services: ✅ done** — the reception
  **payment dialog dropped its cabinet field** (amount + method only; the ticket
  gets its room from the doctor who calls it). **«Услуги добавляет рецепшен»**:
  service management is now its own screen `/services` + «Услуги» nav, because
  reception has services.* but not users.read (so /admin was unreachable). New
  backend `GET /services/assignable-doctors` (services.read) feeds the service
  form's doctor picker without users.read; `/admin` dropped its Services tab.
- **Patient-journey Ф3a — queue call/recall/leave actions: ✅ done** — removed the
  «Направить» button; queue management now has `POST /queue/{id}/call` («Вызвать»
  a specific waiting ticket), `/recall` («Вызвать повторно» — bumps called_at so
  the TV re-announces; **called-only**, else it would hijack the board's headline
  slot), `/leave` («Оставить» — called/serving → waiting, clears the call fields
  + reverts the visit's flow claim). Flutter tiles: «Вызвать»/«Пропустить» on
  waiting; «Принят»/«Готово» + a ⋮ menu (recall/leave) on called.
- **Patient-journey Ф3b — service routing + personal queue workstations: ✅ done** —
  when diagnostics complete and the system auto-issues the doctor (V-) ticket, it
  now **routes by service**: if the visit's service maps to exactly one active
  eligible doctor (`service_doctors`), the ticket is pre-assigned to them and
  pre-filled with **their** `User.cabinet` (TV board shows the room at once);
  several/zero eligible → open pool. `call-next`/`call` now **default the room to
  the caller's own cabinet** (`CallNextRequest.room` made optional), so a doctor
  needn't retype it. **Doctor role gained `queue.manage`** (runs their own queue).
  Flutter: `QueueScreen` got a `personal` single-track mode — a new `/my-queue`
  nav «Моя очередь» (gated `device_results.create`, placed before «Очередь» so a
  diagnost lands there) renders one track derived from rights (`exams.write` →
  doctor «Мой приём», else diagnost «Диагностика»), prefills the room from the
  user's cabinet, and a doctor auto-pulls their routed tickets first. `/auth/me`
  + client `AuthUser` now carry `cabinet`. No migration (service routing reuses
  the existing `assigned_user_id`; the permission grant re-seeds idempotently).
  Tests: `test_queue_service_routing.py` (3) + queue personal-mode widget test.
- **Patient-journey Ф4a — ad-hoc consumables at perform: ✅ done** — at PERFORM,
  reception/surgeon logs the consumables ACTUALLY used beyond the OperationType
  template; backend `perform` gained an optional `PerformOperationRequest`
  {`ad_hoc_consumables:[{product_id,quantity}]`} (omitted = template only — last
  param so existing no-body callers keep working). Template + ad-hoc write off via
  the same FEFO atomically; the pre-check aggregates demand **per product** so a
  product in both lists reports the true cumulative 409. Timeline
  `operation_completed` now carries the clinical result. Flutter: «Выполнить» opens
  a debounced product picker (gated on `inventory.read`, instruments filtered out)
  with validated quantities.
- **Patient-journey Ф4b — operations calendar (agenda): ✅ done** — the Operations
  screen gained a «Список / Календарь» toggle; the calendar shows the selected day's
  SCHEDULED operations (date nav) each tapping through to the patient card.
  Frontend-only; `Operation.scheduledAtLocal` force-reads naive SQLite datetimes as
  UTC (correct day on dev + prod); a dedicated `scheduledOperationsProvider` fetched
  at the 500 cap.
- **Patient-journey Ф4 leftovers: ✅ done** — (1) **backend date-window**: GET
  `/operations` gained `scheduled_from`/`scheduled_to` (half-open `[from,to)` UTC
  window on `scheduled_at`, mirrors `operation_report`'s raw-datetime compare; bare
  referrals drop out). `scheduledOperationsProvider` became a `.family` keyed on the
  local day, sending that day's `[00:00,next-00:00)` bounds as UTC instants — the
  calendar now fetches **one day** instead of relying on the 500-row cap; client
  `_sameDay` stays as a belt-and-suspenders guard. (2) **consumables in history**:
  the consumables actually written off at perform (template + ad-hoc) now ride on the
  patient timeline's `operation_performed` event detail (`"ИОЛ ×1 … · доп.: Шприц
  ×1"`), built by `timeline._operation_consumables` (one bulk ledger query keyed by
  `ref_id`, template/ad-hoc split by the shared `ADHOC_REASON_SUFFIX` constant in
  `models.operation`). **Not billed** — operations are already billed at the
  operation price; consumables are clinic COGS, so this records/surfaces them (no
  cost shown → no finance leak; gated by `operations.read`).
- **Patient-journey Ф5 — standalone visit-history screen: ✅ done** — a dedicated
  `/patients/:id/visits` screen (`PatientVisitsScreen`) lists ALL of a patient's
  visits with a filter bar: date range, status chips, «С долгом» (debt-only). It is
  reception/registrar-friendly — distinct from the doctor's exam card — reached from
  the patients list via an «История визитов» action (gated `visits.read`); the route
  is a deep route under the `/patients` prefix so the redirect guard inherits
  `patients.read`. Backend: GET `/visits` gained `opened_from`/`opened_to` (half-open
  `[from,to)` UTC window on `opened_at`, which is `UTCDateTime` → aware on both DBs),
  mirroring the `/operations` date-window. Flutter: `visitsForPatient` gained optional
  `{openedFrom,openedTo,status,owing}`; a new `patientVisitsFilteredProvider` keyed on
  a `VisitHistoryQuery` record powers the screen, leaving the doctor card's unfiltered
  `patientVisitsProvider` untouched; the screen reuses `VisitSummary` (money/items/debt
  getters) and taps through to the med card.

- **Patient-flow overhaul (owner brief 2026-06-18) — Phase 0 removals: ✅ done** — a
  new 7-phase wave reshaping the clinic flow (attachments, doctor-of-patient,
  queue-by-service + load balancing, «Приём» screen, operations P&L, dashboard
  charts; see the approved plan). **Phase 0** removed two verticals entirely:
  **Оптика** (frontend `lib/features/optics/` + backend feature/model/schema/seq/
  tests + `optics.*` perms) and the **«Видео»/Камеры** screen (frontend
  `lib/features/camera/` + backend feature/model/schema/tests + `cameras.*` perms).
  Migration `b2f7c0a91d34` drops `optics_orders` + `cameras` (keeps `lab_orders`).
  The shared `HikvisionClient` (face terminals) is untouched.

- **Patient-flow overhaul — Phase 1 attachments: ✅ done** — a general patient
  document store (model `attachments`, migration `c4d8e1f0a2b6`): `POST/GET
  /patients/{id}/attachments` (multipart, kind = uzi|hiv|lab|other, optional
  visit_id/operation_id that must belong to the patient), `GET /attachments/{id}/file`
  (auth-gated download), `DELETE /attachments/{id}` — all reusing `core.files`
  (20 MB cap, ext whitelist incl. .pdf; bytes under a random name, original name =
  metadata only). New perms `attachments.read`/`.write` granted to
  Reception/Doctor/Diagnost; documents surface on the patient timeline as an
  `attachment` event. Flutter: `lib/features/attachments/` (plain model + Dio repo +
  reusable `AttachmentsSection`: list / upload PDF via FilePicker / download via
  `saveBytes`), embedded in the doctor card's ПАЦИЕНТ column (gated `attachments.read`).
  Storage caveat: Cloud Run disk is ephemeral (same as device files) — GCS is the
  prod follow-up.

- **Patient-flow overhaul — Phase 2 data model: ✅ done** — (1) `patients.primary_doctor_id`
  (лечащий врач, FK users): POST/PATCH /patients accept it (unknown id → 422); GET
  /patients/{id}/summary also returns `primary_doctor_id`/`_name` plus
  `last_visit_doctor_id`/`_name` (from the most recent visit) so reception can pre-fill
  the picker with a fallback. (2) `users.queue_prefix` (ticket prefix, Сарвар → С-001;
  defaulted from full_name's first letter at create, director-editable) and
  `users.is_external_surgeon` (visiting Tashkent surgeon, shown in surgeon pickers).
  (3) Diagnosis catalog (справочник заключений): model `diagnoses` + M2M `user_diagnoses`,
  `GET/POST/PATCH /diagnoses` (perms `diagnoses.read`/`.manage`; read → Reception/Doctor/
  Diagnost, manage → Doctor); `/users` accept `diagnosis_ids` to scope a diagnostician's
  allowed conclusions; seed adds 7 starter УЗИ/diagnosis entries. Migration `a7e3c9b15d28`.
  Flutter admin: `StaffUser` carries the 3 fields; the create/edit user dialogs gained a
  queue-prefix field, an «Внешний хирург» switch and a «Разрешённые заключения» multipick;
  a new «Диагнозы» admin tab manages the catalog.

- **Patient-flow overhaul — Region analytics: ✅ done** — owner marketing add-on. Patients now carry
  `region` (one of Uzbekistan's 14 oblasts) + `district` (Fergana raion/city, shown only when region =
  Ферганская — the clinic's home region). `POST/PATCH /patients` + `PatientOut` carry both; reception's
  `RegisterPatientDialog` got a «Регион» dropdown (+ conditional «Район / город»); list lives in
  `lib/features/reception/domain/regions.dart`. New `GET /dashboard/patients-by-region` (dashboard.view)
  groups patients by region split **new vs returning** (returning = >1 visit; NULL → «Не указано»),
  sorted by total; a «Пациенты по регионам» dashboard panel renders each region's new/returning split as
  a two-segment bar (so the director sees which audience to market to). Migration `d5b1f3a86c47`.
  **Next:** **Phase 3** — per-doctor ticket numbers (С-001) + queue-by-service routing + load-balancing
  + «Приём» screen + a **TREATMENT queue track** (лечение) on the TV board with flexible payment
  (per-day / 10-day / deferred-pay-at-end / partial, reusing the Visit+Payment balance model).

- **Patient-flow overhaul — Phase 3a per-doctor ticket numbers: ✅ done** — the doctor-track queue
  ticket now takes the assigned doctor's `queue_prefix` (Сарвар → С-001) instead of a fixed «V».
  `next_ticket_number(db, branch, prefix)` is now PREFIX-based — a per-branch, per-prefix daily counter
  (`ticket_number LIKE '<prefix>-%'`, "-"-anchored so С-% never matches Сд-001) — so each doctor has
  their own С-001… series while diagnostic keeps D-001. The doctor for a paid visit resolves in priority
  order (`queue._doctor_for_visit`): `visit.doctor_id` (reception's choice) → `patient.primary_doctor_id`
  (returning patient's лечащий) → the service's single eligible doctor → open pool («V»); the resolved
  doctor also pre-fills cabinet+assignment. No-doctor visits still mint V-001 (existing queue tests green).
  No migration; 3 tests.

- **Patient-flow overhaul — Phase 3b diagnostic queue-by-service: ✅ done** — `Service.is_diagnostic`
  flag (migration `e8c2a4f9b73d`; ServiceCreate/Update/Out carry it; seed marks ARM/TONO/BIO/OCT
  diagnostic, CONS stays doctor-track; Flutter admin service dialogs got a «Диагностическая услуга»
  switch). On payment the diagnostic ticket is tagged with the visit's first `is_diagnostic` service
  (NULL = open to any diagnostician). `call-next` on the diagnostic track filters waiting tickets to the
  caller's assigned services (`service_doctors`) OR untagged — a caller with no services
  (reception/director) stays unrestricted. So a УЗИ-диагност pulls only УЗИ work. 1 test.
- **Patient-flow overhaul — Phase 3c load-balancing + «принят» history: ✅ done** — when several doctors
  are eligible for a paid visit, `queue._eligible_doctor_for_visit` now routes the doctor-track ticket to
  the **least-loaded** doctor (`_least_loaded_doctor`: fewest waiting doctor tickets today, ties by name)
  instead of the open pool, so the 2nd doctor doesn't sit idle. Zero eligible = open pool (call-next fills
  caller cabinet, kept as its own test); one eligible unchanged. Timeline gained a `seen` event
  («Принят: ФИО · Диагностика/Приём врача · каб») from called tickets (gated `queue.read`). Query-only,
  no migration; 2 tests + reworked routing test. **«Вызванных не гонять повторно»** is already satisfied
  by the state machine (called/serving tickets aren't `waiting`, so call-next never re-pulls them; payment
  dedupes active tickets).

- **Patient-flow overhaul — Phase 3d treatment queue track: ✅ done** — a third queue track «Лечение»
  (track="treatment", prefix «Л») for a patient here for a course of treatment. `POST /queue/treatment-ticket`
  (queue.manage) issues a Л-… ticket for a patient (+ optional visit/room/assignee), deliberately NOT gated
  on payment — лечение is paid per-day / prepaid / deferred / partial via the visit's normal balance.
  Flow-engine guard: treatment tickets never drive the diagnostic→doctor visit flow and never auto-advance
  to a doctor ticket. The public TV board (`tv-board` endpoint + the standalone `tv_board.html`) is now a
  **3-column** layout (Врач / Диагностика / Лечение, purple section, voice+chime wired). No migration;
  3 tests. A reception «Талон на лечение» button completes the front-desk side.

- **Patient-flow overhaul — Phase 3e card-centric «Приём» screen: ✅ done (Phase 3 COMPLETE)** — the
  personal queue (`/my-queue` `QueueScreen(personal)`) becomes a 2-pane intake workspace on wide screens
  (≥1000px): the queue + «Вызвать следующего» on the left, and the CURRENT patient (the serving ticket,
  else the first called ticket) on the right — `PatientInfoCard` + `AttachmentsSection` (УЗИ/ВИЧ files) +
  an «Открыть карту» button into the full med-card. Calling a patient immediately surfaces their data.
  Narrow screens keep the original single-pane queue. No backend change; 1 widget test. **Phase 3 of the
  overhaul is fully done** (3a per-doctor numbers, 3b diagnostic-by-service, 3c load-balancing + «принят»
  history, 3d treatment track, 3e «Приём» screen).

- **Patient-flow overhaul — Phase 4a doctor refers to operation with surgeon: ✅ done** — the referral
  `POST /visits/{id}/operations` now accepts an optional `surgeon_id` (validated; set on the operation),
  so the doctor picks the surgeon when sending the patient to surgery (reception can still change it at
  schedule). New `GET /operations/surgeons` (operations.read) lists active staff eligible to operate —
  `operations.perform` OR `is_external_surgeon` (visiting Tashkent surgeons, flagged). Flutter:
  `clinical_repository.surgeons()` + `surgeonsProvider`; the referral dialog (`OperationsSection`) got a
  «Хирург» dropdown (external ones labelled «· приезжий»), optional. No migration (surgeon_id already on
  Operation); 2 tests.

- **Patient-flow overhaul — Phase 4b diagnostician conclusion: ✅ done (Phase 4 COMPLETE)** — a
  diagnostician (УЗИ etc.) records a conclusion (заключение) scoped to the diagnoses the director allowed
  them (`user_diagnoses`). New perm `diagnoses.record` (Doctor + Diagnost); `GET /diagnoses/mine` (the
  user's allowed list — empty = unrestricted → all active) feeds the picker; `POST
  /visits/{id}/diagnostic-conclusion` records a `VisitDiagnosis` authored by the recorder (catalog pick
  validated against the allowed set; a restricted user can't free-type) — separate from `exams.write` so
  the diagnost doesn't author the full 025-8 exam. Shows on the doctor card + timeline next to the УЗИ PDF.
  Flutter: `lib/features/diagnoses/` (model + repo + `DiagnosticConclusionCard`) embedded in the «Приём»
  pane (gated `diagnoses.record` + a visit). No migration (perm is seed data); 3 tests. **Phase 4 done**
  (4a surgeon-at-referral, 4b diagnostician conclusion). Optional follow-up: structure «лечение N дней» on
  `Treatment`.

- **Patient-flow overhaul — Phase 5a operations day P&L: ✅ done** — `GET /operations/day-summary?date=&
  branch_id=` (operations.read): the director's daily operations profit/loss — revenue (Σ price of
  operations PERFORMED that local day) − COGS (consumables written off for them, Σ |qty|×batch unit_cost
  from the stock ledger, joined StockMovement→StockBatch) − that day's operation expenses (finance
  `Expense` category «Операции») = profit; branch-scoped. `OperationDaySummary` DTO; 2 tests; no migration.
  Flutter: `operationDayPnlProvider` + a «P&L дня» card in the operations calendar day-view
  (Выручка/Себестоимость/Расходы/Прибыль).

- **Patient-flow overhaul — Phase 5b/5c schedule board: ✅ done (Phase 5 COMPLETE)** — (5b) `POST
  /operations/{id}/unschedule` (operations.schedule) detaches a scheduled op back to the referred pool
  (de-bills unless paid → refund first); status → referred, scheduled_at/price/visit_item cleared, surgeon
  kept; 3 tests. (5c, Flutter) the operations **calendar** is now a day-scheduling board: the time column
  is DROPPED; wide screens show a 2-pane Row (the day's scheduled ops | a «Направлены на операцию» pool
  from `GET /operations?status=referred`); «Поставить на dd.MM» schedules a pool op onto the selected day
  with an optional surgeon + price override (flexible cost); «Открепить» unschedules; a soft cap badge
  «N / 15 на день» warns (never blocks). The HIV-analysis attach already works via Phase 1 (kind=hiv +
  operation_id; shows in the timeline) — a missing-analysis badge would be optional polish.
- **Patient-flow overhaul — Phase 6 warehouse + dashboard charts: ✅ done** — (6a) `GET
  /inventory/reorder-suggestions?branch_id=` (inventory.read): active products at/below min_stock with a
  suggested restock qty (up to 2× min), most-deficient first; 1 test. (6b) `GET /dashboard/revenue-trend
  ?days=N` (dashboard.view) + an **fl_chart** «Выручка (14 дней)» LineChart on the dashboard (the first
  chart; fl_chart ^1.2.0 added); 2 tests. (6c, Flutter) a «К заказу» inventory tab lists the suggestions
  and turns them into a one-click goods-in via the (generalized, prefill-aware) receipt dialog. **The
  patient-flow & operations overhaul is COMPLETE — Phases 0–6 + region analytics all shipped.**

**Verified green:** backend `pytest` = 262 passed · Flutter `flutter test` = 160 passed
· `flutter analyze` = no issues ·
`alembic upgrade head` = clean (head `e8c2a4f9b73d`; Phase 0 drops optics/cameras,
Phase 1 `attachments`, Phase 2 primary_doctor/queue_prefix/diagnoses, Region adds region/district,
Phase 3a/3c/3d query-only, Phase 3b adds `services.is_diagnostic`).

- **Operations → full TZ Modul 6 flow: ✅ done** — the surgery module now matches
  the clinic's ТЗ: the **doctor refers** a patient to surgery («Operatsiyaga
  yuborish», type + recommendation, **not billed**); **reception schedules** it
  (date/time, surgeon, **price** — catalog default with optional override —
  which is what **bills** the visit); then **start → perform** (FEFO consumable
  write-off) **→ complete** (clinical result on the patient card). Statuses:
  `referred → scheduled → in_progress → performed → completed` (+ `cancelled`,
  which de-bills an unpaid line). Model split `doctor_id` into
  `referring_doctor_id` + `surgeon_id` (the performer becomes the surgeon if
  reception left it unset). New: department **worklist** `GET /operations`
  (branch-scoped, status filter), **report** `GET /operations/report`
  (count + revenue + by-surgeon), permission `operations.schedule` (granted to
  Reception), `require_any_permission` helper. Flutter: doctor card now
  «Направить на операцию», new `/operations` department screen
  (schedule/start/perform/complete). Migration `a1c4e7f9d2b0`.

- **ERP optimization wave (owner brief 2026-06-20) — Phase 1: ✅ done** (branch
  `feat/erp-optimization-2026-06-20`). 14-area brief; 8-phase plan (1 inventory-UX+lab-removal,
  2 op-cost, 3 insights/notifications/dashboard-filters, 4 «талон» facade+role-scoped clinical,
  5 debt, 6 analytics+reports, 7 super-admin, 8 doc-viewer). **Phase 1 shipped:** (a) **Laboratory
  module REMOVED entirely** — backend feature/model/schema/`next_lab_no`/`lab.*` perms + Doctor
  template, frontend `lib/features/lab/` + `/lab` route/nav; migration `32eb64bbf044` drops
  `lab_orders` (the attachments document-kind `"lab"` is a *separate* file-category feature, kept).
  (b) **Inventory/operations UX:** reusable `lib/core/widgets/quantity_stepper.dart` ([−] qty [+],
  unit hidden at qty==1) in write-off + perform dialogs; the **«Выполнить» dialog is now a checkbox
  mass-write-off** (template still auto-written-off server-side — excluded from the list to avoid
  double-deduct; instruments hidden); `GET /operation-types/{id}/availability` gained
  `feasibility_count`/`min_feasibility`/`status`(🟢🟡🔴, thresh 5)/`bottleneck` with a traffic-light
  panel («Хватит ещё на N операций»); `GET /inventory/products` gained a `product_type` filter.
  **⚠️ alembic head note:** the finance module + owner-reqs moved the head past `e8c2a4f9b73d`; the
  real pre-wave head was `3f7348baf0c4`, now `32eb64bbf044`. Gates: pytest 300 · flutter 167 ·
  analyze clean · `alembic upgrade head` clean.

- **ERP optimization wave — Phase 2 (flexible operation cost): ✅ done.** An operation's cost is
  **no longer fixed at planning** — editable before/during/after until it is *financially closed*.
  `operations.financially_closed_at` (+`_by_id`; migration `b6d2f8a1c3e5`, head now `b6d2f8a1c3e5`).
  New `POST /operations/{id}/set-price` (repoints the billed `VisitItem` with **no "refund first"
  block**; returns `{operation, visit_balance, refund_due}` — overpayment on a price cut surfaces a
  refund, collected/returned via the till, never auto-refunded) and `POST /operations/{id}/financial-close`
  (freeze; after it set-price/reschedule/unschedule/cancel → 409). `close_visit` auto-closes its
  operations' finances. The old schedule "paid → refund first" re-price lock is **relaxed** to the
  financial-close gate (unschedule/cancel keep refund-first as they de-bill). Flutter: «Изменить цену» +
  «Закрыть счёт» actions + «счёт закрыт» badge. Gates: pytest 304 · flutter 167 · analyze clean.

- **ERP optimization wave — Phase 3a/3b: ✅ done** (insights engine). **3a smart notifications:**
  the insight rules are now a pure, shared `dashboard.compute_insights(db)`; `GET /dashboard/insights`
  = compute + Telegram-push of criticals; **new `GET /notifications/active`** (notifications.read) returns
  that LIVE, computed-on-read set — a notification exists only while its problem exists. The stored
  `GET /notifications` journal is now history/delivery-log only. Flutter «Уведомления» consumes the live
  endpoint (deep-linking insight cards) and **dropped the fake client-side dismissal**. **3b hanging
  visits:** `GET /dashboard/hanging-visits` (dashboard.view) returns the actual stuck patients in **5
  categories** with per-state freshness thresholds (no_doctor>4h critical, in_doctor>3h, diagnostic
  done w/o result file [no today-window], operation in_progress/performed/scheduled-past, treatment
  prescribed); `GET /visits` gained a `flow_status` CSV filter; Flutter shows a «Зависшие визиты»
  dashboard panel (expandable, tap → patient card). Gates: pytest 313 · flutter 168 · analyze clean.
  **Phase 3c (dashboard period filters Today/…/Custom) is the remaining Phase-3 piece** — it overlaps
  Phase 6 director-analytics, so the per-entity breakdowns will be built period-aware there.

- **ERP optimization wave — Phase 3c: ✅ done (Phase 3 COMPLETE).** Dashboard period filter:
  `_resolve_period_dates(period, date_from, date_to)` (presets Today/Yesterday/Week/Month/Quarter/Year
  «to date» + Custom range, 422-validated) + **`GET /dashboard/period-summary`** (dashboard.view) →
  revenue/expenses/profit/new_patients/visits/operations/diagnostics/treatments for the window. Flutter:
  `PeriodSummary` model, `periodSummaryProvider` family keyed by a `PeriodQuery` record, a «Сводка за
  период» dashboard panel (preset chips + `showDateRangePicker`, 8 metric tiles, auto-recompute on
  change). Per-entity (doctor/diagnostician/region) period breakdowns are deferred to Phase 6 (built
  period-aware there). Gates: pytest 318 · flutter 168 · analyze clean. **Branch pushed to origin**
  (`feat/erp-optimization-2026-06-20`); no PR yet (no gh).

- **ERP optimization wave — Phase 4 («Талон» facade + fix): ✅ done.** Owner chose the **facade
  path** — the `queue_tickets` table / numbering / TV board stay internal. **The «Нет активного талона»
  bug is fixed**: new `POST /visits/{id}/finish-appointment` (require_any_permission `exams.write` |
  `queue.manage`) advances the visit flow (→ follow_up/completed) **off the visit**, closing an active
  doctor ticket if one exists but never requiring one; the doctor card's «Завершить приём» now calls
  `doctorRepository.finishAppointment(visitId)` (no more ticket lookup / error). **Terminology «талон»
  → «номер»/«очередь»** across UI, the receipt PDF (now «НОМЕР В ОЧЕРЕДИ»), the TV voice phrase, and the
  queue-overload insight — internal identifiers (`QueueTicket`, `ticket_number`, table) untouched.
  Role-scoped clinical actions (diagnost conclusions via `diagnoses.record` + attachments; doctor
  referral/treatment) already exist and are now unblocked — no permission change made (a strict
  "only the diagnostician records diagnoses" would mean dropping `diagnoses.record` from Doctor;
  left for owner confirmation since the doctor's 025-8 ташхис is a separate `exams.write` path).
  Gates: pytest 322 · flutter 168 · analyze clean. **Owner decided 2026-06-21: keep `diagnoses.record`
  for BOTH doctor and diagnost (no change).**

- **ERP optimization wave — Phase 5 (debt management): ✅ done.** «Управление задолженностями» built as a
  **view over unpaid visit balances + the Payment ledger — no separate `Debt` table** (a stored copy would
  drift from the live balance), **no migration**. `GET /debts` (debtors, highest first; small `limit` feeds
  the dashboard TOP-debtors card) and `GET /debts/patient/{id}` (owing visits with amount/date/services/
  remaining + full payment history date/sum/cashier/comment), gated new `debts.read` (Reception/Cashier;
  Director auto). **Repayment — incl. partial — reuses `POST /payments`** (`issue_queue_ticket:false`), one
  payment path. Flutter `lib/features/debt/`: models + repo (`debtors`/`patientDebt`/`repay`) + providers
  (`debtorsProvider`/`topDebtorsProvider`/`patientDebtProvider`), a «Долги» screen + per-patient detail
  (repay dialog amount≤remaining/method/comment, history with refunds), routes `/debts` + `/debts/:id`
  (guard inherits `debts.read`), «Долги» nav, and a «ТОП должников» dashboard card. Gates: pytest 324 ·
  flutter 168 · analyze clean.

- **ERP optimization wave — Phase 6a (director analytics): ✅ done.** `reports.py` is already period-aware
  (`date_from`/`date_to`). Enriched: **by-doctor** +distinct_patients / repeat_patients (>1 lifetime visit) /
  avg_check / avg_consult_minutes (efficiency from queue `called_at→done_at`, computed in Python for cross-DB);
  **by-diagnostician** +studies (done diagnostic tickets) / avg_minutes; **by-operation/SurgeonRow** +cogs /
  profit per surgeon (COGS from the stock ledger per-op, same join as the operations day-summary) + clinic-wide
  cogs/profit; **new `GET /reports/profit-by-region`** (+`.csv`) — revenue + new patients per region. CSVs
  extended. Gotcha fixed: a count-only aggregate over `Payment` needs `.select_from(Payment)` or the FROM
  resolves to `Visit` and the join is ambiguous. Gates: pytest 326. **Phase 6b/6c remain:** report constructor
  (extra filters + PDF via reportlab + Excel via openpyxl) and the Flutter reports UI surfacing the new columns
  + a profit-by-region tab + export toggle. (Treatment revenue analytics has no clean price source — `Treatment`
  has no `service_id` — so it's deferred pending owner input.)

- **ERP optimization wave — Phase 6b/6c: ✅ done (Phase 6 COMPLETE).** **6b export:** `+openpyxl`;
  `core/report_export.py` `build_xlsx` (openpyxl) + `build_pdf` (reportlab, **reuses the bundled DejaVu font
  via `print_forms._register_fonts()`** so Cyrillic doesn't tofu); `reports.py` got `_xlsx`/`_pdf` helpers, each
  report's header+rows extracted into a shared `_<name>_table`, and `.xlsx`/`.pdf` endpoints for all 7 reports
  (inherit `reports.view`). **6c Flutter:** the reports models gained the new columns + a `RegionRevenueRow`;
  the repo got `ReportFormat{csv,xlsx,pdf}` + `download(slug, range, format)` + `profitByRegion`; the reports
  screen shows the new doctor/diagnostician/surgeon columns, a new «Прибыль по регионам» tab, and an «Экспорт»
  menu (CSV/Excel/PDF). Gates: pytest 328 · flutter 168 · analyze clean. Deferred: per-entity report-constructor
  filters (doctor/service/etc. as query params) — period filter + per-entity breakdowns already cover most needs.

- **ERP optimization wave — Phase 7a/7b (Super Admin pt.1): ✅ done.** **Audit «who/what/when/device»:**
  `AuditLog` gained `user_agent` (migration `c5f1a2d3b4e6`, head now `c5f1a2d3b4e6`); `record_audit` fills
  `ip_address`+`user_agent` from a **request-scoped ContextVar** (`core/audit.set_request_context`) set by an
  audit middleware in `main.py`, so the device is recorded on EVERY mutation (ContextVar copies into the
  threadpool running sync endpoints). New `GET /admin/audit-logs` (`audit.read`) — filters actor/entity_type/
  action/date + pagination + joined actor name/email (`features/audit.py`, `schemas/audit.py`). Flutter
  `lib/features/audit/` (model + repo + «Аудит действий» screen), route `/audit` + nav (gated `audit.read`); the
  network `Page` import is aliased to dodge Flutter's `Page`. **Custom roles:** 4 editable starter roles
  (Старший ресепшен / Главный врач / Старшая медсестра / Операционный менеджер) seeded via
  `STARTER_ROLE_TEMPLATES` + `_seed_starter_roles` as `is_system=False` (created once; owner can edit/delete).
  Gates: pytest 332 · flutter 168 · analyze clean. Gotcha: a test deleting a seeded role mutated the shared
  session DB and flaked — removed (the `is_system=False` assert already proves deletability).

- **ERP optimization wave — Phase 7c/7d (Super Admin pt.2): ✅ done (Phase 7 COMPLETE).** **7c monitoring:**
  `UserSession` (login history; migration `d7a3f1b9c2e4`) created on login; `core/monitoring.py` holds an
  **in-memory** registry — online last-seen (touched O(1) in `get_current_user`, no DB write on the hot path),
  ring buffers of slow requests + 5xx errors, and uptime (a `_monitor` middleware times every request). New
  `GET /admin/monitoring` + `GET /admin/sessions` (gated `audit.read`); Flutter `lib/features/monitoring/`
  («Мониторинг» screen + nav). In-memory state resets on restart / isn't shared across workers (fine for a
  single clinic server; Redis for scale). **7d archive:** `archived_at` on visits/operations/notifications
  (migration `e9b4c2a7f1d8`, head now `e9b4c2a7f1d8`); new `archive.manage` perm; `GET /admin/archive` (summary
  archived vs archivable) + `POST /admin/archive/run?older_than_days=` (stamps archived_at on old finished
  visits/operations + old notifications, idempotent — wire to a nightly job if wanted); the stored
  `GET /notifications` journal now excludes archived. Flutter `lib/features/archive/` («Архив» screen + nav).
  Gates: pytest 336 · flutter 168 · analyze clean.

- **ERP optimization wave — Phase 8 (document viewer): ✅ done (WAVE COMPLETE — all 8 phases).** In-card
  document viewing: `showDocumentViewer` / `DocumentViewerDialog` (lib/features/attachments/) — an
  Информация / Просмотр toggle + toolbar (zoom −/+/reset for images · fullscreen · download · print). Images
  use `InteractiveViewer` + `Image.memory`; **PDFs render inline on web via a browser `<iframe>` (blob URL)**
  — `inline_pdf.dart` conditional import (`inline_pdf_web.dart` registers an iframe view factory via
  `dart:ui_web` + `package:web`; `inline_pdf_io.dart` falls back to "open externally"). **No `pdfx`/native PDF
  dep** (avoids the §6 build_runner native-hook gotcha); the web iframe reuses the same blob+iframe interop as
  `printBytes`. `AttachmentsSection` opens the viewer on tap / a «Просмотр» button. Gates: flutter 169 · analyze
  clean (backend untouched, pytest 336). ⚠️ Run `flutter build web` before deploy to fully validate the web
  iframe path (analyze covers it; a dart2js build is the final check).

  **WAVE SUMMARY (owner brief 2026-06-20, branch `feat/erp-optimization-2026-06-20`, pushed):** all 8 phases
  shipped — 1 lab-removal+inventory-UX · 2 flexible op cost · 3 insights/notifications/hanging/dashboard
  filters · 4 «талон» facade+fix · 5 debt module · 6 director analytics+report export (PDF/Excel) · 7 super
  admin (audit/roles/monitoring/archive) · 8 document viewer. Migrations: `32eb64bbf044`, `b6d2f8a1c3e5`,
  `c5f1a2d3b4e6`, `d7a3f1b9c2e4`, `e9b4c2a7f1d8` (head). Final gates: pytest 336 · flutter 169 · analyze clean.

## 2. Repo map (where things live)

```
backend/                     FastAPI service (system of record)
  app/
    core/      config, database, security (JWT/bcrypt), deps (auth+RBAC),
               repository, audit, permissions catalog, id sequences,
               print_forms (Form 025-8 PDF), devices/adapters (integration seam),
               stock (FEFO write-off engine), files (upload storage),
               notify (log/Telegram + low-stock alerts)
    models/    SQLAlchemy 2.0 ORM (user, rbac, branch, patient, catalog,
               visit, payment, queue, audit, exam, device, inventory, operation)
    schemas/   Pydantic v2 DTOs
    features/  one router+service per feature (auth, users, roles, permissions,
               branches, patients, catalog, visits, payments, queue, dashboard,
               exams, devices, inventory, operations, treatments, timeline,
               search, attendance, finance, calls, notifications)
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
               devices · inventory (Склад) · finance · attendance · calls ·
               admin · search · splash
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
./.venv/Scripts/python.exe -m pytest -q                         # 140 passed
./.venv/Scripts/alembic.exe upgrade head                        # migrations (prod path)

# Docker (on a Docker-capable host; dev machine has none)
docker compose up --build                                       # api :8000 + Postgres 16

# Flutter  (separate terminal, from repo root)
flutter pub get
flutter run -d chrome                                           # dev: any localhost port OK
flutter test                                                    # 79 passed

# TV board (waiting-room screen): open in any browser, no login required
#   http://127.0.0.1:8000/tv/<branch_id>   (link dialog: Queue screen → TV icon)
```
Logins (auto-seeded; demo staff are **dev-only**, never seeded in production).
The dev login screen has one-tap **quick-login buttons** for the primary roles
(Суперадмин · Директор · Ресепшен · Врач · Диагност):
| Роль | Логин | Пароль | Заметка |
|---|---|---|---|
| Суперадмин (суперюзер) | `superadmin@kozshifo.uz` | `Superadmin!2026` | владелец: наблюдать + управлять всем |
| Директор (суперюзер) | `director@kozshifo.uz` | `Director!2026` | bootstrap-владелец |
| Ресепшен | `reception@kozshifo.uz` | `Reception!2026` | **ресепшен + касса (вкл. возвраты) + склад**; зарплаты НЕ видит |
| Врач | `vrach@kozshifo.uz` | `Vrach!2026` | |
| Диагност | `diagnost@kozshifo.uz` | `Diagnost!2026` | очередь D-трека + результаты приборов |
| Кассир | `kassa@kozshifo.uz` | `Kassa!2026` | узкая роль (split-duty); не на быстрых кнопках |
| Склад | `sklad@kozshifo.uz` | `Sklad!2026` | узкая роль (split-duty); не на быстрых кнопках |

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

**✅ Phase 4 core is DONE (2026-06)** — B-scan binary upload/serving (+doctor-card
preview via file_picker), notification core (`core/notify.py`: log rows always,
Telegram when TELEGRAM_BOT_TOKEN/CHAT_ID set; low-stock alerts on every
write-off path, 24h anti-spam), director KPIs (operations, deficit, expiring lots).

**Next (Phase 5 candidates), plus known leftovers:**
1. Real device transports (serial/HL7/DICOM stubs in `core/devices/adapters.py`), SMS provider, notification UI screen.
2. Full Director KPI suite (conversions, LTV, forecasts) + Reports engine; double-entry ledger.
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
