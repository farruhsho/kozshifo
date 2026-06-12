"""Operations: surgery type catalog, prescribe (bills the visit), perform (FEFO write-off).

Prescribing an operation appends the linked service onto the visit through the
exact same billing helpers visits.py uses, so totals/receipts behave identically.
Performing it consumes the template consumables via the FEFO stock engine.
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
from app.core.flow import advance_flow, recompute_plan
from app.core.notify import check_low_stock
from app.core.stock import InsufficientStockError, on_hand, write_off_fefo
from app.features.visits import _make_item, _recompute_total
from app.models.catalog import Service
from app.models.inventory import Product
from app.models.operation import Operation, OperationType, OperationTypeConsumable
from app.models.visit import Visit, VisitItem
from app.schemas.operation import (
    AvailabilityItem,
    AvailabilityOut,
    OperationCreate,
    OperationOut,
    OperationTypeCreate,
    OperationTypeOut,
)

router = APIRouter(tags=["Operations"])


def _get_or_404(db: Session, operation_id: UUID) -> Operation:
    operation = db.get(Operation, operation_id)
    if operation is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Operation not found")
    return operation


# ── Operation types (catalog) ─────────────────────────────────────────────────
@router.get("/operation-types", response_model=list[OperationTypeOut],
            dependencies=[Depends(require_permission("operations.read"))])
def list_operation_types(db: Annotated[Session, Depends(get_db)]) -> list[OperationType]:
    return list(
        db.execute(
            select(OperationType).order_by(OperationType.is_active.desc(), OperationType.code)
        ).scalars().all()
    )


@router.post("/operation-types", response_model=OperationTypeOut, status_code=status.HTTP_201_CREATED)
def create_operation_type(
    payload: OperationTypeCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.manage"))],
) -> OperationType:
    if db.execute(select(OperationType).where(OperationType.code == payload.code)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, f"Operation type {payload.code} already exists")
    service = db.get(Service, payload.service_id)
    if service is None or not service.is_active:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown or inactive service")
    for line in payload.consumables:
        if db.get(Product, line.product_id) is None:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, f"Product {line.product_id} not found")

    op_type = OperationType(
        code=payload.code,
        name=payload.name,
        service_id=payload.service_id,
        duration_minutes=payload.duration_minutes,
        description=payload.description,
        consumables=[
            OperationTypeConsumable(product_id=line.product_id, quantity=line.quantity)
            for line in payload.consumables
        ],
    )
    db.add(op_type)
    db.flush()
    record_audit(db, action="create", entity_type="operation_type", entity_id=op_type.id, actor_id=actor.id,
                 summary=f"Created operation type {op_type.code} — {op_type.name}")
    db.commit()
    db.refresh(op_type)
    return op_type


@router.get("/operation-types/{op_type_id}/availability", response_model=AvailabilityOut,
            dependencies=[Depends(require_permission("operations.read"))])
def operation_type_availability(
    op_type_id: UUID,
    branch_id: UUID,
    db: Annotated[Session, Depends(get_db)],
) -> AvailabilityOut:
    """Advisory pre-check: can this branch cover the type's consumable template?

    Lets the doctor see shortages at prescribe time. Counts only usable stock
    (`on_hand` already excludes expired batches). Advisory only — the hard,
    atomic guarantee stays in perform_operation's pre-check + FEFO write-off.
    """
    op_type = db.get(OperationType, op_type_id)
    if op_type is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Operation type not found")

    items: list[AvailabilityItem] = []
    for line in op_type.consumables:
        available = on_hand(db, line.product_id, branch_id)
        items.append(
            AvailabilityItem(
                product_id=line.product_id,
                product_name=line.product_name,
                required=line.quantity,
                available=available,
                ok=available >= line.quantity,
            )
        )
    # all([]) is True: an empty template is trivially coverable.
    return AvailabilityOut(ok=all(item.ok for item in items), items=items)


# ── Operations on a visit ─────────────────────────────────────────────────────
@router.post("/visits/{visit_id}/operations", response_model=OperationOut,
             status_code=status.HTTP_201_CREATED)
def prescribe_operation(
    visit_id: UUID,
    payload: OperationCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.prescribe"))],
) -> Operation:
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot prescribe on a {visit.status} visit")
    op_type = db.get(OperationType, payload.operation_type_id)
    if op_type is None or not op_type.is_active:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown or inactive operation type")

    # Bill the linked service onto the visit — same mechanism as visits.add_visit_item.
    item = _make_item(db, op_type.service_id, 1)
    visit.items.append(item)
    _recompute_total(visit)

    operation = Operation(
        visit_id=visit.id,
        patient_id=visit.patient_id,
        doctor_id=payload.doctor_id or actor.id,
        operation_type_id=op_type.id,
        eye=payload.eye,
        priority=payload.priority,
        scheduled_at=payload.scheduled_at,
        notes=payload.notes,
    )
    db.add(operation)
    db.flush()  # assign ids so the billing trace can be recorded
    operation.visit_item_id = item.id
    # Workflow engine: a dated prescription is already "scheduled".
    advance_flow(db, visit, "surgery_scheduled" if payload.scheduled_at else "surgery_prescribed")
    record_audit(db, action="prescribe", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Prescribed operation {op_type.name} ({payload.eye}, {payload.priority}) "
                         f"on visit {visit.visit_no}, billed {op_type.price}")
    db.commit()
    db.refresh(operation)
    return operation


@router.get("/visits/{visit_id}/operations", response_model=list[OperationOut],
            dependencies=[Depends(require_permission("operations.read"))])
def list_visit_operations(visit_id: UUID, db: Annotated[Session, Depends(get_db)]) -> list[Operation]:
    if db.get(Visit, visit_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    return list(
        db.execute(
            select(Operation).where(Operation.visit_id == visit_id).order_by(Operation.created_at.desc())
        ).scalars().all()
    )


@router.post("/operations/{operation_id}/perform", response_model=OperationOut)
def perform_operation(
    operation_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.perform"))],
) -> Operation:
    operation = _get_or_404(db, operation_id)
    if operation.status != "planned":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a planned operation can be performed (status: {operation.status})")
    visit = db.get(Visit, operation.visit_id)
    # A cancelled/closed visit must not consume stock: reception cancelling an
    # unpaid visit would otherwise leave a performable operation with zero revenue.
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Cannot perform an operation on a {visit.status} visit")
    op_type = operation.operation_type

    # Pre-check availability of EVERY template consumable before writing anything
    # off. write_off_fefo checks its own product, but a multi-line loop could
    # otherwise consume the first products and fail midway — pre-checking keeps
    # the whole perform atomic: on shortage nothing has been mutated.
    for line in op_type.consumables:
        available = on_hand(db, line.product_id, visit.branch_id)
        if available < line.quantity:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                f"Insufficient stock for {line.product.name} ({line.product.sku}): "
                f"requested {line.quantity}, available {available}",
            )

    try:
        for line in op_type.consumables:
            write_off_fefo(
                db,
                product_id=line.product_id,
                branch_id=visit.branch_id,
                quantity=line.quantity,
                reason=f"Операция {op_type.name}",
                ref_type="operation",
                ref_id=operation.id,
                actor_id=actor.id,
            )
    except InsufficientStockError as exc:  # safety net (e.g. concurrent change)
        db.rollback()
        product = db.get(Product, exc.product_id)
        name = product.name if product else str(exc.product_id)
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Insufficient stock for {name}: requested {exc.requested}, available {exc.available}",
        ) from None

    operation.status = "done"
    operation.performed_at = datetime.now(timezone.utc)
    advance_flow(db, visit, "surgery_performed")  # workflow engine (same transaction)
    record_audit(db, action="perform", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Performed operation {op_type.name} ({operation.eye}); "
                         f"auto write-off: {len(op_type.consumables)} positions")
    db.commit()
    check_low_stock(db, [l.product_id for l in op_type.consumables], visit.branch_id)  # post-commit
    db.refresh(operation)
    return operation


@router.post("/operations/{operation_id}/cancel", response_model=OperationOut)
def cancel_operation(
    operation_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.prescribe"))],
) -> Operation:
    operation = _get_or_404(db, operation_id)
    if operation.status != "planned":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a planned operation can be cancelled (status: {operation.status})")
    visit = db.get(Visit, operation.visit_id)

    # De-bill: prescribing added the linked service to the visit, so cancelling
    # must take it off again — otherwise the patient stays charged for a surgery
    # that will not happen. A paid item cannot be silently removed (money was
    # taken): require a refund first.
    debilled = ""
    if operation.visit_item_id is not None:
        item = db.get(VisitItem, operation.visit_item_id)
        if item is not None:
            if item.status != "ordered":
                raise HTTPException(
                    status.HTTP_409_CONFLICT,
                    "The billed item is already paid — refund the payment before cancelling",
                )
            visit.items.remove(item)  # delete-orphan cascade removes the row
            _recompute_total(visit)
            debilled = f"; removed billed item {item.service_name} ({item.total})"

    operation.status = "cancelled"
    record_audit(db, action="cancel", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Cancelled operation {operation.type_name}{debilled}")
    db.flush()
    # The lifecycle must stop advertising a surgery that no longer exists.
    recompute_plan(db, visit)
    db.commit()
    db.refresh(operation)
    return operation
