"""Patient DTOs."""
from __future__ import annotations

from datetime import date
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PatientCreate(BaseModel):
    first_name: str
    last_name: str
    middle_name: str | None = None
    birth_date: date | None = None
    gender: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    notes: str | None = None
    branch_id: UUID | None = None
    mrn: str | None = None  # auto-generated if omitted


class PatientUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    middle_name: str | None = None
    birth_date: date | None = None
    gender: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    notes: str | None = None


class PatientOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    mrn: str
    first_name: str
    last_name: str
    middle_name: str | None
    full_name: str
    birth_date: date | None
    gender: str | None
    phone: str | None
    email: str | None
    address: str | None
    notes: str | None
    branch_id: UUID | None
