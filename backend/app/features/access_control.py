"""Access control / Face ID — connect Hikvision terminals and manage enrollment.

Three audiences, mirroring the attendance module:
  * the **director/admin** connects terminals, tests them, and enrolls staff
    faces (access_control.manage) and views status/events (access_control.read);
  * the **terminal** pushes recognition events to the unauthenticated webhook
    ``POST /access-control/event/{token}`` (secret in the URL — the device can't
    set auth headers), which becomes an ``AttendanceEvent(source="faceid")``.

Design: docs/INTEGRATIONS_HIKVISION.md. The enrollment mapping
(``User.faceid_employee_no``) is saved locally **before** the device push, so a
powered-off terminal never loses the mapping — re-running enroll retries the push.
"""
from __future__ import annotations

import json
import secrets
import socket
from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    Query,
    Request,
    UploadFile,
    status,
)
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.config import settings
from app.core.database import get_db
from app.core.dates import business_today
from app.core.deps import CurrentUser, require_permission
from app.core.devices.hikvision import HikvisionClient, TerminalError, TerminalUnreachable
from app.core.visibility import caller_is_owner, owner_user_id_set, owner_user_ids
from app.core.files import MAX_FILE_BYTES, save_upload
from app.core.storage import upload_face_photo
from app.models.attendance import AttendanceEvent
from app.models.face_terminal import FaceTerminal
from app.models.user import User
from app.schemas.access_control import (
    AccessEventOut,
    EnrollmentRow,
    EnrollResult,
    PushConfigIn,
    PushConfigResult,
    TerminalCreate,
    TerminalOut,
    TerminalTestResult,
    TerminalUpdate,
)

router = APIRouter(prefix="/access-control", tags=["AccessControl"])


# --------------------------------------------------------------------- helpers

def _get_terminal_or_404(db: Session, terminal_id: UUID) -> FaceTerminal:
    terminal = db.get(FaceTerminal, terminal_id)
    if terminal is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Terminal not found")
    return terminal


def _next_employee_no(db: Session) -> str:
    """Allocate the next numeric employeeNo (the device person id)."""
    rows = db.execute(
        select(User.faceid_employee_no).where(User.faceid_employee_no.is_not(None))
    ).scalars().all()
    nums = [int(r) for r in rows if r and r.isdigit()]
    return str((max(nums) + 1) if nums else 1001)


