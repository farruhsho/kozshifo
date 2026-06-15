"""Scheduling — appointments calendar (book / reschedule / status).

A *free* slot is the absence of a row, so the grid derives availability.
Double-booking is rejected server-side (overlap-guard) because the grid can't be
trusted. ``arrived`` is a hand-off marker — reception opens the visit as a
walk-in, keeping the till flow single-source.
"""
from __future__ import annotations

from datetime import date as date_cls
from datetime import datetime, time, timedelta, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.sequences import next_appointment_no
from app.models.appointment import Appointment
from app.models.branch import Branch
from app.models.patient import Patient
from app.models.user import User
from app.schemas.appointment import (
    AppointmentCreate,
    AppointmentOut,
    AppointmentReschedule,
    AppointmentStatusUpdate,
    SchedStaffOut,
)

router = APIRouter(prefix="/appointments", tags=["Scheduling"])

# booked -> arrived -> done | cancelled | no_show
_ALLOWED_FROM: dict[str, tuple[str, ...]] = {
    "arrived": ("booked",),
    "done": ("arrived",),
    "cancelled": ("booked", "arrived"),
    "no_show": ("booked",),
}
_LIVE = ("booked", "arrived")  # statuses that still occupy the slot


def _as_utc(ts: datetime) -> datetime:
    return ts.replace(tzinfo=timezone.utc) if ts.tzinfo is None else ts.astimezone(timezone.utc)


def _day_bounds(d: date_cls) -> tuple[datetime, datetime]:
    start = datetime.combine(d, time.min, tzinfo=timezone.utc)
    return start, start + timedelta(days=1)


def _overlaps(db: Session, *, branch_id: UUID, doctor_id: UUID | None,
              starts: datetime, ends: datetime, exclude_id: UUID | None = None) -> bool:
    """A live appointment for the same doctor whose interval intersects [starts, ends)."""
    if doctor_id is None:
        return False  # unassigned bookings never collide
    stmt = (
        select(Appointment.id)
        .where(
            Appointment.doctor_id == doctor_id,
            Appointment.status.in_(_LIVE),
            Appointment.starts_at < ends,
            Appointment.ends_at > starts,
        )
        .limit(1)
    )
    if exclude_id is not None:
        stmt = stmt.where(Appointment.id != exclude_id)
    return db.execute(stmt).first() is not None


def _get_or_404(db: Session, appointment_id: UUID) -> Appointment:
    appt = db.get(Appointment, appointment_id)
    if appt is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Appointment not found")
    return appt


@router.get(
    "",
    response_model=list[AppointmentOut],
    dependencies=[Depends(require_permission("appointments.read"))],
)
def list_appointments(
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
    branch_id: UUID | None = None,
    date: date_cls | None = Query(None, description="Day to show (UTC); defaults to today"),
) -> list[Appointment]:
    day = date or datetime.now(timezone.utc).date()
    start, end = _day_bounds(day)
    stmt = select(Appointment).where(
        Appointment.starts_at >= start, Appointment.starts_at < end
    )
    if branch_id:
        stmt = stmt.where(Appointment.branch_id == branch_id)
    elif not actor.is_superuser and actor.branch_id is not None:
        stmt = stmt.where(Appointment.branch_id == actor.branch_id)
    stmt = stmt.order_by(Appointment.starts_at.asc())
    return list(db.execute(stmt).scalars().all())


@router.get(
    "/staff",
    response_model=list[SchedStaffOut],
    dependencies=[Depends(require_permission("appointments.read"))],
)
def list_staff(db: Annotated[Session, Depends(get_db)], branch_id: UUID) -> list[SchedStaffOut]:
    """Active branch staff for the calendar columns (no users.read needed)."""
    rows = (
        db.execute(
            select(User)
            .where(User.is_active.is_(True), User.branch_id == branch_id)
            .order_by(User.full_name)
        )
        .scalars()
        .all()
    )
    return [
        SchedStaffOut(id=u.id, full_name=u.full_name, roles=[r.name for r in u.roles])
        for u in rows
    ]


@router.post("", response_model=AppointmentOut, status_code=status.HTTP_201_CREATED)
def create_appointment(
    payload: AppointmentCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("appointments.create"))],
) -> Appointment:
    if db.get(Patient, payload.patient_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown patient")
    if db.get(Branch, payload.branch_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown branch")
    starts = _as_utc(payload.starts_at)
    ends = starts + timedelta(minutes=payload.duration_min)
    if _overlaps(db, branch_id=payload.branch_id, doctor_id=payload.doctor_id,
                 starts=starts, ends=ends):
        raise HTTPException(status.HTTP_409_CONFLICT, "Doctor already booked for this time")
    appt = Appointment(
        appointment_no=next_appointment_no(db),
        branch_id=payload.branch_id,
        patient_id=payload.patient_id,
        doctor_id=payload.doctor_id,
        cabinet=payload.cabinet,
        service=payload.service,
        starts_at=starts,
        ends_at=ends,
        notes=payload.notes,
        created_by_id=actor.id,
    )
    db.add(appt)
    db.flush()
    record_audit(db, action="create", entity_type="appointment", entity_id=appt.id,
                 actor_id=actor.id, branch_id=appt.branch_id,
                 summary=f"Booked {appt.appointment_no} at {starts.isoformat()}")
    db.commit()
    db.refresh(appt)
    return appt


@router.post("/{appointment_id}/reschedule", response_model=AppointmentOut)
def reschedule_appointment(
    appointment_id: UUID,
    payload: AppointmentReschedule,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("appointments.update"))],
) -> Appointment:
    appt = _get_or_404(db, appointment_id)
    if appt.status not in _LIVE:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Cannot move a {appt.status} appointment")
    starts = _as_utc(payload.starts_at)
    duration = payload.duration_min or int(
        (_as_utc(appt.ends_at) - _as_utc(appt.starts_at)).total_seconds() // 60
    )
    ends = starts + timedelta(minutes=duration)
    doctor_id = payload.doctor_id if payload.doctor_id is not None else appt.doctor_id
    if _overlaps(db, branch_id=appt.branch_id, doctor_id=doctor_id,
                 starts=starts, ends=ends, exclude_id=appt.id):
        raise HTTPException(status.HTTP_409_CONFLICT, "Doctor already booked for this time")
    appt.starts_at, appt.ends_at, appt.doctor_id = starts, ends, doctor_id
    if payload.cabinet is not None:
        appt.cabinet = payload.cabinet
    record_audit(db, action="update", entity_type="appointment", entity_id=appt.id,
                 actor_id=actor.id, branch_id=appt.branch_id,
                 summary=f"Rescheduled {appt.appointment_no} to {starts.isoformat()}")
    db.commit()
    db.refresh(appt)
    return appt


@router.post("/{appointment_id}/status", response_model=AppointmentOut)
def set_status(
    appointment_id: UUID,
    payload: AppointmentStatusUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("appointments.update"))],
) -> Appointment:
    appt = _get_or_404(db, appointment_id)
    allowed = _ALLOWED_FROM.get(payload.status, ())
    if appt.status not in allowed:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Cannot move appointment {appt.appointment_no} from {appt.status} to {payload.status}",
        )
    appt.status = payload.status
    record_audit(db, action="update", entity_type="appointment", entity_id=appt.id,
                 actor_id=actor.id, branch_id=appt.branch_id,
                 summary=f"Appointment {appt.appointment_no} -> {payload.status}")
    db.commit()
    db.refresh(appt)
    return appt
