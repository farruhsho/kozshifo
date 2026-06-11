"""Branch / clinic location — the platform is multi-branch from day one."""
from __future__ import annotations

from sqlalchemy import Boolean, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class Branch(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "branches"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    code: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    address: Mapped[str | None] = mapped_column(String(512), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
