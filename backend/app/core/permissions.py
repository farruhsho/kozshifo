"""Canonical permission catalog and starter role templates (seed data).

Permission *codes* are the single source of truth shared by the seeder and the
`require_permission(...)` dependency. Roles below are seeded as ordinary data —
they can be edited or deleted at runtime; nothing in the code branches on a
role name.
"""
from __future__ import annotations

# (code, module, description)
PERMISSIONS: list[tuple[str, str, str]] = [
    # Identity & Access
    ("users.read", "identity", "View staff users"),
    ("users.create", "identity", "Create staff users"),
    ("users.update", "identity", "Edit staff users"),
    ("users.delete", "identity", "Deactivate staff users"),
    ("roles.read", "identity", "View roles"),
    ("roles.create", "identity", "Create roles"),
    ("roles.update", "identity", "Edit roles & their permissions"),
    ("roles.delete", "identity", "Delete roles"),
    ("permissions.read", "identity", "View permission catalog"),
    # Branches
    ("branches.read", "branches", "View branches"),
    ("branches.create", "branches", "Create branches"),
    ("branches.update", "branches", "Edit branches"),
    # Cabinets (consulting rooms) — created only by the Super Admin
    ("cabinets.read", "branches", "View cabinets (rooms)"),
    ("cabinets.manage", "branches", "Create / edit cabinets (rooms)"),
    # Patients
    ("patients.read", "patients", "View patients"),
    ("patients.create", "patients", "Register patients"),
    ("patients.update", "patients", "Edit patients"),
    ("patients.delete", "patients", "Delete patients"),
    # Patient document attachments (УЗИ-заключения, анализ на ВИЧ, прочие сканы)
    ("attachments.read", "attachments", "View patient file attachments"),
    ("attachments.write", "attachments", "Upload / delete patient attachments"),
    # Diagnosis / conclusion catalog (справочник заключений)
    ("diagnoses.read", "diagnoses", "View the diagnosis catalog"),
    ("diagnoses.manage", "diagnoses", "Create / edit diagnoses"),
    ("diagnoses.record", "diagnoses", "Record a diagnostic conclusion on a visit"),
    # Service catalog
    ("services.read", "catalog", "View services"),
    ("services.create", "catalog", "Create services & categories"),
    ("services.update", "catalog", "Edit services & categories"),
    # Visits
    ("visits.read", "visits", "View visits"),
    ("visits.create", "visits", "Open visits & add services"),
    ("visits.update", "visits", "Edit visits"),
    ("visits.close", "visits", "Close / cancel visits"),
    # Payments
    ("payments.read", "finance", "View payments"),
    ("payments.create", "finance", "Take payments"),
    ("payments.refund", "finance", "Refund payments"),
    ("debts.read", "finance", "View patient debts / top debtors"),
    # Queue
    ("queue.read", "queue", "View queue & TV board"),
    ("queue.manage", "queue", "Call / serve / skip tickets"),
    ("queue.admin", "queue", "Open the general two-track queue board (front desk / director)"),
    # EMR (Form 025-8 eye exam)
    ("exams.read", "emr", "View eye exams / print Form 025-8"),
    ("exams.write", "emr", "Create / edit eye exams"),
    # Medical devices
    ("devices.read", "devices", "View medical devices"),
    ("devices.manage", "devices", "Register / edit medical devices"),
    ("device_results.read", "devices", "View device measurement results"),
    ("device_results.create", "devices", "Record / import device results"),
    # Inventory / warehouse
    ("inventory.read", "inventory", "View warehouse stock & catalog"),
    ("inventory.manage", "inventory", "Manage products / suppliers / receipts"),
    ("inventory.write_off", "inventory", "Write off stock"),
    # Operations (surgery)
    ("operations.read", "operations", "View operations & types"),
    ("operations.manage", "operations", "Manage operation types"),
    ("operations.prescribe", "operations", "Refer / cancel operations (doctor)"),
    ("operations.schedule", "operations", "Schedule operations: date/surgeon/price (reception)"),
    ("operations.perform", "operations", "Perform operations (auto write-off)"),
    # Treatment
    ("treatments.read", "treatment", "View treatment prescriptions"),
    ("treatments.prescribe", "treatment", "Prescribe / cancel treatments"),
    ("treatments.perform", "treatment", "Dispense / complete treatments"),
    # Notifications
    ("notifications.read", "notifications", "View notification log"),
    # Attendance (TZ Modul 1 — Face ID time tracking)
    ("attendance.read", "attendance", "View staff attendance reports"),
    ("attendance.manage", "attendance", "Record manual attendance punches"),
    # Finance: expenses & payroll (TZ Modul 8)
    ("expenses.read", "finance", "View clinic expenses"),
    ("expenses.manage", "finance", "Record / edit clinic expenses"),
    ("payroll.read", "finance", "View payroll calculations"),
    ("payroll.manage", "finance", "Post payroll payouts"),
    # IP telephony (TZ Modul 9)
    ("calls.read", "calls", "View / search call records & KPIs"),
    ("calls.manage", "calls", "Register reception phones / rotate device keys"),
    # Access control / Face ID terminals
    ("access_control.read", "access_control", "View face terminals, enrollment & events"),
    ("access_control.manage", "access_control", "Connect terminals, enroll staff faces"),
    # Director
    ("dashboard.view", "dashboard", "View director dashboard / KPIs"),
    ("reports.view", "reports", "View director reports (financial / clinical / CRM) + CSV export"),
    ("audit.read", "audit", "View audit log"),
    ("archive.manage", "audit", "View archive & auto-archive old records"),
]

