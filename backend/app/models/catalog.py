"""Service catalog: categories and priced services billed on a visit."""
from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import Boolean, ForeignKey, Integer, Numeric, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


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
