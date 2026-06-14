"""Lab / diagnostics referrals — a test ordered for a patient with its result.

One row per referral. Flow: referred → in_progress → ready (result entered),
or cancelled. The result is free text (a structured result belongs to the
device-results / EMR modules; this is the lightweight referral ledger).
"""
from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class LabOrder(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "lab_orders"

    order_no: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    # Referring doctor (optional).
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), index=True, nullable=True
    )
    test_name: Mapped[str] = mapped_column(String(255), nullable=False)
    # referred -> in_progress -> ready | cancelled
    status: Mapped[str] = mapped_column(String(16), default="referred", index=True, nullable=False)
    result: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    notes: Mapped[str | None] = mapped_column(String(512), nullable=True)
    created_by_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    patient: Mapped["Patient"] = relationship(lazy="joined")  # noqa: F821
    doctor: Mapped["User | None"] = relationship(  # noqa: F821
        foreign_keys=[doctor_id], lazy="joined"
    )

    @property
    def patient_name(self) -> str:
        return self.patient.full_name if self.patient else ""

    @property
    def doctor_name(self) -> str | None:
        return self.doctor.full_name if self.doctor else None
