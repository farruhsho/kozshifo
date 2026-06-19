"""Call log & reception-phone monitoring API (TZ Modul 9).

Two ingest seams write the SAME ``call_records`` table:

* ``POST /calls/ingest`` — PBX webhook (Asterisk dialplan / AMI). Auth: the
  shared ``X-PBX-Key`` secret (503 while unset, 401 on mismatch).
* ``POST /calls/agent/ingest`` (+ ``/agent/heartbeat``) — the Android agent on a
  reception phone. Auth: each phone's OWN ``X-Device-Key``. Batched & idempotent
  so a flaky upload can be retried safely.

The director watches the result through ``GET /calls`` (journal) and
``GET /calls/summary`` (answered / missed / wait-time KPIs, per-device, per-hour,
plus the live "offline phone" list). Reception phones are registered under
``/calls/devices`` (behind ``calls.manage``).
"""
from __future__ import annotations

import hashlib
import re
import secrets
from datetime import date, datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.config import settings
from app.core.database import get_db
from app.core.dates import business_today, local_day_bounds_utc
from app.core.deps import CurrentUser, require_any_permission, require_permission
from app.models.call import CallDevice, CallRecord
from app.models.patient import Patient
from app.schemas.call import (
    AgentBatchResult,
    AgentCallIngest,
    CallDeviceCreate,
    CallDeviceCreated,
    CallDeviceOut,
    CallDeviceStat,
    CallDeviceUpdate,
    CallHourBucket,
    CallIngest,
    CallOut,
    CallsSummary,
    HeartbeatIn,
    HeartbeatOut,
)
from app.schemas.common import Page

router = APIRouter(prefix="/calls", tags=["calls"])

# Below this many digits the number is too ambiguous to auto-link (extensions,
# short codes); above it we compare by the Uzbek subscriber part (last 9):
# +998 90 111-22-33 and 901112233 are the same line.
_MIN_MATCH_DIGITS = 7
_SUFFIX_DIGITS = 9


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _digits(value: str) -> str:
    """Normalize a phone to digits only (strip +, spaces, dashes, parens…)."""
    return re.sub(r"\D", "", value)


def _as_utc(dt: datetime) -> datetime:
    """A naive timestamp from a device/PBX is taken as UTC by contract."""
    return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt.astimezone(timezone.utc)


# ════════════════════════════════════════════════════════════════════════════
# Auth seams
# ════════════════════════════════════════════════════════════════════════════
def _require_pbx_key(
    x_pbx_key: Annotated[str | None, Header(alias="X-PBX-Key")] = None,
) -> None:
    if not settings.pbx_api_key:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "PBX integration is disabled (pbx_api_key is not configured)",
        )
    # compare_digest raises TypeError on non-ASCII str (FastAPI latin-1-decodes
    # headers) → encode both sides so a junk key returns 401, not a 500.
    if x_pbx_key is None or not secrets.compare_digest(
        x_pbx_key.encode(), settings.pbx_api_key.encode()
    ):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid PBX key")


def _hash_key(key: str) -> str:
    """SHA-256 hex of a device key — high-entropy secret, looked up by exact hash."""
    return hashlib.sha256(key.encode()).hexdigest()


def _gen_key() -> str:
    return secrets.token_urlsafe(32)


def _device_from_key(
    db: Annotated[Session, Depends(get_db)],
    x_device_key: Annotated[str | None, Header(alias="X-Device-Key")] = None,
) -> CallDevice:
    """Resolve the reception phone from its per-device key (agent endpoints)."""
    if not x_device_key:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing X-Device-Key")
    device = db.execute(
        select(CallDevice).where(
            CallDevice.api_key_hash == _hash_key(x_device_key),
            CallDevice.is_active.is_(True),
        )
    ).scalar_one_or_none()
    if device is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid device key")
    return device


# ════════════════════════════════════════════════════════════════════════════
# Patient auto-linking
# ════════════════════════════════════════════════════════════════════════════
def _match_patient(db: Session, digits: str) -> Patient | None:
    """Auto-link: first patient whose phone digits end with the call's last 9.

    Pragmatic v1 choice: Patient.phone stores free-form input, so we normalize
    it *in the query* with nested replace() over the usual separators and
    suffix-match with LIKE — a scan, not an index hit. Oldest matching patient
    wins (deterministic "first match").
    """
    if len(digits) < _MIN_MATCH_DIGITS:
        return None
    suffix = digits[-_SUFFIX_DIGITS:]
    normalized = Patient.phone
    for junk in ("+", " ", "-", "(", ")", "."):
        normalized = func.replace(normalized, junk, "")
    stmt = (
        select(Patient)
        .where(Patient.phone.is_not(None), normalized.like(f"%{suffix}"))
        .order_by(Patient.created_at.asc())
        .limit(1)
    )
    return db.execute(stmt).scalars().first()


