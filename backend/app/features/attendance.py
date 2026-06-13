"""Attendance API (TZ Modul 1 — Face ID kirish-chiqish nazorati).

Three consumers:
  * the unattended Face ID terminal POSTs raw punches to /punch — shared-secret
    header (no JWT; the device cannot hold a session);
  * administrators key in manual corrections via /events (attendance.manage);
  * the owner reads the day log / timesheet report / Excel CSV (attendance.read).

Time conventions: `occurred_at` is stored as UTC (naive values from SQLite are
UTC by project convention). The *business day* a punch belongs to and lateness
are evaluated in server-local time — the same convention as `business_today()`
(the clinic and its server share a timezone).
"""
from __future__ import annotations

import csv
import io
import secrets
from datetime import date, datetime, time, timedelta, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.config import settings
from app.core.database import get_db
from app.core.dates import business_today
from app.core.deps import CurrentUser, require_permission
from app.models.attendance import AttendanceEvent
from app.models.user import User
from app.schemas.attendance import (
    AttendanceDay,
    AttendanceEventCreate,
    AttendanceEventOut,
    AttendanceReport,
    AttendanceStatus,
    AttendanceUserReport,
    PunchIn,
    StaffNow,
)
from app.schemas.common import Page

router = APIRouter(prefix="/attendance", tags=["attendance"])

_SUNDAY = 6  # date.weekday() — the clinic's only non-working day


# ---------------------------------------------------------------- time helpers

def _as_utc(ts: datetime) -> datetime:
    """Normalize to aware UTC (naive datetimes from SQLite are UTC)."""
    return ts.replace(tzinfo=timezone.utc) if ts.tzinfo is None else ts.astimezone(timezone.utc)


def _local(ts: datetime) -> datetime:
    """Clinic-local wall clock (server timezone, like business_today)."""
    return _as_utc(ts).astimezone()


def _utc_range(date_from: date, date_to: date) -> tuple[datetime, datetime]:
    """[start, end) UTC instants covering the *local* calendar dates inclusive."""
    start = datetime.combine(date_from, time.min).astimezone(timezone.utc)
    end = datetime.combine(date_to + timedelta(days=1), time.min).astimezone(timezone.utc)
    return start, end


def _normalize_range(date_from: date | None, date_to: date | None) -> tuple[date, date]:
    if date_from is None and date_to is None:
        today = business_today()
        return today, today
    if date_from is None:
        return date_to, date_to  # type: ignore[return-value]
    if date_to is None:
        date_to = max(date_from, business_today())
    if date_from > date_to:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "date_from must be <= date_to")
    return date_from, date_to


def _work_day_start() -> time:
    try:
        return datetime.strptime(settings.work_day_start, "%H:%M").time()
    except ValueError:
        return time(9, 0)


def _event_out(event: AttendanceEvent) -> AttendanceEventOut:
    dto = AttendanceEventOut.model_validate(event)
    dto.user_full_name = event.user.full_name if event.user else None
    return dto


def _primary_role(user: User) -> str | None:
    """First role name for display in the live roster (None if unassigned)."""
    return user.roles[0].name if user.roles else None


# ------------------------------------------------------------------- endpoints

