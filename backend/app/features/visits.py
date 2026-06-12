"""Visits (encounters): open a visit, add billed services, close it."""
from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.sequences import next_visit_no
from app.models.branch import Branch
from app.models.catalog import Service
from app.models.patient import Patient
from app.models.visit import Visit, VisitItem
from app.schemas.common import Page
from app.schemas.visit import VisitCreate, VisitItemAdd, VisitOut

router = APIRouter(prefix="/visits", tags=["Visits"])


def _recompute_total(visit: Visit) -> None:
    visit.total_amount = sum((Decimal(i.total) for i in visit.items), Decimal("0.00"))


def _make_item(db: Session, service_id: UUID, quantity: int) -> VisitItem:
    service = db.get(Service, service_id)
    if service is None or not service.is_active:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, f"Unknown or inactive service {service_id}")
    unit = Decimal(service.price)
    return VisitItem(
        service_id=service.id,
        service_name=service.name,
        unit_price=unit,
        quantity=quantity,
        total=unit * quantity,
    )


@router.get("", response_model=Page[VisitOut], dependencies=[Depends(require_permission("visits.read"))])
def list_visits(
    db: Annotated[Session, Depends(get_db)],
    patient_id: UUID | None = None,
    branch_id: UUID | None = None,
    status_filter: str | None = Query(None, alias="status"),
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[VisitOut]:
    stmt = select(Visit)
    if patient_id:
        stmt = stmt.where(Visit.patient_id == patient_id)
    if branch_id:
        stmt = stmt.where(Visit.branch_id == branch_id)
    if status_filter:
        stmt = stmt.where(Visit.status == status_filter)
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(stmt.order_by(Visit.opened_at.desc()).offset(offset).limit(limit)).scalars().all()
    return Page(items=[VisitOut.model_validate(v) for v in rows], total=total, offset=offset, limit=limit)


@router.post("", response_model=VisitOut, status_code=status.HTTP_201_CREATED)
def create_visit(
    payload: VisitCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("visits.create"))],
) -> Visit:
    if db.get(Patient, payload.patient_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown patient")
    if db.get(Branch, payload.branch_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown branch")

    visit = Visit(
        visit_no=next_visit_no(db),
        patient_id=payload.patient_id,
        branch_id=payload.branch_id,
        doctor_id=payload.doctor_id,
        visit_type=payload.visit_type,
        notes=payload.notes,
    )
    visit.items = [_make_item(db, it.service_id, it.quantity) for it in payload.items]
    _recompute_total(visit)
    db.add(visit)
    db.flush()
    record_audit(db, action="create", entity_type="visit", entity_id=visit.id, actor_id=actor.id,
                 branch_id=visit.branch_id, summary=f"Opened visit {visit.visit_no}")
    db.commit()
    db.refresh(visit)
    return visit


@router.get("/{visit_id}", response_model=VisitOut, dependencies=[Depends(require_permission("visits.read"))])
def get_visit(visit_id: UUID, db: Annotated[Session, Depends(get_db)]) -> Visit:
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    return visit


@router.post("/{visit_id}/items", response_model=VisitOut)
def add_visit_item(
    visit_id: UUID,
    payload: VisitItemAdd,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("visits.update"))],
) -> Visit:
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot modify a {visit.status} visit")
    visit.items.append(_make_item(db, payload.service_id, payload.quantity))
    _recompute_total(visit)
    record_audit(db, action="update", entity_type="visit", entity_id=visit.id, actor_id=actor.id,
                 summary=f"Added service to visit {visit.visit_no}")
    db.commit()
    db.refresh(visit)
    return visit


@router.post("/{visit_id}/cancel", response_model=VisitOut)
def cancel_visit(
    visit_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("visits.update"))],
) -> Visit:
    """Cancel an *unpaid* open visit (reception abort path: patient declined,
    wrong services billed). Paid visits must be refunded first."""
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot cancel a {visit.status} visit")
    if Decimal(visit.paid_amount) > Decimal("0.00"):
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Visit has payments — refund them before cancelling")
    visit.status = "cancelled"
    visit.closed_at = datetime.now(timezone.utc)
    record_audit(db, action="cancel", entity_type="visit", entity_id=visit.id, actor_id=actor.id,
                 branch_id=visit.branch_id, summary=f"Cancelled visit {visit.visit_no}")
    db.commit()
    db.refresh(visit)
    return visit


@router.post("/{visit_id}/close", response_model=VisitOut)
def close_visit(
    visit_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("visits.close"))],
) -> Visit:
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    visit.status = "completed"
    visit.closed_at = datetime.now(timezone.utc)
    record_audit(db, action="close", entity_type="visit", entity_id=visit.id, actor_id=actor.id,
                 summary=f"Closed visit {visit.visit_no} (balance {visit.balance})")
    db.commit()
    db.refresh(visit)
    return visit