# ════════════════════════════════════════════════════════════════════════════
# Ingest — PBX webhook (legacy single call)
# ════════════════════════════════════════════════════════════════════════════
@router.post("/ingest", response_model=CallOut, dependencies=[Depends(_require_pbx_key)])
def ingest_call(payload: CallIngest, db: Annotated[Session, Depends(get_db)]) -> CallRecord:
    """PBX webhook: store one finished call, auto-linking the patient by phone."""
    digits = _digits(payload.phone)
    if not digits:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "phone must contain digits")

    patient = _match_patient(db, digits)
    # The PBX payload has no explicit status — derive a sensible one so the
    # monitoring KPIs work on this path too: outgoing, else answered if there
    # was talk time, else missed.
    call_status = (
        "outgoing" if payload.direction == "out"
        else ("answered" if payload.duration_seconds > 0 else "missed")
    )
    record = CallRecord(
        direction=payload.direction,
        status=call_status,
        phone=payload.phone,
        phone_normalized=digits,
        started_at=_as_utc(payload.started_at),
        duration_seconds=payload.duration_seconds,
        recording_url=payload.recording_url,
        note=payload.note,
        patient_id=patient.id if patient else None,
        branch_id=patient.branch_id if patient else None,
    )
    db.add(record)
    db.flush()
    record_audit(
        db, action="create", entity_type="call_record", entity_id=record.id,
        branch_id=patient.branch_id if patient else None,
        summary=(
            f"{'Incoming' if payload.direction == 'in' else 'Outgoing'} call {payload.phone}"
            + (f" → patient {patient.full_name}" if patient else " (no patient match)")
        ),
    )
    db.commit()
    db.refresh(record)
    return record


# ════════════════════════════════════════════════════════════════════════════
# Ingest — Android reception-phone agent (batch, idempotent)
# ════════════════════════════════════════════════════════════════════════════
@router.post("/agent/ingest", response_model=AgentBatchResult)
def agent_ingest(
    payload: list[AgentCallIngest],
    device: Annotated[CallDevice, Depends(_device_from_key)],
    db: Annotated[Session, Depends(get_db)],
) -> AgentBatchResult:
    """Reception phone uploads a batch of finished calls (idempotent per device)."""
    ingested = duplicates = 0
    for item in payload:
        digits = _digits(item.phone)
        if not digits:
            continue  # junk number (e.g. unknown/private) — nothing to record
        exists = db.execute(
            select(CallRecord.id).where(
                CallRecord.device_id == device.id,
                CallRecord.external_id == item.external_id,
            )
        ).scalar_one_or_none()
        if exists is not None:
            duplicates += 1
            continue
        patient = _match_patient(db, digits)
        db.add(CallRecord(
            direction=item.direction,
            status=item.status,
            phone=item.phone,
            phone_normalized=digits,
            started_at=_as_utc(item.started_at),
            ended_at=_as_utc(item.ended_at) if item.ended_at else None,
            wait_seconds=item.wait_seconds,
            duration_seconds=item.duration_seconds,
            note=item.note,
            patient_id=patient.id if patient else None,
            device_id=device.id,
            external_id=item.external_id,
            branch_id=device.branch_id,
        ))
        ingested += 1

    device.last_seen_at = _now()  # an upload is also a sign of life
    if ingested:
        record_audit(
            db, action="create", entity_type="call_record", entity_id=device.id,
            branch_id=device.branch_id,
            summary=f"Agent '{device.label}' uploaded {ingested} call(s)",
        )
    db.commit()
    return AgentBatchResult(received=len(payload), ingested=ingested, duplicates=duplicates)


@router.post("/agent/heartbeat", response_model=HeartbeatOut)
def agent_heartbeat(
    payload: HeartbeatIn,
    device: Annotated[CallDevice, Depends(_device_from_key)],
    db: Annotated[Session, Depends(get_db)],
) -> HeartbeatOut:
    """Liveness ping (~every 60s) so the director sees a phone go offline."""
    now = _now()
    device.last_seen_at = now
    if payload.app_version:
        device.app_version = payload.app_version
    db.commit()
    return HeartbeatOut(server_time=now)


# ════════════════════════════════════════════════════════════════════════════
# Device registry (director)
# ════════════════════════════════════════════════════════════════════════════
def _is_online(device: CallDevice, now: datetime) -> bool:
    if device.last_seen_at is None:
        return False
    age = (now - _as_utc(device.last_seen_at)).total_seconds()
    return age <= settings.call_device_offline_minutes * 60


