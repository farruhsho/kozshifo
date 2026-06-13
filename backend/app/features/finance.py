"""Finance (TZ Modul 8): clinic expenses, percent-based payroll, cash reports.

Money semantics mirror app/features/payments.py exactly:

* A refund is a STATUS FLIP on the original Payment row (completed ->
  refunded) — there are no negative payment rows. Hence, per period:
  - income          = payments CREATED in the period, ANY status (the cash
    physically entered the till when the row was created);
  - refund_total    = refunded payments whose ``updated_at`` falls in the
    period — the refund flip is the only mutation a payment ever receives,
    so updated_at IS the refund moment;
  - a same-day payment+refund therefore nets to zero, while a later refund
    is booked on the day the cash actually left the till.
* Payroll revenue counts status="completed" only: the refund flip removes a
  refunded payment from the doctor's revenue automatically — no separate
  subtraction is needed.

Period boundaries are the clinic's LOCAL day/month: payment timestamps (UTC)
are filtered by the local window converted to UTC instants, and expense rows
(a plain local business DATE) by the matching calendar-date window — so a day's
takings reconcile with that day's expenses. The director dashboard uses the
same local boundaries, so its revenue KPIs and these cash reports agree.

Cash reports are branch-scoped to the actor: a non-superuser sees only their
own branch; the director (superuser) sees the whole clinic.

Payroll payouts are Expense rows too (kind="payroll"), so the cash balance
stays one query; the (payroll_user_id, payroll_month) unique constraint makes
a payout idempotent — a second attempt returns 409.
"""
from __future__ import annotations

import csv
import io
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Annotated, Iterable, Sequence
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import Select, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.dates import (
    business_today,
    current_business_month,
    local_day_bounds_utc,
    local_month_bounds_utc,
    local_month_date_range,
)
from app.core.deps import CurrentUser, require_permission
from app.models.branch import Branch
from app.models.finance import Expense
from app.models.payment import Payment
from app.models.user import User
from app.models.visit import Visit
from app.schemas.common import Message, Page
from app.schemas.finance import (
    MONTH_PATTERN,
    DailyReport,
    ExpenseCreate,
    ExpenseOut,
    MonthlyReport,
    PayrollPayoutIn,
    PayrollRow,
)

router = APIRouter(prefix="/finance", tags=["finance"])

_TWO_PLACES = Decimal("0.01")
_METHODS = ("cash", "card", "qr", "transfer")

MonthParam = Annotated[str, Query(pattern=MONTH_PATTERN)]


def _q2(value) -> Decimal:
    return Decimal(value).quantize(_TWO_PLACES)


# Payment timestamps are UTC; a clinic day/month is local. Convert the local
# calendar window to its UTC instant window so a day's takings reconcile with
# that day's expenses (which are filtered on a local DATE).
def _day_bounds(d: date) -> tuple[datetime, datetime]:
    return local_day_bounds_utc(d)


def _month_bounds(month: str) -> tuple[datetime, datetime]:
    return local_month_bounds_utc(month)


def _expense_out(expense: Expense, created_by_name: str | None) -> ExpenseOut:
    return ExpenseOut(
        id=expense.id,
        branch_id=expense.branch_id,
        category=expense.category,
        amount=Decimal(expense.amount),
        expense_date=expense.expense_date,
        note=expense.note,
        kind=expense.kind,
        payroll_user_id=expense.payroll_user_id,
        payroll_month=expense.payroll_month,
        created_by_name=created_by_name,
        created_at=expense.created_at,
    )


