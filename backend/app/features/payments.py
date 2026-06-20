"""Payments: take payment on a visit and (on full payment) issue a queue ticket.

This closes the central loop of the Patient Journey:
    services billed -> payment taken -> receipt -> queue ticket -> TV board.
"""
from __future__ import annotations

from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import Response
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.flow import advance_flow
from app.core.print_forms import build_receipt_pdf
from app.core.sequences import next_receipt_no, next_ticket_number
from app.features.queue import issue_doctor_ticket
from app.models.catalog import Service
from app.models.payment import Payment
from app.models.queue import QueueTicket
from app.models.visit import Visit
from app.schemas.common import Page
from app.schemas.payment import PaymentCreate, PaymentOut, PaymentResult

router = APIRouter(prefix="/payments", tags=["Finance"])

_ACTIVE_TICKET = ("waiting", "called", "serving")


@router.get("", response_model=Page[PaymentOut])
def list_payments(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("payments.read"))],
    visit_id: UUID | None = None,
    branch_id: UUID | None = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[PaymentOut]:
    stmt = select(Payment)
    if visit_id:
        stmt = stmt.where(Payment.visit_id == visit_id)
    if branch_id:
        stmt = stmt.where(Payment.branch_id == branch_id)
    # Server-side branch isolation: a non-superuser only ever sees their own
    # branch's receipts, regardless of the client-supplied branch_id (mirrors
    # GET /visits). The director (superuser) can still filter to any branch.
    if not actor.is_superuser and actor.branch_id is not None:
        stmt = stmt.where(Payment.branch_id == actor.branch_id)
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(stmt.order_by(Payment.created_at.desc()).offset(offset).limit(limit)).scalars().all()
    return Page(items=[PaymentOut.model_validate(p) for p in rows], total=total, offset=offset, limit=limit)


@router.post("", response_model=PaymentResult, status_code=status.HTTP_201_CREATED)
def take_payment(
    payload: PaymentCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("payments.create"))],
) -> PaymentResult:
    visit = db.get(Visit, payload.visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    if visit.status == "cancelled":
        raise HTTPException(status.HTTP_409_CONFLICT, "Cannot pay a cancelled visit")

    amount = Decimal(payload.amount)
    if amount > visit.balance:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            f"Amount {amount} exceeds outstanding balance {visit.balance}",
        )

    payment = Payment(
        receipt_no=next_receipt_no(db),
        visit_id=visit.id,
        patient_id=visit.patient_id,
        branch_id=visit.branch_id,
        cashier_id=actor.id,
        amount=amount,
        method=payload.method,
        note=payload.note,
    )
    db.add(payment)
    visit.paid_amount = Decimal(visit.paid_amount) + amount

    fully_paid = visit.balance <= Decimal("0.00")
    if fully_paid:
        for item in visit.items:
            if item.status == "ordered":
                item.status = "paid"
        # Reception's registration choice drives where the patient goes (the
        # journey still starts exactly once — the events are guarded to "registered").
        advance_flow(db, visit, {
            "doctor": "referred_to_doctor",   # Вариант 2: «Направлен к врачу»
            "hold": "held_for_assignment",    # Вариант 1: «Ожидает назначения»
        }.get(payload.referral_intent, "paid_in_full"))  # default: diagnostics

    record_audit(db, action="payment", entity_type="payment", entity_id=payment.id, actor_id=actor.id,
                 branch_id=visit.branch_id,
                 summary=f"Payment {amount} ({payload.method}) on visit {visit.visit_no}")

    ticket_number: str | None = None
    if fully_paid and payload.issue_queue_ticket:
        # Dedupe deliberately ignores the track: a patient mid-flow (active D *or*
        # auto-advanced V ticket) must never be handed a second diagnostic ticket —
        # the active ticket's number is just reported back to reception.
        existing = db.execute(
            select(QueueTicket)
            .where(QueueTicket.visit_id == visit.id, QueueTicket.status.in_(_ACTIVE_TICKET))
            .limit(1)
        ).scalar_one_or_none()
        if existing:
            ticket_number = existing.ticket_number
        # «Направлен к врачу» (Вариант 2): mint the doctor ticket directly, routed
        # to the visit's doctor (лечащий / chosen / eligible) with their С-001
        # prefix + cabinet. «Ожидает назначения» leaves flow at awaiting_assignment
        # and mints nothing (reception refers later via /queue/refer-to-doctor).
        elif visit.flow_status == "waiting_doctor":
            new_ticket = issue_doctor_ticket(db, visit, actor, room=payload.room,
                                             audit_note=" at payment (направлен к врачу)")
            if new_ticket is not None:
                ticket_number = new_ticket.ticket_number
        # A NEW diagnostics ticket is minted only when the JOURNEY starts (flow
        # is waiting_diagnostic). Settling a later bill — e.g. a prescribed
        # surgery after the appointment — must never re-queue the patient to
        # diagnostics, even when no ticket is active anymore.
        elif visit.flow_status == "waiting_diagnostic":
            # Tag the ticket with the visit's diagnostic service (УЗИ, биометрия…)
            # so call-next routes it to the matching diagnostician. NULL when the
            # visit has no diagnostic service → open to any diagnostician.
            billed_service_ids = [it.service_id for it in visit.items if it.service_id is not None]
            diag_service_id = db.execute(
                select(Service.id).where(
                    Service.id.in_(billed_service_ids),
                    Service.is_diagnostic.is_(True),
                ).limit(1)
            ).scalar_one_or_none() if billed_service_ids else None
            ticket = QueueTicket(
                ticket_number=next_ticket_number(db, visit.branch_id, "D"),
                track="diagnostic",
                patient_id=visit.patient_id,
                branch_id=visit.branch_id,
                visit_id=visit.id,
                service_id=diag_service_id,
                room=payload.room,
                # Emergency intake jumps the queue: inherit the visit's priority
                # + reason so this ticket sorts to the top and flags «ЭКСТРЕННЫЙ».
                priority=visit.priority,
                priority_reason=visit.priority_reason,
            )
            db.add(ticket)
            db.flush()
            ticket_number = ticket.ticket_number
            record_audit(db, action="create", entity_type="queue_ticket", entity_id=ticket.id, actor_id=actor.id,
                         branch_id=visit.branch_id, summary=f"Issued queue ticket {ticket_number}")

    db.commit()
    db.refresh(payment)
    db.refresh(visit)
    return PaymentResult(
        payment=PaymentOut.model_validate(payment),
        visit_status=visit.status,
        visit_balance=visit.balance,
        queue_ticket_number=ticket_number,
        priority=visit.priority,
        priority_reason=visit.priority_reason,
    )


