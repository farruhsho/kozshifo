"""Aggregate all feature routers under the versioned API prefix."""
from __future__ import annotations

from fastapi import APIRouter

from app.features import (
    auth,
    branches,
    catalog,
    dashboard,
    devices,
    exams,
    inventory,
    patients,
    payments,
    permissions,
    queue,
    roles,
    users,
    visits,
)

api_router = APIRouter()
for module in (auth, permissions, roles, users, branches, patients, catalog, visits, payments, queue, dashboard, exams, devices, inventory):
    api_router.include_router(module.router)
