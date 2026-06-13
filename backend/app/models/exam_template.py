"""Doctor's saved exam-conclusion templates (reusable назначения).

A doctor types the same diagnosis + recommendations for common cases (cataract,
glaucoma follow-up, …). A template snapshots that conclusion under a name so the
next time they pick it instead of retyping. Scoped to the owning doctor; the
director (superuser) can manage any.
"""
from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class ExamTemplate(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "exam_templates"

    doctor_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    diagnosis: Mapped[str | None] = mapped_column(Text, nullable=True)
    icd10: Mapped[str | None] = mapped_column(String(16), nullable=True)
    recommendations: Mapped[str | None] = mapped_column(Text, nullable=True)
