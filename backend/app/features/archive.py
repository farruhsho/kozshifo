"""Super Admin → архив: auto-archive old records (визиты / операции / уведомления)
past a retention window by stamping archived_at. Manual run + a summary of what is
archived vs archivable. Gated by archive.manage (director / superadmin).
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy import update as sa_update
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.notification import Notification
from app.models.operation import Operation
from app.models.visit import Visit

router = APIRouter(prefix="/admin", tags=["Super Admin"])

_DEFAULT_DAYS = 365


class EntityArchive(BaseModel):
    archived: int      # уже в архиве
    archivable: int    # старые, ещё не архивированные


class ArchiveSummary(BaseModel):
    older_than_days: int
    visits: EntityArchive
    operations: EntityArchive
    notifications: EntityArchive


class ArchiveRunResult(BaseModel):
    older_than_days: int
    visits: int
    operations: int
    notifications: int


def _cutoff(days: int) -> datetime:
    return datetime.now(timezone.utc) - timedelta(days=days)


def _visit_archivable(cutoff: datetime):
    # Only finished visits old enough — never an open/in-progress one.
    return (Visit.archived_at.is_(None),
            Visit.status.in_(("completed", "cancelled")),
            Visit.opened_at < cutoff)


def _op_archivable(cutoff: datetime):
    return (Operation.archived_at.is_(None),
            Operation.status.in_(("completed", "cancelled")),
            Operation.created_at < cutoff)


def _notif_archivable(cutoff: datetime):
    return (Notification.archived_at.is_(None), Notification.created_at < cutoff)


@router.get("/archive", response_model=ArchiveSummary,
            dependencies=[Depends(require_permission("archive.manage"))])
def archive_summary(
    db: Annotated[Session, Depends(get_db)],
    older_than_days: int = Query(_DEFAULT_DAYS, ge=1, le=3650),
) -> ArchiveSummary:
    cutoff = _cutoff(older_than_days)

    def counts(model, archivable_pred) -> EntityArchive:
        archived = db.execute(
            select(func.count()).select_from(model).where(model.archived_at.is_not(None))
        ).scalar_one()
        archivable = db.execute(
            select(func.count()).select_from(model).where(*archivable_pred)
        ).scalar_one()
        return EntityArchive(archived=int(archived), archivable=int(archivable))

    return ArchiveSummary(
        older_than_days=older_than_days,
        visits=counts(Visit, _visit_archivable(cutoff)),
        operations=counts(Operation, _op_archivable(cutoff)),
        notifications=counts(Notification, _notif_archivable(cutoff)),
    )


@router.post("/archive/run", response_model=ArchiveRunResult,
             dependencies=[Depends(require_permission("archive.manage"))])
def archive_run(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("archive.manage"))],
    older_than_days: int = Query(_DEFAULT_DAYS, ge=1, le=3650),
) -> ArchiveRunResult:
    """Stamp archived_at on all archivable records older than the window. Idempotent
    (re-running archives only what is newly old). Can be wired to a nightly job."""
    cutoff = _cutoff(older_than_days)
    now = datetime.now(timezone.utc)

    def archive(model, pred) -> int:
        res = db.execute(
            sa_update(model).where(*pred).values(archived_at=now)
            .execution_options(synchronize_session=False)
        )
        return int(res.rowcount or 0)

    v = archive(Visit, _visit_archivable(cutoff))
    o = archive(Operation, _op_archivable(cutoff))
    n = archive(Notification, _notif_archivable(cutoff))
    record_audit(db, action="archive", entity_type="system", actor_id=actor.id,
                 summary=f"Auto-archive >{older_than_days}d: visits={v}, "
                         f"operations={o}, notifications={n}")
    db.commit()
    return ArchiveRunResult(older_than_days=older_than_days,
                            visits=v, operations=o, notifications=n)
