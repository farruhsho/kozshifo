"""Operations: surgery type catalog, prescribe (bills the visit), perform (FEFO write-off).

Prescribing an operation appends the linked service onto the visit through the
exact same billing helpers visits.py uses, so totals/receipts behave identically.
Performing it consumes the template consumables via the FEFO stock engine.
"""
from __future__ import annotations

from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.dates import local_day_bounds_utc
from app.core.deps import CurrentUser, require_any_permission, require_permission
from app.core.flow import advance_flow, recompute_plan
from app.core.notify import check_low_stock
from app.core.stock import InsufficientStockError, on_hand, write_off_fefo
from app.core.visibility import owner_user_ids
from app.features.visits import _make_item, _recompute_total
from app.models.catalog import Service
from app.models.finance import Expense
from app.models.inventory import Product, StockBatch, StockMovement
from app.models.operation import (
    ADHOC_REASON_SUFFIX,
    Operation,
    OperationType,
    OperationTypeConsumable,
)
from app.models.user import User
from app.models.visit import Visit, VisitItem
from app.schemas.operation import (
    AvailabilityItem,
    AvailabilityOut,
    OperationComplete,
    OperationCreate,
    OperationDaySummary,
    OperationOut,
    OperationPriceResult,
    OperationPriceUpdate,
    OperationReport,
    OperationSchedule,
    OperationTypeCreate,
    OperationTypeOut,
    PerformOperationRequest,
    SurgeonOperationStat,
    SurgeonOut,
)

router = APIRouter(tags=["Operations"])

