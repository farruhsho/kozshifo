"""Treatments: doctor's prescriptions on a visit.

Two kinds: a *procedure* (course item completed by staff) and a *medication*
dispensed from the warehouse — dispensing writes the product off via the same
FEFO stock engine used everywhere else.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.stock import InsufficientStockError, write_off_fefo
from app.models.inventory import Product
from app.models.operation import Treatment
from app.models.patient import Patient
from app.models.visit import Visit
from app.schemas.operation import TreatmentCreate, TreatmentOut

router = APIRouter(tags=["Treatments"])


def _get_or_404(db: Session, treatment_id: UUID) -> Treatment:
    treatment = db.get(Treatment, treatment_id)
    if treatment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Treatment not found")
    return treatment


@router.post("/visits/{visit_id}/treatments", response_model=TreatmentOut,
             status_code=status.HTTP_201_CREATED)
def prescribe_treatment(
    visit_id: UUID,
    payload: TreatmentCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("treatments.prescribe"))],
) -> Treatment:
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if payload.kind == "medication":
        if payload.product_id is None or payload.quantity is None:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                                "A medication prescription requires product_id and quantity")
    if payload.product_id is not None and db.get(Product, payload.product_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Product not found")

    treatment = Treatment(
        visit_id=visit.id,
        patient_id=visit.patient_id,
        doctor_id=payload.doctor_id or actor.id,
        kind=payload.kind,
        name=payload.name,
        product_id=payload.product_id,
        quantity=payload.quantity,
        instructions=payload.instructions,
    )
    db.add(treatment)
    db.flush()
    record_audit(db, action="prescribe", entity_type="treatment", entity_id=treatment.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Prescribed {payload.kind} «{payload.name}» on visit {visit.visit_no}")
    db.commit()
    db.refresh(treatment)
    return treatment


@router.get("/visits/{visit_id}/treatments", response_model=list[TreatmentOut],
            dependencies=[Depends(require_permission("treatments.read"))])
def list_visit_treatments(visit_id: UUID, db: Annotated[Session, Depends(get_db)]) -> list[Treatment]:
    if db.get(Visit, visit_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    return list(
        db.execute(
            select(Treatment).where(Treatment.visit_id == visit_id).order_by(Treatment.created_at.desc())
        ).scalars().all()
    )


@router.get("/patients/{patient_id}/treatments", response_model=list[TreatmentOut],
            dependencies=[Depends(require_permission("treatments.read"))])
def list_patient_treatments(patient_id: UUID, db: Annotated[Session, Depends(get_db)]) -> list[Treatment]:
    if db.get(Patient, patient_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")
    return list(
        db.execute(
            select(Treatment).where(Treatment.patient_id == patient_id).order_by(Treatment.created_at.desc())
        ).scalars().all()
    )


@router.post("/treatments/{treatment_id}/dispense", response_model=TreatmentOut)
def dispense_treatment(
    treatment_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("treatments.perform"))],
) -> Treatment:
    treatment = _get_or_404(db, treatment_id)
    if treatment.kind != "medication" or treatment.status != "prescribed":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Only a prescribed medication can be dispensed "
                            f"(kind: {treatment.kind}, status: {treatment.status})")
    if treatment.product_id is None or treatment.quantity is None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Treatment has no linked product to dispense")
    visit = db.get(Visit, treatment.visit_id)
    product = db.get(Product, treatment.product_id)

    # Single product: write_off_fefo checks availability before mutating, so a
    # 409 here leaves stock untouched.
    try:
        write_off_fefo(
            db,
            product_id=treatment.product_id,
            branch_id=visit.branch_id,
            quantity=treatment.quantity,
            reason=f"Выдача по назначению: {treatment.name}",
            ref_type="treatment",
            ref_id=treatment.id,
            actor_id=actor.id,
        )
    except InsufficientStockError as exc:
        db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Insufficient stock for {product.name} ({product.sku}): "
            f"requested {exc.requested}, available {exc.available}",
        ) from None

    treatment.status = "done"
    treatment.performed_at = datetime.now(timezone.utc)
    record_audit(db, action="dispense", entity_type="treatment", entity_id=treatment.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Dispensed {treatment.quantity} x {product.name} for «{treatment.name}»")
    db.commit()
    db.refresh(treatment)
    return treatment


@router.post("/treatments/{treatment_id}/complete", response_model=TreatmentOut)
def complete_treatment(
    treatment_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("treatments.perform"))],
) -> Treatment:
    treatment = _get_or_404(db, treatment_id)
    if treatment.kind != "procedure" or treatment.status != "prescribed":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Only a prescribed procedure can be completed "
                            f"(kind: {treatment.kind}, status: {treatment.status})")
    treatment.status = "done"
    treatment.performed_at = datetime.now(timezone.utc)
    record_audit(db, action="complete", entity_type="treatment", entity_id=treatment.id,
                 actor_id=actor.id,
                 summary=f"Completed procedure «{treatment.name}»")
    db.commit()
    db.refresh(treatment)
    return treatment


@router.post("/treatments/{treatment_id}/cancel", response_model=TreatmentOut)
def cancel_treatment(
    treatment_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("treatments.prescribe"))],
) -> Treatment:
    treatment = _get_or_404(db, treatment_id)
    if treatment.status != "prescribed":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a prescribed treatment can be cancelled (status: {treatment.status})")
    treatment.status = "cancelled"
    record_audit(db, action="cancel", entity_type="treatment", entity_id=treatment.id,
                 actor_id=actor.id,
                 summary=f"Cancelled treatment «{treatment.name}»")
    db.commit()
    db.refresh(treatment)
    return treatment