def _detect_lan_ip() -> str:
    """Best-effort primary LAN IPv4 of this server (the address the device pushes to)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))  # no packets sent; picks the default-route iface
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def _as_utc(ts: datetime) -> datetime:
    return ts.replace(tzinfo=timezone.utc) if ts.tzinfo is None else ts.astimezone(timezone.utc)


def _local_date(ts: datetime):
    return _as_utc(ts).astimezone().date()


# ------------------------------------------------------------------- terminals

@router.get(
    "/terminals",
    response_model=list[TerminalOut],
    dependencies=[Depends(require_permission("access_control.read"))],
)
def list_terminals(db: Annotated[Session, Depends(get_db)]) -> list[FaceTerminal]:
    return list(
        db.execute(select(FaceTerminal).order_by(FaceTerminal.created_at.asc())).scalars().all()
    )


@router.post("/terminals", response_model=TerminalOut, status_code=status.HTTP_201_CREATED)
def create_terminal(
    payload: TerminalCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("access_control.manage"))],
) -> FaceTerminal:
    terminal = FaceTerminal(**payload.model_dump())
    db.add(terminal)
    db.flush()
    record_audit(db, action="create", entity_type="face_terminal", entity_id=terminal.id,
                 actor_id=actor.id, branch_id=terminal.branch_id,
                 summary=f"Connected face terminal {terminal.name} ({terminal.host}:{terminal.port})")
    db.commit()
    db.refresh(terminal)
    return terminal


@router.patch("/terminals/{terminal_id}", response_model=TerminalOut)
def update_terminal(
    terminal_id: UUID,
    payload: TerminalUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("access_control.manage"))],
) -> FaceTerminal:
    terminal = _get_terminal_or_404(db, terminal_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(terminal, field, value)  # password only set when present
    record_audit(db, action="update", entity_type="face_terminal", entity_id=terminal.id,
                 actor_id=actor.id, branch_id=terminal.branch_id,
                 summary=f"Updated face terminal {terminal.name}")
    db.commit()
    db.refresh(terminal)
    return terminal


@router.delete("/terminals/{terminal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_terminal(
    terminal_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("access_control.manage"))],
) -> None:
    terminal = _get_terminal_or_404(db, terminal_id)
    record_audit(db, action="delete", entity_type="face_terminal", entity_id=terminal.id,
                 actor_id=actor.id, branch_id=terminal.branch_id,
                 summary=f"Removed face terminal {terminal.name}")
    db.delete(terminal)
    db.commit()


@router.post("/terminals/{terminal_id}/test", response_model=TerminalTestResult)
def test_terminal(
    terminal_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[CurrentUser, Depends(require_permission("access_control.manage"))],
) -> TerminalTestResult:
    """Probe the terminal over ISAPI and refresh its online status / device info."""
    terminal = _get_terminal_or_404(db, terminal_id)
    client = HikvisionClient.from_terminal(terminal)
    try:
        info = client.get_device_info()
    except (TerminalUnreachable, TerminalError) as exc:
        terminal.online = False
        db.commit()
        return TerminalTestResult(online=False, error=str(exc))

    terminal.online = True
    terminal.last_seen = datetime.now(timezone.utc)
    terminal.device_info = info
    db.commit()
    return TerminalTestResult(
        online=True,
        model=info.get("model"),
        firmware=info.get("firmwareVersion"),
        serial=info.get("serialNumber"),
        device_name=info.get("deviceName"),
    )


@router.post("/terminals/{terminal_id}/configure-push", response_model=PushConfigResult)
def configure_push(
    terminal_id: UUID,
    payload: PushConfigIn,
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[CurrentUser, Depends(require_permission("access_control.manage"))],
) -> PushConfigResult:
    """One-click: tell the terminal to POST its events to our webhook.

    Saves the operator from configuring the device web UI by hand. Needs the
    webhook secret configured (HIKVISION_EVENT_TOKEN); the server's LAN IP is
    auto-detected unless the caller passes the host it reached us on.
    """
    terminal = _get_terminal_or_404(db, terminal_id)
    token = settings.hikvision_event_token
    if not token:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            "Webhook secret is not configured (set HIKVISION_EVENT_TOKEN in the server .env)",
        )
    server_host = payload.server_host or _detect_lan_ip()
    server_port = payload.server_port or 8000
    masked = f"http://{server_host}:{server_port}/api/v1/access-control/event/****"

    client = HikvisionClient.from_terminal(terminal)
    try:
        client.enable_event_push(server_host, server_port, token, host_id=1)
        return PushConfigResult(configured=True, url=masked)
    except (TerminalUnreachable, TerminalError) as exc:
        return PushConfigResult(configured=False, url=masked, error=str(exc))


# ------------------------------------------------------------------ enrollment

@router.get(
    "/enrollment",
    response_model=list[EnrollmentRow],
)
def list_enrollment(
    db: Annotated[Session, Depends(get_db)],
    viewer: Annotated[CurrentUser, Depends(require_permission("access_control.read"))],
    only_active: bool = Query(True),
) -> list[EnrollmentRow]:
    """Every staff member with their Face ID enrollment status."""
    stmt = select(User)
    if only_active:
        stmt = stmt.where(User.is_active.is_(True))
    # Ghost owner: excluded from the enrollment list for every non-owner viewer.
    if not caller_is_owner(viewer, owner_user_id_set(db)):
        stmt = stmt.where(User.id.not_in(owner_user_ids()))
    users = db.execute(stmt.order_by(User.full_name.asc())).scalars().all()
    return [
        EnrollmentRow(
            user_id=u.id,
            full_name=u.full_name,
            email=u.email,
            branch_id=u.branch_id,
            faceid_employee_no=u.faceid_employee_no,
            enrolled=u.faceid_employee_no is not None,
        )
        for u in users
    ]


@router.post("/terminals/{terminal_id}/enroll/{user_id}", response_model=EnrollResult)
def enroll_user(
    terminal_id: UUID,
    user_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("access_control.manage"))],
) -> EnrollResult:
    """Assign an employeeNo (if needed) and push the person onto the terminal.

    The mapping is committed locally first; the device push is best-effort so an
    offline terminal still leaves the staff member enrolled (retry pushes later).
    """
    terminal = _get_terminal_or_404(db, terminal_id)
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")

    if user.faceid_employee_no is None:
        user.faceid_employee_no = _next_employee_no(db)
        record_audit(db, action="update", entity_type="user", entity_id=user.id,
                     actor_id=actor.id, branch_id=user.branch_id,
                     summary=f"Assigned Face ID employeeNo {user.faceid_employee_no} to {user.full_name}")
        db.commit()
        db.refresh(user)

    employee_no = user.faceid_employee_no
    client = HikvisionClient.from_terminal(terminal)
    try:
        client.enroll_user(employee_no, user.full_name, door_no=terminal.door_no)
        return EnrollResult(user_id=user.id, faceid_employee_no=employee_no, pushed_to_device=True)
    except (TerminalUnreachable, TerminalError) as exc:
        return EnrollResult(user_id=user.id, faceid_employee_no=employee_no,
                            pushed_to_device=False, error=str(exc))


@router.post("/terminals/{terminal_id}/enroll/{user_id}/face", response_model=EnrollResult)
def upload_user_face(
    terminal_id: UUID,
    user_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[CurrentUser, Depends(require_permission("access_control.manage"))],
    file: Annotated[UploadFile, File()],
) -> EnrollResult:
    """Upload a face photo for an already-enrolled staff member to the terminal."""
    terminal = _get_terminal_or_404(db, terminal_id)
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if user.faceid_employee_no is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "Enroll the staff member before uploading a face")

    content = file.file.read(MAX_FILE_BYTES + 1)
    if len(content) > MAX_FILE_BYTES:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            f"File too large (max {MAX_FILE_BYTES // (1024 * 1024)} MB)")
    # Keep a local copy (validates the extension too); ignore the stored name.
    try:
        save_upload(content, file.filename or "face.jpg")
    except ValueError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(exc)) from None

    # Durable backup to cloud storage (best-effort, no-op if unconfigured) — so a
    # face survives an ephemeral server and can be re-pushed to a new terminal.
    upload_face_photo(user.faceid_employee_no, content)

    client = HikvisionClient.from_terminal(terminal)
    try:
        client.upload_face(user.faceid_employee_no, content)
        return EnrollResult(user_id=user.id, faceid_employee_no=user.faceid_employee_no,
                            pushed_to_device=True, face_uploaded=True)
    except (TerminalUnreachable, TerminalError) as exc:
        return EnrollResult(user_id=user.id, faceid_employee_no=user.faceid_employee_no,
                            pushed_to_device=True, face_uploaded=False, error=str(exc))


@router.delete("/terminals/{terminal_id}/enroll/{user_id}", response_model=EnrollResult)
def remove_enrollment(
    terminal_id: UUID,
    user_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("access_control.manage"))],
) -> EnrollResult:
    """Delete the person from the terminal and clear the local mapping."""
    terminal = _get_terminal_or_404(db, terminal_id)
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if user.faceid_employee_no is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "User is not enrolled")

    employee_no = user.faceid_employee_no
    client = HikvisionClient.from_terminal(terminal)
    device_error: str | None = None
    try:
        client.delete_user(employee_no)
    except (TerminalUnreachable, TerminalError) as exc:
        device_error = str(exc)

    user.faceid_employee_no = None
    record_audit(db, action="update", entity_type="user", entity_id=user.id,
                 actor_id=actor.id, branch_id=user.branch_id,
                 summary=f"Removed Face ID enrollment ({employee_no}) for {user.full_name}")
    db.commit()
    return EnrollResult(user_id=user.id, faceid_employee_no=employee_no,
                        pushed_to_device=device_error is None, error=device_error)


# ---------------------------------------------------------------------- events

@router.get(
    "/events",
    response_model=list[AccessEventOut],
    dependencies=[Depends(require_permission("access_control.read"))],
)
def recent_events(
    db: Annotated[Session, Depends(get_db)],
    limit: int = Query(50, ge=1, le=200),
) -> list[AccessEventOut]:
    """Recent Face ID recognitions (attendance punches with source='faceid')."""
    rows = db.execute(
        select(AttendanceEvent)
        .where(AttendanceEvent.source == "faceid")
        .order_by(AttendanceEvent.occurred_at.desc(), AttendanceEvent.created_at.desc())
        .limit(limit)
    ).scalars().all()
    out: list[AccessEventOut] = []
    for e in rows:
        dto = AccessEventOut.model_validate(e)
        dto.user_full_name = e.user.full_name if e.user else None
        out.append(dto)
    return out


# --------------------------------------------------------------------- webhook

_ATTENDANCE_DIRECTION = {
    "checkIn": "in", "checkOut": "out",
    "breakIn": "in", "breakOut": "out",
}


async def _parse_event_request(request: Request) -> tuple[dict, bytes | None]:
    """Extract the event JSON and optional face JPEG from a device push.

    Hikvision sends either ``application/json`` or ``multipart/form-data`` (a
    JSON part + a picture part); part names vary by firmware, so we parse
    defensively: merge every JSON-looking part and grab the first image.
    """
    content_type = request.headers.get("content-type", "")
    if content_type.startswith("application/json"):
        try:
            return json.loads(await request.body() or b"{}"), None
        except (json.JSONDecodeError, ValueError):
            return {}, None

    event: dict = {}
    image: bytes | None = None
    form = await request.form()
    for value in form.values():
        if isinstance(value, UploadFile):
            blob = await value.read()
            ctype = (value.content_type or "")
            if "json" in ctype or (value.filename or "").endswith(".json"):
                try:
                    parsed = json.loads(blob or b"{}")
                    if isinstance(parsed, dict):
                        event.update(parsed)
                except (json.JSONDecodeError, ValueError):
                    pass
            elif "image" in ctype or (value.filename or "").lower().endswith((".jpg", ".jpeg", ".png")):
                image = image or blob
        elif isinstance(value, str):
            try:
                parsed = json.loads(value)
                if isinstance(parsed, dict):
                    event.update(parsed)
            except (json.JSONDecodeError, ValueError):
                pass
    return event, image


@router.post("/event/{token}", status_code=status.HTTP_200_OK)
async def terminal_event_webhook(
    token: str,
    request: Request,
    db: Annotated[Session, Depends(get_db)],
) -> dict:
    """Unauthenticated device webhook (secret in the path + optional IP allowlist).

    Maps ``employeeNoString`` -> User and records an ``AttendanceEvent``. Always
    answers 200-ish for handled cases so the device never retry-storms; only the
    security gates (token / IP) reject.
    """
    if not settings.hikvision_event_token:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE,
                            "Face ID webhook not configured (HIKVISION_EVENT_TOKEN unset)")
    if not secrets.compare_digest(token, settings.hikvision_event_token):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid event token")
    if settings.hikvision_allowed_ips:
        client_ip = request.client.host if request.client else None
        if client_ip not in settings.hikvision_allowed_ips:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Source IP not allowed")

    event, _image = await _parse_event_request(request)
    ace = event.get("AccessControllerEvent") or {}
    employee_no = (ace.get("employeeNoString") or ace.get("employeeNo")
                   or event.get("employeeNoString"))
    if not employee_no:
        return {"status": "ignored", "reason": "no employee (heartbeat/non-auth event)"}
    employee_no = str(employee_no)

    user = db.execute(
        select(User).where(User.faceid_employee_no == employee_no)
    ).scalar_one_or_none()
    if user is None or not user.is_active:
        return {"status": "unknown_employee", "employee_no": employee_no}

    # Event time: trust the device clock (NTP); fall back to receipt time.
    raw_time = event.get("dateTime") or ace.get("time")
    try:
        occurred_at = _as_utc(datetime.fromisoformat(raw_time)) if raw_time else datetime.now(timezone.utc)
    except (ValueError, TypeError):
        occurred_at = datetime.now(timezone.utc)

    # Direction: explicit attendanceStatus wins; else auto-toggle vs last event today.
    direction = _ATTENDANCE_DIRECTION.get(ace.get("attendanceStatus") or "")
    if direction is None:
        last = db.execute(
            select(AttendanceEvent)
            .where(AttendanceEvent.user_id == user.id)
            .order_by(AttendanceEvent.occurred_at.desc(), AttendanceEvent.created_at.desc())
            .limit(1)
        ).scalar_one_or_none()
        last_today = last is not None and _local_date(last.occurred_at) == business_today()
        direction = "out" if last_today and last.direction == "in" else "in"

    punch = AttendanceEvent(
        user_id=user.id,
        branch_id=user.branch_id,
        direction=direction,
        occurred_at=occurred_at,
        source="faceid",
    )
    db.add(punch)
    db.commit()
    db.refresh(punch)
    return {"status": "recorded", "event_id": str(punch.id),
            "user_id": str(user.id), "direction": direction}
