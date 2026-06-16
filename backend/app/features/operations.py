"""Operations: surgery type catalog, prescribe (bills the visit), perform (FEFO write-off).

Prescribing an operation appends the linked service onto the visit through the
exact same billing helpers visits.py uses, so totals/receipts behave identically.
Performing it consumes the template consumables via the FEFO stock engine.
"""
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
from app.core.deps import CurrentUser, require_any_permission, require_permission
from app.core.flow import advance_flow, recompute_plan
from app.core.notify import check_low_stock
from app.core.stock import InsufficientStockError, on_hand, write_off_fefo
from app.features.visits import _make_item, _recompute_total
from app.models.catalog import Service
from app.models.inventory import Product
from app.models.operation import Operation, OperationType, OperationTypeConsumable
from app.models.user import User
from app.models.visit import Visit, VisitItem
from app.schemas.operation import (
    AvailabilityItem,
    AvailabilityOut,
    OperationComplete,
    OperationCreate,
    OperationOut,
    OperationReport,
    OperationSchedule,
    OperationTypeCreate,
    OperationTypeOut,
    PerformOperationRequest,
    SurgeonOperationStat,
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
def refer_operation(
    visit_id: UUID,
    payload: OperationCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.prescribe"))],
) -> Operation:
    """Doctor refers the patient to surgery (TZ Modul 6: «Operatsiyaga yuborish»).

    A referral records only the type, eye, priority and recommendation — it is
    NOT billed and has no date/surgeon yet. Reception schedules it afterwards,
    which is when the visit is billed.
    """
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot refer on a {visit.status} visit")
    op_type = db.get(OperationType, payload.operation_type_id)
    if op_type is None or not op_type.is_active:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown or inactive operation type")

    operation = Operation(
        visit_id=visit.id,
        patient_id=visit.patient_id,
        referring_doctor_id=actor.id,
        operation_type_id=op_type.id,
        eye=payload.eye,
        priority=payload.priority,
        status="referred",
        notes=payload.notes,
    )
    db.add(operation)
    db.flush()
    # Workflow engine: a referral with no date yet is an assignment, not a schedule.
    advance_flow(db, visit, "surgery_prescribed")
    record_audit(db, action="refer", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Referred to operation {op_type.name} ({payload.eye}, {payload.priority}) "
                         f"on visit {visit.visit_no}")
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


# ── Operations department worklist & report (TZ Modul 6) ──────────────────────
@router.get("/operations", response_model=list[OperationOut],
            dependencies=[Depends(require_permission("operations.read"))])
def list_operations(
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
    status_filter: str | None = Query(None, alias="status"),
    branch_id: UUID | None = None,
    surgeon_id: UUID | None = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
) -> list[Operation]:
    """The Operations-department worklist: referrals waiting to be scheduled,
    scheduled/in-progress surgeries, and (filtered) history. Branch-scoped."""
    stmt = select(Operation).join(Visit, Operation.visit_id == Visit.id)
    # Branch isolation mirrors visits.list_visits: a single-branch user only
    # sees their branch; the director (superuser) sees all.
    if not actor.is_superuser and actor.branch_id is not None:
        stmt = stmt.where(Visit.branch_id == actor.branch_id)
    if branch_id is not None:
        stmt = stmt.where(Visit.branch_id == branch_id)
    if status_filter:
        stmt = stmt.where(Operation.status == status_filter)
    if surgeon_id is not None:
        stmt = stmt.where(Operation.surgeon_id == surgeon_id)
    # Urgent first, then by referral time (oldest waiting at the top).
    stmt = stmt.order_by(
        (Operation.priority == "urgent").desc(), Operation.created_at.asc()
    ).offset(offset).limit(limit)
    return list(db.execute(stmt).scalars().all())


@router.get("/operations/report", response_model=OperationReport,
            dependencies=[Depends(require_permission("operations.read"))])
def operation_report(
    date_from: datetime,
    date_to: datetime,
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
) -> OperationReport:
    """Period report: count, total revenue and a by-surgeon breakdown over
    performed/completed operations (TZ Modul 6: Hisobot)."""
    def _scoped(stmt):
        stmt = stmt.join(Visit, Operation.visit_id == Visit.id).where(
            Operation.status.in_(Operation.DONE_STATUSES),
            Operation.performed_at >= date_from,
            Operation.performed_at <= date_to,
        )
        if not actor.is_superuser and actor.branch_id is not None:
            stmt = stmt.where(Visit.branch_id == actor.branch_id)
        return stmt

    count, total = db.execute(
        _scoped(select(func.count(), func.coalesce(func.sum(Operation.price), 0)))
    ).one()

    rows = db.execute(
        _scoped(select(
            Operation.surgeon_id,
            func.count(),
            func.coalesce(func.sum(Operation.price), 0),
        )).group_by(Operation.surgeon_id)
    ).all()
    by_surgeon = []
    for surgeon_id, s_count, s_total in rows:
        surgeon = db.get(User, surgeon_id) if surgeon_id else None
        by_surgeon.append(SurgeonOperationStat(
            surgeon_id=surgeon_id,
            surgeon_name=surgeon.full_name if surgeon else None,
            count=s_count,
            total_amount=Decimal(s_total),
        ))
    by_surgeon.sort(key=lambda s: s.total_amount, reverse=True)
    return OperationReport(
        date_from=date_from, date_to=date_to,
        count=count, total_amount=Decimal(total), by_surgeon=by_surgeon,
    )


@router.post("/operations/{operation_id}/schedule", response_model=OperationOut)
def schedule_operation(
    operation_id: UUID,
    payload: OperationSchedule,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.schedule"))],
) -> Operation:
    """Reception fixes date/time, surgeon and price, and bills the visit
    (TZ Modul 6). The linked service lands on the visit at the final price —
    the catalog price unless reception overrides it. Re-scheduling an unpaid
    operation updates the same billed line."""
    operation = _get_or_404(db, operation_id)
    if operation.status not in ("referred", "scheduled"):
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a referred or scheduled operation can be scheduled "
                            f"(status: {operation.status})")
    visit = db.get(Visit, operation.visit_id)
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot schedule on a {visit.status} visit")
    if payload.surgeon_id is not None and db.get(User, payload.surgeon_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown surgeon")

    op_type = operation.operation_type
    final_price = payload.price if payload.price is not None else Decimal(op_type.price)

    if operation.status == "referred":
        # First scheduling: bill the linked service at the final price.
        item = _make_item(db, op_type.service_id, 1, unit_price=final_price)
        visit.items.append(item)
        _recompute_total(visit)
        db.flush()  # assign the item id for the billing trace
        operation.visit_item_id = item.id
    elif operation.visit_item_id is not None:
        # Re-schedule: adjust the existing billed line if it is still unpaid.
        item = db.get(VisitItem, operation.visit_item_id)
        if item is not None and Decimal(item.unit_price) != final_price:
            if item.status != "ordered":
                raise HTTPException(
                    status.HTTP_409_CONFLICT,
                    "The billed item is already paid — refund before changing the price",
                )
            item.unit_price = final_price
            item.total = final_price * item.quantity
            _recompute_total(visit)

    operation.surgeon_id = payload.surgeon_id
    operation.scheduled_at = payload.scheduled_at
    operation.price = final_price
    if payload.notes is not None:
        operation.notes = payload.notes
    operation.status = "scheduled"
    advance_flow(db, visit, "surgery_scheduled")
    record_audit(db, action="schedule", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Scheduled operation {op_type.name} on visit {visit.visit_no} "
                         f"for {payload.scheduled_at:%Y-%m-%d %H:%M}, price {final_price}")
    db.commit()
    db.refresh(operation)
    return operation


@router.post("/operations/{operation_id}/start", response_model=OperationOut)
def start_operation(
    operation_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.perform"))],
) -> Operation:
    """Mark a scheduled operation as in progress (TZ: «Bajarilmoqda»)."""
    operation = _get_or_404(db, operation_id)
    if operation.status != "scheduled":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a scheduled operation can be started (status: {operation.status})")
    visit = db.get(Visit, operation.visit_id)
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot start an operation on a {visit.status} visit")
    operation.status = "in_progress"
    record_audit(db, action="start", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Started operation {operation.type_name} on visit {visit.visit_no}")
    db.commit()
    db.refresh(operation)
    return operation


@router.post("/operations/{operation_id}/perform", response_model=OperationOut)
def perform_operation(
    operation_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.perform"))],
    # Optional body — omitted = template only (keeps existing no-body callers working).
    payload: PerformOperationRequest | None = None,
) -> Operation:
    operation = _get_or_404(db, operation_id)
    if operation.status not in ("scheduled", "in_progress"):
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a scheduled/in-progress operation can be performed "
                            f"(status: {operation.status})")
    visit = db.get(Visit, operation.visit_id)
    # A cancelled/closed visit must not consume stock: reception cancelling an
    # unpaid visit would otherwise leave a performable operation with zero revenue.
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Cannot perform an operation on a {visit.status} visit")
    op_type = operation.operation_type
    ad_hoc = payload.ad_hoc_consumables if payload is not None else []

    # Consumables actually written off = the type's TEMPLATE plus any AD-HOC
    # extras the operating team picked from the warehouse (reception logs what
    # was really used). Both go through the same FEFO; ad-hoc lines are tagged in
    # the movement reason for traceability. (product_id, quantity, reason) tuples.
    lines = [
        (c.product_id, c.quantity, f"Операция {op_type.name}")
        for c in op_type.consumables
    ]
    lines += [
        (a.product_id, a.quantity, f"Операция {op_type.name} — доп. расходник")
        for a in ad_hoc
    ]

    # Pre-check per PRODUCT (summing duplicate lines — a product can be both a
    # template consumable AND an ad-hoc extra, or listed twice) before writing
    # anything off. Keeps the whole perform atomic AND makes the 409 report the
    # TRUE cumulative demand, not one line's quantity.
    demand: dict = {}
    for product_id, quantity, _ in lines:
        demand[product_id] = (demand.get(product_id) or 0) + quantity
    for product_id, needed in demand.items():
        available = on_hand(db, product_id, visit.branch_id)
        if available < needed:
            product = db.get(Product, product_id)
            label = f"{product.name} ({product.sku})" if product else str(product_id)
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                f"Insufficient stock for {label}: requested {needed}, available {available}",
            )

    try:
        for product_id, quantity, reason in lines:
            write_off_fefo(
                db,
                product_id=product_id,
                branch_id=visit.branch_id,
                quantity=quantity,
                reason=reason,
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

    operation.status = "performed"
    operation.performed_at = datetime.now(timezone.utc)
    # If reception didn't assign a surgeon, the performer IS the surgeon — keeps
    # the by-surgeon report attributed without forcing a pre-op assignment.
    if operation.surgeon_id is None:
        operation.surgeon_id = actor.id
    advance_flow(db, visit, "surgery_performed")  # workflow engine (same transaction)
    n_adhoc = len(ad_hoc)
    record_audit(db, action="perform", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Performed operation {op_type.name} ({operation.eye}); write-off: "
                         f"{len(op_type.consumables)} template + {n_adhoc} ad-hoc positions")
    db.commit()
    check_low_stock(db, [pid for pid, _, _ in lines], visit.branch_id)  # post-commit
    db.refresh(operation)
    return operation


@router.post("/operations/{operation_id}/complete", response_model=OperationOut)
def complete_operation(
    operation_id: UUID,
    payload: OperationComplete,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.perform"))],
) -> Operation:
    """Wrap up a performed operation (TZ: «Yakunlandi») — the outcome is written
    to the patient card and shows in future visits."""
    operation = _get_or_404(db, operation_id)
    if operation.status != "performed":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a performed operation can be completed (status: {operation.status})")
    visit = db.get(Visit, operation.visit_id)
    operation.status = "completed"
    operation.completed_at = datetime.now(timezone.utc)
    if payload.result is not None:
        operation.result = payload.result
    record_audit(db, action="complete", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Completed operation {operation.type_name} on visit {visit.visit_no}")
    db.commit()
    db.refresh(operation)
    return operation


@router.post("/operations/{operation_id}/cancel", response_model=OperationOut)
def cancel_operation(
    operation_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(
        require_any_permission("operations.prescribe", "operations.schedule"))],
) -> Operation:
    """Cancel a not-yet-performed operation. The doctor may withdraw a referral,
    reception may cancel a scheduling — either way the billed line (if any) is
    removed, unless it was already paid (refund first)."""
    operation = _get_or_404(db, operation_id)
    if operation.status not in Operation.OPEN_STATUSES:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a not-yet-performed operation can be cancelled "
                            f"(status: {operation.status})")
    visit = db.get(Visit, operation.visit_id)

    # De-bill: scheduling added the linked service to the visit, so cancelling
    # must take it off again — otherwise the patient stays charged for a surgery
    # that will not happen. A paid item cannot be silently removed (money was
    # taken): require a refund first. A bare referral has no billed item.
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
