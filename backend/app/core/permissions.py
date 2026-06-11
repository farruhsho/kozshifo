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
    # Director
    ("dashboard.view", "dashboard", "View director dashboard / KPIs"),
    ("audit.read", "audit", "View audit log"),
]

ALL_CODES: list[str] = [code for code, _, _ in PERMISSIONS]

# Starter roles (seed data only). Director is also flagged superuser at the user level.
ROLE_TEMPLATES: dict[str, list[str]] = {
    "Director": ALL_CODES,
    "Reception": [
        "patients.read", "patients.create", "patients.update",
        "visits.read", "visits.create", "visits.update",
        "payments.read", "payments.create",
        "queue.read", "queue.manage",
        "services.read", "branches.read",
    ],
    "Cashier": [
        "patients.read", "visits.read",
        "payments.read", "payments.create",
        "queue.read", "queue.manage", "services.read",
    ],
    "Doctor": [
        "patients.read", "visits.read", "visits.update",
        "queue.read", "services.read",
    ],
}
