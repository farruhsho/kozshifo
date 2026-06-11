"""Branch DTOs."""
from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BranchCreate(BaseModel):
    name: str
    code: str
    address: str | None = None
    phone: str | None = None


class BranchUpdate(BaseModel):
    name: str | None = None
    address: str | None = None
    phone: str | None = None
    is_active: bool | None = None


class BranchOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    code: str
    address: str | None
    phone: str | None
    is_active: bool
