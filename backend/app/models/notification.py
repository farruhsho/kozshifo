"""Notification log: every fired event is persisted, per delivery channel.

One business event produces one row per channel — always a "log" row (the
in-system journal) and, when Telegram is configured, a "telegram" row whose
status records whether the push actually went out. Delivery must never break
the business request that triggered it (see app.core.notify).
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.core.types import UTCDateTime
from app.models.base import TimestampMixin, UUIDPKMixin


class Notification(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "notifications"

    # e.g. "low_stock"
    event: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    # log | telegram
    channel: Mapped[str] = mapped_column(String(16), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    # sent | failed
    status: Mapped[str] = mapped_column(String(16), nullable=False)
    error: Mapped[str | None] = mapped_column(String(512), nullable=True)
    # Polymorphic link to the entity the event is about
    # (e.g. ref_type="product", ref_id=<product uuid>).
    ref_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    ref_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, nullable=True)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), nullable=True
    )
    # Auto-archive (Super Admin): old delivery-log rows. NULL = live; archived
    # rows drop out of the stored journal (GET /notifications).
    archived_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