def _csv_response(filename: str, header: Sequence[str], rows: Iterable[Sequence]) -> Response:
    """UTF-8 CSV with a BOM so Excel opens Cyrillic columns correctly."""
    buf = io.StringIO()
    writer = csv.writer(buf, lineterminator="\r\n")
    writer.writerow(header)
    writer.writerows(rows)
    return Response(
        content="\ufeff" + buf.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


# ════════════════════════════════════════════════════════════════════════════
# Expenses (rashod)
# ════════════════════════════════════════════════════════════════════════════


def _expense_filters(
    stmt: Select,
    date_from: date | None,
    date_to: date | None,
    category: str | None,
) -> Select:
    if date_from is not None:
        stmt = stmt.where(Expense.expense_date >= date_from)
    if date_to is not None:
        stmt = stmt.where(Expense.expense_date <= date_to)
    if category:
        stmt = stmt.where(Expense.category == category)
    return stmt


def _expense_rows(
    db: Session,
    date_from: date | None,
    date_to: date | None,
    category: str | None,
) -> Select:
    """Filtered (Expense, created_by full name) select, newest first."""
    return _expense_filters(
        select(Expense, User.full_name).outerjoin(User, User.id == Expense.created_by_id),
        date_from, date_to, category,
    ).order_by(Expense.expense_date.desc(), Expense.created_at.desc())


@router.get("/expenses", response_model=Page[ExpenseOut],
            dependencies=[Depends(require_permission("expenses.read"))])
def list_expenses(
    db: Annotated[Session, Depends(get_db)],
    date_from: date | None = None,
    date_to: date | None = None,
    category: str | None = None,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[ExpenseOut]:
    total = db.execute(
        _expense_filters(select(func.count()).select_from(Expense), date_from, date_to, category)
    ).scalar_one()
    rows = db.execute(_expense_rows(db, date_from, date_to, category).offset(offset).limit(limit)).all()
    return Page(items=[_expense_out(e, name) for e, name in rows], total=total, offset=offset, limit=limit)


@router.get("/expenses.csv", dependencies=[Depends(require_permission("expenses.read"))])
def export_expenses_csv(
    db: Annotated[Session, Depends(get_db)],
    date_from: date | None = None,
    date_to: date | None = None,
    category: str | None = None,
) -> Response:
    rows = [
        (e.expense_date.isoformat(), e.category, str(Decimal(e.amount)), e.kind,
         e.payroll_month or "", e.note or "", name or "")
        for e, name in db.execute(_expense_rows(db, date_from, date_to, category)).all()
    ]
    return _csv_response(
        "expenses.csv",
        ("expense_date", "category", "amount", "kind", "payroll_month", "note", "created_by"),
        rows,
    )


@router.post("/expenses", response_model=ExpenseOut, status_code=status.HTTP_201_CREATED)
def create_expense(
    payload: ExpenseCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> ExpenseOut:
    branch_id = payload.branch_id or actor.branch_id
    if branch_id is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            "branch_id is required (current user has no branch)")
    if db.get(Branch, branch_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Branch not found")

    expense = Expense(
        branch_id=branch_id,
        category=payload.category,
        amount=payload.amount,
        expense_date=payload.expense_date,
        note=payload.note,
        created_by_id=actor.id,
        kind="regular",
    )
    db.add(expense)
    db.flush()
    record_audit(db, action="create", entity_type="expense", entity_id=expense.id, actor_id=actor.id,
                 branch_id=branch_id, summary=f"Expense {payload.amount} ({payload.category})")
    db.commit()
    db.refresh(expense)
    return _expense_out(expense, actor.full_name)


@router.delete("/expenses/{expense_id}", response_model=Message)
def delete_expense(
    expense_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> Message:
    expense = db.get(Expense, expense_id)
    if expense is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Expense not found")
    if expense.kind != "regular":
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Payroll expenses cannot be deleted via the expense API")
    # Snapshot into the audit row — the expense itself is gone after this.
    snapshot = {
        "branch_id": str(expense.branch_id),
        "category": expense.category,
        "amount": str(expense.amount),
        "expense_date": expense.expense_date.isoformat(),
        "note": expense.note,
        "kind": expense.kind,
    }
    record_audit(db, action="delete", entity_type="expense", entity_id=expense.id, actor_id=actor.id,
                 branch_id=expense.branch_id, changes=snapshot,
                 summary=f"Deleted expense {expense.amount} ({expense.category})")
    db.delete(expense)
    db.commit()
    return Message(detail="Expense deleted")


# ════════════════════════════════════════════════════════════════════════════
# Payroll — doctor gets a % of completed-payment revenue from their visits
# ════════════════════════════════════════════════════════════════════════════


def _payroll_rows(db: Session, month: str) -> list[PayrollRow]:
    start, end = _month_bounds(month)
    users = db.execute(
        select(User)
        .where(User.is_active.is_(True), User.salary_percent.is_not(None))
        .order_by(User.full_name)
    ).scalars().all()
    revenue_by_doctor = {
        doctor_id: Decimal(total)
        for doctor_id, total in db.execute(
            select(Visit.doctor_id, func.sum(Payment.amount))
            .join(Visit, Visit.id == Payment.visit_id)
            .where(
                Payment.status == "completed",
                Payment.created_at >= start,
                Payment.created_at < end,
                Visit.doctor_id.is_not(None),
            )
            .group_by(Visit.doctor_id)
        ).all()
    }
    payouts = {
        e.payroll_user_id: e
        for e in db.execute(
            select(Expense).where(Expense.kind == "payroll", Expense.payroll_month == month)
        ).scalars().all()
    }
    rows: list[PayrollRow] = []
    for user in users:
        revenue = _q2(revenue_by_doctor.get(user.id, 0))
        percent = Decimal(user.salary_percent)
        payout = payouts.get(user.id)
        rows.append(PayrollRow(
            user_id=user.id,
            full_name=user.full_name,
            salary_percent=percent,
            revenue=revenue,
            salary=_q2(revenue * percent / 100),
            paid=payout is not None,
            paid_at=payout.created_at if payout is not None else None,
            # The amount actually booked at payout time — may differ from the
            # live `salary` if revenue moved (new payments / a refund) after the
            # payout. Showing both makes a divergence visible instead of silent.
            paid_amount=_q2(payout.amount) if payout is not None else None,
        ))
    return rows


@router.get("/payroll", response_model=list[PayrollRow],
            dependencies=[Depends(require_permission("payroll.read"))])
def payroll(db: Annotated[Session, Depends(get_db)], month: MonthParam) -> list[PayrollRow]:
    return _payroll_rows(db, month)


@router.get("/payroll.csv", dependencies=[Depends(require_permission("payroll.read"))])
def export_payroll_csv(db: Annotated[Session, Depends(get_db)], month: MonthParam) -> Response:
    rows = [
        (str(r.user_id), r.full_name, str(r.salary_percent), str(r.revenue), str(r.salary),
         "yes" if r.paid else "no", r.paid_at.isoformat() if r.paid_at else "")
        for r in _payroll_rows(db, month)
    ]
    return _csv_response(
        f"payroll-{month}.csv",
        ("user_id", "full_name", "salary_percent", "revenue", "salary", "paid", "paid_at"),
        rows,
    )


@router.post("/payroll/payout", response_model=ExpenseOut, status_code=status.HTTP_201_CREATED)
def payroll_payout(
    payload: PayrollPayoutIn,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("payroll.manage"))],
) -> ExpenseOut:
    # Only pay out a CLOSED month: revenue keeps growing until month-end, so a
    # mid-month payout would freeze salary at revenue-so-far and (being capped
    # by the unique constraint) leave the remainder unpayable. Corrections to a
    # closed month go through /payroll/void → re-payout.
    if payload.month >= current_business_month():
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Month is not closed yet — payroll can only be paid out for a finished month",
        )

    user = db.get(User, payload.user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if user.salary_percent is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "User has no salary_percent configured")

    start, end = _month_bounds(payload.month)
    revenue = Decimal(db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0))
        .join(Visit, Visit.id == Payment.visit_id)
        .where(
            Payment.status == "completed",
            Payment.created_at >= start,
            Payment.created_at < end,
            Visit.doctor_id == user.id,
        )
    ).scalar_one())
    percent = Decimal(user.salary_percent)
    salary = _q2(revenue * percent / 100)
    if salary <= 0:
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            f"No payable salary for {payload.month}")

    branch_id = user.branch_id
    if branch_id is None:  # fall back to the main (earliest-seeded) branch
        branch_id = db.execute(select(Branch.id).where(Branch.code == "MAIN")).scalar_one_or_none()
    if branch_id is None:
        branch_id = db.execute(
            select(Branch.id).order_by(Branch.created_at).limit(1)
        ).scalar_one_or_none()
    if branch_id is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "No branch to book the payout against")

    expense = Expense(
        branch_id=branch_id,
        category="Зарплата",
        amount=salary,
        expense_date=business_today(),
        note=f"Оклад {percent:g}% за {payload.month}",
        created_by_id=actor.id,
        kind="payroll",
        payroll_user_id=user.id,
        payroll_month=payload.month,
    )
    db.add(expense)
    try:
        # The unique constraint (payroll_user_id, payroll_month) is the
        # idempotency guard — no racy pre-check.
        db.flush()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Payroll for {payload.month} is already paid out") from None
    record_audit(db, action="payout", entity_type="expense", entity_id=expense.id, actor_id=actor.id,
                 branch_id=branch_id,
                 summary=f"Payroll payout {salary} to {user.full_name} for {payload.month}")
    db.commit()
    db.refresh(expense)
    return _expense_out(expense, actor.full_name)


