"""Debt management (owner brief 2026-06-20): «Управление задолженностями».

Debt is a VIEW over the existing data, not a parallel ledger:
- a debtor = a patient with OPEN visits whose payable > paid_amount;
- the amount owed is always the live `Visit.balance` (no stored copy to drift);
- repayment (incl. PARTIAL) reuses POST /payments — one payment path, one audit;
- payment history (date / sum / cashier / comment) comes from the Payment rows.

Endpoints (all read-only here): GET /debts (debtors, highest first — also feeds the
dashboard TOP-debtors card via a small limit) and GET /debts/patient/{id} (one
patient's owing visits + full payment history).
"""
from __future__ import annotations

from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.user import User
from app.models.visit import Visit
from app.schemas.debt import (
    DebtorRow,
    DebtPaymentRow,
    DebtVisitRow,
    PatientDebtDetail,
)

router = APIRouter(prefix="/debts", tags=["Debts"])


def _payable_expr():
    """SQL payable = total − discount (mirrors Visit.payable / the /visits owing
    filter) so the DB pre-filter matches the Python balance exactly."""
    discount = case(
        (Visit.discount_percent.is_not(None),
         func.round(Visit.total_amount * Visit.discount_percent / 100, 2)),
        (Visit.discount_amount.is_not(None),
         case((Visit.discount_amount > Visit.total_amount, Visit.total_amount),
              else_=Visit.discount_amount)),
        else_=0,
    )
    return Visit.total_amount - discount


@router.get("", response_model=list[DebtorRow],
            dependencies=[Depends(require_permission("debts.read"))])
def list_debtors(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("debts.read"))],
    limit: int = Query(100, ge=1, le=500, description="dashboard TOP-debtors uses a small limit"),
    branch_id: UUID | None = None,
) -> list[DebtorRow]:
    """Debtors (patients with open visits owing money), highest total first."""
    stmt = select(Visit).where(Visit.status == "open", _payable_expr() > Visit.paid_amount)
    if branch_id is not None:
        stmt = stmt.where(Visit.branch_id == branch_id)
    elif not actor.is_superuser and actor.branch_id is not None:
        stmt = stmt.where(Visit.branch_id == actor.branch_id)
    visits = db.execute(stmt).scalars().all()

    agg: dict[UUID, dict] = {}
    for v in visits:
        bal = v.balance
        if bal <= 0:  # belt-and-suspenders vs the SQL pre-filter
            continue
        a = agg.get(v.patient_id)
        if a is None:
            a = {"patient": v.patient, "total": Decimal("0.00"),
                 "count": 0, "oldest": v.opened_at}
            agg[v.patient_id] = a
        a["total"] += bal
        a["count"] += 1
        if v.opened_at < a["oldest"]:
            a["oldest"] = v.opened_at
    if not agg:
        return []

    last_pay = dict(db.execute(
        select(Payment.patient_id, func.max(Payment.created_at))
        .where(Payment.patient_id.in_(agg.keys()))
        .group_by(Payment.patient_id)
    ).all())

    rows = [
        DebtorRow(
            patient_id=pid,
            patient_name=a["patient"].full_name,
            phone=a["patient"].phone,
            patient_no=getattr(a["patient"], "patient_no", None),
            total_debt=a["total"],
            visit_count=a["count"],
            oldest_debt_at=a["oldest"],
            last_payment_at=last_pay.get(pid),
        )
        for pid, a in agg.items()
    ]
    rows.sort(key=lambda r: r.total_debt, reverse=True)
    return rows[:limit]


@router.get("/patient/{patient_id}", response_model=PatientDebtDetail,
            dependencies=[Depends(require_permission("debts.read"))])
def patient_debt(
    patient_id: UUID,
    db: Annotated[Session, Depends(get_db)],
) -> PatientDebtDetail:
    """One patient's owing visits (amount/date/services/remaining) + the full
    payment history (date/sum/cashier/comment) — partial repayment via /payments."""
    patient = db.get(Patient, patient_id)
    if patient is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")

    owing = db.execute(
        select(Visit).where(
            Visit.patient_id == patient_id,
            Visit.status == "open",
            _payable_expr() > Visit.paid_amount,
        ).order_by(Visit.opened_at)
    ).scalars().all()

    total = Decimal("0.00")
    visit_rows: list[DebtVisitRow] = []
    for v in owing:
        remaining = v.balance
        total += remaining
        services = ", ".join(i.service_name for i in v.items) or "—"
        visit_rows.append(DebtVisitRow(
            visit_id=v.id, visit_no=v.visit_no, opened_at=v.opened_at,
            payable=v.payable, paid=Decimal(v.paid_amount), remaining=remaining,
            services=services, flow_status=v.flow_status,
        ))

    pay_rows = db.execute(
        select(Payment, Visit.visit_no, User.full_name)
        .join(Visit, Payment.visit_id == Visit.id)
        .outerjoin(User, Payment.cashier_id == User.id)
        .where(Payment.patient_id == patient_id)
        .order_by(Payment.created_at.desc())
        .limit(200)
    ).all()
    payments = [
        DebtPaymentRow(
            paid_at=p.created_at, amount=p.amount, method=p.method,
            cashier_name=cashier, note=p.note, visit_no=vno, status=p.status,
        )
        for p, vno, cashier in pay_rows
    ]

    return PatientDebtDetail(
        patient_id=patient.id, patient_name=patient.full_name,
        phone=patient.phone, total_debt=total,
        visits=visit_rows, payments=payments,
    )