@router.post("/punch", response_model=AttendanceEventOut, status_code=status.HTTP_201_CREATED)
def faceid_punch(
    payload: PunchIn,
    db: Annotated[Session, Depends(get_db)],
    x_attendance_key: Annotated[str | None, Header(alias="X-Attendance-Key")] = None,
) -> AttendanceEventOut:
    """Face ID terminal webhook: shared-secret header, no JWT.

    Without a direction the punch auto-toggles: if the employee's last event
    *today* is "in", this one is "out"; otherwise "in".
    """
    if not settings.attendance_api_key:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Attendance integration is not configured (ATTENDANCE_API_KEY unset)",
        )
    if not x_attendance_key or not secrets.compare_digest(
        x_attendance_key.encode(), settings.attendance_api_key.encode()
    ):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid attendance key")

    if payload.user_id is not None:
        user = db.get(User, payload.user_id)
    else:
        user = db.execute(
            select(User).where(func.lower(User.email) == payload.email.strip().lower())
        ).scalar_one_or_none()
    if user is None or not user.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")

    direction = payload.direction
    if direction is None:
        last = db.execute(
            select(AttendanceEvent)
            .where(AttendanceEvent.user_id == user.id)
            .order_by(AttendanceEvent.occurred_at.desc(), AttendanceEvent.created_at.desc())
            .limit(1)
        ).scalar_one_or_none()
        last_is_today = last is not None and _local(last.occurred_at).date() == business_today()
        direction = "out" if last_is_today and last.direction == "in" else "in"

    event = AttendanceEvent(
        user_id=user.id,
        branch_id=user.branch_id,
        direction=direction,
        occurred_at=datetime.now(timezone.utc),
        source="faceid",
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return _event_out(event)


@router.post("/events", response_model=AttendanceEventOut, status_code=status.HTTP_201_CREATED)
def create_manual_event(
    payload: AttendanceEventCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("attendance.manage"))],
) -> AttendanceEventOut:
    """Manual punch by an administrator (correction / forgotten badge)."""
    user = db.get(User, payload.user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")

    event = AttendanceEvent(
        user_id=user.id,
        branch_id=user.branch_id,
        direction=payload.direction,
        occurred_at=_as_utc(payload.occurred_at),
        source="manual",
        note=payload.note,
        recorded_by_id=actor.id,
    )
    db.add(event)
    db.flush()
    record_audit(
        db,
        action="create",
        entity_type="attendance_event",
        entity_id=event.id,
        actor_id=actor.id,
        branch_id=event.branch_id,
        summary=f"Manual '{payload.direction}' punch for {user.full_name} "
                f"at {_local(event.occurred_at):%Y-%m-%d %H:%M}",
    )
    db.commit()
    db.refresh(event)
    return _event_out(event)


@router.get(
    "/events",
    response_model=Page[AttendanceEventOut],
    dependencies=[Depends(require_permission("attendance.read"))],
)
def list_events(
    db: Annotated[Session, Depends(get_db)],
    user_id: UUID | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[AttendanceEventOut]:
    """Raw punch log, newest first. Defaults to today (local business day)."""
    date_from, date_to = _normalize_range(date_from, date_to)
    start, end = _utc_range(date_from, date_to)

    stmt = select(AttendanceEvent).where(
        AttendanceEvent.occurred_at >= start, AttendanceEvent.occurred_at < end
    )
    if user_id:
        stmt = stmt.where(AttendanceEvent.user_id == user_id)
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(
        stmt.order_by(AttendanceEvent.occurred_at.desc(), AttendanceEvent.created_at.desc())
        .offset(offset)
        .limit(limit)
    ).scalars().all()
    return Page(items=[_event_out(e) for e in rows], total=total, offset=offset, limit=limit)


# ---------------------------------------------------------------------- report

def _day_row(day: date, events: list[AttendanceEvent], workday_start: time) -> AttendanceDay:
    """Reconstruct one working day from chronological events.

    worked_minutes = sum of closed in->out pairs; a trailing unpaired "in"
    contributes 0 (day still open). Stray "out" without an open "in" and
    duplicate "in" recognitions are ignored.
    """
    first_in = next((e for e in events if e.direction == "in"), None)
    last_out = next((e for e in reversed(events) if e.direction == "out"), None)

    worked = 0
    open_in: datetime | None = None
    for e in events:
        if e.direction == "in":
            if open_in is None:
                open_in = _as_utc(e.occurred_at)
        elif open_in is not None:
            worked += int((_as_utc(e.occurred_at) - open_in).total_seconds() // 60)
            open_in = None

    late = first_in is not None and _local(first_in.occurred_at).time() > workday_start
    return AttendanceDay(
        day=day,
        first_in=_as_utc(first_in.occurred_at) if first_in else None,
        last_out=_as_utc(last_out.occurred_at) if last_out else None,
        worked_minutes=worked,
        late=late,
    )


def _build_report(db: Session, date_from: date, date_to: date) -> AttendanceReport:
    start, end = _utc_range(date_from, date_to)
    events = db.execute(
        select(AttendanceEvent)
        .where(AttendanceEvent.occurred_at >= start, AttendanceEvent.occurred_at < end)
        .order_by(AttendanceEvent.occurred_at, AttendanceEvent.created_at)
    ).scalars().all()

    # Active staff always appear (absences matter even with zero punches);
    # inactive users appear only when they have events inside the range.
    users: dict[UUID, User] = {
        u.id: u for u in db.execute(select(User).where(User.is_active.is_(True))).scalars()
    }
    by_user: dict[UUID, dict[date, list[AttendanceEvent]]] = {}
    for e in events:
        users.setdefault(e.user_id, e.user)
        by_user.setdefault(e.user_id, {}).setdefault(_local(e.occurred_at).date(), []).append(e)

    today = business_today()
    workday_start = _work_day_start()
    rows: list[AttendanceUserReport] = []
    for uid, user in users.items():
        days_events = by_user.get(uid, {})
        day_rows = [_day_row(d, days_events[d], workday_start) for d in sorted(days_events)]

        days_absent = 0
        if user.is_active:
            d = date_from
            while d <= min(date_to, today):  # future days are not absences yet
                if d.weekday() != _SUNDAY and d not in days_events:
                    days_absent += 1
                d += timedelta(days=1)

        rows.append(
            AttendanceUserReport(
                user_id=uid,
                full_name=user.full_name,
                days=day_rows,
                days_present=len(day_rows),
                days_absent=days_absent,
                total_minutes=sum(r.worked_minutes for r in day_rows),
                late_count=sum(1 for r in day_rows if r.late),
            )
        )

    rows.sort(key=lambda r: r.full_name.lower())
    return AttendanceReport(
        date_from=date_from,
        date_to=date_to,
        work_day_start=settings.work_day_start,
        users=rows,
    )


@router.get(
    "/report",
    response_model=AttendanceReport,
    dependencies=[Depends(require_permission("attendance.read"))],
)
def attendance_report(
    db: Annotated[Session, Depends(get_db)],
    date_from: date | None = None,
    date_to: date | None = None,
) -> AttendanceReport:
    """Timesheet: per-user day rows + presence/absence/lateness totals."""
    date_from, date_to = _normalize_range(date_from, date_to)
    return _build_report(db, date_from, date_to)


@router.get(
    "/report.csv",
    dependencies=[Depends(require_permission("attendance.read"))],
    response_class=Response,
)
def attendance_report_csv(
    db: Annotated[Session, Depends(get_db)],
    date_from: date | None = None,
    date_to: date | None = None,
) -> Response:
    """Same timesheet flattened to CSV (UTF-8 with BOM so Excel opens it)."""
    date_from, date_to = _normalize_range(date_from, date_to)
    report = _build_report(db, date_from, date_to)

    buf = io.StringIO()
    writer = csv.writer(buf, delimiter=";")  # RU-locale Excel expects semicolons
    writer.writerow(["Сотрудник", "Дата", "Приход", "Уход", "Отработано (мин)", "Опоздание"])
    for u in report.users:
        for d in u.days:
            writer.writerow([
                u.full_name,
                d.day.isoformat(),
                _local(d.first_in).strftime("%H:%M") if d.first_in else "",
                _local(d.last_out).strftime("%H:%M") if d.last_out else "",
                d.worked_minutes,
                "да" if d.late else "",
            ])
    writer.writerow([])
    writer.writerow(["Сотрудник", "Дней на работе", "Прогулы", "Минут всего", "Опозданий"])
    for u in report.users:
        writer.writerow([u.full_name, u.days_present, u.days_absent, u.total_minutes, u.late_count])

    content = ("\ufeff" + buf.getvalue()).encode("utf-8")  # BOM: Excel auto-detects UTF-8
    filename = f"attendance_{date_from.isoformat()}_{date_to.isoformat()}.csv"
    return Response(
        content=content,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


# ------------------------------------------------------------- live status (now)

@router.get(
    "/status",
    response_model=AttendanceStatus,
    dependencies=[Depends(require_permission("attendance.read"))],
)
def attendance_status(db: Annotated[Session, Depends(get_db)]) -> AttendanceStatus:
    """Live roster for the director: who is in / has left / absent right now,
    lateness and hours so far today, plus whether the Face ID terminal is wired.
    """
    today = business_today()
    start, end = _utc_range(today, today)
    events = db.execute(
        select(AttendanceEvent)
        .where(AttendanceEvent.occurred_at >= start, AttendanceEvent.occurred_at < end)
        .order_by(AttendanceEvent.occurred_at, AttendanceEvent.created_at)
    ).scalars().all()

    # Active staff always appear; an inactive user who punched today is shown too.
    users: dict[UUID, User] = {
        u.id: u for u in db.execute(select(User).where(User.is_active.is_(True))).scalars()
    }
    by_user: dict[UUID, list[AttendanceEvent]] = {}
    for e in events:
        users.setdefault(e.user_id, e.user)
        by_user.setdefault(e.user_id, []).append(e)

    workday_start = _work_day_start()
    is_sunday = today.weekday() == _SUNDAY
    staff: list[StaffNow] = []
    present = left = absent = late_n = 0
    for uid, user in users.items():
        evs = by_user.get(uid, [])
        if not evs:
            staff.append(StaffNow(
                user_id=uid, full_name=user.full_name, role=_primary_role(user),
                status="absent", last_direction=None, last_event_at=None,
                first_in=None, late=False, worked_minutes=0,
            ))
            if user.is_active and not is_sunday:
                absent += 1
            continue

        first_in = next((e for e in evs if e.direction == "in"), None)
        last = evs[-1]
        worked = 0
        open_in: datetime | None = None
        for e in evs:
            if e.direction == "in":
                if open_in is None:
                    open_in = _as_utc(e.occurred_at)
            elif open_in is not None:
                worked += int((_as_utc(e.occurred_at) - open_in).total_seconds() // 60)
                open_in = None
        late = first_in is not None and _local(first_in.occurred_at).time() > workday_start
        status = "present" if last.direction == "in" else "left"
        if status == "present":
            present += 1
        else:
            left += 1
        if late:
            late_n += 1
        staff.append(StaffNow(
            user_id=uid, full_name=user.full_name, role=_primary_role(user),
            status=status, last_direction=last.direction,
            last_event_at=_as_utc(last.occurred_at),
            first_in=_as_utc(first_in.occurred_at) if first_in else None,
            late=late, worked_minutes=worked,
        ))

    # Present first, then left, then absent; alphabetical within each group.
    order = {"present": 0, "left": 1, "absent": 2}
    staff.sort(key=lambda s: (order[s.status], s.full_name.lower()))
    return AttendanceStatus(
        as_of=datetime.now(timezone.utc),
        work_day_start=settings.work_day_start,
        integration_enabled=bool(settings.attendance_api_key),
        total_staff=sum(1 for u in users.values() if u.is_active),
        present_count=present,
        left_count=left,
        absent_count=absent,
        late_count=late_n,
        staff=staff,
    )