@router.post("/payroll/void", response_model=Message)
def payroll_void(
    payload: PayrollPayoutIn,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("payroll.manage"))],
) -> Message:
    """Reverse a payroll payout so it can be corrected and re-issued.

    The unique (user, month) constraint makes a payout idempotent; this is the
    only way to undo a wrong one (e.g. paid before a refund landed) — it deletes
    the payroll Expense, freeing the slot for a fresh payout. Audited with the
    voided snapshot.
    """
    expense = db.execute(
        select(Expense).where(
            Expense.kind == "payroll",
            Expense.payroll_user_id == payload.user_id,
            Expense.payroll_month == payload.month,
        )
    ).scalar_one_or_none()
    if expense is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND,
                            f"No payroll payout found for {payload.month}")
    snapshot = {
        "payroll_user_id": str(expense.payroll_user_id),
        "payroll_month": expense.payroll_month,
        "amount": str(expense.amount),
        "expense_date": expense.expense_date.isoformat(),
    }
    record_audit(db, action="payout_void", entity_type="expense", entity_id=expense.id,
                 actor_id=actor.id, branch_id=expense.branch_id, changes=snapshot,
                 summary=f"Voided payroll payout {expense.amount} for {payload.month}")
    db.delete(expense)
    db.commit()
    return Message(detail="Payroll payout voided")


