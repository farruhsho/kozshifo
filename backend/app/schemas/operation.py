"""Operations & treatments DTOs."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# ── Operation types (catalog) ─────────────────────────────────────────────────
class OperationTypeConsumableIn(BaseModel):
    product_id: UUID
    quantity: Decimal = Field(gt=0)


class OperationTypeCreate(BaseModel):
    code: str
    name: str
    service_id: UUID
    duration_minutes: int | None = None
    description: str | None = None
    consumables: list[OperationTypeConsumableIn] = []


class ConsumableOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    product_id: UUID
    product_name: str  # populated from the ORM relationship property
    quantity: Decimal


class OperationTypeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    service_id: UUID
    price: Decimal  # the linked service's price (model property)
    duration_minutes: int | None
    is_active: bool
    description: str | None
    consumables: list[ConsumableOut]


# ── Operations (instances on a visit) ─────────────────────────────────────────
class OperationCreate(BaseModel):
    operation_type_id: UUID
    eye: Literal["od", "os", "ou"] = "ou"
    scheduled_at: datetime | None = None
    notes: str | None = None
    doctor_id: UUID | None = None


class OperationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    visit_id: UUID
    patient_id: UUID
    doctor_id: UUID | None
    operation_type_id: UUID
    type_name: str  # model property -> operation_type.name
    eye: str
    status: str
    scheduled_at: datetime | None
    performed_at: datetime | None
    notes: str | None
    created_at: datetime


# ── Treatments ────────────────────────────────────────────────────────────────
class TreatmentCreate(BaseModel):
    kind: Literal["procedure", "medication"]
    name: str
    product_id: UUID | None = None
    quantity: Decimal | None = Field(default=None, gt=0)
    instructions: str | None = None
    doctor_id: UUID | None = None


class TreatmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    visit_id: UUID
    patient_id: UUID
    doctor_id: UUID | None
    kind: str
    name: str
    product_id: UUID | None
    quantity: Decimal | None
    instructions: str | None
    status: str
    performed_at: datetime | None
    created_at: datetime
