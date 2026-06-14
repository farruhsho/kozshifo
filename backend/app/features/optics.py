"""Optics salon — glasses/lenses orders (create / list / advance status).

Mirrors the appointments vertical: read under ``optics.read``, mutate under
``optics.manage``. Status is a guarded state machine so the UI can't push an
order backwards. Non-superusers are scoped to their own branch (like visits).
"""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.sequences import next_optics_no
from app.models.branch import Branch
from app.models.optics import OpticsOrder
from app.models.patient import Patient
from app.schemas.optics import OpticsOrderCreate, OpticsOrderOut, OpticsStatusUpdate

router = APIRouter(prefix="/optics", tags=["Optics"])

# ordered -> in_progress -> ready -> issued | cancelled
_ALLOWED_FROM: dict[str, tuple[str, ...]] = {
    "in_progress": ("ordered",),
    "ready": ("in_progress", "ordered"),
    "issued": ("ready",),
    "cancelled": ("ordered", "in_progress", "ready"),
}


def _get_or_404(db: Session, order_id: UUID) -> OpticsOrder:
    order = db.get(OpticsOrder, order_id)
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Optics order not found")
    return order


@router.get(
    "",
    response_model=list[OpticsOrderOut],
    dependencies=[Depends(require_permission("optics.read"))],
)
def list_orders(
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
    branch_id: UUID | None = None,
    status_eq: str | None = Query(None, alias="status", description="Filter by status"),
) -> list[OpticsOrder]:
    stmt = select(OpticsOrder)
    if branch_id:
        stmt = stmt.where(OpticsOrder.branch_id == branch_id)
    elif not actor.is_superuser and actor.branch_id is not None:
        stmt = stmt.where(OpticsOrder.branch_id == actor.branch_id)
    if status_eq:
        stmt = stmt.where(OpticsOrder.status == status_eq)
    stmt = stmt.order_by(OpticsOrder.created_at.desc()).limit(200)
    return list(db.execute(stmt).scalars().all())


@router.post("", response_model=OpticsOrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    payload: OpticsOrderCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("optics.manage"))],
) -> OpticsOrder:
    if db.get(Patient, payload.patient_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown patient")
    if db.get(Branch, payload.branch_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown branch")
    order = OpticsOrder(
        order_no=next_optics_no(db),
        branch_id=payload.branch_id,
        patient_id=payload.patient_id,
        doctor_id=payload.doctor_id,
        kind=payload.kind,
        rx=payload.rx,
        frame=payload.frame,
        price=payload.price,
        notes=payload.notes,
        created_by_id=actor.id,
    )
    db.add(order)
    db.flush()
    record_audit(db, action="create", entity_type="optics_order", entity_id=order.id,
                 actor_id=actor.id, branch_id=order.branch_id,
                 summary=f"Optics order {order.order_no} ({order.kind})")
    db.commit()
    db.refresh(order)
    return order


@router.post("/{order_id}/status", response_model=OpticsOrderOut)
def set_status(
    order_id: UUID,
    payload: OpticsStatusUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("optics.manage"))],
) -> OpticsOrder:
    order = _get_or_404(db, order_id)
    allowed = _ALLOWED_FROM.get(payload.status, ())
    if order.status not in allowed:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Cannot move optics order {order.order_no} from {order.status} to {payload.status}",
        )
    order.status = payload.status
    record_audit(db, action="update", entity_type="optics_order", entity_id=order.id,
                 actor_id=actor.id, branch_id=order.branch_id,
                 summary=f"Optics order {order.order_no} -> {payload.status}")
    db.commit()
    db.refresh(order)
    return order