# ════════════════════════════════════════════════════════════════════════════
# Cash reports (daily / monthly) — income by method, refunds, expenses, net
# ════════════════════════════════════════════════════════════════════════════


def _cash_flow(
    db: Session,
    pay_start: datetime,
    pay_end: datetime,
    exp_start: date,
    exp_end: date,
    branch_id: UUID | None = None,
) -> dict:
    """Shared aggregate: see the module docstring for the refund semantics.

    ``branch_id`` scopes both income and expenses to one branch (None = whole
    clinic, for the director).
    """
    pay_window = [Payment.created_at >= pay_start, Payment.created_at < pay_end]
    if branch_id is not None:
        pay_window.append(Payment.branch_id == branch_id)
    income_by_method = {m: Decimal("0.00") for m in _METHODS}
    for method, total in db.execute(
        select(Payment.method, func.sum(Payment.amount))
        .where(*pay_window)
        .group_by(Payment.method)
    ).all():
        income_by_method[method] = _q2(total)
    income_total = _q2(sum(income_by_method.values()))
    refund_window = [
        Payment.status == "refunded",
        Payment.updated_at >= pay_start,
        Payment.updated_at < pay_end,
    ]
    if branch_id is not None:
        refund_window.append(Payment.branch_id == branch_id)
    refund_total = _q2(db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0)).where(*refund_window)
    ).scalar_one())
    exp_window = [Expense.expense_date >= exp_start, Expense.expense_date < exp_end]
    if branch_id is not None:
        exp_window.append(Expense.branch_id == branch_id)
    expense_total = _q2(db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(*exp_window)
    ).scalar_one())
    return {
        "income_by_method": income_by_method,
        "income_total": income_total,
        "refund_total": refund_total,
        "expense_total": expense_total,
        "net": income_total - refund_total - expense_total,
    }


def _scope_branch(actor: CurrentUser) -> UUID | None:
    """Branch a non-superuser is locked to (None = whole clinic, for the director)."""
    return None if actor.is_superuser else actor.branch_id


def _daily_report(db: Session, d: date, branch_id: UUID | None = None) -> DailyReport:
    start, end = _day_bounds(d)
    return DailyReport(date=d, **_cash_flow(db, start, end, d, d + timedelta(days=1), branch_id))


@router.get("/reports/daily", response_model=DailyReport)
def daily_report(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.read"))],
    d: date,
) -> DailyReport:
    return _daily_report(db, d, _scope_branch(actor))


@router.get("/reports/daily.csv")
def export_daily_report_csv(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.read"))],
    d: date,
) -> Response:
    report = _daily_report(db, d, _scope_branch(actor))
    return _csv_response(
        f"daily-{d.isoformat()}.csv",
        ("date", "income_cash", "income_card", "income_qr", "income_transfer",
         "income_total", "refund_total", "expense_total", "net"),
        [(
            d.isoformat(),
            *(str(report.income_by_method[m]) for m in _METHODS),
            str(report.income_total), str(report.refund_total),
            str(report.expense_total), str(report.net),
        )],
    )


@router.get("/reports/monthly", response_model=MonthlyReport)
def monthly_report(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.read"))],
    month: MonthParam,
) -> MonthlyReport:
    branch_id = _scope_branch(actor)
    start, end = _month_bounds(month)  # UTC instants for Payment timestamps
    # Expenses carry a local business DATE; derive the DATE window from the
    # calendar month directly (NOT start.date()/end.date(), which shift a day on
    # non-UTC hosts) so the expense side reconciles with the income side.
    exp_start, exp_end = local_month_date_range(month)
    flow = _cash_flow(db, start, end, exp_start, exp_end, branch_id)
    payroll_window = [
        Expense.kind == "payroll",
        Expense.expense_date >= exp_start,
        Expense.expense_date < exp_end,
    ]
    if branch_id is not None:
        payroll_window.append(Expense.branch_id == branch_id)
    payroll_total = _q2(db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(*payroll_window)
    ).scalar_one())
    return MonthlyReport(month=month, payroll_total=payroll_total, **flow)
