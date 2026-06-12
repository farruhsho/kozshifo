"""Queue / TV-board DTOs."""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class QueueTicketOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    ticket_number: str
    patient_id: UUID
    branch_id: UUID
    visit_id: UUID | None
    service_id: UUID | None
    room: str | None
    status: str
    priority: int
    called_at: datetime | None
    created_at: datetime


class CallNextRequest(BaseModel):
    room: str
    branch_id: UUID


class TVBoardEntry(BaseModel):
    ticket_number: str
    patient_label: str  # privacy-safe label (e.g. initials + last digits)
    room: str | None
    status: str


class TVBoard(BaseModel):
    branch_id: UUID
    branch_name: str | None = None
    now_serving: list[TVBoardEntry]
    waiting: list[TVBoardEntry]
