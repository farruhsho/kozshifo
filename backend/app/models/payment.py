"""Payment received against a visit (cash / card / transfer)."""
from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import ForeignKey, Numeric, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class Payment(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "payments"

    receipt_no: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    visit_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), nullable=False
    )
    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    cashier_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    method: Mapped[str] = mapped_column(String(16), default="cash", nullable=False)  # cash|card|transfer
    status: Mapped[str] = mapped_column(String(16), default="completed", nullable=False)  # completed|refunded
    note: Mapped[str | None] = mapped_column(String(512), nullable=True)
