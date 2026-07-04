"""Visit (encounter) and its billed line items.

A Visit is opened when a patient arrives. Services are added as VisitItems;
payments draw down the balance. Totals are kept in sync by the visit service.
"""
from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, ForeignKey, Integer, Numeric, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.core.types import UTCDateTime
from app.models.base import TimestampMixin, UUIDPKMixin


class Visit(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "visits"

    visit_no: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    visit_type: Mapped[str] = mapped_column(String(32), default="consultation", nullable=False)
    # open -> in_progress -> completed | cancelled
    status: Mapped[str] = mapped_column(String(16), default="open", index=True, nullable=False)
    # Smart Workflow Engine lifecycle (app/core/flow.py). NEVER written via the
    # API — it advances itself from real events (payment, queue calls, doctor
    # prescriptions, close/cancel). Fixed vocabulary:
    #   registered, waiting_diagnostic, in_diagnostic, waiting_doctor, in_doctor,
    #   treatment_assigned, surgery_assigned, surgery_scheduled, surgery_completed,
    #   follow_up, completed, cancelled.
    flow_status: Mapped[str] = mapped_column(
        String(24), default="registered", index=True, nullable=False
    )
    total_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0.00"), nullable=False)
    paid_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0.00"), nullable=False)
    # Reception discount (TZ Modul 2.2): EITHER percent OR fixed amount, plus a
    # mandatory reason when set. total_amount stays gross; payable applies it.
    discount_percent: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    discount_amount: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    discount_reason: Mapped[str | None] = mapped_column(String(128), nullable=True)
    # Emergency / priority intake (reception «ЭКСТРЕННО»). priority>0 jumps the
    # queue: the ticket minted on payment inherits it (+ reason) and the receipt
    # / TV board flag «ЭКСТРЕННЫЙ». Reason is kept for analytics & audit.
    priority: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    priority_reason: Mapped[str | None] = mapped_column(String(128), nullable=True)
    notes: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    # Дата повторного приёма (recall). Проставляется врачом при завершении приёма
    # с переводом визита в follow_up; питает список «на повторный приём» (recall).
    follow_up_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    opened_at: Mapped[datetime] = mapped_column(
        UTCDateTime, server_default=func.now(), nullable=False
    )
    closed_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
    # Auto-archive (Super Admin): old completed/cancelled visits get a timestamp
    # so they can be filtered out of active views. NULL = live.
    archived_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)

    patient: Mapped["Patient"] = relationship(lazy="joined")  # noqa: F821
    items: Mapped[list["VisitItem"]] = relationship(
        back_populates="visit", cascade="all, delete-orphan", lazy="selectin"
    )

    @property
    def discount_value(self) -> Decimal:
        """Discount in currency, derived from percent or fixed amount (capped at total)."""
        total = Decimal(self.total_amount)
        if self.discount_percent:
            return (total * Decimal(self.discount_percent) / Decimal("100")).quantize(Decimal("0.01"))
        if self.discount_amount:
            return min(Decimal(self.discount_amount), total)
        return Decimal("0.00")

    @property
    def payable(self) -> Decimal:
        """What the patient actually owes: gross total minus discount."""
        return Decimal(self.total_amount) - self.discount_value

    @property
    def balance(self) -> Decimal:
        return self.payable - Decimal(self.paid_amount)


class VisitItem(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "visit_items"

    visit_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="CASCADE"), index=True, nullable=False
    )
    service_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("services.id", ondelete="RESTRICT"), nullable=False
    )
    service_name: Mapped[str] = mapped_column(String(255), nullable=False)  # snapshot at order time
    unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    # ordered -> paid -> in_progress -> done
    status: Mapped[str] = mapped_column(String(16), default="ordered", nullable=False)

    visit: Mapped[Visit] = relationship(back_populates="items")
