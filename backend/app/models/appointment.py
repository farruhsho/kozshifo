"""Scheduling — a booked appointment slot (calendar by doctor/cabinet).

One row per booking. A *free* slot is simply the absence of a row for that
doctor+time, so the grid derives availability — we never store empty slots.
``arrived`` is a hand-off marker: reception then opens the visit as for a
walk-in (no auto-created visit, keeps the till flow single-source).
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.core.types import UTCDateTime
from app.models.base import TimestampMixin, UUIDPKMixin


class Appointment(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "appointments"

    appointment_no: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), index=True, nullable=True
    )
    cabinet: Mapped[str | None] = mapped_column(String(32), nullable=True)
    service: Mapped[str | None] = mapped_column(String(255), nullable=True)
    starts_at: Mapped[datetime] = mapped_column(UTCDateTime, index=True, nullable=False)
    ends_at: Mapped[datetime] = mapped_column(UTCDateTime, nullable=False)
    # booked -> arrived -> done | cancelled | no_show
    status: Mapped[str] = mapped_column(String(16), default="booked", index=True, nullable=False)
    notes: Mapped[str | None] = mapped_column(String(512), nullable=True)
    created_by_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    patient: Mapped["Patient"] = relationship(lazy="joined")  # noqa: F821
    # Two FKs to users (doctor + created_by) -> foreign_keys disambiguates.
    doctor: Mapped["User | None"] = relationship(  # noqa: F821
        foreign_keys=[doctor_id], lazy="joined"
    )

    @property
    def patient_name(self) -> str:
        return self.patient.full_name if self.patient else ""

    @property
    def doctor_name(self) -> str | None:
        return self.doctor.full_name if self.doctor else None
