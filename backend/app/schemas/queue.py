"""Queue / TV-board DTOs (two-track: diagnostic D-… and doctor V-…)."""
from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict

QueueTrack = Literal["doctor", "diagnostic"]


class QueueTicketOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    ticket_number: str
    track: str
    patient_id: UUID
    branch_id: UUID
    visit_id: UUID | None
    service_id: UUID | None
    room: str | None
    status: str
    priority: int
    called_at: datetime | None
    called_by_id: UUID | None
    created_at: datetime


class CallNextRequest(BaseModel):
    room: str
    branch_id: UUID
    track: QueueTrack = "doctor"


class TVBoardEntry(BaseModel):
    ticket_number: str
    patient_label: str  # privacy-safe label (e.g. initials + last digits)
    room: str | None
    status: str
    called_at: datetime | None = None
    specialist: str | None = None  # full name of the user who called the ticket


class TVTrack(BaseModel):
    """One column pair of the 2x2 TV board."""

    now: list[TVBoardEntry]  # called/serving, most recently called first
    waiting: list[TVBoardEntry]  # FEFO order


class TVBoard(BaseModel):
    branch_id: UUID
    branch_name: str | None = None
    doctor: TVTrack
    diagnostic: TVTrack
