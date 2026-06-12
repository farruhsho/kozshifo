"""Ophthalmology exam record — the «ОКУЛИСТ КУРИГИ» section of MoH Form 025-8.

One exam per visit (one-to-one via unique visit_id). Field set and order follow
docs/DOMAIN.md §2.2–§2.3 — the card is a legal document, so names match the form.
Clinical decimals (sph/cyl, IOP) use Numeric, never float.
"""
from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import Date, ForeignKey, Integer, Numeric, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class EyeExam(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "eye_exams"

    visit_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="CASCADE"), unique=True, index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    exam_date: Mapped[date] = mapped_column(Date, default=date.today, nullable=False)

    # Subjective
    complaints: Mapped[str | None] = mapped_column(Text, nullable=True)
    anamnesis: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Refraction per eye: uncorrected Visus, correction (sph/cyl/axis), corrected VA
    od_va: Mapped[str | None] = mapped_column(String(32), nullable=True)
    os_va: Mapped[str | None] = mapped_column(String(32), nullable=True)
    od_sph: Mapped[Decimal | None] = mapped_column(Numeric(4, 2), nullable=True)
    os_sph: Mapped[Decimal | None] = mapped_column(Numeric(4, 2), nullable=True)
    od_cyl: Mapped[Decimal | None] = mapped_column(Numeric(4, 2), nullable=True)
    os_cyl: Mapped[Decimal | None] = mapped_column(Numeric(4, 2), nullable=True)
    od_axis: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 0–180
    os_axis: Mapped[int | None] = mapped_column(Integer, nullable=True)  # 0–180
    od_va_cc: Mapped[str | None] = mapped_column(String(32), nullable=True)
    os_va_cc: Mapped[str | None] = mapped_column(String(32), nullable=True)

    # Tonometry (mmHg)
    iop_od: Mapped[Decimal | None] = mapped_column(Numeric(4, 1), nullable=True)
    iop_os: Mapped[Decimal | None] = mapped_column(Numeric(4, 1), nullable=True)

    # Biomicroscopy / structures, in form order
    orbit: Mapped[str | None] = mapped_column(Text, nullable=True)
    eyeball: Mapped[str | None] = mapped_column(Text, nullable=True)
    eyelids: Mapped[str | None] = mapped_column(Text, nullable=True)
    conjunctiva: Mapped[str | None] = mapped_column(Text, nullable=True)
    lacrimal: Mapped[str | None] = mapped_column(Text, nullable=True)
    cornea: Mapped[str | None] = mapped_column(Text, nullable=True)
    anterior_chamber: Mapped[str | None] = mapped_column(Text, nullable=True)
    iris: Mapped[str | None] = mapped_column(Text, nullable=True)
    pupil: Mapped[str | None] = mapped_column(Text, nullable=True)
    lens: Mapped[str | None] = mapped_column(Text, nullable=True)
    vitreous: Mapped[str | None] = mapped_column(Text, nullable=True)
    fundus: Mapped[str | None] = mapped_column(Text, nullable=True)

    # «Кўз A/B-скан текшеруви» — note; scan files attach via DeviceResult
    ab_scan_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Conclusion: Ташхис / Тавсия
    diagnosis: Mapped[str | None] = mapped_column(Text, nullable=True)
    icd10: Mapped[str | None] = mapped_column(String(16), nullable=True)
    recommendations: Mapped[str | None] = mapped_column(Text, nullable=True)

    visit: Mapped["Visit"] = relationship(lazy="joined")  # noqa: F821
    patient: Mapped["Patient"] = relationship(lazy="joined")  # noqa: F821
    doctor: Mapped["User | None"] = relationship(lazy="joined")  # noqa: F821
