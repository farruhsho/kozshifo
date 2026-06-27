"""Login session record (Super Admin → системный мониторинг).

One row per successful login — a persisted login HISTORY (who logged in, when,
from which IP/device). «Online now» is derived separately from an in-memory
last-seen registry (core/monitoring), so no per-request DB write is needed.
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import ForeignKey, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.core.types import UTCDateTime
from app.models.base import UUIDPKMixin


class UserSession(UUIDPKMixin, Base):
    __tablename__ = "user_sessions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    started_at: Mapped[datetime] = mapped_column(
        UTCDateTime, server_default=func.now(), index=True, nullable=False
    )
    ip_address: Mapped[str | None] = mapped_column(String(64), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(String(256), nullable=True)
