"""Patient master record (the central object of the platform)."""
from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class Patient(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "patients"

    # Medical Record Number — internal patient card identifier (e.g. P-000123).
    mrn: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    # Public 8-digit patient number (e.g. 00000123) — the human-facing ID shown
    # on receipts / queue / search. Generated alongside mrn; nullable only so the
    # additive migration can backfill existing rows (the app always sets it).
    patient_no: Mapped[str | None] = mapped_column(String(8), unique=True, index=True, nullable=True)
    first_name: Mapped[str] = mapped_column(String(128), nullable=False)
    last_name: Mapped[str] = mapped_column(String(128), nullable=False)
    middle_name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    gender: Mapped[str | None] = mapped_column(String(16), nullable=True)  # male | female | other
    phone: Mapped[str | None] = mapped_column(String(32), index=True, nullable=True)
    phone2: Mapped[str | None] = mapped_column(String(32), nullable=True)  # secondary contact
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    address: Mapped[str | None] = mapped_column(String(512), nullable=True)
    # Identity documents (Uzbekistan): passport series+number and ПИНФЛ (14 digits).
    passport: Mapped[str | None] = mapped_column(String(32), nullable=True)
    pinfl: Mapped[str | None] = mapped_column(String(14), index=True, nullable=True)
    # CRM: where the patient came from — feeds the director's lead-source analytics.
    # instagram | telegram | google | referral | banner | walk_in | other
    lead_source: Mapped[str | None] = mapped_column(String(16), index=True, nullable=True)
    # Form 025-8 cover (DOMAIN.md §2.1): place of work/study + dispensary follow-up.
    workplace: Mapped[str | None] = mapped_column(String(255), nullable=True)
    study_place: Mapped[str | None] = mapped_column(String(255), nullable=True)  # «Учёба»
    profession: Mapped[str | None] = mapped_column(String(128), nullable=True)
    dispensary_here: Mapped[str | None] = mapped_column(String(255), nullable=True)
    dispensary_other: Mapped[str | None] = mapped_column(String(255), nullable=True)
    notes: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), nullable=True
    )
    # The patient's regular («лечащий») doctor. Auto-filled on a new visit for a
    # returning patient; if the doctor is away, reception picks another for that
    # visit without changing this field. NULL = no fixed doctor yet.
    primary_doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    primary_doctor: Mapped["User | None"] = relationship(lazy="joined")  # noqa: F821

    @property
    def primary_doctor_name(self) -> str | None:
        return self.primary_doctor.full_name if self.primary_doctor else None

    @property
    def full_name(self) -> str:
        parts = [self.last_name, self.first_name, self.middle_name or ""]
        return " ".join(p for p in parts if p).strip()
