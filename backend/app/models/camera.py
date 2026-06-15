"""IP camera on the clinic LAN (live view + still capture).

One row per camera. The backend reaches the unit over ISAPI/HTTP (Digest auth,
same transport as the Face ID terminals) to pull a JPEG snapshot and proxy it to
the app — browsers can't play RTSP, so the live view is snapshot polling.

Security note: ``password`` is the camera admin secret. Like the face terminals,
it lives on this isolated table (never the generic ``devices`` table) and is
**never returned by any API response** — the schemas omit it deliberately.
On-prem LAN MVP keeps it as a plain column; encryption-at-rest is a documented
follow-up (mirrors models/face_terminal.py).
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import JSON, Boolean, ForeignKey, Integer, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.core.types import UTCDateTime
from app.models.base import TimestampMixin, UUIDPKMixin


class Camera(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "cameras"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    host: Mapped[str] = mapped_column(String(255), nullable=False)  # LAN IP or hostname
    port: Mapped[int] = mapped_column(Integer, default=80, nullable=False)
    username: Mapped[str] = mapped_column(String(128), nullable=False)
    # Device admin secret — write-only, excluded from every response schema.
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    use_https: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    # hikvision (ISAPI snapshot path is derived) | generic (snapshot_path required).
    vendor: Mapped[str] = mapped_column(String(16), default="hikvision", nullable=False)
    # Video channel on the unit (most single-lens cameras use 1).
    channel_no: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    # Optional override for non-Hikvision cameras: the full snapshot URL path
    # (e.g. "/cgi-bin/snapshot.cgi"). NULL = derive the standard ISAPI path.
    snapshot_path: Mapped[str | None] = mapped_column(String(255), nullable=True)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), nullable=True
    )
    # active | inactive
    status: Mapped[str] = mapped_column(String(16), default="active", index=True, nullable=False)

    # Liveness, refreshed by the "test connection" call.
    online: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    last_seen: Mapped[datetime | None] = mapped_column(UTCDateTime, nullable=True)
    # Last successful /ISAPI/System/deviceInfo (model, firmware, serial, …).
    device_info: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    branch: Mapped["Branch | None"] = relationship(lazy="joined")  # noqa: F821

    @property
    def branch_name(self) -> str | None:
        return self.branch.name if self.branch else None
