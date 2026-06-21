"""Aggregate all feature routers under the versioned API prefix."""
from __future__ import annotations

from fastapi import APIRouter

from app.features import (
    access_control,
    attachments,
    attendance,
    audit,
    auth,
    branches,
    cabinets,
    calls,
    catalog,
    dashboard,
    debt,
    devices,
    diagnoses,
    exams,
    finance,
    inventory,
    notifications,
    operations,
    patients,
    payments,
    permissions,
    queue,
    reports,
    roles,
    search,
    timeline,
    treatments,
    users,
    visits,
)

api_router = APIRouter()
for module in (auth, permissions, roles, users, branches, cabinets, patients, catalog, visits, payments, queue, dashboard, exams, devices, inventory, operations, treatments, timeline, notifications, search, attendance, finance, calls, access_control, attachments, diagnoses, reports, debt, audit):
    api_router.include_router(module.router)