def _device_out(device: CallDevice, now: datetime) -> CallDeviceOut:
    return CallDeviceOut(
        id=device.id, label=device.label, phone_number=device.phone_number,
        branch_id=device.branch_id, is_active=device.is_active,
        last_seen_at=device.last_seen_at, app_version=device.app_version,
        online=_is_online(device, now),
    )


@router.get("/devices", response_model=list[CallDeviceOut],
            dependencies=[Depends(require_permission("calls.manage"))])
def list_devices(db: Annotated[Session, Depends(get_db)]) -> list[CallDeviceOut]:
    now = _now()
    rows = db.execute(select(CallDevice).order_by(CallDevice.label)).scalars().all()
    return [_device_out(d, now) for d in rows]


@router.post("/devices", response_model=CallDeviceCreated, status_code=status.HTTP_201_CREATED,
             dependencies=[Depends(require_permission("calls.manage"))])
def create_device(
    payload: CallDeviceCreate,
    db: Annotated[Session, Depends(get_db)],
    user: CurrentUser,
) -> CallDeviceCreated:
    """Register a reception phone; returns its key ONCE (only the hash is stored)."""
    key = _gen_key()
    device = CallDevice(
        label=payload.label,
        phone_number=payload.phone_number,
        branch_id=payload.branch_id,
        api_key_hash=_hash_key(key),
    )
    db.add(device)
    db.flush()
    record_audit(
        db, action="create", entity_type="call_device", entity_id=device.id,
        actor_id=user.id, branch_id=device.branch_id,
        summary=f"Registered reception phone '{device.label}'",
    )
    db.commit()
    db.refresh(device)
    base = _device_out(device, _now())
    return CallDeviceCreated(**base.model_dump(), api_key=key)


@router.patch("/devices/{device_id}", response_model=CallDeviceOut,
              dependencies=[Depends(require_permission("calls.manage"))])
def update_device(
    device_id: UUID,
    payload: CallDeviceUpdate,
    db: Annotated[Session, Depends(get_db)],
    user: CurrentUser,
) -> CallDeviceOut:
    device = db.get(CallDevice, device_id)
    if device is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Device not found")
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(device, field, value)
    record_audit(
        db, action="update", entity_type="call_device", entity_id=device.id,
        actor_id=user.id, branch_id=device.branch_id, changes=data,
        summary=f"Updated reception phone '{device.label}'",
    )
    db.commit()
    db.refresh(device)
    return _device_out(device, _now())


@router.post("/devices/{device_id}/rotate-key", response_model=CallDeviceCreated,
             dependencies=[Depends(require_permission("calls.manage"))])
def rotate_device_key(
    device_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    user: CurrentUser,
) -> CallDeviceCreated:
    """Issue a fresh key (the old one stops working immediately)."""
    device = db.get(CallDevice, device_id)
    if device is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Device not found")
    key = _gen_key()
    device.api_key_hash = _hash_key(key)
    record_audit(
        db, action="update", entity_type="call_device", entity_id=device.id,
        actor_id=user.id, branch_id=device.branch_id,
        summary=f"Rotated key for reception phone '{device.label}'",
    )
    db.commit()
    db.refresh(device)
    base = _device_out(device, _now())
    return CallDeviceCreated(**base.model_dump(), api_key=key)


# ════════════════════════════════════════════════════════════════════════════
# Journal
# ════════════════════════════════════════════════════════════════════════════
@router.get("", response_model=Page[CallOut],
            dependencies=[Depends(require_permission("calls.read"))])
