"""Patient registration & management (the central record)."""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.sequences import next_mrn
from app.models.patient import Patient
from app.models.visit import Visit
from app.schemas.common import Page
from app.schemas.patient import PatientCreate, PatientOut, PatientUpdate

router = APIRouter(prefix="/patients", tags=["Patients"])


@router.get("", response_model=Page[PatientOut], dependencies=[Depends(require_permission("patients.read"))])
def list_patients(
    db: Annotated[Session, Depends(get_db)],
    q: str | None = Query(None, description="Search by name, MRN or phone"),
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[PatientOut]:
    stmt = select(Patient)
    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(
            or_(
                Patient.first_name.ilike(like),
                Patient.last_name.ilike(like),
                Patient.mrn.ilike(like),
                Patient.phone.ilike(like),
            )
        )
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(stmt.order_by(Patient.created_at.desc()).offset(offset).limit(limit)).scalars().all()
    return Page(items=[PatientOut.model_validate(p) for p in rows], total=total, offset=offset, limit=limit)


@router.post("", response_model=PatientOut, status_code=status.HTTP_201_CREATED)
def create_patient(
    payload: PatientCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("patients.create"))],
) -> Patient:
    data = payload.model_dump()
    mrn = data.pop("mrn") or next_mrn(db)
    if db.execute(select(Patient).where(Patient.mrn == mrn)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, f"MRN {mrn} already exists")
    patient = Patient(mrn=mrn, **data)
    db.add(patient)
    db.flush()
    record_audit(db, action="create", entity_type="patient", entity_id=patient.id, actor_id=actor.id,
                 branch_id=patient.branch_id, summary=f"Registered patient {patient.full_name} ({mrn})")
    db.commit()
    db.refresh(patient)
    return patient


@router.get("/{patient_id}", response_model=PatientOut, dependencies=[Depends(require_permission("patients.read"))])
def get_patient(patient_id: UUID, db: Annotated[Session, Depends(get_db)]) -> Patient:
    patient = db.get(Patient, patient_id)
    if patient is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")
    return patient


@router.patch("/{patient_id}", response_model=PatientOut)
def update_patient(
    patient_id: UUID,
    payload: PatientUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("patients.update"))],
) -> Patient:
    patient = db.get(Patient, patient_id)
    if patient is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(patient, field, value)
    record_audit(db, action="update", entity_type="patient", entity_id=patient.id, actor_id=actor.id,
                 summary=f"Updated patient {patient.full_name}")
    db.commit()
    db.refresh(patient)
    return patient


@router.delete("/{patient_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_patient(
    patient_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("patients.delete"))],
) -> None:
    patient = db.get(Patient, patient_id)
    if patient is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")
    if db.execute(select(Visit.id).where(Visit.patient_id == patient_id).limit(1)).first():
        raise HTTPException(status.HTTP_409_CONFLICT, "Patient has visits and cannot be deleted")
    record_audit(db, action="delete", entity_type="patient", entity_id=patient.id, actor_id=actor.id,
                 summary=f"Deleted patient {patient.full_name}")
    db.delete(patient)
    db.commit()
