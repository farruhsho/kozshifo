"""Patient master record (the central object of the platform)."""
from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import Date, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class Patient(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "patients"

    # Medical Record Number — human-facing patient card identifier.
    mrn: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    first_name: Mapped[str] = mapped_column(String(128), nullable=False)
    last_name: Mapped[str] = mapped_column(String(128), nullable=False)
    middle_name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    gender: Mapped[str | None] = mapped_column(String(16), nullable=True)  # male | female | other
    phone: Mapped[str | None] = mapped_column(String(32), index=True, nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    address: Mapped[str | None] = mapped_column(String(512), nullable=True)
    notes: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), nullable=True
    )

    @property
    def full_name(self) -> str:
        parts = [self.last_name, self.first_name, self.middle_name or ""]
        return " ".join(p for p in parts if p).strip()
