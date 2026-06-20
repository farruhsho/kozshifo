"""Cabinet (consulting room) DTOs."""
from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict, field_validator


class CabinetCreate(BaseModel):
    branch_id: UUID
    name: str
    kind: str | None = None

    @field_validator("name")
    @classmethod
    def _name_not_blank(cls, v: str) -> str:
        v = (v or "").strip()
        if not v:
            raise ValueError("Cabinet name must not be blank")
        return v


class CabinetUpdate(BaseModel):
    name: str | None = None
    kind: str | None = None
    is_active: bool | None = None

    @field_validator("name")
    @classmethod
    def _name_not_blank(cls, v: str | None) -> str | None:
        if v is None:
            return v
        v = v.strip()
        if not v:
            raise ValueError("Cabinet name must not be blank")
        return v


class CabinetOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    branch_id: UUID
    name: str
    kind: str | None
    is_active: bool