def list_calls(
    db: Annotated[Session, Depends(get_db)],
    date_from: datetime | None = Query(None, description="started_at >= (UTC)"),
    date_to: datetime | None = Query(None, description="started_at <= (UTC)"),
    q: str | None = Query(None, description="Phone digits fragment or patient name"),
    call_status: str | None = Query(None, alias="status",
                                    description="answered|missed|rejected|outgoing"),
    device_id: UUID | None = Query(None),
    branch_id: UUID | None = Query(None),
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[CallOut]:
    stmt = select(CallRecord).outerjoin(Patient, CallRecord.patient_id == Patient.id)
    if date_from is not None:
        stmt = stmt.where(CallRecord.started_at >= date_from)
    if date_to is not None:
        stmt = stmt.where(CallRecord.started_at <= date_to)
    if call_status:
        stmt = stmt.where(CallRecord.status == call_status)
    if device_id is not None:
        stmt = stmt.where(CallRecord.device_id == device_id)
    if branch_id is not None:
        stmt = stmt.where(CallRecord.branch_id == branch_id)
    if q and q.strip():
        term = q.strip()
        like = f"%{term}%"
        conds = [Patient.first_name.ilike(like), Patient.last_name.ilike(like)]
        digits = _digits(term)
        if digits:
            conds.append(CallRecord.phone_normalized.like(f"%{digits}%"))
        stmt = stmt.where(or_(*conds))
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(
        stmt.order_by(CallRecord.started_at.desc()).offset(offset).limit(limit)
    ).scalars().all()
    return Page(items=[CallOut.model_validate(r) for r in rows], total=total, offset=offset, limit=limit)


# ════════════════════════════════════════════════════════════════════════════
# KPI summary (director monitoring) — answered / missed / wait-time
# ════════════════════════════════════════════════════════════════════════════
def _local_hour(dt: datetime) -> int:
    return _as_utc(dt).astimezone().hour  # clinic-local hour (host timezone)


@router.get("/summary", response_model=CallsSummary,
            dependencies=[Depends(require_any_permission("calls.read", "dashboard.view"))])
def calls_summary(
    db: Annotated[Session, Depends(get_db)],
    date_from: date | None = Query(None, description="Local start date (inclusive)"),
    date_to: date | None = Query(None, description="Local end date (inclusive)"),
    branch_id: UUID | None = Query(None),
) -> CallsSummary:
    """Answered / missed / wait-time KPIs over a LOCAL day range (default: today).

    Aggregated in Python over the window's rows (a clinic's daily call volume is
    small) so per-hour buckets use the clinic-local hour without DB-specific date
    functions. ``offline_devices`` is live (independent of the date range).
    """
    if date_from and date_to and date_from > date_to:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "date_from must be <= date_to")

    if date_from is None and date_to is None:
        start, end = local_day_bounds_utc(business_today())
    else:
        start = local_day_bounds_utc(date_from)[0] if date_from else None
        end = local_day_bounds_utc(date_to)[1] if date_to else None  # date_to inclusive

    stmt = select(CallRecord)
    if start is not None:
        stmt = stmt.where(CallRecord.started_at >= start)
    if end is not None:
        stmt = stmt.where(CallRecord.started_at < end)
    if branch_id is not None:
        stmt = stmt.where(CallRecord.branch_id == branch_id)
    rows = db.execute(stmt).scalars().all()

    answered = sum(1 for r in rows if r.status == "answered")
    missed = sum(1 for r in rows if r.status == "missed")
    rejected = sum(1 for r in rows if r.status == "rejected")
    outgoing = sum(1 for r in rows if r.status == "outgoing")
    incoming = sum(1 for r in rows if r.direction == "in")
    waits = [r.wait_seconds for r in rows if r.status == "answered" and r.direction == "in"]
    avg_wait = round(sum(waits) / len(waits)) if waits else 0

    # Per-device breakdown (None bucket = PBX / unassigned).
    dev_groups: dict[UUID | None, dict] = {}
    for r in rows:
        g = dev_groups.setdefault(
            r.device_id,
            {"label": r.device.label if r.device else "Без устройства",
             "total": 0, "answered": 0, "missed": 0, "waits": []},
        )
        g["total"] += 1
        if r.status == "answered":
            g["answered"] += 1
            if r.direction == "in":
                g["waits"].append(r.wait_seconds)
        elif r.status == "missed":
            g["missed"] += 1
    by_device = [
        CallDeviceStat(
            device_id=dev_id, label=g["label"], total=g["total"],
            answered=g["answered"], missed=g["missed"],
            avg_wait_seconds=round(sum(g["waits"]) / len(g["waits"])) if g["waits"] else 0,
        )
        for dev_id, g in dev_groups.items()
    ]
    by_device.sort(key=lambda s: s.total, reverse=True)

    # Per-hour buckets (all 24, clinic-local) for a heatmap.
    hours = {h: {"total": 0, "missed": 0} for h in range(24)}
    for r in rows:
        h = _local_hour(r.started_at)
        hours[h]["total"] += 1
        if r.status == "missed":
            hours[h]["missed"] += 1
    by_hour = [CallHourBucket(hour=h, total=v["total"], missed=v["missed"]) for h, v in sorted(hours.items())]

    # Live offline phones (independent of the date filter, optionally per branch).
    now = _now()
    dev_stmt = select(CallDevice).where(CallDevice.is_active.is_(True))
    if branch_id is not None:
        dev_stmt = dev_stmt.where(CallDevice.branch_id == branch_id)
    offline = [
        _device_out(d, now)
        for d in db.execute(dev_stmt).scalars().all()
        if not _is_online(d, now)
    ]

    return CallsSummary(
        total=len(rows), incoming=incoming, answered=answered, missed=missed,
        rejected=rejected, outgoing=outgoing,
        missed_rate=(missed / incoming) if incoming else 0.0,
        avg_wait_seconds=avg_wait,
        max_wait_seconds=max(waits) if waits else 0,
        by_device=by_device, by_hour=by_hour, offline_devices=offline,
    )
