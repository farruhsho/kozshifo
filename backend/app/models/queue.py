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

    ticket_number: Mapped[str] = mapped_column(String(16), index=True, nullable=False)  # e.g. D-001 / V-001
    # Two-track queue: "diagnostic" (issued on payment) -> "doctor" (auto-issued
    # when the diagnostic ticket completes).
    track: Mapped[str] = mapped_column(String(12), default="doctor", index=True, nullable=False)
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
    # Why this ticket is priority/emergency (inherited from the visit at mint
    # time) — drives the TV «⚠ ЭКСТРЕННЫЙ» flag, the receipt, and analytics.
    priority_reason: Mapped[str | None] = mapped_column(String(128), nullable=True)
    called_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    served_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    done_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Who called the ticket (specialist name shown on the TV board).
    called_by_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    # Optional pre-assignment: the specific specialist this ticket is routed to
    # (reception/diagnost sends the patient to a named doctor, or the patient
    # returns to the doctor seen earlier). NULL = open pool — current behaviour:
    # any specialist with queue.manage pulls the next waiting ticket.
    assigned_user_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    patient: Mapped["Patient"] = relationship(lazy="joined")  # noqa: F821

    # Authenticated-only convenience for staff-facing lists (doctor worklist /
    # queue screen). The PUBLIC TV board never uses these — it builds its own
    # privacy-safe label (see queue._patient_label). Behind queue.read these are
    # safe to expose: the same caller already holds patients.read.
    @property
    def patient_name(self) -> str:
        return self.patient.full_name if self.patient is not None else ""

    @property
    def patient_mrn(self) -> str | None:
        return self.patient.mrn if self.patient is not None else None
    # Two FKs now point at users (called_by + assigned_user); foreign_keys is
    # required so SQLAlchemy can disambiguate each relationship's join.
    called_by: Mapped["User | None"] = relationship(  # noqa: F821
        foreign_keys=[called_by_id], lazy="joined"
    )
    assigned_user: Mapped["User | None"] = relationship(  # noqa: F821
        foreign_keys=[assigned_user_id], lazy="joined"
    )
