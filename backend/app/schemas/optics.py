"""Optics salon DTOs."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

OpticsKind = Literal["glasses", "lenses"]
# ordered -> in_progress -> ready -> issued | cancelled
OpticsStatus = Literal["ordered", "in_progress", "ready", "issued", "cancelled"]


class OpticsOrderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    order_no: str
    branch_id: UUID
    patient_id: UUID
    patient_name: str
    doctor_id: UUID | None
    doctor_name: str | None = None
    kind: str
    rx: str | None
    frame: str | None
    price: Decimal
    status: str
    notes: str | None
    created_at: datetime


class OpticsOrderCreate(BaseModel):
    branch_id: UUID
    patient_id: UUID
    doctor_id: UUID | None = None
    kind: OpticsKind = "glasses"
    rx: str | None = Field(None, max_length=512)
    frame: str | None = Field(None, max_length=255)
    price: Decimal = Field(default=Decimal("0.00"), ge=0, le=Decimal("99999999.99"))
    notes: str | None = Field(None, max_length=512)


class OpticsStatusUpdate(BaseModel):
    status: OpticsStatus
