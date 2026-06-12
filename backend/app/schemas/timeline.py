"""Patient Timeline DTOs — the whole history as one chronological feed."""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class TimelineEvent(BaseModel):
    """One event in the patient's feed (read-only projection, no own table)."""

    ts: datetime
    kind: str
    title: str
    detail: str | None = None
    visit_id: UUID | None = None
    ref_id: UUID | None = None


class TimelineOut(BaseModel):
    patient_id: UUID
    events: list[TimelineEvent]
