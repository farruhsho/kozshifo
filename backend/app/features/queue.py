"""Live two-track queue management and the public TV board.

Tracks: payment issues a *diagnostic* ticket (D-001…); when it completes, the
system auto-issues a *doctor* ticket (V-001…) for the same visit — no
receptionist involved. The TV board shows both tracks side by side.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func, or_, select
from sqlalchemy import update as sa_update
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.flow import advance_flow
from app.core.sequences import next_ticket_number
from app.core.visibility import owner_user_ids
from app.models.branch import Branch
from app.models.catalog import service_doctors
from app.models.patient import Patient
from app.models.queue import QueueTicket
from app.models.user import User
from app.models.visit import Visit
from app.schemas.queue import (
    AssignRequest,
    CallNextRequest,
    CallTicketRequest,
    QueueTicketOut,
    QueueTrack,
    ReferToDoctorRequest,
    SpecialistOut,
    TreatmentTicketRequest,
    TvBranchOption,
    TVBoard,
    TVBoardEntry,
    TVTrack,
)

router = APIRouter(prefix="/queue", tags=["Queue"])

_NOW_SERVING = ("called", "serving")
_ACTIVE = ("waiting", *_NOW_SERVING)


def _today_start() -> datetime:
    """UTC day boundary — the same convention next_ticket_number resets on.

    Active views (call-next, TV board, default queue list) are scoped to
    today's tickets: numbers restart daily, so yesterday's forgotten ticket
    must not jump the queue or collide with today's identical number.
    """
    return datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)


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
    track: QueueTrack | None = Query(None),
    active_only: bool = Query(True),
) -> list[QueueTicket]:
    stmt = select(QueueTicket).where(QueueTicket.branch_id == branch_id)
    if track:
        stmt = stmt.where(QueueTicket.track == track)
    if active_only:
        stmt = stmt.where(QueueTicket.status.in_(_ACTIVE),
                          QueueTicket.created_at >= _today_start())
    stmt = stmt.order_by(QueueTicket.priority.desc(), QueueTicket.created_at.asc())
    return list(db.execute(stmt).scalars().all())


@router.get(
    "/specialists",
    response_model=list[SpecialistOut],
    dependencies=[Depends(require_permission("queue.manage"))],
)
def list_specialists(
    db: Annotated[Session, Depends(get_db)],
    branch_id: UUID,
) -> list[SpecialistOut]:
    """Active staff of the branch, for the queue routing picker.

    Guarded by queue.manage (NOT users.read) so reception/diagnost can route a
    patient to a named specialist without identity-module access. Returns only
    non-sensitive staff fields (id, name, role names).
    """
    rows = (
        db.execute(
            select(User)
            .where(
                User.is_active.is_(True),
                User.branch_id == branch_id,
                User.id.not_in(owner_user_ids()),  # ghost: never expose the owner
            )
            .order_by(User.full_name)
        )
        .scalars()
        .all()
    )
    return [
        SpecialistOut(id=u.id, full_name=u.full_name, roles=[r.name for r in u.roles])
        for u in rows
    ]


def _mark_called_effects(db: Session, ticket: QueueTicket, room: str | None,
                         actor: CurrentUser) -> None:
    """Side-effects shared by call-next and the per-ticket call: the audit row
    and the visit's «patient is now in the room» flow event. The guarded claim
    UPDATE itself differs (loop-retry vs single 409) and stays at each call site.
    """
    db.expire(ticket)
    record_audit(db, action="update", entity_type="queue_ticket", entity_id=ticket.id,
                 actor_id=actor.id, branch_id=ticket.branch_id,
                 summary=f"Called {ticket.ticket_number} to {room}")
    # Treatment tickets stand apart from the diagnostic→doctor journey, so they
    # never drive the visit flow engine (only diagnostic/doctor do).
    if ticket.visit_id is not None and ticket.track in ("diagnostic", "doctor"):
        visit = db.get(Visit, ticket.visit_id)
        if visit is not None:
            advance_flow(db, visit,
                         "diagnostic_called" if ticket.track == "diagnostic" else "doctor_called")


@router.post("/call-next", response_model=QueueTicketOut)
def call_next(
    payload: CallNextRequest,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))],
) -> QueueTicket:
    # The room defaults to the caller's own cabinet (User.cabinet) when not given,
    # so a doctor's «Моя очередь» auto-routes the patient to their room.
    room = (payload.room or "").strip() or actor.cabinet
    # Guarded UPDATE (status must still be "waiting") so two operators clicking
    # concurrently can never be handed the same ticket; loser retries the next one.
    for _ in range(3):
        stmt = select(QueueTicket).where(
            QueueTicket.branch_id == payload.branch_id,
            QueueTicket.track == payload.track,
            QueueTicket.status == "waiting",
            QueueTicket.created_at >= _today_start(),
        )
        # Adressed routing (opt-in): a specialist claims tickets routed to them
        # OR still in the open pool. Omitted -> unchanged: any waiting ticket.
        if payload.for_user_id is not None:
            stmt = stmt.where(
                or_(
                    QueueTicket.assigned_user_id == payload.for_user_id,
                    QueueTicket.assigned_user_id.is_(None),
                )
            )
        # Diagnostic queue is distributed BY SERVICE: a diagnostician who serves
        # specific services (service_doctors) only pulls tickets tagged with one
        # of those services (or untagged = open). A caller with no assigned
        # services (e.g. reception/director) is unrestricted, as before.
        if payload.track == "diagnostic":
            caller_service_ids = [s.id for s in actor.services]
            if caller_service_ids:
                stmt = stmt.where(
                    or_(
                        QueueTicket.service_id.in_(caller_service_ids),
                        QueueTicket.service_id.is_(None),
                    )
                )
        ticket = db.execute(
            stmt.order_by(QueueTicket.priority.desc(), QueueTicket.created_at.asc()).limit(1)
        ).scalar_one_or_none()
        if ticket is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "No waiting tickets")
        claimed = db.execute(
            sa_update(QueueTicket)
            .where(QueueTicket.id == ticket.id, QueueTicket.status == "waiting")
            .values(
                status="called",
                room=room,
                called_at=datetime.now(timezone.utc),
                called_by_id=actor.id,
            )
            .execution_options(synchronize_session=False)
        )
        if claimed.rowcount == 1:
            _mark_called_effects(db, ticket, room, actor)
            db.commit()
            db.refresh(ticket)
            return ticket
        db.rollback()  # someone else claimed it — try the next waiting ticket
    raise HTTPException(status.HTTP_409_CONFLICT, "Queue is contended, try again")


# Enforced state machine: waiting -> called -> serving -> done | skipped,
# plus skipped -> waiting (requeue: a skipped no-show who showed up after all).
# called -> done is a deliberate shortcut (operator completes without "serve").
_ALLOWED_FROM: dict[str, tuple[str, ...]] = {
    "serving": ("called",),
    "done": ("called", "serving"),
    "skipped": ("waiting", "called"),
    "waiting": ("skipped",),
}


def _least_loaded_doctor(db: Session, branch_id: UUID, doctors: list[User]) -> User:
    """The eligible doctor with the fewest WAITING doctor-track tickets today —
    the load-balancer that keeps a second doctor from sitting idle while the
    first one's line grows (the owner's «11-й пациент идёт ко 2-му врачу»). Ties
    break by name so the choice is deterministic."""
    ids = [d.id for d in doctors]
    counts = {d.id: 0 for d in doctors}
    rows = db.execute(
        select(QueueTicket.assigned_user_id, func.count())
        .where(
            QueueTicket.branch_id == branch_id,
            QueueTicket.track == "doctor",
            QueueTicket.status == "waiting",
            QueueTicket.assigned_user_id.in_(ids),
            QueueTicket.created_at >= _today_start(),
        )
        .group_by(QueueTicket.assigned_user_id)
    ).all()
    for uid, count in rows:
        counts[uid] = count
    return sorted(doctors, key=lambda d: (counts[d.id], d.full_name))[0]


def _eligible_doctor_for_visit(db: Session, visit: Visit) -> User | None:
    """The doctor a paid visit's billed services route to, else None (open pool).

    Unions the eligible doctors (service_doctors M2M) across the visit's billed
    services. One eligible doctor → that doctor (pre-assigned + their cabinet).
    Several eligible doctors → LOAD-BALANCE to the least-loaded one so no doctor
    sits idle. Zero eligible doctors → open pool: the cabinet then comes from
    whichever doctor calls the ticket.
    """
    service_ids = {it.service_id for it in visit.items if it.service_id is not None}
    if not service_ids:
        return None
    doctors = list(
        db.execute(
            select(User)
            .join(service_doctors, User.id == service_doctors.c.user_id)
            .where(
                service_doctors.c.service_id.in_(service_ids),
                User.is_active.is_(True),
            )
            .distinct()
        )
        .scalars()
        .all()
    )
    if not doctors:
        return None
    if len(doctors) == 1:
        return doctors[0]
    return _least_loaded_doctor(db, visit.branch_id, doctors)


def _doctor_prefix(doctor: User | None) -> str:
    """Queue-ticket prefix for a doctor's track: their ``queue_prefix``, else the
    first letter of their name, else the generic 'V' (open pool)."""
    if doctor is None:
        return "V"
    if doctor.queue_prefix and doctor.queue_prefix.strip():
        return doctor.queue_prefix.strip()
    name = (doctor.full_name or "").strip()
    return name[0].upper() if name else "V"


def _doctor_for_visit(db: Session, visit: Visit) -> User | None:
    """The doctor a paid visit's doctor-track ticket belongs to, in priority
    order: the doctor reception chose on the visit (``visit.doctor_id``) → the
    patient's лечащий (primary) doctor → the single eligible doctor of the billed
    services → None (open pool). This is what makes a returning patient land back
    with their own doctor (and gives the ticket their С-001 prefix)."""
    patient = db.get(Patient, visit.patient_id)
    for uid in (visit.doctor_id, patient.primary_doctor_id if patient else None):
        if uid is not None:
            user = db.get(User, uid)
            if user is not None and user.is_active:
                return user
    return _eligible_doctor_for_visit(db, visit)


def issue_doctor_ticket(db: Session, visit: Visit, actor: CurrentUser,
                        room: str | None = None, audit_note: str = "") -> QueueTicket | None:
    """Mint a waiting doctor-track ticket for a visit, routed to its doctor
    (visit.doctor_id → patient's primary → single eligible → open pool «V»),
    pre-filled with that doctor's cabinet + their ``queue_prefix`` (С-001…), and
    inheriting the visit's emergency priority. Returns None (mints nothing) for a
    dead visit or one that already has an active doctor ticket.

    Shared by (a) diagnostics auto-advance and (b) reception's «Направить к врачу»
    (registration Вариант 2 / assigning a held patient). Runs in the caller's
    transaction so the ticket commits atomically with whatever triggered it.
    """
    if visit is None or visit.status in ("completed", "cancelled"):
        return None
    active_doctor = db.execute(
        select(QueueTicket.id)
        .where(
            QueueTicket.visit_id == visit.id,
            QueueTicket.track == "doctor",
            QueueTicket.status.in_(_ACTIVE),
        )
        .limit(1)
    ).first()
    if active_doctor is not None:
        return None
    doctor = _doctor_for_visit(db, visit)
    new_ticket = QueueTicket(
        ticket_number=next_ticket_number(db, visit.branch_id, _doctor_prefix(doctor)),
        track="doctor",
        patient_id=visit.patient_id,
        branch_id=visit.branch_id,
        visit_id=visit.id,
        room=room if room is not None else (doctor.cabinet if doctor is not None else None),
        assigned_user_id=doctor.id if doctor is not None else None,
        status="waiting",
        priority=visit.priority,
        priority_reason=visit.priority_reason,
    )
    db.add(new_ticket)
    db.flush()
    routed = f" routed to {doctor.full_name}" if doctor is not None else ""
    record_audit(db, action="create", entity_type="queue_ticket", entity_id=new_ticket.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Doctor ticket {new_ticket.ticket_number}{audit_note}{routed}")
    return new_ticket


def _auto_advance_to_doctor(db: Session, ticket: QueueTicket, actor: CurrentUser) -> None:
    """Diagnostics finished -> automatically queue the patient for the doctor.
    A dead/closed visit (refunded-then-cancelled) gets no doctor ticket."""
    visit = db.get(Visit, ticket.visit_id)
    if visit is None:
        return
    issue_doctor_ticket(db, visit, actor,
                        audit_note=f" auto-advance after {ticket.ticket_number} done")


def _transition(db: Session, ticket_id: UUID, actor: CurrentUser, new_status: str, ts_field: str | None) -> QueueTicket:
    ticket = db.get(QueueTicket, ticket_id)
    if ticket is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ticket not found")
    allowed = _ALLOWED_FROM[new_status]
    if ticket.status not in allowed:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Cannot move ticket {ticket.ticket_number} from {ticket.status} to {new_status}")
    # Guarded UPDATE (same pattern as call_next): a concurrent done/skip race
    # must lose with a 409, not double-fire the state machine — an unguarded
    # write here could spawn duplicate V tickets or resurrect a skipped no-show.
    values: dict = {"status": new_status}
    if ts_field:
        values[ts_field] = datetime.now(timezone.utc)
    claimed = db.execute(
        sa_update(QueueTicket)
        .where(QueueTicket.id == ticket.id, QueueTicket.status.in_(allowed))
        .values(**values)
        .execution_options(synchronize_session=False)
    )
    if claimed.rowcount != 1:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Ticket {ticket.ticket_number} was changed concurrently — refresh and retry")
    db.expire(ticket)
    record_audit(db, action="update", entity_type="queue_ticket", entity_id=ticket.id, actor_id=actor.id,
                 branch_id=ticket.branch_id, summary=f"Ticket {ticket.ticket_number} -> {new_status}")
    if new_status == "done" and ticket.track == "diagnostic" and ticket.visit_id is not None:
        _auto_advance_to_doctor(db, ticket, actor)
    if (new_status in ("done", "skipped") and ticket.visit_id is not None
            and ticket.track in ("diagnostic", "doctor")):
        visit = db.get(Visit, ticket.visit_id)
        if visit is not None:  # workflow engine: same transaction as the transition
            if new_status == "done":
                advance_flow(db, visit,
                             "diagnostic_done" if ticket.track == "diagnostic"
                             else "appointment_finished")
            else:
                # No-show skip: the "in the room" claim must be reverted —
                # the engine itself ignores skips of never-called tickets.
                advance_flow(db, visit,
                             "diagnostic_skipped" if ticket.track == "diagnostic"
                             else "doctor_skipped")
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


@router.post("/{ticket_id}/requeue", response_model=QueueTicketOut)
def requeue_ticket(ticket_id: UUID, db: Annotated[Session, Depends(get_db)],
                   actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))]) -> QueueTicket:
    """Return a skipped no-show to the waiting line (he showed up after all).

    Without this the only ways back into the queue were refund-then-repay or
    cancelling the visit — both move real money for a purely logistical event.
    Only today's tickets can be requeued (active views are day-scoped).
    """
    ticket = db.get(QueueTicket, ticket_id)
    if ticket is not None and ticket.created_at is not None:
        boundary = _today_start()
        if ticket.created_at.tzinfo is None:  # SQLite returns naive datetimes
            boundary = boundary.replace(tzinfo=None)
        if ticket.created_at < boundary:
            raise HTTPException(status.HTTP_409_CONFLICT,
                                "Yesterday's ticket cannot be requeued — issue a new visit")
    return _transition(db, ticket_id, actor, "waiting", None)


@router.post("/{ticket_id}/call", response_model=QueueTicketOut)
def call_ticket(
    ticket_id: UUID,
    payload: CallTicketRequest,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))],
) -> QueueTicket:
    """Call ONE specific waiting ticket into a room — the operator picks who
    comes next instead of taking the head of the line («Вызвать»). Guarded
    UPDATE (status must still be waiting) so a concurrent call can't double-fire.
    """
    ticket = db.get(QueueTicket, ticket_id)
    if ticket is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ticket not found")
    room = (payload.room or "").strip() or actor.cabinet
    claimed = db.execute(
        sa_update(QueueTicket)
        .where(QueueTicket.id == ticket.id, QueueTicket.status == "waiting")
        .values(status="called", room=room,
                called_at=datetime.now(timezone.utc), called_by_id=actor.id)
        .execution_options(synchronize_session=False)
    )
    if claimed.rowcount != 1:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Ticket {ticket.ticket_number} is no longer waiting — refresh and retry")
    _mark_called_effects(db, ticket, room, actor)
    db.commit()
    db.refresh(ticket)
    return ticket


@router.post("/{ticket_id}/recall", response_model=QueueTicketOut)
def recall_ticket(ticket_id: UUID, db: Annotated[Session, Depends(get_db)],
                  actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))]) -> QueueTicket:
    """Re-announce an already-called ticket («Вызвать повторно») — the patient
    didn't hear/show. Bumps called_at so the TV board fires the call-out again;
    the status is unchanged (no state-machine move)."""
    ticket = db.get(QueueTicket, ticket_id)
    if ticket is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ticket not found")
    claimed = db.execute(
        sa_update(QueueTicket)
        .where(QueueTicket.id == ticket.id, QueueTicket.status == "called")
        .values(called_at=datetime.now(timezone.utc))
        .execution_options(synchronize_session=False)
    )
    if claimed.rowcount != 1:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a called ticket can be re-announced (ticket {ticket.ticket_number})")
    db.expire(ticket)
    record_audit(db, action="update", entity_type="queue_ticket", entity_id=ticket.id,
                 actor_id=actor.id, branch_id=ticket.branch_id,
                 summary=f"Re-announced {ticket.ticket_number}")
    db.commit()
    db.refresh(ticket)
    return ticket


@router.post("/{ticket_id}/leave", response_model=QueueTicketOut)
def leave_ticket(ticket_id: UUID, db: Annotated[Session, Depends(get_db)],
                 actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))]) -> QueueTicket:
    """Return a called/serving ticket to the waiting line («Оставить») — wrong or
    absent patient called; put them back in the queue. Clears the call fields so
    the ticket is a clean waiting entry, and reverts the visit's «in the room»
    flow claim (same effect as a no-show skip, but the ticket stays active)."""
    ticket = db.get(QueueTicket, ticket_id)
    if ticket is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ticket not found")
    track, visit_id = ticket.track, ticket.visit_id
    claimed = db.execute(
        sa_update(QueueTicket)
        .where(QueueTicket.id == ticket.id, QueueTicket.status.in_(_NOW_SERVING))
        .values(status="waiting", room=None, called_at=None, called_by_id=None,
                served_at=None, done_at=None)
        .execution_options(synchronize_session=False)
    )
    if claimed.rowcount != 1:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a called ticket can be returned to waiting (ticket {ticket.ticket_number})")
    db.expire(ticket)
    record_audit(db, action="update", entity_type="queue_ticket", entity_id=ticket.id,
                 actor_id=actor.id, branch_id=ticket.branch_id,
                 summary=f"Returned {ticket.ticket_number} to waiting")
    if visit_id is not None and track in ("diagnostic", "doctor"):  # revert flow claim
        visit = db.get(Visit, visit_id)
        if visit is not None:
            advance_flow(db, visit,
                         "diagnostic_skipped" if track == "diagnostic" else "doctor_skipped")
    db.commit()
    db.refresh(ticket)
    return ticket


@router.post("/{ticket_id}/assign", response_model=QueueTicketOut)
def assign_ticket(
    ticket_id: UUID,
    payload: AssignRequest,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))],
) -> QueueTicket:
    """Route a WAITING ticket to a specific specialist (or clear it back to the
    open pool with assigned_user_id=null). Reception/diagnost decides who sees
    the patient next; call-next with for_user_id then honours it. Only waiting
    tickets are routable — once called the patient is already in a room.

    Assignment is a metadata pointer, not a state-machine transition: a
    concurrent call-next that claims the ticket simply makes the routing moot.
    """
    ticket = db.get(QueueTicket, ticket_id)
    if ticket is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ticket not found")
    if ticket.status != "waiting":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Only a waiting ticket can be routed (ticket {ticket.ticket_number} is {ticket.status})",
        )
    target: User | None = None
    if payload.assigned_user_id is not None:
        target = db.get(User, payload.assigned_user_id)
        if target is None or not target.is_active:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Assignee user not found or inactive")
    ticket.assigned_user_id = payload.assigned_user_id
    record_audit(
        db, action="update", entity_type="queue_ticket", entity_id=ticket.id,
        actor_id=actor.id, branch_id=ticket.branch_id,
        summary=(f"Routed {ticket.ticket_number} to {target.full_name}" if target is not None
                 else f"Cleared routing on {ticket.ticket_number}"),
    )
    db.commit()
    db.refresh(ticket)
    return ticket


@router.post("/refer-to-doctor", response_model=QueueTicketOut, status_code=status.HTTP_201_CREATED)
def refer_to_doctor(
    payload: ReferToDoctorRequest,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("queue.admin"))],
) -> QueueTicket:
    """Reception sends a visit straight to a doctor — registration Вариант 2
    «Направлен к врачу», or assigning a previously held «Ожидает назначения»
    patient. Optionally pins the doctor on the visit (when the suggested лечащий
    is absent and reception picks another), then mints the doctor-track ticket
    routed to them (their С-001 prefix + cabinet). Idempotent: a visit that already
    has an active doctor ticket returns that one."""
    visit = db.get(Visit, payload.visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, "Visit is closed")
    if payload.doctor_id is not None:
        doctor = db.get(User, payload.doctor_id)
        if doctor is None or not doctor.is_active:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Doctor not found or inactive")
        visit.doctor_id = doctor.id
    advance_flow(db, visit, "referred_to_doctor")  # workflow engine (same transaction)
    ticket = issue_doctor_ticket(db, visit, actor,
                                 room=(payload.room or "").strip() or None,
                                 audit_note=" referred by reception")
    if ticket is None:  # already had an active doctor ticket → return it (idempotent)
        ticket = db.execute(
            select(QueueTicket)
            .where(QueueTicket.visit_id == visit.id, QueueTicket.track == "doctor",
                   QueueTicket.status.in_(_ACTIVE))
            .order_by(QueueTicket.created_at.desc()).limit(1)
        ).scalars().first()
        if ticket is None:
            raise HTTPException(status.HTTP_409_CONFLICT, "Could not issue a doctor ticket")
    db.commit()
    db.refresh(ticket)
    return ticket


@router.post("/treatment-ticket", response_model=QueueTicketOut, status_code=status.HTTP_201_CREATED)
def issue_treatment_ticket(
    payload: TreatmentTicketRequest,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("queue.manage"))],
) -> QueueTicket:
    """Reception issues a TREATMENT-track ticket (Л-…) so a patient who came for a
    course of treatment is queued and called to the procedure room, and appears on
    the TV board's «Лечение» section.

    Deliberately independent of payment: лечение can be paid per-day, prepaid for
    several days, deferred to the end, or partially — all via the visit's normal
    balance — so the ticket is NOT gated on a full payment.
    """
    patient = db.get(Patient, payload.patient_id)
    if patient is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")
    if db.get(Branch, payload.branch_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Branch not found")
    if payload.visit_id is not None:
        visit = db.get(Visit, payload.visit_id)
        if visit is None or visit.patient_id != patient.id:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                                "visit_id does not belong to this patient")
    assigned: User | None = None
    if payload.assigned_user_id is not None:
        assigned = db.get(User, payload.assigned_user_id)
        if assigned is None or not assigned.is_active:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Assignee not found or inactive")
    room = (payload.room or "").strip() or (assigned.cabinet if assigned else None)
    ticket = QueueTicket(
        ticket_number=next_ticket_number(db, payload.branch_id, "Л"),
        track="treatment",
        patient_id=patient.id,
        branch_id=payload.branch_id,
        visit_id=payload.visit_id,
        room=room,
        assigned_user_id=payload.assigned_user_id,
        status="waiting",
    )
    db.add(ticket)
    db.flush()
    record_audit(db, action="create", entity_type="queue_ticket", entity_id=ticket.id,
                 actor_id=actor.id, branch_id=payload.branch_id,
                 summary=f"Issued treatment ticket {ticket.ticket_number} for {patient.mrn}")
    db.commit()
    db.refresh(ticket)
    return ticket


def _called_desc_nulls_last(ticket: QueueTicket) -> tuple[bool, float]:
    """Sort key: called_at DESC with NULLs last."""
    if ticket.called_at is None:
        return (True, 0.0)
    return (False, -ticket.called_at.timestamp())


def _tv_entry(t: QueueTicket) -> TVBoardEntry:
    return TVBoardEntry(
        ticket_number=t.ticket_number,
        patient_label=_patient_label(t.patient),
        room=t.room,
        status=t.status,
        called_at=t.called_at,
        specialist=t.called_by.full_name if t.called_by is not None else None,
        assigned=t.assigned_user.full_name if t.assigned_user is not None else None,
        emergency=t.priority > 0,
    )


@router.get("/tv-branches", response_model=list[TvBranchOption])
def tv_branches(db: Annotated[Session, Depends(get_db)], response: Response) -> list[Branch]:
    """Public (no auth): branch id+name for the standalone TV board's picker.

    Branch names are already shown on the public board, so exposing the list is
    safe; ACAO:* lets the board page run from file:// or another host.
    """
    response.headers["Access-Control-Allow-Origin"] = "*"
    return list(db.execute(select(Branch).order_by(Branch.name)).scalars().all())


@router.get("/tv-board/{branch_id}", response_model=TVBoard)
def tv_board(branch_id: UUID, db: Annotated[Session, Depends(get_db)], response: Response) -> TVBoard:
    """Public (no auth): consumed by the standalone TV page at /tv/{branch_id}.

    Deliberately exposes only privacy-safe data — ticket numbers, rooms,
    anonymized patient labels (see `_patient_label`) and the calling
    specialist's name. Keep it that way.
    ACAO:* lets the board page run from file:// or another host (it is
    credential-free, so the wildcard is safe here).
    """
    response.headers["Access-Control-Allow-Origin"] = "*"
    branch = db.get(Branch, branch_id)
    if branch is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Branch not found")
    rows = list(
        db.execute(
            select(QueueTicket)
            .where(
                QueueTicket.branch_id == branch_id,
                QueueTicket.status.in_(_ACTIVE),
                # Numbers restart daily: yesterday's forgotten ticket must not
                # appear next to today's identical number on the public board.
                QueueTicket.created_at >= _today_start(),
            )
            .order_by(QueueTicket.priority.desc(), QueueTicket.created_at.asc())
        ).scalars().all()
    )
    tracks: dict[str, dict[str, list[QueueTicket]]] = {
        "doctor": {"now": [], "waiting": []},
        "diagnostic": {"now": [], "waiting": []},
        "treatment": {"now": [], "waiting": []},
    }
    for t in rows:
        bucket = tracks.get(t.track)
        if bucket is None:  # unknown track value — never break the public board
            continue
        bucket["now" if t.status in _NOW_SERVING else "waiting"].append(t)
    for bucket in tracks.values():
        bucket["now"].sort(key=_called_desc_nulls_last)
    return TVBoard(
        branch_id=branch_id,
        branch_name=branch.name,
        doctor=TVTrack(
            now=[_tv_entry(t) for t in tracks["doctor"]["now"]],
            waiting=[_tv_entry(t) for t in tracks["doctor"]["waiting"]],
        ),
        diagnostic=TVTrack(
            now=[_tv_entry(t) for t in tracks["diagnostic"]["now"]],
            waiting=[_tv_entry(t) for t in tracks["diagnostic"]["waiting"]],
        ),
        treatment=TVTrack(
            now=[_tv_entry(t) for t in tracks["treatment"]["now"]],
            waiting=[_tv_entry(t) for t in tracks["treatment"]["waiting"]],
        ),
    )
