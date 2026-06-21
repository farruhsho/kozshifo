"""Notifications.

Two surfaces:
- GET /notifications        — read-only DELIVERY journal of fired events (low
  stock etc.), created by app.core.notify (fire-and-forget, post-commit). This
  is a historical log and MAY contain resolved events.
- GET /notifications/active — the LIVE, self-resolving problem set (computed on
  read from current data via the shared insight engine). A notification here
  exists ONLY while its problem exists — nothing stale is ever stored. This is
  the in-app attention surface (owner brief 2026-06-20).
"""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_permission
from app.features.dashboard import InsightOut, compute_insights
from app.models.notification import Notification
from app.schemas.notification import NotificationOut

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/active", response_model=list[InsightOut],
            dependencies=[Depends(require_permission("notifications.read"))])
def active_notifications(db: Annotated[Session, Depends(get_db)]) -> list[InsightOut]:
    """Live, self-resolving problem set: a notification exists ONLY while its
    problem exists (computed on read — never a stale stored row). Same rules as
    the director's dashboard attention panel, so the two surfaces stay in sync."""
    return compute_insights(db)


@router.get("", response_model=list[NotificationOut],
            dependencies=[Depends(require_permission("notifications.read"))])
def list_notifications(
    db: Annotated[Session, Depends(get_db)],
    event: str | None = Query(None, description="Filter by event code, e.g. low_stock"),
    limit: int = Query(50, ge=1, le=200),
) -> list[Notification]:
    stmt = select(Notification).where(Notification.archived_at.is_(None))
    if event:
        stmt = stmt.where(Notification.event == event)
    stmt = stmt.order_by(Notification.created_at.desc()).limit(limit)
    return list(db.execute(stmt).scalars().all())
