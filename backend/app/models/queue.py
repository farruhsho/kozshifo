"""Queue ticket issued after payment; drives the live queue and TV board."""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class QueueTicket(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "queue_tickets"

    ticket_number: Mapped[str] = mapped_column(String(16), index=True, nullable=False)  # e.g. A-001
    patient_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="RESTRICT"), nullable=False
    )
    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    visit_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="SET NULL"), nullable=True
    )
    service_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("services.id", ondelete="SET NULL"), nullable=True
    )
    room: Mapped[str | None] = mapped_column(String(32), nullable=True)  # cabinet / window
    # waiting -> called -> serving -> done | skipped
    status: Mapped[str] = mapped_column(String(16), default="waiting", index=True, nullable=False)
    priority: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    called_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    served_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    done_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    patient: Mapped["Patient"] = relationship(lazy="joined")  # noqa: F821
