"""Service catalog DTOs."""
from __future__ import annotations

from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ServiceCategoryCreate(BaseModel):
    name: str
    description: str | None = None


class ServiceCategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None
    is_active: bool


class ServiceCreate(BaseModel):
    code: str
    name: str
    price: Decimal
    duration_minutes: int | None = None
    description: str | None = None
    category_id: UUID | None = None
    # Eligible doctors (their cabinets become the routing target). Empty = any.
    doctor_ids: list[UUID] = []


class ServiceUpdate(BaseModel):
    name: str | None = None
    price: Decimal | None = None
    duration_minutes: int | None = None
    description: str | None = None
    category_id: UUID | None = None
    is_active: bool | None = None
    doctor_ids: list[UUID] | None = None


class DoctorRef(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    full_name: str
    cabinet: str | None


class ServiceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    price: Decimal
    duration_minutes: int | None
    description: str | None
    is_active: bool
    category_id: UUID | None
    doctors: list[DoctorRef] = []
