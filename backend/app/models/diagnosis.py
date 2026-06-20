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

from sqlalchemy import Boolean, Column, ForeignKey, String, Table, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin

# Which catalog diagnoses a staff member is allowed to record (M2M). Scopes the
# «Приём» conclusion picker for a diagnostician (e.g. УЗИ-диагност sees only УЗИ
# conclusions). Empty membership = unrestricted.
user_diagnoses = Table(
    "user_diagnoses",
    Base.metadata,
    Column("user_id", Uuid, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("diagnosis_id", Uuid, ForeignKey("diagnoses.id", ondelete="CASCADE"), primary_key=True),
)


class Diagnosis(UUIDPKMixin, TimestampMixin, Base):
    """Catalog of diagnoses / conclusions (справочник заключений).

    A reusable reference list the director maintains; staff pick from it (scoped
    by `user_diagnoses`) instead of free-typing every time. Distinct from
    `VisitDiagnosis`, which is the per-visit instance the doctor records.
    """

    __tablename__ = "diagnoses"

    code: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # Grouping label, e.g. "УЗИ" / "Диагноз" / "Биометрия". NULL = uncategorised.
    category: Mapped[str | None] = mapped_column(String(64), index=True, nullable=True)
    icd10: Mapped[str | None] = mapped_column(String(16), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


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
    # Room the conclusion was recorded in (snapshot of the recorder's cabinet).
    cabinet: Mapped[str | None] = mapped_column(String(64), nullable=True)

    visit: Mapped["Visit"] = relationship()  # noqa: F821
    doctor: Mapped["User | None"] = relationship(lazy="joined")  # noqa: F821

    @property
    def doctor_name(self) -> str | None:
        return self.doctor.full_name if self.doctor else None
