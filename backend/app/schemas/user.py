"""Staff user DTOs."""
from __future__ import annotations

from decimal import Decimal
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
    # Clinical setup (director sets these when creating a doctor): the doctor's
    # cabinet and the services they provide. None/empty for non-clinical staff.
    cabinet: str | None = None
    service_ids: list[UUID] = []
    # Queue-ticket prefix (e.g. "С" → С-001). Omitted = derived from full_name.
    queue_prefix: str | None = None
    # Visiting/external surgeon (from out of town) — shown in surgeon pickers.
    is_external_surgeon: bool = False
    # Diagnoses/conclusions this staff member may record (scopes the Приём picker).
    diagnosis_ids: list[UUID] = []


class UserUpdate(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    is_active: bool | None = None
    branch_id: UUID | None = None
    role_names: list[str] | None = None
    # Percent-based payroll (TZ Modul 8): doctor's cut of revenue from their
    # visits. Explicit null clears it (= not on percent-based pay).
    salary_percent: Decimal | None = Field(default=None, ge=0, le=100)
    cabinet: str | None = None
    service_ids: list[UUID] | None = None
    queue_prefix: str | None = None
    is_external_surgeon: bool | None = None
    diagnosis_ids: list[UUID] | None = None


class RoleRef(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str


class ServiceRef(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str


class DiagnosisRef(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
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
    salary_percent: Decimal | None
    cabinet: str | None = None
    queue_prefix: str | None = None
    is_external_surgeon: bool = False
    roles: list[RoleRef]
    services: list[ServiceRef] = []
    diagnoses: list[DiagnosisRef] = []
