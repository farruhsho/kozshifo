"""Aggregate all feature routers under the versioned API prefix."""
from __future__ import annotations

from fastapi import APIRouter

from app.features import (
    access_control,
    attendance,
    auth,
    branches,
    calls,
    catalog,
    dashboard,
    devices,
    exams,
    finance,
    inventory,
    notifications,
    operations,
    patients,
    payments,
    permissions,
    queue,
    roles,
    search,
    timeline,
    treatments,
    users,
    visits,
)

api_router = APIRouter()
for module in (auth, permissions, roles, users, branches, patients, catalog, visits, payments, queue, dashboard, exams, devices, inventory, operations, treatments, timeline, notifications, search, attendance, finance, calls, access_control):
    api_router.include_router(module.router)
