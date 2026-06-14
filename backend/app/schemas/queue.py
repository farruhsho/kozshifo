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
    # Optional adressed routing: the specialist this ticket is routed to
    # (NULL = open pool). See QueueTicket.assigned_user_id.
    assigned_user_id: UUID | None = None
    created_at: datetime


class CallNextRequest(BaseModel):
    room: str
    branch_id: UUID
    track: QueueTrack = "doctor"
    # Adressed routing (opt-in). When set, call-next claims the next ticket that
    # is routed to this specialist OR unassigned (open pool) — so reception can
    # call on behalf of a named doctor, and a doctor pulls their own + the pool.
    # Omitted (None) = unchanged behaviour: the next waiting ticket of the track.
    for_user_id: UUID | None = None


class AssignRequest(BaseModel):
    # Route a waiting ticket to a specific specialist; None clears it back to
    # the open pool.
    assigned_user_id: UUID | None = None


class SpecialistOut(BaseModel):
    """Routable staff member for the queue assign-picker (privacy: staff only).

    Exposed under queue.manage so reception/diagnost can route without the
    identity-module users.read permission.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    full_name: str
    roles: list[str] = []


class TVBoardEntry(BaseModel):
    ticket_number: str
    patient_label: str  # privacy-safe label (e.g. initials + last digits)
    room: str | None
    status: str
    called_at: datetime | None = None
    specialist: str | None = None  # full name of the user who called the ticket
    assigned: str | None = None  # full name of the specialist the ticket is routed to


class TVTrack(BaseModel):
    """One column pair of the 2x2 TV board."""

    now: list[TVBoardEntry]  # called/serving, most recently called first
    waiting: list[TVBoardEntry]  # FEFO order


class TVBoard(BaseModel):
    branch_id: UUID
    branch_name: str | None = None
    doctor: TVTrack
    diagnostic: TVTrack
