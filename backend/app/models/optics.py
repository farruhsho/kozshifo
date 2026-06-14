"""Optics salon — a glasses/lenses order made to a patient's prescription.

One row per order. The order walks a small pipeline (ordered → in_progress →
ready → issued) and can be cancelled before it is issued. Price is the salon
charge; it is informational here (billing stays in the visit/till flow).
"""
from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import ForeignKey, Numeric, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class OpticsOrder(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "optics_orders"

    order_no: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    # Prescribing doctor (optional — a salon walk-in order has none).
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), index=True, nullable=True
    )
    kind: Mapped[str] = mapped_column(String(16), default="glasses", nullable=False)  # glasses | lenses
    rx: Mapped[str | None] = mapped_column(String(512), nullable=True)        # prescription text
    frame: Mapped[str | None] = mapped_column(String(255), nullable=True)     # frame / lens model
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0.00"), nullable=False)
    # ordered -> in_progress -> ready -> issued | cancelled
    status: Mapped[str] = mapped_column(String(16), default="ordered", index=True, nullable=False)
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
