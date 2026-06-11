"""Live queue management and the public TV board."""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.patient import Patient
from app.models.queue import QueueTicket
from app.schemas.queue import CallNextRequest, QueueTicketOut, TVBoard, TVBoardEntry

router = APIRouter(prefix="/queue", tags=["Queue"])

_NOW_SERVING = ("called", "serving")


def _patient_label(patient: Patient | None) -> str:
    """Privacy-safe label for public displays: initials + last 3 of MRN."""
    if patient is None:
        return "—"
    initials = f"{patient.last_name[:1]}{patient.first_name[:1]}".upper()
    tail = patient.mrn[-3:] if patient.mrn else ""
    return f"{initials} · {tail}"


@router.get("", response_model=list[QueueTicketOut], dependencies=[Depends(require_permission("queue.read"))])
def list_queue(
    db: Annotated[Session, Depends(get_db)],
    branch_id: UUID,
    active_only: bool = Query(True),
) -> list[QueueTicket]:
    stmt = select(QueueTicket).where(QueueTicket.branch_id == branch_id)
    if active_only:
        stmt = stmt.where(QueueTicket.status.in_(("waiting", *_NOW_SERVING)))
    stmt = stmt.order_by(QueueTicket.priority.desc(), QueueTicket.created_at.asc())
    return list(db.execute(stmt).scalars().all())


@router.post("/call-next", response_model=QueueTicketOut)
def call_next(
    payload: CallNextRequest,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))],
) -> QueueTicket:
    ticket = db.execute(
        select(QueueTicket)
        .where(QueueTicket.branch_id == payload.branch_id, QueueTicket.status == "waiting")
        .order_by(QueueTicket.priority.desc(), QueueTicket.created_at.asc())
        .limit(1)
    ).scalar_one_or_none()
    if ticket is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No waiting tickets")
    ticket.status = "called"
    ticket.room = payload.room
    ticket.called_at = datetime.now(timezone.utc)
    record_audit(db, action="update", entity_type="queue_ticket", entity_id=ticket.id, actor_id=actor.id,
                 branch_id=ticket.branch_id, summary=f"Called {ticket.ticket_number} to {payload.room}")
    db.commit()
    db.refresh(ticket)
    return ticket


def _transition(db: Session, ticket_id: UUID, actor: CurrentUser, new_status: str, ts_field: str | None) -> QueueTicket:
    ticket = db.get(QueueTicket, ticket_id)
    if ticket is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ticket not found")
    ticket.status = new_status
    if ts_field:
        setattr(ticket, ts_field, datetime.now(timezone.utc))
    record_audit(db, action="update", entity_type="queue_ticket", entity_id=ticket.id, actor_id=actor.id,
                 branch_id=ticket.branch_id, summary=f"Ticket {ticket.ticket_number} -> {new_status}")
    db.commit()
    db.refresh(ticket)
    return ticket


@router.post("/{ticket_id}/serve", response_model=QueueTicketOut)
def serve_ticket(ticket_id: UUID, db: Annotated[Session, Depends(get_db)],
                 actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))]) -> QueueTicket:
    return _transition(db, ticket_id, actor, "serving", "served_at")


@router.post("/{ticket_id}/done", response_model=QueueTicketOut)
def complete_ticket(ticket_id: UUID, db: Annotated[Session, Depends(get_db)],
                    actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))]) -> QueueTicket:
    return _transition(db, ticket_id, actor, "done", "done_at")


@router.post("/{ticket_id}/skip", response_model=QueueTicketOut)
def skip_ticket(ticket_id: UUID, db: Annotated[Session, Depends(get_db)],
                actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))]) -> QueueTicket:
    return _transition(db, ticket_id, actor, "skipped", None)


@router.get("/tv-board/{branch_id}", response_model=TVBoard,
            dependencies=[Depends(require_permission("queue.read"))])
def tv_board(branch_id: UUID, db: Annotated[Session, Depends(get_db)]) -> TVBoard:
    rows = list(
        db.execute(
            select(QueueTicket)
            .where(QueueTicket.branch_id == branch_id, QueueTicket.status.in_(("waiting", *_NOW_SERVING)))
            .order_by(QueueTicket.priority.desc(), QueueTicket.created_at.asc())
        ).scalars().all()
    )
    now_serving, waiting = [], []
    for t in rows:
        entry = TVBoardEntry(
            ticket_number=t.ticket_number,
            patient_label=_patient_label(t.patient),
            room=t.room,
            status=t.status,
        )
        (now_serving if t.status in _NOW_SERVING else waiting).append(entry)
    return TVBoard(branch_id=branch_id, now_serving=now_serving, waiting=waiting)
