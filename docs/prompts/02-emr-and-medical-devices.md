# ULTRA PROMPT — Epic 2: Ophthalmology EMR (Form 025-8) + Medical Devices

> Hand this whole file to a coding agent. It is self-contained but assumes the
> repo. **First action: read `AGENTS.md`, then `PLATFORM.md`, then this file's
> ground-truth source `docs/DOMAIN.md`.** Do not start coding until you have.

---

## ROLE
You are the autonomous senior engineering team (CTO + Principal Engineer + HIS
Architect + QA Lead) for **KO'Z SHIFO**, a medical ERP/HIS for an eye clinic.
Work to production quality. Make sound decisions autonomously; don't ask trivial
questions. Honor every convention in `AGENTS.md` §4–§6 (it overrides your defaults).

## CONTEXT (what already exists — do not rebuild)
- **Backend (FastAPI, tested):** auth (JWT), dynamic RBAC by permission code,
  audit log, multi-branch, and the Patient-Journey core: `Patient → Visit →
  Services → Payment → Queue ticket → TV board → Director KPIs`. Layering:
  `core / models / schemas / features`, SQLite dev / Postgres-ready.
- **Flutter (Clean Arch, compiles):** Riverpod · GoRouter (auth-guarded) · Dio
  (JWT) · Freezed. Screens: login, director dashboard, patients (list/search/register).
- A `Visit` is the encounter that everything attaches to. A `User` with the
  `Doctor` role exists. `Patient` already has name/DOB/phone/address/MRN.

## MISSION (this epic)
Turn the system from "front-desk + billing" into a real **clinical HIS** by adding:
1. **EPIC 2A — Ophthalmology EMR / Patient Card** that captures (and can print)
   the clinic's legal record: **MoH Form 025-8 «Амбулатор тиббий карта»**.
2. **EPIC 2B — Medical Devices registry + results**, seeded with the clinic's two
   real instruments, with the **refractometer auto-filling the eye exam** and the
   **A/B ultrasound attaching scans** to the visit.

**Ground truth for all fields/specs is `docs/DOMAIN.md`. Match it exactly.**

---

## EPIC 2A — Ophthalmology EMR (Form 025-8)

### Backend
1. **Extend `Patient`** (cover §2.1 of DOMAIN.md): add `workplace`, `dispensary_here`,
   `dispensary_other` (all nullable text). Update schema + migration path. `mrn` is
   the "Бемор коди".
2. **New model `EyeExam`** (one per Visit; `app/models/exam.py`), attached to
   `visit_id` (unique), `patient_id`, `doctor_id`, `exam_date`. Fields per DOMAIN.md §2.2:
   - `complaints`, `anamnesis` (text)
   - Refraction per eye: `od_va`, `os_va` (str, uncorrected Visus);
     `od_sph`,`od_cyl` `Numeric(4,2)`, `od_axis` int(0–180), `od_va_cc` (corrected VA str);
     same `os_*`.
   - IOP: `iop_od`, `iop_os` (`Numeric(4,1)`, nullable).
   - Slit-lamp / structures (nullable text, form order): `orbit`, `eyeball`,
     `eyelids`, `conjunctiva`, `lacrimal`, `cornea`, `anterior_chamber`, `iris`,
     `pupil`, `lens`, `vitreous`, `fundus`.
   - `ab_scan_note` (text) + relation to attached device results.
   - Conclusion: `diagnosis` (text), `icd10` (str, nullable), `recommendations` (text).
3. **Schemas** (`schemas/exam.py`): `EyeExamUpsert`, `EyeExamOut`. Validate axis 0–180.
4. **Feature** (`features/exams.py`):
   - `PUT  /visits/{visit_id}/exam` — create-or-update the exam (idempotent upsert).
   - `GET  /visits/{visit_id}/exam`
   - `GET  /patients/{patient_id}/exams` — chronological history.
   - Guard with permission codes `exams.read`, `exams.write`. Add them to
     `core/permissions.py` and grant `exams.*` to the `Doctor` template (read to Reception).
   - `record_audit(...)` on every write.
5. **Print 025-8 (sub-task, can be a thin first pass):** `GET /visits/{id}/exam/card.pdf`
   rendering the official card (cover + oculist exam + conclusion) with the clinic
   header. A server-side PDF (reportlab/weasyprint) is fine; if deferred, stub the
   route and track it in PLATFORM.md.
6. **Tests** (`backend/tests/test_eye_exam.py`): upsert round-trips; axis validation
   rejects 200; RBAC — a user without `exams.write` gets 403; history returns N exams.

