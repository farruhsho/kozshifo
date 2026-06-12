"""Operations (surgery) and treatment prescriptions.

An OperationType is a catalog template: it points at the Service that carries
the price (single pricing source — the service catalog) and lists the
consumables auto-written-off when the operation is performed. An Operation is
one scheduled/performed instance attached to a visit; prescribing it bills the
linked service onto the visit (visit_item_id keeps the billing trace).

A Treatment is a doctor's prescription on a visit: a procedure (course item)
or a medication dispensed from the warehouse (FEFO write-off on dispense).
"""
from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, Numeric, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class OperationType(UUIDPKMixin, TimestampMixin, Base):
    """Catalog template for a surgery: priced via the linked Service."""

    __tablename__ = "operation_types"

    code: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # Price lives in the service catalog — the single pricing source.
    service_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("services.id", ondelete="RESTRICT"), nullable=False
    )
    duration_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    description: Mapped[str | None] = mapped_column(String(512), nullable=True)

    service: Mapped["Service"] = relationship(lazy="joined")  # noqa: F821
    consumables: Mapped[list["OperationTypeConsumable"]] = relationship(
        back_populates="operation_type", cascade="all, delete-orphan", lazy="selectin"
    )

    @property
    def price(self) -> Decimal:
        """The linked service's price (exposed on the API as the operation price)."""
        return self.service.price


class OperationTypeConsumable(UUIDPKMixin, TimestampMixin, Base):
    """One template line: product + quantity auto-written-off per operation."""

    __tablename__ = "operation_type_consumables"

    operation_type_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("operation_types.id", ondelete="CASCADE"), index=True, nullable=False
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("products.id", ondelete="RESTRICT"), nullable=False
    )
    quantity: Mapped[Decimal] = mapped_column(Numeric(12, 3), nullable=False)

    operation_type: Mapped[OperationType] = relationship(back_populates="consumables")
    product: Mapped["Product"] = relationship(lazy="joined")  # noqa: F821

    @property
    def product_name(self) -> str:
        return self.product.name


class Operation(UUIDPKMixin, TimestampMixin, Base):
    """One surgery instance on a visit. planned -> done | cancelled."""

    __tablename__ = "operations"

    visit_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    operation_type_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("operation_types.id", ondelete="RESTRICT"), nullable=False
    )
    # od (right) | os (left) | ou (both)
    eye: Mapped[str] = mapped_column(String(4), default="ou", nullable=False)
    # planned -> done | cancelled
    status: Mapped[str] = mapped_column(String(16), default="planned", index=True, nullable=False)
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    performed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Billing trace: the VisitItem created when the operation was prescribed.
    visit_item_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("visit_items.id", ondelete="SET NULL"), nullable=True
    )

    operation_type: Mapped[OperationType] = relationship(lazy="joined")
    patient: Mapped["Patient"] = relationship(lazy="joined")  # noqa: F821

    @property
    def type_name(self) -> str:
        return self.operation_type.name


class Treatment(UUIDPKMixin, TimestampMixin, Base):
    """Doctor's prescription: procedure or warehouse-dispensed medication."""

    __tablename__ = "treatments"

    visit_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    doctor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    # procedure | medication
    kind: Mapped[str] = mapped_column(String(16), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    product_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("products.id", ondelete="SET NULL"), nullable=True
    )
    quantity: Mapped[Decimal | None] = mapped_column(Numeric(12, 3), nullable=True)
    instructions: Mapped[str | None] = mapped_column(Text, nullable=True)
    # prescribed -> done | cancelled
    status: Mapped[str] = mapped_column(String(16), default="prescribed", index=True, nullable=False)
    performed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
