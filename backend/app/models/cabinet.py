"""Cabinet / consulting room — a named room within a branch.

Examples: «Кабинет №1», «Кабинет УЗИ», «Кабинет ЭКГ», «Процедурный»,
«Операционная №1». Created ONLY by the Super Admin; staff choose «Мой кабинет»
at login so all their patient calls are directed to that room. This is the
managed list behind what used to be a free-text `User.cabinet` string.
"""
from __future__ import annotations

import uuid

from sqlalchemy import Boolean, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class Cabinet(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "cabinets"

    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="CASCADE"), index=True, nullable=False
    )
    name: Mapped[str] = mapped_column(String(64), nullable=False)
    # Optional kind/label (УЗИ, ЭКГ, процедурный, операционная…) — free-form.
    kind: Mapped[str | None] = mapped_column(String(32), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
