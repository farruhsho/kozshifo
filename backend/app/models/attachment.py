"""Patient file attachments — scanned analyses and documents on the card.

A general-purpose binary store for non-device documents the clinic must keep on
the patient record: УЗИ (ultrasound) conclusions, the pre-op HIV/АНАЛИЗ на СПИД
report, lab printouts, consent forms, etc. Unlike ``DeviceResult`` (which is tied
to an instrument), an attachment is owned by the patient and may optionally be
linked to a visit and/or an operation, so the same HIV PDF that reception staples
to a scheduled operation also shows up on the patient timeline.

Bytes live under ``settings.upload_dir`` via ``core.files`` (random UUID name,
20 MB cap, extension whitelist incl. .pdf). ``file_path`` keeps only the bare
generated filename — the client-supplied ``original_name`` is metadata, never a
path component (mirrors ``DeviceResult``).
"""
from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin

# Document categories. "uzi" = УЗИ-заключение, "hiv" = анализ на ВИЧ/СПИД
# (pre-op requirement), "lab" = прочие лабораторные, "other" = всё остальное.
ATTACHMENT_KINDS = ("uzi", "hiv", "lab", "other")


class Attachment(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "attachments"

    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="CASCADE"), index=True, nullable=False
    )
    # Optional context links — SET NULL so deleting a visit/operation keeps the
    # document on the patient record (the analysis itself is still history).
    visit_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="SET NULL"), index=True, nullable=True
    )
    operation_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("operations.id", ondelete="SET NULL"), index=True, nullable=True
    )
    # one of ATTACHMENT_KINDS
    kind: Mapped[str] = mapped_column(String(16), index=True, nullable=False)
    # Bare generated filename inside upload_dir (never a path).
    file_path: Mapped[str] = mapped_column(String(512), nullable=False)
    original_name: Mapped[str | None] = mapped_column(String(512), nullable=True)
    content_type: Mapped[str | None] = mapped_column(String(128), nullable=True)
    size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    note: Mapped[str | None] = mapped_column(String(512), nullable=True)
    # The room the study was done in (snapshot of the uploader's cabinet at the
    # time), so a later cabinet change doesn't rewrite this result's history.
    cabinet: Mapped[str | None] = mapped_column(String(64), nullable=True)
    uploaded_by_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    uploaded_by: Mapped["User | None"] = relationship(lazy="joined")  # noqa: F821

    @property
    def uploaded_by_name(self) -> str | None:
        return self.uploaded_by.full_name if self.uploaded_by else None
