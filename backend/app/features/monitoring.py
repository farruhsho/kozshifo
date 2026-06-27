"""Super Admin → системный мониторинг: online users, login sessions, process
uptime, recent slow requests + recent server errors. Gated by audit.read
(director / superadmin). «Online» + slow/errors come from the in-memory
monitoring registry; login history from the persisted UserSession table.
"""
from __future__ import annotations

from datetime import datetime
from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core import monitoring
from app.core.database import get_db
from app.core.dates import business_today, local_day_bounds_utc
from app.core.deps import require_permission
from app.models.user import User
from app.models.user_session import UserSession

router = APIRouter(prefix="/admin", tags=["Super Admin"])


class OnlineUser(BaseModel):
    user_id: UUID
    name: str


class MonitoringOut(BaseModel):
    uptime_seconds: int
    online_count: int
    online_users: list[OnlineUser]
    logins_today: int
    total_sessions: int
    recent_slow: list[dict[str, Any]]
    recent_errors: list[dict[str, Any]]


class SessionOut(BaseModel):
    id: UUID
    user_id: UUID
    user_name: str | None
    started_at: datetime
    ip_address: str | None
    user_agent: str | None
    online: bool


@router.get("/monitoring", response_model=MonitoringOut,
            dependencies=[Depends(require_permission("audit.read"))])
def system_monitoring(db: Annotated[Session, Depends(get_db)]) -> MonitoringOut:
    online = monitoring.online_user_ids()
    today_start = local_day_bounds_utc(business_today())[0]
    logins_today = db.execute(
        select(func.count()).select_from(UserSession)
        .where(UserSession.started_at >= today_start)
    ).scalar_one()
    total_sessions = db.execute(select(func.count()).select_from(UserSession)).scalar_one()

    online_users: list[OnlineUser] = []
    if online:
        users = db.execute(select(User).where(User.id.in_(online))).scalars().all()
        online_users = [OnlineUser(user_id=u.id, name=u.full_name) for u in users]

    return MonitoringOut(
        uptime_seconds=int(monitoring.uptime_seconds()),
        online_count=len(online),
        online_users=online_users,
        logins_today=int(logins_today),
        total_sessions=int(total_sessions),
        recent_slow=monitoring.recent_slow(),
        recent_errors=monitoring.recent_errors(),
    )


@router.get("/sessions", response_model=list[SessionOut],
            dependencies=[Depends(require_permission("audit.read"))])
def list_sessions(
    db: Annotated[Session, Depends(get_db)],
    limit: int = Query(100, ge=1, le=500),
) -> list[SessionOut]:
    """Recent login sessions (newest first), with an «online now» flag."""
    rows = db.execute(
        select(UserSession).order_by(UserSession.started_at.desc()).limit(limit)
    ).scalars().all()
    online = monitoring.online_user_ids()
    uids = {r.user_id for r in rows}
    names = {
        u.id: u.full_name for u in db.execute(select(User).where(User.id.in_(uids))).scalars().all()
    } if uids else {}
    return [
        SessionOut(
            id=r.id, user_id=r.user_id, user_name=names.get(r.user_id),
            started_at=r.started_at, ip_address=r.ip_address, user_agent=r.user_agent,
            online=r.user_id in online,
        )
        for r in rows
    ]
