"""Audit-log DTOs (Super Admin → audit trail: who / what / when / device)."""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class AuditLogOut(BaseModel):
    id: UUID
    created_at: datetime
    action: str
    entity_type: str
    entity_id: str | None = None
    actor_id: UUID | None = None
    actor_name: str | None = None       # joined from users (кто)
    actor_email: str | None = None
    branch_id: UUID | None = None
    summary: str | None = None          # что
    ip_address: str | None = None       # откуда (IP)
    user_agent: str | None = None       # с какого устройства
