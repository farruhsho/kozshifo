"""Inventory / warehouse: categories, suppliers, products, stock batches & movements.

Stock is tracked per (product, branch) in *batches* (partiya) so expiry dates and
unit costs survive. Every quantity change is mirrored by an immutable
StockMovement row (positive = in, negative = out) — the movement ledger is the
audit trail of the warehouse.
"""
from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class InventoryCategory(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "inventory_categories"

    name: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("inventory_categories.id", ondelete="SET NULL"), nullable=True
    )
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)


class Supplier(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "suppliers"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class Product(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "products"

    sku: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("inventory_categories.id", ondelete="SET NULL"), nullable=True
    )
    unit: Mapped[str] = mapped_column(String(16), default="шт", nullable=False)
    # medicine | consumable | material | instrument
    product_type: Mapped[str] = mapped_column(String(16), default="consumable", nullable=False)
    barcode: Mapped[str | None] = mapped_column(String(64), index=True, nullable=True)
    min_stock: Mapped[Decimal] = mapped_column(Numeric(12, 3), default=Decimal("0"), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    description: Mapped[str | None] = mapped_column(String(512), nullable=True)


class StockBatch(UUIDPKMixin, TimestampMixin, Base):
    """One received lot of a product in one branch. quantity is the *remaining* qty."""

    __tablename__ = "stock_batches"

    product_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("products.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    batch_no: Mapped[str | None] = mapped_column(String(64), nullable=True)
    expiry_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    quantity: Mapped[Decimal] = mapped_column(Numeric(12, 3), nullable=False)
    unit_cost: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0.00"), nullable=False)
    supplier_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("suppliers.id", ondelete="SET NULL"), nullable=True
    )
    received_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    product: Mapped[Product] = relationship(lazy="joined")

    @property
    def expired(self) -> bool:
        from app.core.dates import business_today  # local: avoid models↔core cycle

        return self.expiry_date is not None and self.expiry_date < business_today()


class StockMovement(UUIDPKMixin, TimestampMixin, Base):
    """Immutable ledger row: positive quantity = stock in, negative = stock out."""

    __tablename__ = "stock_movements"

    product_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("products.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    batch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("stock_batches.id", ondelete="SET NULL"), nullable=True
    )
    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    # receipt | write_off | adjustment | transfer_out | transfer_in | supplier_return
    movement_type: Mapped[str] = mapped_column(String(16), nullable=False)
    quantity: Mapped[Decimal] = mapped_column(Numeric(12, 3), nullable=False)
    reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    # Polymorphic link to the business document that caused the movement
    # (e.g. ref_type="operation", ref_id=<operation uuid>).
    ref_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    ref_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, nullable=True)
    actor_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )


class StockCount(UUIDPKMixin, TimestampMixin, Base):
    """Инвентаризация (пересчёт факта): a physical stock-count session for one
    branch. Opened as a `draft` snapshot of current on-hand per batch; committing
    it turns every non-zero variance into an `adjustment` movement."""

    __tablename__ = "stock_counts"

    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    created_by_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    # draft | committed
    status: Mapped[str] = mapped_column(String(16), default="draft", nullable=False)
    note: Mapped[str | None] = mapped_column(String(255), nullable=True)

    lines: Mapped[list["StockCountLine"]] = relationship(
        back_populates="stock_count", cascade="all, delete-orphan", lazy="selectin"
    )


class StockCountLine(UUIDPKMixin, TimestampMixin, Base):
    """One counted line of a stock-count: a (product, batch) snapshot with the
    expected qty frozen at open time, the counted qty entered by staff, and the
    resulting variance (counted − expected)."""

    __tablename__ = "stock_count_lines"

    stock_count_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("stock_counts.id", ondelete="CASCADE"), index=True, nullable=False
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("products.id", ondelete="RESTRICT"), nullable=False
    )
    batch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("stock_batches.id", ondelete="SET NULL"), nullable=True
    )
    expected_qty: Mapped[Decimal] = mapped_column(Numeric(12, 3), nullable=False)
    counted_qty: Mapped[Decimal] = mapped_column(Numeric(12, 3), nullable=False)
    variance: Mapped[Decimal] = mapped_column(Numeric(12, 3), default=Decimal("0"), nullable=False)

    stock_count: Mapped[StockCount] = relationship(back_populates="lines")
    product: Mapped[Product] = relationship(lazy="joined")