@router.get(
    "/{payment_id}/receipt.pdf",
    dependencies=[Depends(require_permission("payments.read"))],
    response_class=Response,
)
def receipt_pdf(payment_id: UUID, db: Annotated[Session, Depends(get_db)]) -> Response:
    """Printable receipt (чек) — services, total, discount, method, queue ticket,
    «ЭКСТРЕННЫЙ ПРИЕМ» flag and a QR of the visit."""
    payment = db.get(Payment, payment_id)
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Payment not found")
    visit = db.get(Visit, payment.visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    # The active queue ticket for the visit (the one shown on the чек).
    ticket = db.execute(
        select(QueueTicket.ticket_number)
        .where(QueueTicket.visit_id == visit.id, QueueTicket.status.in_(_ACTIVE_TICKET))
        .order_by(QueueTicket.created_at.desc()).limit(1)
    ).scalar_one_or_none()
    pdf = build_receipt_pdf(payment, visit, queue_ticket_number=ticket)
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="receipt-{payment.receipt_no}.pdf"'},
    )


@router.post("/{payment_id}/refund", response_model=PaymentOut)
def refund_payment(
    payment_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("payments.refund"))],
) -> Payment:
    payment = db.get(Payment, payment_id)
    if payment is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Payment not found")
    if payment.status == "refunded":
        raise HTTPException(status.HTTP_409_CONFLICT, "Payment already refunded")
    payment.status = "refunded"
    visit = db.get(Visit, payment.visit_id)
    if visit is not None:
        visit.paid_amount = Decimal(visit.paid_amount) - Decimal(payment.amount)
        if Decimal(visit.paid_amount) <= Decimal("0.00"):
            # Fully refunded — the patient leaves the flow: active queue
            # tickets must not stay on the TV board or auto-advance later.
            active = db.execute(
                select(QueueTicket).where(
                    QueueTicket.visit_id == visit.id,
                    QueueTicket.status.in_(_ACTIVE_TICKET),
                )
            ).scalars().all()
            for ticket in active:
                ticket.status = "skipped"
                record_audit(db, action="update", entity_type="queue_ticket", entity_id=ticket.id,
                             actor_id=actor.id, branch_id=visit.branch_id,
                             summary=f"Ticket {ticket.ticket_number} skipped after full refund")
    record_audit(db, action="refund", entity_type="payment", entity_id=payment.id, actor_id=actor.id,
                 branch_id=payment.branch_id, summary=f"Refunded payment {payment.receipt_no}")
    db.commit()
    db.refresh(payment)
    return payment
