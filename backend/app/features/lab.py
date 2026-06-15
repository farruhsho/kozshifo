"""Lab / diagnostics referrals — refer / list / enter result / status.

Read under ``lab.read``, mutate under ``lab.manage``. Entering a result moves
the referral to ``ready`` in one call (the common path for the lab tech).
Non-superusers are scoped to their own branch.
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
from app.core.sequences import next_lab_no
from app.models.branch import Branch
from app.models.lab import LabOrder
from app.models.patient import Patient
from app.schemas.lab import LabOrderCreate, LabOrderOut, LabResultUpdate, LabStatusUpdate

router = APIRouter(prefix="/lab", tags=["Lab"])

# referred -> in_progress -> ready | cancelled
_ALLOWED_FROM: dict[str, tuple[str, ...]] = {
    "in_progress": ("referred",),
    "ready": ("referred", "in_progress"),
    "cancelled": ("referred", "in_progress"),
}


def _get_or_404(db: Session, order_id: UUID) -> LabOrder:
    order = db.get(LabOrder, order_id)
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Lab referral not found")
    return order


@router.get(
    "",
    response_model=list[LabOrderOut],
    dependencies=[Depends(require_permission("lab.read"))],
)
def list_orders(
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
    branch_id: UUID | None = None,
    status_eq: str | None = Query(None, alias="status", description="Filter by status"),
) -> list[LabOrder]:
    stmt = select(LabOrder)
    if branch_id:
        stmt = stmt.where(LabOrder.branch_id == branch_id)
    elif not actor.is_superuser and actor.branch_id is not None:
        stmt = stmt.where(LabOrder.branch_id == actor.branch_id)
    if status_eq:
        stmt = stmt.where(LabOrder.status == status_eq)
    stmt = stmt.order_by(LabOrder.created_at.desc()).limit(200)
    return list(db.execute(stmt).scalars().all())


@router.post("", response_model=LabOrderOut, status_code=status.HTTP_201_CREATED)
def create_order(
    payload: LabOrderCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("lab.manage"))],
) -> LabOrder:
    if db.get(Patient, payload.patient_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown patient")
    if db.get(Branch, payload.branch_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown branch")
    order = LabOrder(
        order_no=next_lab_no(db),
        branch_id=payload.branch_id,
        patient_id=payload.patient_id,
        doctor_id=payload.doctor_id,
        test_name=payload.test_name,
        notes=payload.notes,
        created_by_id=actor.id,
    )
    db.add(order)
    db.flush()
    record_audit(db, action="create", entity_type="lab_order", entity_id=order.id,
                 actor_id=actor.id, branch_id=order.branch_id,
                 summary=f"Lab referral {order.order_no}: {order.test_name}")
    db.commit()
    db.refresh(order)
    return order


@router.post("/{order_id}/result", response_model=LabOrderOut)
def set_result(
    order_id: UUID,
    payload: LabResultUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("lab.manage"))],
) -> LabOrder:
    order = _get_or_404(db, order_id)
    if order.status == "cancelled":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Lab referral {order.order_no} is cancelled")
    order.result = payload.result
    order.status = "ready"
    record_audit(db, action="update", entity_type="lab_order", entity_id=order.id,
                 actor_id=actor.id, branch_id=order.branch_id,
                 summary=f"Lab referral {order.order_no} result entered")
    db.commit()
    db.refresh(order)
    return order


@router.post("/{order_id}/status", response_model=LabOrderOut)
def set_status(
    order_id: UUID,
    payload: LabStatusUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("lab.manage"))],
) -> LabOrder:
    order = _get_or_404(db, order_id)
    allowed = _ALLOWED_FROM.get(payload.status, ())
    if order.status not in allowed:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Cannot move lab referral {order.order_no} from {order.status} to {payload.status}",
        )
    order.status = payload.status
    record_audit(db, action="update", entity_type="lab_order", entity_id=order.id,
                 actor_id=actor.id, branch_id=order.branch_id,
                 summary=f"Lab referral {order.order_no} -> {payload.status}")
    db.commit()
    db.refresh(order)
    return order
