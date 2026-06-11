"""RBAC DTOs: permissions and roles."""
from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PermissionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    module: str
    description: str | None


class RoleCreate(BaseModel):
    name: str
    description: str | None = None
    permission_codes: list[str] = []


class RoleUpdate(BaseModel):
    description: str | None = None
    permission_codes: list[str] | None = None


class RoleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None
    is_system: bool
    permissions: list[PermissionOut]
