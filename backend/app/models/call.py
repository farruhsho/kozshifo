"""Call log — IP-telephony PBX *or* Android reception-phone agents (TZ Modul 9).

Two ingest seams feed the SAME ``call_records`` table:

* PBX webhook (features/calls.py ``/calls/ingest``) — Asterisk dialplan / AMI.
* Android agent (``/calls/agent/ingest``) — a small app on each reception phone
  that reports every finished call (incoming / outgoing / missed / rejected),
  the ring-wait before pickup and a heartbeat, so the director can watch in
  near-real-time whether the front desk answers on time. No recording on this
  path (Android 10+ blocks it) — metrics only.

Patients are auto-matched by normalized phone digits at ingest time. Per-device
calls carry an ``external_id`` (the phone's own call id) so an agent retry after
a flaky upload never double-counts.
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import ForeignKey, Integer, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.core.types import UTCDateTime
from app.models.base import TimestampMixin, UUIDPKMixin


class CallDevice(UUIDPKMixin, TimestampMixin, Base):
    """A reception Android phone (or a PBX line) that reports calls.

    Each device authenticates the agent endpoints with its OWN secret key
    (``X-Device-Key``); we store only its SHA-256 hash. ``last_seen_at`` is bumped
    by the heartbeat so the director gets an "offline phone" alert when a reception
    line goes silent (dead battery / app killed) and calls are being lost unseen.
    """

    __tablename__ = "call_devices"

    label: Mapped[str] = mapped_column(String(120), nullable=False)  # "Ресепшн 1 (Главный)"
    phone_number: Mapped[str | None] = mapped_column(String(32), nullable=True)  # the SIM number
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), index=True, nullable=True
    )
    # SHA-256 hex of the device key — high-entropy random secret, looked up by
    # exact hash on ingest (not a low-entropy password, so a plain digest is fine).
    api_key_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    last_seen_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
    app_version: Mapped[str | None] = mapped_column(String(32), nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)

    branch: Mapped["Branch | None"] = relationship(lazy="joined")  # noqa: F821


class CallRecord(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "call_records"
    __table_args__ = (
        # An agent may resend a batch after a flaky upload — (device, phone's call
        # id) makes re-ingest a no-op. NULLs don't collide, so the PBX path
        # (device_id/external_id NULL) is unaffected.
        UniqueConstraint("device_id", "external_id", name="uq_call_records_device_external"),
    )

    direction: Mapped[str] = mapped_column(String(8), default="in", nullable=False)  # in | out
    # answered | missed | rejected | outgoing — the monitoring axis: did the front
    # desk pick up? ``missed`` = rang, nobody answered; ``rejected`` = declined.
    status: Mapped[str] = mapped_column(String(12), default="answered", nullable=False)
    phone: Mapped[str] = mapped_column(String(32), nullable=False)
    phone_normalized: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    started_at: Mapped[datetime] = mapped_column(
        UTCDateTime, index=True, nullable=False
    )
    ended_at: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
    # Seconds the phone rang before pickup (answered) or before it stopped
    # (missed/rejected) — the "how fast does reception answer" KPI.
    wait_seconds: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    recording_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    handled_by_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    patient_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="SET NULL"), index=True, nullable=True
    )
    # Which reception phone reported it (agent path); NULL for PBX/webhook rows.
    device_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("call_devices.id", ondelete="SET NULL"), index=True, nullable=True
    )
    # The phone's own call id — idempotency key within a device (see __table_args__).
    external_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    # Denormalized from the device for per-branch KPIs without a join.
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), index=True, nullable=True
    )
    note: Mapped[str | None] = mapped_column(String(512), nullable=True)

    patient: Mapped["Patient | None"] = relationship(lazy="joined")  # noqa: F821
    handled_by: Mapped["User | None"] = relationship(lazy="joined")  # noqa: F821
    device: Mapped["CallDevice | None"] = relationship(lazy="joined")
