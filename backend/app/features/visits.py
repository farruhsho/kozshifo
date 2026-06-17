"""Visits (encounters): open a visit, add billed services, close it."""
from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.flow import advance_flow
from app.core.sequences import next_ticket_number, next_visit_no
from app.models.branch import Branch
from app.models.catalog import Service
from app.models.patient import Patient
from app.models.queue import QueueTicket
from app.models.visit import Visit, VisitItem
from app.schemas.common import Page
from app.schemas.visit import (
    VisitCreate,
    VisitDiscountApply,
    VisitItemAdd,
    VisitOut,
    VisitPriorityApply,
)

router = APIRouter(prefix="/visits", tags=["Visits"])

# Priority weight for an emergency intake — well above the default 0 so the
# ticket sorts to the top (queue queries order by priority DESC, created ASC).
_EMERGENCY_PRIORITY = 100


def _recompute_total(visit: Visit) -> None:
    visit.total_amount = sum((Decimal(i.total) for i in visit.items), Decimal("0.00"))


def _make_item(db: Session, service_id: UUID, quantity: int,
               unit_price: Decimal | None = None) -> VisitItem:
    """Build a billed line for a service.

    `unit_price` overrides the catalog price (TZ Modul 6: reception may set a
    per-operation price). The service is still the name/billing-trace source.
    """
    service = db.get(Service, service_id)
    if service is None or not service.is_active:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, f"Unknown or inactive service {service_id}")
    unit = Decimal(unit_price) if unit_price is not None else Decimal(service.price)
    return VisitItem(
        service_id=service.id,
        service_name=service.name,
        unit_price=unit,
        quantity=quantity,
        total=unit * quantity,
    )


@router.get("", response_model=Page[VisitOut])
def list_visits(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("visits.read"))],
    patient_id: UUID | None = None,
    branch_id: UUID | None = None,
    status_filter: str | None = Query(None, alias="status"),
    owing: bool = Query(False, description="Only visits that still owe money (payable > paid)"),
    opened_from: datetime | None = None,
    opened_to: datetime | None = None,
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
    # opened_at date-window (half-open [from, to) of absolute UTC instants — the
    # visit-history screen passes the selected local day bounds as UTC). opened_at
    # is UTCDateTime (aware UTC on both Postgres and SQLite), so the comparison is
    # consistent across backends.
    if opened_from is not None:
        stmt = stmt.where(Visit.opened_at >= opened_from)
    if opened_to is not None:
        stmt = stmt.where(Visit.opened_at < opened_to)
    # Branch isolation: a single-branch user (e.g. a cashier) only ever sees
    # their own branch's visits; the director (superuser) sees all branches.
    if not actor.is_superuser and actor.branch_id is not None:
        stmt = stmt.where(Visit.branch_id == actor.branch_id)
    if owing:
        # payable = total - discount (mirror Visit.payable); list only debtors so
        # the till's pagination describes exactly the owing set, not all open.
        discount = case(
            (Visit.discount_percent.is_not(None),
             func.round(Visit.total_amount * Visit.discount_percent / 100, 2)),
            (Visit.discount_amount.is_not(None),
             case((Visit.discount_amount > Visit.total_amount, Visit.total_amount),
                  else_=Visit.discount_amount)),
            else_=0,
        )
        stmt = stmt.where(Visit.total_amount - discount > Visit.paid_amount)
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


def _discount_snapshot(visit: Visit) -> dict[str, str | None]:
    """JSON-safe before/after picture for the audit trail."""
    return {
        "discount_percent": str(visit.discount_percent) if visit.discount_percent is not None else None,
        "discount_amount": str(visit.discount_amount) if visit.discount_amount is not None else None,
        "discount_reason": visit.discount_reason,
        "payable": str(visit.payable),
    }