# Below this many supported operations the availability verdict turns yellow
# (low stock) instead of green; 0 supported operations is always red.
LOW_FEASIBILITY_THRESHOLD = 5
# Sentinel "effectively unlimited": a template line that requires nothing must
# not drag min_feasibility down — it never constrains the operation.
_UNCONSTRAINED = 10**9


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
    # Track the most-constrained line so we can name the bottleneck product.
    min_feasibility = _UNCONSTRAINED
    bottleneck: str | None = None
    for line in op_type.consumables:
        available = on_hand(db, line.product_id, branch_id)
        # floor(available / required): whole operations this line alone supports.
        # A line that requires nothing never constrains the operation count.
        if line.quantity > 0:
            feasibility = int(available // line.quantity)
        else:
            feasibility = _UNCONSTRAINED
        items.append(
            AvailabilityItem(
                product_id=line.product_id,
                product_name=line.product_name,
                required=line.quantity,
                available=available,
                ok=available >= line.quantity,
                feasibility_count=feasibility,
            )
        )
        if feasibility < min_feasibility:
            min_feasibility = feasibility
            bottleneck = line.product_name

    # An empty template (no constraining line) is trivially coverable → green,
    # no finite limit and no bottleneck to surface.
    if min_feasibility == _UNCONSTRAINED:
        min_feasibility = 0
        bottleneck = None
        status_value = "green"
    elif min_feasibility == 0:
        status_value = "red"
    elif min_feasibility < LOW_FEASIBILITY_THRESHOLD:
        status_value = "yellow"
    else:
        status_value = "green"
        bottleneck = None  # plenty in stock — no limiting line to highlight

    # all([]) is True: an empty template is trivially coverable.
    return AvailabilityOut(
        ok=all(item.ok for item in items),
        items=items,
        min_feasibility=min_feasibility,
        status=status_value,
        bottleneck=bottleneck,
    )


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
    if payload.surgeon_id is not None and db.get(User, payload.surgeon_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown surgeon")

    operation = Operation(
        visit_id=visit.id,
        patient_id=visit.patient_id,
        referring_doctor_id=actor.id,
        surgeon_id=payload.surgeon_id,
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


@router.get("/operations/surgeons", response_model=list[SurgeonOut],
            dependencies=[Depends(require_permission("operations.read"))])
def list_surgeons(db: Annotated[Session, Depends(get_db)]) -> list[User]:
    """Staff eligible to operate — for the referral / schedule surgeon picker.

    A surgeon is an active user who can perform operations (operations.perform via
    role or direct grant) OR is flagged as a visiting/external surgeon (e.g.
    приезжает из Ташкента). Gated operations.read so the referring doctor can pick
    without identity-module (users.read) access; external surgeons are flagged so
    the UI can mark «приезжий»."""
    users = db.execute(
        select(User)
        .where(User.is_active.is_(True), User.id.not_in(owner_user_ids()))
        .order_by(User.full_name)
    ).scalars().all()
    return [
        u for u in users
        if u.is_external_surgeon or "operations.perform" in u.effective_permission_codes()
    ]


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
    scheduled_from: datetime | None = None,
    scheduled_to: datetime | None = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
) -> list[Operation]:
    """The Operations-department worklist: referrals waiting to be scheduled,
    scheduled/in-progress surgeries, and (filtered) history. Branch-scoped.

    `scheduled_from`/`scheduled_to` window the result by `scheduled_at` (a
    half-open [from, to) interval of absolute UTC instants — the calendar passes
    the selected local day's UTC bounds). This lets the agenda fetch just one
    day instead of pulling every scheduled op and capping at 500 client-side;
    rows with no `scheduled_at` (bare referrals) drop out of a windowed query."""
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
    # Mirror operation_report's raw-datetime comparison: scheduled_at is stored
    # UTC (client sends `.toUtc()`), so an absolute-instant window is correct on
    # both Postgres (aware) and SQLite (naive UTC wall-clock).
    if scheduled_from is not None:
        stmt = stmt.where(Operation.scheduled_at >= scheduled_from)
    if scheduled_to is not None:
        stmt = stmt.where(Operation.scheduled_at < scheduled_to)
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


# Operation day-expenses are logged via the finance module under this category;
# the day-summary subtracts exactly these from the day's operation revenue.
OPERATIONS_EXPENSE_CATEGORY = "Операции"


@router.get("/operations/day-summary", response_model=OperationDaySummary,
            dependencies=[Depends(require_permission("operations.read"))])
def operation_day_summary(
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
    d: date = Query(..., alias="date"),
    branch_id: UUID | None = None,
) -> OperationDaySummary:
    """End-of-day operations P&L for the director: revenue (Σ price of operations
    PERFORMED that local day) − COGS (consumables written off for them, qty ×
    batch unit_cost) − the day's operation expenses (finance Expense category
    «Операции»). Branch scope: explicit param, else the caller's own branch."""
    start, end = local_day_bounds_utc(d)
    branch = branch_id if branch_id is not None else (
        None if actor.is_superuser else actor.branch_id)

    op_stmt = (
        select(Operation.id, Operation.price)
        .join(Visit, Operation.visit_id == Visit.id)
        .where(
            Operation.status.in_(Operation.DONE_STATUSES),
            Operation.performed_at >= start,
            Operation.performed_at < end,
        )
    )
    if branch is not None:
        op_stmt = op_stmt.where(Visit.branch_id == branch)
    op_rows = db.execute(op_stmt).all()
    op_ids = [r[0] for r in op_rows]
    revenue = sum((r[1] if r[1] is not None else Decimal("0") for r in op_rows), Decimal("0"))

    cogs = Decimal("0")
    if op_ids:
        cogs = Decimal(db.execute(
            select(func.coalesce(
                func.sum(func.abs(StockMovement.quantity) * StockBatch.unit_cost), 0))
            .select_from(StockMovement)
            .join(StockBatch, StockBatch.id == StockMovement.batch_id)
            .where(
                StockMovement.ref_type == "operation",
                StockMovement.ref_id.in_(op_ids),
                StockMovement.movement_type == "write_off",
            )
        ).scalar_one())

    exp_stmt = select(func.coalesce(func.sum(Expense.amount), 0)).where(
        Expense.expense_date == d,
        Expense.category == OPERATIONS_EXPENSE_CATEGORY,
    )
    if branch is not None:
        exp_stmt = exp_stmt.where(Expense.branch_id == branch)
    expenses = Decimal(db.execute(exp_stmt).scalar_one())

    return OperationDaySummary(
        date=d,
        operations_count=len(op_ids),
        revenue=revenue,
        cogs=cogs,
        expenses=expenses,
        profit=revenue - cogs - expenses,
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
    if operation.financially_closed_at is not None:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Operation is financially closed — cannot reschedule/reprice it")
    visit = db.get(Visit, operation.visit_id)
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot schedule on a {visit.status} visit")
    if payload.surgeon_id is not None and db.get(User, payload.surgeon_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown surgeon")

    op_type = operation.operation_type
    # Price precedence: explicit override → a pre-set quote (set-price on a still
    # referred op) → the service catalog default.
    if payload.price is not None:
        final_price = payload.price
    elif operation.price is not None:
        final_price = Decimal(operation.price)
    else:
        final_price = Decimal(op_type.price)

    if operation.status == "referred":
        # First scheduling: bill the linked service at the final price.
        item = _make_item(db, op_type.service_id, 1, unit_price=final_price)
        visit.items.append(item)
        _recompute_total(visit)
        db.flush()  # assign the item id for the billing trace
        operation.visit_item_id = item.id
    elif operation.visit_item_id is not None:
        # Re-schedule: adjust the existing billed line. Cost stays editable even
        # after payment (owner brief 2026-06-20) — the only freeze is financial
        # close (guarded above). A new price re-derives the visit balance; an
        # over/under payment is reconciled by reception via the till/refund.
        item = db.get(VisitItem, operation.visit_item_id)
        if item is not None and Decimal(item.unit_price) != final_price:
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


@router.post("/operations/{operation_id}/set-price", response_model=OperationPriceResult)
def set_operation_price(
    operation_id: UUID,
    payload: OperationPriceUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.schedule"))],
) -> OperationPriceResult:
    """Change an operation's cost at any point (before/during/after) until it is
    financially closed (owner brief 2026-06-20 — cost is NOT fixed at planning).
    Repoints the billed visit line if one exists; a still-referred op just stores
    the quote, applied when it is scheduled. The new price re-derives the visit
    balance — if it drops below what was already paid the response reports the
    refund owed (reception returns it via the till)."""
    operation = _get_or_404(db, operation_id)
    if operation.status == "cancelled":
        raise HTTPException(status.HTTP_409_CONFLICT, "Cannot price a cancelled operation")
    if operation.financially_closed_at is not None:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Operation is financially closed — its price can no longer be changed")
    visit = db.get(Visit, operation.visit_id)
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot change price on a {visit.status} visit")

    new_price = Decimal(payload.price)
    old_price = operation.price
    if operation.visit_item_id is not None:
        item = db.get(VisitItem, operation.visit_item_id)
        if item is not None:
            item.unit_price = new_price
            item.total = new_price * item.quantity
            _recompute_total(visit)
    operation.price = new_price
    reason = (payload.reason or "").strip()
    record_audit(db, action="price_change", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Changed price of operation {operation.type_name} on visit "
                         f"{visit.visit_no}: {old_price} → {new_price}"
                         + (f" ({reason})" if reason else ""))
    db.commit()
    db.refresh(operation)
    db.refresh(visit)
    refund_due = max(Decimal("0.00"), Decimal(visit.paid_amount) - visit.payable)
    return OperationPriceResult(
        operation=OperationOut.model_validate(operation),
        visit_balance=visit.balance,
        refund_due=refund_due,
    )


@router.post("/operations/{operation_id}/financial-close", response_model=OperationOut)
def financial_close_operation(
    operation_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.schedule"))],
) -> Operation:
    """Freeze an operation's finances: after this the price/bill can no longer be
    changed — the end of the editable window. Closing the visit auto-closes its
    operations too (see visits.close_visit)."""
    operation = _get_or_404(db, operation_id)
    if operation.status == "cancelled":
        raise HTTPException(status.HTTP_409_CONFLICT, "Cannot financially close a cancelled operation")
    if operation.financially_closed_at is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Operation is already financially closed")
    visit = db.get(Visit, operation.visit_id)
    operation.financially_closed_at = datetime.now(timezone.utc)
    operation.financially_closed_by_id = actor.id
    record_audit(db, action="financial_close", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Financially closed operation {operation.type_name} on visit "
                         f"{visit.visit_no} (price {operation.price})")
    db.commit()
    db.refresh(operation)
    return operation


@router.post("/operations/{operation_id}/unschedule", response_model=OperationOut)
def unschedule_operation(
    operation_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("operations.schedule"))],
) -> Operation:
    """Detach a SCHEDULED operation from its day, back to the referred pool
    (force-majeure: the patient can't make that day, so reception frees the slot
    for another from the pool). De-bills the visit (scheduling had added the
    linked service) unless it was already paid — then a refund is required first.
    The operation stays alive (status → referred) so it can be re-scheduled for
    another day; the chosen surgeon is kept."""
    operation = _get_or_404(db, operation_id)
    if operation.status != "scheduled":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Only a scheduled operation can be detached (status: {operation.status})")
    if operation.financially_closed_at is not None:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Operation is financially closed — cannot detach it")
    visit = db.get(Visit, operation.visit_id)
    if operation.visit_item_id is not None:
        item = db.get(VisitItem, operation.visit_item_id)
        if item is not None:
            if item.status != "ordered":
                raise HTTPException(
                    status.HTTP_409_CONFLICT,
                    "The billed item is already paid — refund the payment before detaching")
            visit.items.remove(item)  # delete-orphan cascade removes the row
            _recompute_total(visit)
        operation.visit_item_id = None
    operation.status = "referred"
    operation.scheduled_at = None
    operation.price = None
    record_audit(db, action="unschedule", entity_type="operation", entity_id=operation.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Detached operation {operation.type_name} from its day (back to pool)")
    db.flush()
    recompute_plan(db, visit)  # the lifecycle stops advertising a fixed surgery date
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
        (a.product_id, a.quantity, f"Операция {op_type.name}{ADHOC_REASON_SUFFIX}")
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
    if operation.financially_closed_at is not None:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Operation is financially closed — cannot cancel it")
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
