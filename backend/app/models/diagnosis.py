"""Visit diagnoses — the doctor's conclusion as a COLLECTION, not one field.

TZ Modul 5 §7.1.5: «Bir bemorga bir nechta tashxис qo‘yilishi mumkin; barcha
tashxislar to‘planadi.» So a visit accumulates many diagnoses (each with an
optional ICD-10 code), authored by the doctor — instead of the single
`eye_exams.diagnosis` text the card carried before.

Kept separate from `eye_exams` (which stays 1:1 with the visit as the legal
form): diagnoses are 1:N and can be added/removed independently of saving the
exam body.
"""
from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class VisitDiagnosis(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "visit_diagnoses"

    visit_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="CASCADE"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    # Who diagnosed — drives the per-doctor «frequent diagnoses» aggregation.
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    diagnosis: Mapped[str] = mapped_column(Text, nullable=False)
    icd10: Mapped[str | None] = mapped_column(String(16), nullable=True)

    visit: Mapped["Visit"] = relationship()  # noqa: F821
