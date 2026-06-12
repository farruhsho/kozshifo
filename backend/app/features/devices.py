"""Medical devices: registry, measurement results, and EMR hand-off.

Results enter through the adapter seam (core/devices/adapters.py). The
apply-refraction endpoint closes the loop devices → EMR: it copies an
RMK-700 refraction result into the visit's Form 025-8 exam.
"""
from __future__ import annotations

from decimal import Decimal
from pathlib import Path
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.devices.adapters import (
    AdapterError,
    FileImportAdapter,
    adapter_for_source,
    validate_refraction_payload,
)
from app.core.files import ALLOWED_EXTENSIONS, MAX_FILE_BYTES, media_type_for, resolve_stored, save_upload
from app.features.exams import get_or_404_visit
from app.models.device import Device, DeviceResult
from app.models.exam import EyeExam
from app.models.patient import Patient
from app.schemas.common import Page
from app.schemas.device import (
    DeviceCreate,
    DeviceOut,
    DeviceResultCreate,
    DeviceResultOut,
    DeviceUpdate,
)
from app.schemas.exam import EyeExamOut

router = APIRouter(tags=["Devices"])


def _get_or_404_device(db: Session, device_id: UUID) -> Device:
    device = db.get(Device, device_id)
    if device is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Device not found")
    return device


@router.get("/devices", response_model=Page[DeviceOut],
            dependencies=[Depends(require_permission("devices.read"))])
def list_devices(
    db: Annotated[Session, Depends(get_db)],
    device_type: str | None = None,
    status_filter: str | None = Query(None, alias="status"),
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[DeviceOut]:
    stmt = select(Device)
    if device_type:
        stmt = stmt.where(Device.device_type == device_type)
    if status_filter:
        stmt = stmt.where(Device.status == status_filter)
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(stmt.order_by(Device.created_at.asc()).offset(offset).limit(limit)).scalars().all()
    return Page(items=[DeviceOut.model_validate(d) for d in rows], total=total, offset=offset, limit=limit)


@router.post("/devices", response_model=DeviceOut, status_code=status.HTTP_201_CREATED)
def create_device(
    payload: DeviceCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("devices.manage"))],
) -> Device:
    if db.execute(select(Device).where(Device.serial_no == payload.serial_no)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, f"Device with serial {payload.serial_no} already exists")
    device = Device(**payload.model_dump())
    db.add(device)
    db.flush()
    record_audit(db, action="create", entity_type="device", entity_id=device.id, actor_id=actor.id,
                 branch_id=device.branch_id, summary=f"Registered device {device.name} (S/N {device.serial_no})")
    db.commit()
    db.refresh(device)
    return device


@router.patch("/devices/{device_id}", response_model=DeviceOut)
def update_device(
    device_id: UUID,
    payload: DeviceUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("devices.manage"))],
) -> Device:
    device = _get_or_404_device(db, device_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(device, field, value)
    record_audit(db, action="update", entity_type="device", entity_id=device.id, actor_id=actor.id,
                 branch_id=device.branch_id, summary=f"Updated device {device.name} (S/N {device.serial_no})")
    db.commit()
    db.refresh(device)
    return device


@router.post("/devices/{device_id}/results", response_model=DeviceResultOut,
             status_code=status.HTTP_201_CREATED)
def add_device_result(
    device_id: UUID,
    payload: DeviceResultCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("device_results.create"))],
) -> DeviceResult:
    device = _get_or_404_device(db, device_id)

    patient_id = payload.patient_id
    visit = None
    if payload.visit_id is not None:
        visit = get_or_404_visit(db, payload.visit_id)
        patient_id = patient_id or visit.patient_id
    if patient_id is not None and db.get(Patient, patient_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown patient")

    adapter = adapter_for_source(payload.source)
    try:
        draft = adapter.parse(result_type=payload.result_type,
                              payload=payload.payload, file_path=payload.file_path)
    except AdapterError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(exc)) from None

    result = DeviceResult(
        device_id=device.id,
        patient_id=patient_id,
        visit_id=payload.visit_id,
        result_type=draft["result_type"],
        payload=draft["payload"],
        file_path=draft["file_path"],
        source=payload.source,
    )
    if payload.measured_at is not None:
        result.measured_at = payload.measured_at
    db.add(result)
    db.flush()
    record_audit(db, action="create", entity_type="device_result", entity_id=result.id, actor_id=actor.id,
                 branch_id=visit.branch_id if visit else None,
                 summary=f"{draft['result_type']} result from {device.name} (S/N {device.serial_no})")
    db.commit()
    db.refresh(result)
    return result


