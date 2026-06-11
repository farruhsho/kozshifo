"""Staff user DTOs."""
from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserCreate(BaseModel):
    email: EmailStr
    full_name: str
    password: str = Field(min_length=8)
    phone: str | None = None
    branch_id: UUID | None = None
    is_superuser: bool = False
    role_names: list[str] = []


class UserUpdate(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    is_active: bool | None = None
    branch_id: UUID | None = None
    role_names: list[str] | None = None


class RoleRef(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    full_name: str
    phone: str | None
    is_active: bool
    is_superuser: bool
    branch_id: UUID | None
    roles: list[RoleRef]