### Flutter (Doctor module — `features/doctor/`)
- **Patient card screen**: patient header (025-8 cover) + the visit's **EyeExam form**
  laid out in form-025-8 order (complaints, anamnesis, Visus OD/OS with sph/cyl/ax,
  IOP OD/OS, the 12 structure fields, diagnosis + ICD-10, recommendations). Save via
  `PUT /visits/{id}/exam`. Freezed model + repository + Riverpod, per `AGENTS.md` §5.
- Entry point: from a Visit (add a "Open card" action) and from the patients list.
- Show exam **history** for the patient (read-only past exams).
- Permission-gate edit on `exams.write`.

---

## EPIC 2B — Medical Devices

### Backend
1. **`Device` model** (`models/device.py`): `name`, `device_type`
   (`ab_ultrasound | refractometer | other`), `model`, `manufacturer`, `serial_no`
   (unique), `asset_code`, `connection_type` (`manual | file | serial | usb | hl7 | dicom`),
   `branch_id`, `status` (`active|inactive|maintenance`), `manufacture_date`,
   `settings` (JSON), plus optional `eu_rep`, `address`, `useful_life_years`.
2. **`DeviceResult` model**: `device_id`, `patient_id?`, `visit_id?`, `result_type`
   (`refraction | biometry | bscan_image | file`), `payload` (JSON; e.g. refraction
   `{od:{sph,cyl,axis}, os:{...}}`), `file_path?`, `measured_at`, `source`
   (`manual | import`).
3. **Seed** the two real devices from `docs/DOMAIN.md` §1 in `seed.py` (idempotent by serial_no).
4. **Adapter seam** (`core/devices/`): `DeviceAdapter` protocol with
   `ManualEntryAdapter` and `FileImportAdapter` implemented now; leave a clear TODO
   interface for `SerialAdapter`/`Hl7Adapter`/`DicomAdapter`. **Don't** implement real
   protocol I/O this epic.
5. **Feature** (`features/devices.py`):
   - `GET/POST/PATCH /devices` (perm `devices.read` / `devices.manage`).
   - `POST /devices/{id}/results` (perm `device_results.create`) — manual or file.
   - `GET /visits/{visit_id}/device-results`.
   - `POST /visits/{visit_id}/exam/apply-refraction?result_id=…` — copy the latest
     refractometer `DeviceResult` into the visit's `EyeExam` (od/os sph/cyl/axis).
   - Audit all writes. Add permission codes to `core/permissions.py`.
6. **Tests** (`test_devices.py`): two devices seeded; post a refraction result and
   `apply-refraction` populates the exam's sph/cyl/axis for OD & OS; RBAC enforced.

### Flutter
- **Devices admin screen** (director; `features/devices/`): list seeded devices, status,
  view recent results.
- In the doctor card: **"Подтянуть из рефрактометра"** button → calls `apply-refraction`,
  refreshes the form. **"A/B-скан"** section → list/preview attached scan files for the visit.

---

## CONVENTIONS (non-negotiable — see AGENTS.md)
- Dynamic RBAC: **check permission codes, never role names**. Director = superuser bypass.
- **Audit every mutation** in the same transaction (`record_audit`).
- Money = decimal string on the wire; **never float**. Clinical decimals
  (sph/cyl/IOP) use `Numeric`, sent as strings; parse with `Decimal`/string on client.
- Freezed models: JSON is **snake_case** (build.yaml). After editing a model run
  `dart run build_runner build --delete-conflicting-outputs`. **Do not re-add packages
  with native build hooks** (broke build_runner; see AGENTS.md §6).
- Follow the existing feature/file layout; copy `patients`/`visits` as templates.

## DEFINITION OF DONE
- [ ] Backend `pytest -q` green **including** the new `test_eye_exam.py` & `test_devices.py`.
- [ ] `flutter analyze` clean **and** `flutter build web` succeeds; `flutter test` green.
- [ ] An eye exam created from the Flutter doctor card round-trips through the API and
      re-opens with all fields.
- [ ] Posting a refractometer `DeviceResult` and calling `apply-refraction` fills the
      exam's OD/OS sph/cyl/axis.
- [ ] The two real devices appear seeded in `GET /devices`.
- [ ] `PLATFORM.md` matrix rows (Doctors/EMR #13, Diagnostics #11, Medical Devices #12)
      and `AGENTS.md` §1/§7 updated to reflect what shipped.

## OUT OF SCOPE (later phases)
Real protocol auto-capture (serial/HL7/DICOM), IOL-power calculation formulas,
Operations/Treatment, Inventory auto write-off, multi-doctor workflow routing.

## SUGGESTED ORDER
1. Patient cover fields → 2. `EyeExam` model+API+tests → 3. Doctor card screen →
4. `Device`/`DeviceResult` + seed + tests → 5. `apply-refraction` wiring → 6. Devices UI
→ 7. 025-8 PDF → 8. update docs.
