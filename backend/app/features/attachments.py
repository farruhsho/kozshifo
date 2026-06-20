"""Patient file attachments: upload / list / download / delete.

A general document store on the patient card (УЗИ-заключения, анализ на ВИЧ перед
операцией, прочие сканы). Reuses ``core.files`` for safe binary storage (random
name, 20 MB cap, extension whitelist incl. .pdf) — the same machinery that backs
device-result files. Each document is owned by a patient and may optionally be
linked to a visit and/or an operation.
"""
from __future__ import annotations

from pathlib import Path
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.files import (
    ALLOWED_EXTENSIONS,
    MAX_FILE_BYTES,
    media_type_for,
    resolve_stored,
    save_upload,
)
from app.models.attachment import ATTACHMENT_KINDS, Attachment
from app.models.operation import Operation
from app.models.patient import Patient
from app.models.visit import Visit
from app.schemas.attachment import AttachmentOut

router = APIRouter(tags=["Attachments"])


def _get_or_404_patient(db: Session, patient_id: UUID) -> Patient:
    patient = db.get(Patient, patient_id)
    if patient is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")
    return patient


@router.post(
    "/patients/{patient_id}/attachments",
    response_model=AttachmentOut,
    status_code=status.HTTP_201_CREATED,
)
def upload_attachment(
    patient_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("attachments.write"))],
    file: Annotated[UploadFile, File()],
    kind: Annotated[str, Form()] = "other",
    visit_id: Annotated[UUID | None, Form()] = None,
    operation_id: Annotated[UUID | None, Form()] = None,
    note: Annotated[str | None, Form()] = None,
) -> Attachment:
    """Store a document (PDF/image) on the patient's record.

    ``kind`` is one of uzi | hiv | lab | other. ``visit_id`` / ``operation_id``
    are optional context links and, when given, must belong to this patient.
    """
    patient = _get_or_404_patient(db, patient_id)

    if kind not in ATTACHMENT_KINDS:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            f"kind must be one of: {', '.join(ATTACHMENT_KINDS)}",
        )

    if visit_id is not None:
        visit = db.get(Visit, visit_id)
        if visit is None or visit.patient_id != patient.id:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                                "visit_id does not belong to this patient")
    if operation_id is not None:
        operation = db.get(Operation, operation_id)
        if operation is None or operation.patient_id != patient.id:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                                "operation_id does not belong to this patient")

    original_name = file.filename or ""
    # DoS guard: reject by declared size first, then read at most cap+1 bytes.
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

    attachment = Attachment(
        patient_id=patient.id,
        visit_id=visit_id,
        operation_id=operation_id,
        kind=kind,
        file_path=stored_name,
        original_name=file.filename,
        content_type=file.content_type,
        size=len(content),
        note=note,
        cabinet=actor.cabinet,
        uploaded_by_id=actor.id,
    )
    db.add(attachment)
    db.flush()
    record_audit(db, action="create", entity_type="attachment", entity_id=attachment.id,
                 actor_id=actor.id, branch_id=patient.branch_id,
                 summary=f"Uploaded {kind} '{original_name}' for patient {patient.mrn}")
    db.commit()
    db.refresh(attachment)
    return attachment


@router.get(
    "/patients/{patient_id}/attachments",
    response_model=list[AttachmentOut],
    dependencies=[Depends(require_permission("attachments.read"))],
)
def list_attachments(
    patient_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    kind: str | None = None,
    operation_id: UUID | None = Query(None),
) -> list[Attachment]:
    _get_or_404_patient(db, patient_id)
    stmt = select(Attachment).where(Attachment.patient_id == patient_id)
    if kind is not None:
        stmt = stmt.where(Attachment.kind == kind)
    if operation_id is not None:
        stmt = stmt.where(Attachment.operation_id == operation_id)
    rows = db.execute(stmt.order_by(Attachment.created_at.desc())).scalars().all()
    return list(rows)


@router.get(
    "/attachments/{attachment_id}/file",
    dependencies=[Depends(require_permission("attachments.read"))],
)
def download_attachment(
    attachment_id: UUID,
    db: Annotated[Session, Depends(get_db)],
) -> FileResponse:
    """Serve the stored binary of an attachment (404 hides all detail)."""
    not_found = HTTPException(status.HTTP_404_NOT_FOUND, "Attachment file not found")
    attachment = db.get(Attachment, attachment_id)
    if attachment is None or not attachment.file_path:
        raise not_found
    try:
        path = resolve_stored(attachment.file_path)
    except ValueError:
        raise not_found from None  # never leak why the stored name was rejected
    if not path.is_file():
        raise not_found
    # Only a whitelisted-extension original name may become the download filename;
    # otherwise fall back to the stored uuid name (mirrors device-result download).
    safe_name = attachment.file_path
    original = attachment.original_name
    if isinstance(original, str) and Path(original).suffix.lower() in ALLOWED_EXTENSIONS:
        safe_name = original
    return FileResponse(
        path,
        media_type=media_type_for(attachment.file_path),
        filename=safe_name,
    )


@router.delete("/attachments/{attachment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_attachment(
    attachment_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("attachments.write"))],
) -> None:
    attachment = db.get(Attachment, attachment_id)
    if attachment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Attachment not found")
    patient = db.get(Patient, attachment.patient_id)
    # Best-effort remove the underlying file; a missing/odd file never blocks the
    # row delete (the DB record is the source of truth).
    try:
        path = resolve_stored(attachment.file_path)
        if path.is_file():
            path.unlink()
    except (ValueError, OSError):
        pass
    record_audit(db, action="delete", entity_type="attachment", entity_id=attachment.id,
                 actor_id=actor.id, branch_id=patient.branch_id if patient else None,
                 summary=f"Deleted {attachment.kind} '{attachment.original_name}'")
    db.delete(attachment)
    db.commit()
