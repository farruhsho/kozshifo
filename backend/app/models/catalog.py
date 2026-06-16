"""Service catalog: categories and priced services billed on a visit."""
from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import Boolean, Column, ForeignKey, Integer, Numeric, String, Table, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin

# Doctors eligible to provide a service (M2M). Empty for a service = open pool
# (any doctor); the cabinet always comes from whichever doctor calls the ticket.
service_doctors = Table(
    "service_doctors",
    Base.metadata,
    Column("service_id", Uuid, ForeignKey("services.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id", Uuid, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
)


class ServiceCategory(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "service_categories"

    name: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class Service(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "services"

    code: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0.00"), nullable=False)
    duration_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    description: Mapped[str | None] = mapped_column(String(512), nullable=True)
    category_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("service_categories.id", ondelete="SET NULL"), nullable=True
    )

    category: Mapped[ServiceCategory | None] = relationship(lazy="joined")
    # Eligible doctors (M2M) — reception picks them on the service form; the
    # queue routes a paid ticket to one of them, into that doctor's cabinet.
    doctors: Mapped[list["User"]] = relationship(  # noqa: F821
        "User", secondary=service_doctors, back_populates="services", lazy="selectin"
    )