@router.post("/{visit_id}/discount", response_model=VisitOut)
def apply_discount(
    visit_id: UUID,
    payload: VisitDiscountApply,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("visits.update"))],
) -> Visit:
    """Apply, overwrite or clear the reception discount (TZ Modul 2.2).

    total_amount stays gross; `payable` (= total - discount) becomes the due
    basis for payments. Every change is audited with a before/after snapshot.
    """
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Cannot change discount on a {visit.status} visit")

    before = _discount_snapshot(visit)
    if payload.clear:
        if Decimal(visit.paid_amount) > Decimal("0.00"):
            raise HTTPException(status.HTTP_409_CONFLICT,
                                "Cannot clear a discount after payments were taken — refund first")
        visit.discount_percent = None
        visit.discount_amount = None
        visit.discount_reason = None
    else:
        total = Decimal(visit.total_amount)
        # A fixed-amount discount may not exceed the bill — an amount larger than
        # the total would lie dormant and silently absorb services added later,
        # making them free. (A 100% discount uses discount_percent instead.)
        if payload.discount_amount is not None and Decimal(payload.discount_amount) > total:
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                f"Discount amount {payload.discount_amount} exceeds visit total {total}",
            )
        if payload.discount_percent is not None:
            new_value = (total * payload.discount_percent / Decimal("100")).quantize(Decimal("0.01"))
        else:
            new_value = Decimal(payload.discount_amount)
        # Guard: the new payable must not drop below what is already paid,
        # otherwise the visit silently becomes overpaid.
        if total - new_value < Decimal(visit.paid_amount):
            raise HTTPException(status.HTTP_409_CONFLICT,
                                "Discount would drop payable below the amount already paid — refund first")
        visit.discount_percent = payload.discount_percent
        visit.discount_amount = payload.discount_amount
        visit.discount_reason = (payload.discount_reason or "").strip()

    # A discount that fully covers the bill leaves nothing to pay, so a payment
    # (which the journey relies on to start) can never be taken. Settle the
    # visit here the same way a full payment would: items -> paid, advance the
    # flow, and mint a diagnostic ticket — otherwise a free visit is stranded.
    ticket_number: str | None = None
    if not payload.clear and visit.balance <= Decimal("0.00"):
        for item in visit.items:
            if item.status == "ordered":
                item.status = "paid"
        advance_flow(db, visit, "paid_in_full")  # workflow engine (same transaction)
        if payload.issue_queue_ticket and visit.flow_status == "waiting_diagnostic":
            existing = db.execute(
                select(QueueTicket).where(
                    QueueTicket.visit_id == visit.id,
                    QueueTicket.status.in_(("waiting", "called", "serving")),
                ).limit(1)
            ).scalar_one_or_none()
            if existing is not None:
                ticket_number = existing.ticket_number
            else:
                ticket = QueueTicket(
                    ticket_number=next_ticket_number(db, visit.branch_id, "diagnostic"),
                    track="diagnostic",
                    patient_id=visit.patient_id,
                    branch_id=visit.branch_id,
                    visit_id=visit.id,
                    room=payload.room,
                    priority=visit.priority,
                    priority_reason=visit.priority_reason,
                )
                db.add(ticket)
                db.flush()
                ticket_number = ticket.ticket_number
                record_audit(db, action="create", entity_type="queue_ticket", entity_id=ticket.id,
                             actor_id=actor.id, branch_id=visit.branch_id,
                             summary=f"Issued queue ticket {ticket_number} (free visit, full discount)")

    action = "discount_clear" if payload.clear else "discount"
    summary = (f"{'Cleared' if payload.clear else 'Applied'} discount on visit "
               f"{visit.visit_no} (payable {visit.payable})")
    if ticket_number is not None:
        summary += f" — settled free, ticket {ticket_number}"
    record_audit(db, action=action, entity_type="visit", entity_id=visit.id, actor_id=actor.id,
                 branch_id=visit.branch_id, summary=summary,
                 changes={"before": before, "after": _discount_snapshot(visit)})
    db.commit()
    db.refresh(visit)
    return visit


@router.post("/{visit_id}/priority", response_model=VisitOut)
def set_priority(
    visit_id: UUID,
    payload: VisitPriorityApply,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("visits.update"))],
) -> Visit:
    """Mark/clear EMERGENCY intake on a visit (reception «ЭКСТРЕННО»).

    Sets visit.priority (>0 jumps the queue) + a reason kept for analytics. Any
    already-active ticket for the visit is bumped immediately so a patient who is
    already waiting moves to the top. The receipt/TV flag «ЭКСТРЕННЫЙ» reads this.
    """
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Cannot change priority on a {visit.status} visit")
    if payload.emergency and not (payload.reason or "").strip():
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "Reason is required for an emergency visit")

    visit.priority = _EMERGENCY_PRIORITY if payload.emergency else 0
    visit.priority_reason = (payload.reason or "").strip() if payload.emergency else None

    # Bump any active ticket immediately (patient already in the queue).
    for ticket in db.execute(
        select(QueueTicket).where(
            QueueTicket.visit_id == visit.id,
            QueueTicket.status.in_(("waiting", "called", "serving")),
        )
    ).scalars().all():
        ticket.priority = visit.priority
        ticket.priority_reason = visit.priority_reason

    record_audit(db, action="priority", entity_type="visit", entity_id=visit.id, actor_id=actor.id,
                 branch_id=visit.branch_id,
                 summary=(f"{'Set' if payload.emergency else 'Cleared'} emergency on visit "
                          f"{visit.visit_no}"
                          + (f": {visit.priority_reason}" if payload.emergency else "")))
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
    advance_flow(db, visit, "visit_cancelled")  # workflow engine (same transaction)
    # The patient leaves the flow: active queue tickets of this visit must not
    # stay on the TV board or auto-advance to the doctor queue later.
    active_tickets = db.execute(
        select(QueueTicket).where(
            QueueTicket.visit_id == visit.id,
            QueueTicket.status.in_(("waiting", "called", "serving")),
        )
    ).scalars().all()
    for ticket in active_tickets:
        ticket.status = "skipped"
        record_audit(db, action="update", entity_type="queue_ticket", entity_id=ticket.id,
                     actor_id=actor.id, branch_id=visit.branch_id,
                     summary=f"Ticket {ticket.ticket_number} skipped: visit cancelled")
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
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"Cannot close a {visit.status} visit")
    visit.status = "completed"
    visit.closed_at = datetime.now(timezone.utc)
    advance_flow(db, visit, "visit_closed")  # workflow engine (same transaction)
    record_audit(db, action="close", entity_type="visit", entity_id=visit.id, actor_id=actor.id,
                 summary=f"Closed visit {visit.visit_no} (balance {visit.balance})")
    db.commit()
    db.refresh(visit)
    return visit