# Result types a binary upload may carry — refraction stays numeric-payload only.
_UPLOAD_RESULT_TYPES = {"bscan_image", "biometry", "file"}


@router.post("/devices/{device_id}/results/file", response_model=DeviceResultOut,
             status_code=status.HTTP_201_CREATED)
def upload_device_result_file(
    device_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("device_results.create"))],
    file: Annotated[UploadFile, File()],
    visit_id: Annotated[UUID | None, Form()] = None,
    patient_id: Annotated[UUID | None, Form()] = None,
    result_type: Annotated[str | None, Form()] = None,
) -> DeviceResult:
    """Upload a device-result binary (B-scan image, biometry printout, PDF).

    The file is stored under a generated name in ``settings.upload_dir``; the
    original filename survives only as payload metadata. When ``result_type``
    is omitted it is inferred from the extension (image → ``bscan_image``).
    """
    device = _get_or_404_device(db, device_id)

    visit = None
    if visit_id is not None:
        visit = get_or_404_visit(db, visit_id)
        patient_id = patient_id or visit.patient_id
    if patient_id is not None and db.get(Patient, patient_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown patient")

    if result_type is not None and result_type not in _UPLOAD_RESULT_TYPES:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            f"result_type must be one of: {', '.join(sorted(_UPLOAD_RESULT_TYPES))}",
        )

    original_name = file.filename or ""
    # DoS guard: reject by declared size first, then read at most cap+1 bytes —
    # a multi-GB upload must never be materialized in RAM before the check.
    if file.size is not None and file.size > MAX_FILE_BYTES:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            f"File too large (max {MAX_FILE_BYTES // (1024 * 1024)} MB)")
    content = file.file.read(MAX_FILE_BYTES + 1)
    if len(content) > MAX_FILE_BYTES:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            f"File too large (max {MAX_FILE_BYTES // (1024 * 1024)} MB)")
    try:
        stored_name = save_upload(content, original_name)
    except ValueError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(exc)) from None

    if result_type is None:
        is_image = Path(stored_name).suffix.lower() in FileImportAdapter._IMAGE_EXT
        result_type = "bscan_image" if is_image else "file"

    result = DeviceResult(
        device_id=device.id,
        patient_id=patient_id,
        visit_id=visit_id,
        result_type=result_type,
        payload={
            "original_name": file.filename,
            "size": len(content),
            "content_type": file.content_type,
        },
        file_path=stored_name,
        source="import",
    )
    db.add(result)
    db.flush()
    record_audit(db, action="create", entity_type="device_result", entity_id=result.id, actor_id=actor.id,
                 branch_id=visit.branch_id if visit else None,
                 summary=f"Uploaded {result_type} file '{original_name}' "
                         f"from {device.name} (S/N {device.serial_no})")
    db.commit()
    db.refresh(result)
    return result


@router.get("/device-results/{result_id}/file",
            dependencies=[Depends(require_permission("device_results.read"))])
