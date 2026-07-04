"""Staff user DTOs."""
from __future__ import annotations

from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, model_validator

# Doctor pay (TZ Modul 8): each side (consult / operation) is paid either as a
# PERCENT of that side's revenue, or a FIXED sum. NULL type = side not paid.
SalaryType = Literal["percent", "fixed"]


def _validate_percent_caps(model: "BaseModel") -> "BaseModel":
    """A 'percent'-type salary value must be 0..100 (a fixed value may exceed)."""
    for side in ("consult", "operation"):
        if getattr(model, f"{side}_salary_type", None) == "percent":
            value = getattr(model, f"{side}_salary_value", None)
            if value is not None and value > 100:
                raise ValueError(f"{side}_salary_value must be <= 100 for percent pay")
    return model


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
    # Flexible doctor pay: consult & operation each percent|fixed (see SalaryType).
    consult_salary_type: SalaryType | None = None
    consult_salary_value: Decimal | None = Field(default=None, ge=0)
    operation_salary_type: SalaryType | None = None
    operation_salary_value: Decimal | None = Field(default=None, ge=0)

    _check_percent = model_validator(mode="after")(_validate_percent_caps)


class UserUpdate(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    is_active: bool | None = None
    branch_id: UUID | None = None
    role_names: list[str] | None = None
    # Percent-based payroll (TZ Modul 8): doctor's cut of revenue from their
    # visits. Explicit null clears it (= not on percent-based pay).
    salary_percent: Decimal | None = Field(default=None, ge=0, le=100)
    # Flexible doctor pay. Explicit null clears that side. A "percent" value is
    # additionally capped at 100 by the endpoint (a fixed value can exceed 100).
    consult_salary_type: SalaryType | None = None
    consult_salary_value: Decimal | None = Field(default=None, ge=0)
    operation_salary_type: SalaryType | None = None
    operation_salary_value: Decimal | None = Field(default=None, ge=0)
    cabinet: str | None = None
    service_ids: list[UUID] | None = None
    queue_prefix: str | None = None
    is_external_surgeon: bool | None = None
    diagnosis_ids: list[UUID] | None = None

    _check_percent = model_validator(mode="after")(_validate_percent_caps)


class UserSetPassword(BaseModel):
    """Admin password reset (POST /users/{id}/set-password) — the only way to
    change a staff password after creation. Same length floor as UserCreate."""

    password: str = Field(min_length=8)


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
    consult_salary_type: str | None = None
    consult_salary_value: Decimal | None = None
    operation_salary_type: str | None = None
    operation_salary_value: Decimal | None = None
    cabinet: str | None = None
    queue_prefix: str | None = None
    is_external_surgeon: bool = False
    roles: list[RoleRef]
    services: list[ServiceRef] = []
    diagnoses: list[DiagnosisRef] = []
