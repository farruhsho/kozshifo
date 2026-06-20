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
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from typing import Annotated, Iterable, Sequence
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import Select, func, or_, select
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
from app.core.print_forms import build_payroll_detail_pdf
from app.models.branch import Branch
from app.models.finance import Expense, ExpenseCategory, RecurringExpense
from app.models.operation import Operation
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.user import User
from app.models.visit import Visit
from app.schemas.common import Message, Page
from app.schemas.finance import (
    MONTH_PATTERN,
    DailyReport,
    ExpenseCategoryCreate,
    ExpenseCategoryOut,
    ExpenseCategoryUpdate,
    ExpenseCreate,
    ExpenseOut,
    MonthlyReport,
    PayrollDetail,
    PayrollDetailDay,
    PayrollDetailOperation,
    PayrollDetailPatient,
    PayrollPayoutIn,
    PayrollRow,
    RecurringExpenseCreate,
    RecurringExpenseOut,
    RecurringExpensePostIn,
    RecurringExpenseStatus,
    RecurringExpenseUpdate,
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


def _local_date(dt: datetime) -> date:
    """Local calendar date of a stored (UTC) timestamp — matches the local
    day/month windows used elsewhere in this module."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone().date()


def _consult_pay(salary_type: str | None, value, revenue: Decimal) -> Decimal:
    """Consultation pay: percent of consult revenue, or a flat monthly sum."""
    if value is None:
        return Decimal("0.00")
    if salary_type == "percent":
        return _q2(revenue * Decimal(value) / 100)
    if salary_type == "fixed":
        return _q2(Decimal(value))
    return Decimal("0.00")


def _operation_pay(salary_type: str | None, value, revenue: Decimal, count: int) -> Decimal:
    """Operation pay: percent of operation revenue, or a fixed sum PER operation."""
    if value is None:
        return Decimal("0.00")
    if salary_type == "percent":
        return _q2(revenue * Decimal(value) / 100)
    if salary_type == "fixed":
        return _q2(Decimal(value) * count)
    return Decimal("0.00")


def _expense_out(expense: Expense, created_by_name: str | None) -> ExpenseOut:
    return ExpenseOut(
        id=expense.id,
        branch_id=expense.branch_id,
        category=expense.category,
        name=expense.name,
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
        (e.expense_date.isoformat(), e.category, e.name or "", str(Decimal(e.amount)), e.kind,
         e.payroll_month or "", e.note or "", created or "")
        for e, created in db.execute(_expense_rows(db, date_from, date_to, category)).all()
    ]
    return _csv_response(
        "expenses.csv",
        ("expense_date", "category", "name", "amount", "kind", "payroll_month", "note", "created_by"),
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
        name=payload.name,
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
# Expense types (rasxod turlari) — admin-managed catalog
# ════════════════════════════════════════════════════════════════════════════


@router.get("/expense-categories", response_model=list[ExpenseCategoryOut],
            dependencies=[Depends(require_permission("expenses.read"))])
def list_expense_categories(
    db: Annotated[Session, Depends(get_db)],
    active_only: bool = False,
) -> list[ExpenseCategoryOut]:
    stmt = select(ExpenseCategory)
    if active_only:
        stmt = stmt.where(ExpenseCategory.is_active.is_(True))
    rows = db.execute(stmt.order_by(ExpenseCategory.sort_order, ExpenseCategory.name)).scalars().all()
    return [ExpenseCategoryOut.model_validate(c) for c in rows]


@router.post("/expense-categories", response_model=ExpenseCategoryOut,
             status_code=status.HTTP_201_CREATED)
def create_expense_category(
    payload: ExpenseCategoryCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> ExpenseCategoryOut:
    name = payload.name.strip()
    if db.execute(select(ExpenseCategory).where(ExpenseCategory.name == name)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Expense type with this name already exists")
    category = ExpenseCategory(name=name, is_active=payload.is_active, sort_order=payload.sort_order)
    db.add(category)
    db.flush()
    record_audit(db, action="create", entity_type="expense_category", entity_id=category.id,
                 actor_id=actor.id, summary=f"Created expense type {name}")
    db.commit()
    db.refresh(category)
    return ExpenseCategoryOut.model_validate(category)


@router.patch("/expense-categories/{category_id}", response_model=ExpenseCategoryOut)
def update_expense_category(
    category_id: UUID,
    payload: ExpenseCategoryUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> ExpenseCategoryOut:
    category = db.get(ExpenseCategory, category_id)
    if category is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Expense type not found")
    data = payload.model_dump(exclude_unset=True)
    if "name" in data and data["name"] is not None:
        new_name = data["name"].strip()
        clash = db.execute(
            select(ExpenseCategory).where(ExpenseCategory.name == new_name, ExpenseCategory.id != category_id)
        ).scalar_one_or_none()
        if clash:
            raise HTTPException(status.HTTP_409_CONFLICT, "Expense type with this name already exists")
        data["name"] = new_name
    for field, value in data.items():
        if value is not None:
            setattr(category, field, value)
    record_audit(db, action="update", entity_type="expense_category", entity_id=category.id,
                 actor_id=actor.id, summary=f"Updated expense type {category.name}")
    db.commit()
    db.refresh(category)
    return ExpenseCategoryOut.model_validate(category)


@router.delete("/expense-categories/{category_id}", response_model=Message)
def delete_expense_category(
    category_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> Message:
    category = db.get(ExpenseCategory, category_id)
    if category is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Expense type not found")
    if category.is_system:
        # System types (e.g. «Зарплата») back payroll postings — never delete,
        # only deactivate.
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "System expense type cannot be deleted (deactivate it instead)")
    record_audit(db, action="delete", entity_type="expense_category", entity_id=category.id,
                 actor_id=actor.id, summary=f"Deleted expense type {category.name}")
    db.delete(category)
    db.commit()
    return Message(detail="Expense type deleted")


# ════════════════════════════════════════════════════════════════════════════
# Recurring (monthly) expenses — постоянные расходы (fixed or variable)
# ════════════════════════════════════════════════════════════════════════════


@router.get("/recurring-expenses", response_model=list[RecurringExpenseStatus],
            dependencies=[Depends(require_permission("expenses.read"))])
def list_recurring_expenses(
    db: Annotated[Session, Depends(get_db)],
    month: MonthParam | None = None,
) -> list[RecurringExpenseStatus]:
    """Active-first template list. When ``month`` is given, each row is tagged
    with whether it has already been booked (posted) for that month."""
    rows = db.execute(
        select(RecurringExpense).order_by(
            RecurringExpense.is_active.desc(), RecurringExpense.category, RecurringExpense.name
        )
    ).scalars().all()
    posted_amounts: dict[UUID, Decimal] = {}
    if month is not None:
        exp_start, exp_end = local_month_date_range(month)
        # A template is "posted" when a regular Expense with the same
        # category+name exists in that month (the marker written at post time).
        for e in db.execute(
            select(Expense).where(
                Expense.kind == "regular",
                Expense.expense_date >= exp_start,
                Expense.expense_date < exp_end,
            )
        ).scalars().all():
            for r in rows:
                if e.category == r.category and (e.name or "") == r.name:
                    posted_amounts[r.id] = _q2(Decimal(e.amount))
    return [
        RecurringExpenseStatus(
            id=r.id, category=r.category, name=r.name,
            amount=Decimal(r.amount) if r.amount is not None else None,
            is_fixed=r.is_fixed, is_active=r.is_active,
            posted=r.id in posted_amounts,
            posted_amount=posted_amounts.get(r.id),
        )
        for r in rows
    ]


@router.post("/recurring-expenses", response_model=RecurringExpenseOut,
             status_code=status.HTTP_201_CREATED)
def create_recurring_expense(
    payload: RecurringExpenseCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> RecurringExpenseOut:
    if payload.is_fixed and payload.amount is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "A fixed recurring expense needs an amount")
    recurring = RecurringExpense(
        category=payload.category.strip(),
        name=payload.name.strip(),
        amount=payload.amount,
        is_fixed=payload.is_fixed,
        is_active=payload.is_active,
        branch_id=actor.branch_id,
    )
    db.add(recurring)
    db.flush()
    record_audit(db, action="create", entity_type="recurring_expense", entity_id=recurring.id,
                 actor_id=actor.id, summary=f"Created recurring expense {recurring.name}")
    db.commit()
    db.refresh(recurring)
    return RecurringExpenseOut.model_validate(recurring)


@router.patch("/recurring-expenses/{recurring_id}", response_model=RecurringExpenseOut)
def update_recurring_expense(
    recurring_id: UUID,
    payload: RecurringExpenseUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> RecurringExpenseOut:
    recurring = db.get(RecurringExpense, recurring_id)
    if recurring is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Recurring expense not found")
    data = payload.model_dump(exclude_unset=True)
    for field in ("category", "name"):
        if field in data and data[field] is not None:
            data[field] = data[field].strip()
    for field, value in data.items():
        setattr(recurring, field, value)
    record_audit(db, action="update", entity_type="recurring_expense", entity_id=recurring.id,
                 actor_id=actor.id, summary=f"Updated recurring expense {recurring.name}")
    db.commit()
    db.refresh(recurring)
    return RecurringExpenseOut.model_validate(recurring)


@router.delete("/recurring-expenses/{recurring_id}", response_model=Message)
def delete_recurring_expense(
    recurring_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> Message:
    recurring = db.get(RecurringExpense, recurring_id)
    if recurring is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Recurring expense not found")
    record_audit(db, action="delete", entity_type="recurring_expense", entity_id=recurring.id,
                 actor_id=actor.id, summary=f"Deleted recurring expense {recurring.name}")
    db.delete(recurring)
    db.commit()
    return Message(detail="Recurring expense deleted")


@router.post("/recurring-expenses/{recurring_id}/post", response_model=ExpenseOut,
             status_code=status.HTTP_201_CREATED)
def post_recurring_expense(
    recurring_id: UUID,
    payload: RecurringExpensePostIn,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("expenses.manage"))],
) -> ExpenseOut:
    """Materialise a recurring template into a regular Expense for a month.

    Idempotent per (template, month): a second post for the same month returns
    409. Fixed templates use the template amount; variable ones require ``amount``.
    """
    recurring = db.get(RecurringExpense, recurring_id)
    if recurring is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Recurring expense not found")

    amount = payload.amount if payload.amount is not None else recurring.amount
    if amount is None or Decimal(amount) <= 0:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "Amount is required to post this recurring expense")

    exp_start, exp_end = local_month_date_range(payload.month)
    already = db.execute(
        select(Expense).where(
            Expense.kind == "regular",
            Expense.category == recurring.category,
            Expense.name == recurring.name,
            Expense.expense_date >= exp_start,
            Expense.expense_date < exp_end,
        ).limit(1)
    ).scalar_one_or_none()
    if already is not None:
        raise HTTPException(status.HTTP_409_CONFLICT,
                            f"Already posted for {payload.month}")

    branch_id = recurring.branch_id or actor.branch_id
    if branch_id is None:
        branch_id = db.execute(select(Branch.id).where(Branch.code == "MAIN")).scalar_one_or_none()
    if branch_id is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "No branch to book the expense against")

    # Book it on the first of the target month (a recurring expense is monthly).
    expense = Expense(
        branch_id=branch_id,
        category=recurring.category,
        name=recurring.name,
        amount=Decimal(amount),
        expense_date=exp_start,
        note=f"Постоянный расход за {payload.month}",
        created_by_id=actor.id,
        kind="regular",
    )
    db.add(expense)
    db.flush()
    record_audit(db, action="create", entity_type="expense", entity_id=expense.id, actor_id=actor.id,
                 branch_id=branch_id,
                 summary=f"Posted recurring expense {recurring.name} for {payload.month}")
    db.commit()
    db.refresh(expense)
    return _expense_out(expense, actor.full_name)


# ════════════════════════════════════════════════════════════════════════════
# Payroll — doctor gets % or fixed pay for consultations + operations
# ════════════════════════════════════════════════════════════════════════════


def _consult_revenue(db: Session, user_id: UUID, start: datetime, end: datetime) -> Decimal:
    """Completed payments in the window on visits where the user is the doctor."""
    return Decimal(db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0))
        .join(Visit, Visit.id == Payment.visit_id)
        .where(
            Payment.status == "completed",
            Payment.created_at >= start,
            Payment.created_at < end,
            Visit.doctor_id == user_id,
        )
    ).scalar_one())


def _operation_revenue(db: Session, user_id: UUID, start: datetime, end: datetime) -> tuple[Decimal, int]:
    """Revenue + count of operations the user performed (as surgeon) in the window."""
    count, revenue = db.execute(
        select(func.count(), func.coalesce(func.sum(Operation.price), 0)).where(
            Operation.status.in_(Operation.DONE_STATUSES),
            Operation.performed_at >= start,
            Operation.performed_at < end,
            Operation.surgeon_id == user_id,
        )
    ).one()
    return Decimal(revenue), int(count)


def _user_pay(db: Session, user: User, start: datetime, end: datetime) -> dict:
    """Full pay breakdown for one user over a window (the shared payroll maths)."""
    consult_revenue = _q2(_consult_revenue(db, user.id, start, end))
    operation_revenue_raw, operation_count = _operation_revenue(db, user.id, start, end)
    operation_revenue = _q2(operation_revenue_raw)
    consult_pay = _consult_pay(user.consult_salary_type, user.consult_salary_value, consult_revenue)
    operation_pay = _operation_pay(
        user.operation_salary_type, user.operation_salary_value, operation_revenue, operation_count
    )
    return {
        "consult_salary_type": user.consult_salary_type,
        "consult_salary_value": (Decimal(user.consult_salary_value)
                                 if user.consult_salary_value is not None else None),
        "consult_revenue": consult_revenue,
        "consult_pay": consult_pay,
        "operation_salary_type": user.operation_salary_type,
        "operation_salary_value": (Decimal(user.operation_salary_value)
                                   if user.operation_salary_value is not None else None),
        "operation_revenue": operation_revenue,
        "operation_count": operation_count,
        "operation_pay": operation_pay,
        "salary": _q2(consult_pay + operation_pay),
    }


def _payroll_rows(db: Session, month: str) -> list[PayrollRow]:
    start, end = _month_bounds(month)
    users = db.execute(
        select(User)
        .where(
            User.is_active.is_(True),
            or_(User.consult_salary_type.is_not(None), User.operation_salary_type.is_not(None)),
        )
        .order_by(User.full_name)
    ).scalars().all()
    payouts = {
        e.payroll_user_id: e
        for e in db.execute(
            select(Expense).where(Expense.kind == "payroll", Expense.payroll_month == month)
        ).scalars().all()
    }
    rows: list[PayrollRow] = []
    for user in users:
        pay = _user_pay(db, user, start, end)
        payout = payouts.get(user.id)
        rows.append(PayrollRow(
            user_id=user.id,
            full_name=user.full_name,
            paid=payout is not None,
            paid_at=payout.created_at if payout is not None else None,
            # The amount actually booked at payout time — may differ from the
            # live `salary` if revenue moved (new payments / a refund) after the
            # payout. Showing both makes a divergence visible instead of silent.
            paid_amount=_q2(payout.amount) if payout is not None else None,
            **pay,
        ))
    return rows


@router.get("/payroll", response_model=list[PayrollRow],
            dependencies=[Depends(require_permission("payroll.read"))])
def payroll(db: Annotated[Session, Depends(get_db)], month: MonthParam) -> list[PayrollRow]:
    return _payroll_rows(db, month)


@router.get("/payroll.csv", dependencies=[Depends(require_permission("payroll.read"))])
def export_payroll_csv(db: Annotated[Session, Depends(get_db)], month: MonthParam) -> Response:
    rows = [
        (str(r.user_id), r.full_name,
         r.consult_salary_type or "", str(r.consult_revenue), str(r.consult_pay),
         r.operation_salary_type or "", str(r.operation_revenue), str(r.operation_count),
         str(r.operation_pay), str(r.salary),
         "yes" if r.paid else "no", r.paid_at.isoformat() if r.paid_at else "")
        for r in _payroll_rows(db, month)
    ]
    return _csv_response(
        f"payroll-{month}.csv",
        ("user_id", "full_name", "consult_type", "consult_revenue", "consult_pay",
         "operation_type", "operation_revenue", "operation_count", "operation_pay",
         "salary", "paid", "paid_at"),
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
    if user.consult_salary_type is None and user.operation_salary_type is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "User has no salary configured")

    start, end = _month_bounds(payload.month)
    pay = _user_pay(db, user, start, end)
    salary = pay["salary"]
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

    note = (f"Оклад за {payload.month}: приём {pay['consult_pay']}"
            f" + операции {pay['operation_pay']}")
    expense = Expense(
        branch_id=branch_id,
        category="Зарплата",
        name=f"Зарплата · {user.full_name}",
        amount=salary,
        expense_date=business_today(),
        note=note,
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


def _payroll_detail(db: Session, user: User, month: str) -> PayrollDetail:
    """Per-day, per-patient salary breakdown for one doctor and month."""
    start, end = _month_bounds(month)
    pct = (Decimal(user.consult_salary_value)
           if user.consult_salary_type == "percent" and user.consult_salary_value is not None
           else None)

    # Consultation side — group completed payments by local day.
    pay_rows = db.execute(
        select(Payment.visit_id, Payment.amount, Payment.created_at, Patient)
        .join(Visit, Visit.id == Payment.visit_id)
        .join(Patient, Patient.id == Payment.patient_id)
        .where(
            Payment.status == "completed",
            Payment.created_at >= start,
            Payment.created_at < end,
            Visit.doctor_id == user.id,
        )
        .order_by(Payment.created_at)
    ).all()
    by_day: dict[date, list[PayrollDetailPatient]] = {}
    for visit_id, amount, created_at, patient in pay_rows:
        amt = _q2(amount)
        share = _q2(amt * pct / 100) if pct is not None else Decimal("0.00")
        by_day.setdefault(_local_date(created_at), []).append(
            PayrollDetailPatient(visit_id=visit_id, patient_name=patient.full_name,
                                 amount=amt, share=share)
        )
    days = [
        PayrollDetailDay(
            date=d,
            patients=patients,
            revenue=_q2(sum((p.amount for p in patients), Decimal("0.00"))),
            share=_q2(sum((p.share for p in patients), Decimal("0.00"))),
        )
        for d, patients in sorted(by_day.items())
    ]

    # Operation side — one row per performed operation by this surgeon.
    op_pct = (Decimal(user.operation_salary_value)
              if user.operation_salary_type == "percent" and user.operation_salary_value is not None
              else None)
    op_fixed = (Decimal(user.operation_salary_value)
                if user.operation_salary_type == "fixed" and user.operation_salary_value is not None
                else None)
    ops = db.execute(
        select(Operation).where(
            Operation.status.in_(Operation.DONE_STATUSES),
            Operation.performed_at >= start,
            Operation.performed_at < end,
            Operation.surgeon_id == user.id,
        ).order_by(Operation.performed_at)
    ).scalars().all()
    operations: list[PayrollDetailOperation] = []
    for op in ops:
        price = _q2(op.price or 0)
        if op_pct is not None:
            op_share = _q2(price * op_pct / 100)
        elif op_fixed is not None:
            op_share = _q2(op_fixed)
        else:
            op_share = Decimal("0.00")
        operations.append(PayrollDetailOperation(
            date=_local_date(op.performed_at) if op.performed_at else business_today(),
            patient_name=op.patient_name,
            type_name=op.type_name,
            price=price,
            share=op_share,
        ))

    pay = _user_pay(db, user, start, end)
    return PayrollDetail(
        user_id=user.id,
        full_name=user.full_name,
        month=month,
        days=days,
        operations=operations,
        **{k: pay[k] for k in (
            "consult_salary_type", "consult_salary_value", "operation_salary_type",
            "operation_salary_value", "consult_revenue", "consult_pay",
            "operation_revenue", "operation_count", "operation_pay", "salary",
        )},
    )


@router.get("/payroll/{user_id}/detail", response_model=PayrollDetail,
            dependencies=[Depends(require_permission("payroll.read"))])
def payroll_detail(
    user_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    month: MonthParam,
) -> PayrollDetail:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    return _payroll_detail(db, user, month)


@router.get("/payroll/{user_id}/detail.pdf",
            dependencies=[Depends(require_permission("payroll.read"))],
            response_class=Response)
def payroll_detail_pdf(
    user_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    month: MonthParam,
) -> Response:
    """Printable per-day / per-patient salary detalizatsiya (the TZ example)."""
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    detail = _payroll_detail(db, user, month)
    pdf = build_payroll_detail_pdf(detail)
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="payroll-{user_id}-{month}.pdf"'},
    )


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
    # payroll_total ISOLATES salary spend — that's behind the payroll.read wall.
    # The cash report is reachable with only expenses.read (Reception runs the
    # till), so a non-payroll actor gets the figure as null, not a back door.
    can_payroll = actor.is_superuser or "payroll.read" in actor.effective_permission_codes()
    payroll_total: Decimal | None = None
    if can_payroll:
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
