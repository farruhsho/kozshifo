"""Visit DTOs."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class VisitItemAdd(BaseModel):
    service_id: UUID
    quantity: int = Field(default=1, ge=1)


class VisitCreate(BaseModel):
    patient_id: UUID
    branch_id: UUID
    visit_type: str = "consultation"
    doctor_id: UUID | None = None
    notes: str | None = None
    items: list[VisitItemAdd] = []


class VisitItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    service_id: UUID
    service_name: str
    unit_price: Decimal
    quantity: int
    total: Decimal
    status: str


class VisitOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    visit_no: str
    patient_id: UUID
    branch_id: UUID
    doctor_id: UUID | None
    visit_type: str
    status: str
    # Read-only by design: produced by the Smart Workflow Engine (core/flow.py);
    # there is deliberately no input DTO / endpoint that accepts this field.
    flow_status: str
    total_amount: Decimal
    paid_amount: Decimal
    balance: Decimal
    notes: str | None
    opened_at: datetime
    closed_at: datetime | None
    items: list[VisitItemOut]
