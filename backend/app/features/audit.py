"""Super Admin → audit trail. Read-only view of the append-only audit log:
who (actor) did what (action/summary), when, from which device (ip + user-agent).
Filterable by actor / entity type / action / local date range, paginated.
"""
from __future__ import annotations

from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dates import local_day_bounds_utc
from app.core.deps import require_permission
from app.models.audit import AuditLog
from app.models.user import User
from app.schemas.audit import AuditLogOut
from app.schemas.common import Page

router = APIRouter(prefix="/admin", tags=["Super Admin"])


@router.get("/audit-logs", response_model=Page[AuditLogOut],
            dependencies=[Depends(require_permission("audit.read"))])
def list_audit_logs(
    db: Annotated[Session, Depends(get_db)],
    actor_id: UUID | None = None,
    entity_type: str | None = None,
    action: str | None = None,
    date_from: date | None = Query(None, description="Local start date (inclusive)"),
    date_to: date | None = Query(None, description="Local end date (inclusive)"),
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[AuditLogOut]:
    """Audit trail, newest first. Actor name/email are joined from users."""
    if date_from and date_to and date_from > date_to:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "date_from must be <= date_to")

    stmt = select(AuditLog)
    if actor_id is not None:
        stmt = stmt.where(AuditLog.actor_id == actor_id)
    if entity_type:
        stmt = stmt.where(AuditLog.entity_type == entity_type)
    if action:
        stmt = stmt.where(AuditLog.action == action)
    if date_from is not None:
        stmt = stmt.where(AuditLog.created_at >= local_day_bounds_utc(date_from)[0])
    if date_to is not None:
        stmt = stmt.where(AuditLog.created_at < local_day_bounds_utc(date_to)[1])

    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(
        stmt.order_by(AuditLog.created_at.desc()).offset(offset).limit(limit)
    ).scalars().all()

    actor_ids = {r.actor_id for r in rows if r.actor_id is not None}
    users = {
        u.id: u for u in db.execute(select(User).where(User.id.in_(actor_ids))).scalars().all()
    } if actor_ids else {}

    items = [
        AuditLogOut(
            id=r.id, created_at=r.created_at, action=r.action,
            entity_type=r.entity_type, entity_id=r.entity_id,
            actor_id=r.actor_id,
            actor_name=users[r.actor_id].full_name if r.actor_id in users else None,
            actor_email=users[r.actor_id].email if r.actor_id in users else None,
            branch_id=r.branch_id, summary=r.summary,
            ip_address=r.ip_address, user_agent=r.user_agent,
        )
        for r in rows
    ]
    return Page(items=items, total=total, offset=offset, limit=limit)
