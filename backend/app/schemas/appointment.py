"""Scheduling DTOs (appointments calendar)."""
from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

AppointmentStatus = Literal["booked", "arrived", "done", "cancelled", "no_show"]


class AppointmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    appointment_no: str
    branch_id: UUID
    patient_id: UUID
    patient_name: str
    doctor_id: UUID | None
    doctor_name: str | None = None
    cabinet: str | None
    service: str | None
    starts_at: datetime
    ends_at: datetime
    status: str
    notes: str | None
    created_at: datetime


class AppointmentCreate(BaseModel):
    branch_id: UUID
    patient_id: UUID
    doctor_id: UUID | None = None
    starts_at: datetime
    duration_min: int = Field(default=30, ge=5, le=240)
    cabinet: str | None = Field(None, max_length=32)
    service: str | None = Field(None, max_length=255)
    notes: str | None = Field(None, max_length=512)


class AppointmentReschedule(BaseModel):
    starts_at: datetime
    duration_min: int | None = Field(None, ge=5, le=240)
    doctor_id: UUID | None = None
    cabinet: str | None = Field(None, max_length=32)


class AppointmentStatusUpdate(BaseModel):
    status: AppointmentStatus


class SchedStaffOut(BaseModel):
    """Doctor/staff member for the calendar columns (under appointments.read)."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    full_name: str
    roles: list[str] = []
