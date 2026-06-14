"""Lab referral DTOs."""
from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

# referred -> in_progress -> ready | cancelled
LabStatus = Literal["referred", "in_progress", "ready", "cancelled"]


class LabOrderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    order_no: str
    branch_id: UUID
    patient_id: UUID
    patient_name: str
    doctor_id: UUID | None
    doctor_name: str | None = None
    test_name: str
    status: str
    result: str | None
    notes: str | None
    created_at: datetime


class LabOrderCreate(BaseModel):
    branch_id: UUID
    patient_id: UUID
    doctor_id: UUID | None = None
    test_name: str = Field(min_length=1, max_length=255)
    notes: str | None = Field(None, max_length=512)


class LabResultUpdate(BaseModel):
    """Enter a result; this also moves the referral to ``ready``."""

    result: str = Field(min_length=1, max_length=2000)


class LabStatusUpdate(BaseModel):
    status: LabStatus
