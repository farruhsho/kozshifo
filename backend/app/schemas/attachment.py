"""DTOs for patient file attachments (УЗИ, анализ на ВИЧ, прочие документы)."""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class AttachmentOut(BaseModel):
    """A stored document on the patient record. Bytes are fetched separately via
    ``GET /attachments/{id}/file`` (auth-gated) — this carries only metadata."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    visit_id: UUID | None = None
    operation_id: UUID | None = None
    kind: str
    original_name: str | None = None
    content_type: str | None = None
    size: int | None = None
    note: str | None = None
    cabinet: str | None = None        # room the study was done in
    uploaded_by_id: UUID | None = None
    uploaded_by_name: str | None = None
    created_at: datetime