ALL_CODES: list[str] = [code for code, _, _ in PERMISSIONS]

# System-administration codes the Director must NOT hold. Per the owner's model
# the Super Admin (owner) alone creates staff, assigns roles, manages branches
# and cabinets; the Director sees everything and runs day-to-day operations but
# «не может изменять системные настройки». The Director is therefore NOT a
# superuser (see seed.py) and is granted ALL_CODES MINUS this set — keeping
# read-only visibility of staff/roles/branches but no mutation.
_DIRECTOR_CANNOT: set[str] = {
    "users.create", "users.update", "users.delete",
    "roles.create", "roles.update", "roles.delete",
    "branches.create", "branches.update",
    "cabinets.manage",  # Phase 4: cabinets are owner-only
}

# Starter roles (seed data only).
#
# THE PRIMARY ROLES a small clinic logs in as are Super Admin / Director /
# Administrator / Doctor. Per the owner's model the Super Admin (owner) alone
# changes system settings; the front office is ONE seat — the **Administrator**
# folds reception + касса (till) + склад (warehouse) into a single role: one
# person registers, takes payment & refunds, runs purchasing/stocktake, prints
# documents and watches finance analytics / reports. Clinical authoring
# (exams.write, operations prescribe/perform) stays OUT. System administration
# (users/roles/branches/cabinets mutation) stays owner-only — even the Director
# only has read-only visibility there.
ROLE_TEMPLATES: dict[str, list[str]] = {
    # Superadmin — owner tier: every permission AND is_superuser at the user
    # level (bypasses checks). Only an account WITH this role may see/manage other
    # Superadmins (see _is_owner in users.py).
    "Superadmin": ALL_CODES,
    # Director — sees ALL queues/finance/operations/reports/patients and runs
    # day-to-day work, but cannot change system settings: no staff/role/branch/
    # cabinet mutation (owner-only). NOT a superuser (no bypass) so these limits
    # actually bite; the owner-visibility rule still hides the Superadmin account.
    "Director": [c for c in ALL_CODES if c not in _DIRECTOR_CANNOT],
    # Administrator — the merged front office (ресепшен + касса + склад) for one
    # branch, plus finance analytics & reports. Everything EXCEPT clinical
    # authoring and owner-only system administration.
    "Administrator": [
        "patients.read", "patients.create", "patients.update",
        # scanned analyses (УЗИ-заключения, анализ на ВИЧ перед операцией и т.п.)
        "attachments.read", "attachments.write",
        "visits.read", "visits.create", "visits.update",
        # FULL till incl. refunds (касса) + patient debts / top debtors (Долги)
        "payments.read", "payments.create", "payments.refund", "debts.read",
        # owns the general two-track queue board
        "queue.read", "queue.manage", "queue.admin",
        # warehouse + purchasing + stocktake (склад)
        "inventory.read", "inventory.manage", "inventory.write_off",
        # expenses + payroll visibility (runs клиника finances)
        "expenses.read", "expenses.manage", "payroll.read",
        # price list — add / edit (Услуги)
        "services.read", "services.create", "services.update",
        "branches.read", "cabinets.read",
        "exams.read", "diagnoses.read",
        # Operations dept (TZ Modul 6): schedule referred operations (date/surgeon/price)
        "operations.read", "operations.schedule", "treatments.read",
        "devices.read", "notifications.read",
        # management views: finance analytics + director-style reports + staff
        # attendance (Аналитика / Отчёты / Сотрудники). View-only — no system
        # administration (users/roles/branches/cabinets stay owner-only).
        "dashboard.view", "reports.view", "attendance.read",
    ],
    "Doctor": [
        "patients.read", "visits.read", "visits.update",
        "attachments.read", "attachments.write",
        # queue.manage: a doctor runs their OWN queue — calls the next patient
        # into their cabinet, recalls, returns to waiting (the «Моя очередь·Приём»
        # workstation). Reception keeps the full two-track board. Also finishes
        # walk-in patients auto-queued after diagnostics → cashier (TZ §7.1.6).
        "queue.read", "queue.manage", "services.read", "cabinets.read",
        "exams.read", "exams.write", "diagnoses.read", "diagnoses.manage", "diagnoses.record",
        "devices.read", "device_results.read", "device_results.create",
        "inventory.read",
        "operations.read", "operations.prescribe", "operations.perform",
        "treatments.read", "treatments.prescribe", "treatments.perform",
    ],
    # Diagnostics workspace: serves the D-track, records device measurements,
    # sees patients/visits. No clinical authoring (exams.write) or money.
    "Diagnost": [
        "patients.read", "visits.read",
        # diagnost attaches УЗИ / scan conclusions to the patient card
        "attachments.read", "attachments.write",
        "queue.read", "queue.manage", "cabinets.read",
        "exams.read", "diagnoses.read", "diagnoses.record",
        "devices.read", "device_results.read", "device_results.create",
    ],
    # Лечебный кабинет (процедурная медсестра) — runs ONLY the treatment track
    # «Мои процедуры» (/treatment-queue, gated treatments.perform): calls the
    # next Л-… patient into the procedure room, dispenses/completes treatments,
    # reads the patient card + scans. NO general queue (no queue.admin), NO
    # personal doctor/diagnost workstation (no device_results.create), NO
    # clinical authoring (no exams.write) and no money.
    "TreatmentRoom": [
        "patients.read", "visits.read",
        "attachments.read",
        "queue.read", "queue.manage", "cabinets.read",
        "treatments.read", "treatments.perform",
        "diagnoses.read",
    ],
}

# Example CUSTOM roles seeded ONCE as editable starters (is_system=False), per the
# owner's Super-Admin brief («создание собственных ролей» — Старший ресепшен /
# Главный врач / Старшая медсестра / Операционный менеджер). Unlike ROLE_TEMPLATES
# (system roles re-synced every seed), these are created only if absent and never
# overwritten, so the owner can rename / retune / delete them.
STARTER_ROLE_TEMPLATES: dict[str, list[str]] = {
    "Старший ресепшен": ROLE_TEMPLATES["Administrator"] + [
        "reports.view", "dashboard.view",
    ],
    "Главный врач": ROLE_TEMPLATES["Doctor"] + [
        "reports.view", "dashboard.view", "operations.schedule",
    ],
    "Старшая медсестра": ROLE_TEMPLATES["TreatmentRoom"] + [
        "inventory.read", "devices.read", "attendance.read",
    ],
    "Операционный менеджер": [
        "patients.read", "visits.read", "queue.read",
        "operations.read", "operations.schedule", "operations.manage",
        "inventory.read", "treatments.read", "expenses.read",
        "reports.view", "dashboard.view", "cabinets.read", "services.read",
    ],
}
