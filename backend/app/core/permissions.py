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
    # Patients
    ("patients.read", "patients", "View patients"),
    ("patients.create", "patients", "Register patients"),
    ("patients.update", "patients", "Edit patients"),
    ("patients.delete", "patients", "Delete patients"),
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
    # Queue
    ("queue.read", "queue", "View queue & TV board"),
    ("queue.manage", "queue", "Call / serve / skip tickets"),
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
    ("operations.prescribe", "operations", "Prescribe / cancel operations"),
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
    ("calls.read", "calls", "View / search call records"),
    # Access control / Face ID terminals
    ("access_control.read", "access_control", "View face terminals, enrollment & events"),
    ("access_control.manage", "access_control", "Connect terminals, enroll staff faces"),
    # Director
    ("dashboard.view", "dashboard", "View director dashboard / KPIs"),
    ("audit.read", "audit", "View audit log"),
]

ALL_CODES: list[str] = [code for code, _, _ in PERMISSIONS]

# Starter roles (seed data only). Director is also flagged superuser at the user level.
#
# THE 3 PRIMARY ROLES a small clinic logs in as are Director / Reception / Doctor.
# Per the owner's model, the front desk (Reception) ALSO runs the till and the
# warehouse — one person registers, takes payment, does purchasing/stocktake and
# prints documents. Money REVERSALS (payments.refund), clinical authoring
# (exams.write, operations.*), and any delete stay OUT of Reception.
# Cashier / Warehouse below remain as optional narrower roles the director can
# assign when a larger clinic splits these duties (RBAC is fully dynamic).
ROLE_TEMPLATES: dict[str, list[str]] = {
    "Director": ALL_CODES,
    "Reception": [
        "patients.read", "patients.create", "patients.update",
        "visits.read", "visits.create", "visits.update",
        "payments.read", "payments.create",
        "queue.read", "queue.manage",
        # warehouse + purchasing + stocktake (front desk owns the store)
        "inventory.read", "inventory.manage", "inventory.write_off",
        # expenses (rashod)
        "expenses.read", "expenses.manage",
        "services.read", "branches.read",
        "exams.read",
        "operations.read", "treatments.read",
        "devices.read", "notifications.read",
    ],
    "Cashier": [
        "patients.read", "visits.read",
        "payments.read", "payments.create", "payments.refund",
        "queue.read", "queue.manage", "services.read",
        "expenses.read", "expenses.manage", "payroll.read",
    ],
    "Doctor": [
        "patients.read", "visits.read", "visits.update",
        "queue.read", "services.read",
        "exams.read", "exams.write",
        "devices.read", "device_results.read", "device_results.create",
        "inventory.read",
        "operations.read", "operations.prescribe", "operations.perform",
        "treatments.read", "treatments.prescribe", "treatments.perform",
    ],
    "Warehouse": [
        "inventory.read", "inventory.manage", "inventory.write_off",
        "branches.read", "notifications.read",
    ],
}