def download_device_result_file(
    result_id: UUID,
    db: Annotated[Session, Depends(get_db)],
) -> FileResponse:
    """Serve the stored binary of a device result (404 hides all detail)."""
    not_found = HTTPException(status.HTTP_404_NOT_FOUND, "Device result file not found")
    result = db.get(DeviceResult, result_id)
    if result is None or not result.file_path:
        raise not_found
    try:
        path = resolve_stored(result.file_path)
    except ValueError:
        raise not_found from None  # never leak why the stored name was rejected
    if not path.is_file():
        raise not_found
    # The payload is attacker-influencable JSON (the plain results endpoint
    # accepts arbitrary dicts): only a str with a whitelisted extension may
    # become the download filename — anything else falls back to the stored
    # uuid name (non-str would 500 inside FileResponse; .html would let a
    # whitelisted png masquerade as a web page once saved locally).
    original = result.payload.get("original_name") if isinstance(result.payload, dict) else None
    safe_name = result.file_path
    if isinstance(original, str) and Path(original).suffix.lower() in ALLOWED_EXTENSIONS:
        safe_name = original
    return FileResponse(
        path,
        media_type=media_type_for(result.file_path),
        filename=safe_name,
    )


@router.get("/devices/{device_id}/results", response_model=list[DeviceResultOut],
            dependencies=[Depends(require_permission("device_results.read"))])
def device_recent_results(
    device_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    limit: int = Query(20, ge=1, le=200),
) -> list[DeviceResult]:
    _get_or_404_device(db, device_id)
    rows = db.execute(
        select(DeviceResult).where(DeviceResult.device_id == device_id)
        .order_by(DeviceResult.measured_at.desc()).limit(limit)
    ).scalars().all()
    return list(rows)


@router.get("/visits/{visit_id}/device-results", response_model=list[DeviceResultOut],
            dependencies=[Depends(require_permission("device_results.read"))])
def visit_device_results(visit_id: UUID, db: Annotated[Session, Depends(get_db)]) -> list[DeviceResult]:
    get_or_404_visit(db, visit_id)
    rows = db.execute(
        select(DeviceResult).where(DeviceResult.visit_id == visit_id)
        .order_by(DeviceResult.measured_at.desc())
    ).scalars().all()
    return list(rows)


@router.post("/visits/{visit_id}/exam/apply-refraction", response_model=EyeExamOut)
def apply_refraction(
    visit_id: UUID,
    result_id: Annotated[UUID, Query()],
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.write"))],
) -> EyeExam:
    """Copy an RMK-700 refraction DeviceResult into the visit's exam (OD/OS sph/cyl/axis)."""
    visit = get_or_404_visit(db, visit_id)
    result = db.get(DeviceResult, result_id)
    if result is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Device result not found")
    if result.result_type != "refraction":
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            f"Result {result_id} is '{result.result_type}', not a refraction")
    if result.visit_id is not None and result.visit_id != visit_id:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "Result belongs to a different visit")
    try:
        payload = validate_refraction_payload(result.payload)
    except AdapterError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(exc)) from None

    exam = db.execute(select(EyeExam).where(EyeExam.visit_id == visit_id)).scalar_one_or_none()
    if exam is None:
        exam = EyeExam(visit_id=visit.id, patient_id=visit.patient_id, doctor_id=actor.id)
        db.add(exam)

    for eye in ("od", "os"):
        eye_data = payload.get(eye)
        if not eye_data:
            continue
        if eye_data.get("sph") is not None:
            setattr(exam, f"{eye}_sph", Decimal(str(eye_data["sph"])))
        if eye_data.get("cyl") is not None:
            setattr(exam, f"{eye}_cyl", Decimal(str(eye_data["cyl"])))
        if eye_data.get("axis") is not None:
            setattr(exam, f"{eye}_axis", int(eye_data["axis"]))

    # Attach a free-floating result to this visit so it shows in the visit's history.
    if result.visit_id is None:
        result.visit_id = visit.id
        result.patient_id = result.patient_id or visit.patient_id

    db.flush()
    record_audit(db, action="update", entity_type="eye_exam", entity_id=exam.id, actor_id=actor.id,
                 branch_id=visit.branch_id,
                 summary=f"Applied refraction result {result_id} to exam of visit {visit.visit_no}")
    db.commit()
    db.refresh(exam)
    return exam
