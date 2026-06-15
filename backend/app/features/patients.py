"""Patient registration & management (the central record)."""
from __future__ import annotations

import re
from datetime import date as date_cls
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.sequences import next_mrn, next_patient_no
from app.models.exam import EyeExam
from app.models.operation import Operation
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.visit import Visit
from app.schemas.common import Page
from app.schemas.patient import (
    DuplicateCandidate,
    PatientCreate,
    PatientOut,
    PatientSummary,
    PatientUpdate,
)

router = APIRouter(prefix="/patients", tags=["Patients"])

_OPEN_VISIT = ("open", "in_progress")


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
    patient = Patient(mrn=mrn, patient_no=next_patient_no(db), **data)
    db.add(patient)
    db.flush()
    record_audit(db, action="create", entity_type="patient", entity_id=patient.id, actor_id=actor.id,
                 branch_id=patient.branch_id,
                 summary=f"Registered patient {patient.full_name} (№ {patient.patient_no})")
    db.commit()
    db.refresh(patient)
    return patient


@router.get(
    "/duplicates",
    response_model=list[DuplicateCandidate],
    dependencies=[Depends(require_permission("patients.read"))],
)
def find_duplicates(
    db: Annotated[Session, Depends(get_db)],
    last_name: str | None = Query(None),
    first_name: str | None = Query(None),
    phone: str | None = Query(None),
    birth_date: date_cls | None = Query(None),
) -> list[DuplicateCandidate]:
    """Likely existing matches to show BEFORE creating a new patient.

    Matches (strongest first): same phone (digits) · same ФИО + birth date ·
    same ФИО. Empty query → empty list (nothing to warn about). Read-only.
    """
    ln = (last_name or "").strip()
    fn = (first_name or "").strip()
    digits = re.sub(r"\D", "", phone or "")
    if not ln and not fn and not digits:
        return []

    name_match = None
    if ln and fn:
        name_match = Patient.last_name.ilike(f"%{ln}%") & Patient.first_name.ilike(f"%{fn}%")
    elif ln:
        name_match = Patient.last_name.ilike(f"%{ln}%")
    elif fn:
        name_match = Patient.first_name.ilike(f"%{fn}%")

    clauses = []
    if digits:
        clauses.append(Patient.phone.ilike(f"%{digits}%"))
    if name_match is not None:
        clauses.append(name_match)
    rows = db.execute(
        select(Patient).where(or_(*clauses)).order_by(Patient.created_at.desc()).limit(15)
    ).scalars().all()

    out: list[DuplicateCandidate] = []
    for p in rows:
        p_digits = re.sub(r"\D", "", p.phone or "")
        if digits and p_digits and digits in p_digits:
            reason = "телефон"
        elif birth_date and p.birth_date == birth_date and ln and fn:
            reason = "ФИО + дата рождения"
        else:
            reason = "ФИО"
        out.append(DuplicateCandidate(
            id=p.id, patient_no=p.patient_no, mrn=p.mrn, full_name=p.full_name,
            birth_date=p.birth_date, phone=p.phone, reason=reason,
        ))
    # Phone matches first (strongest), then name+dob, then name.
    _rank = {"телефон": 0, "ФИО + дата рождения": 1, "ФИО": 2}
    out.sort(key=lambda c: _rank[c.reason])
    return out


@router.get("/{patient_id}", response_model=PatientOut, dependencies=[Depends(require_permission("patients.read"))])
def get_patient(patient_id: UUID, db: Annotated[Session, Depends(get_db)]) -> Patient:
    patient = db.get(Patient, patient_id)
    if patient is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")
    return patient


@router.get(
    "/{patient_id}/summary",
    response_model=PatientSummary,
    dependencies=[Depends(require_permission("patients.read"))],
)
def patient_summary(patient_id: UUID, db: Annotated[Session, Depends(get_db)]) -> PatientSummary:
    """At-a-glance history for the reception panel — counts, last events, debt.

    Reception-appropriate (no clinical detail beyond the last diagnosis label,
    which reception already sees via exams.read on the doctor card)."""
    if db.get(Patient, patient_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")

    visit_count = db.execute(
        select(func.count()).select_from(Visit).where(Visit.patient_id == patient_id)
    ).scalar_one()

    last_visit = db.execute(
        select(Visit).where(Visit.patient_id == patient_id).order_by(Visit.opened_at.desc()).limit(1)
    ).scalar_one_or_none()

    # Debt = sum of balance over still-open visits (balance is a Python property).
    open_visits = db.execute(
        select(Visit).where(Visit.patient_id == patient_id, Visit.status.in_(_OPEN_VISIT))
    ).scalars().all()
    total_debt = sum((v.balance for v in open_visits), Decimal("0.00"))

    last_dx = db.execute(
        select(EyeExam.diagnosis)
        .where(EyeExam.patient_id == patient_id, EyeExam.diagnosis.is_not(None))
        .order_by(EyeExam.created_at.desc()).limit(1)
    ).scalar_one_or_none()

    last_op = db.execute(
        select(Operation).where(Operation.patient_id == patient_id)
        .order_by(Operation.created_at.desc()).limit(1)
    ).scalar_one_or_none()

    last_pay = db.execute(
        select(Payment).where(Payment.patient_id == patient_id, Payment.status == "completed")
        .order_by(Payment.created_at.desc()).limit(1)
    ).scalar_one_or_none()

    last_disc = db.execute(
        select(Visit.discount_reason)
        .where(Visit.patient_id == patient_id, Visit.discount_reason.is_not(None))
        .order_by(Visit.created_at.desc()).limit(1)
    ).scalar_one_or_none()

    return PatientSummary(
        patient_id=patient_id,
        visit_count=visit_count,
        last_visit_at=last_visit.opened_at.date() if last_visit else None,
        last_diagnosis=last_dx,
        last_operation=last_op.type_name if last_op else None,
        last_payment_amount=str(last_pay.amount) if last_pay else None,
        last_payment_at=last_pay.created_at.date() if last_pay else None,
        total_debt=str(total_debt.quantize(Decimal("0.01"))),
        last_discount_reason=last_disc,
        is_repeat=visit_count > 1,
    )


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
