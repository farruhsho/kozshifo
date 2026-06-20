"""Finance DTOs (TZ Modul 8): expenses, percent-based payroll, cash reports."""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

# Calendar month on the wire: "YYYY-MM" (payroll period / monthly report key).
MONTH_PATTERN = r"^\d{4}-(0[1-9]|1[0-2])$"


class ExpenseCreate(BaseModel):
    category: str = Field(max_length=64)
    name: str | None = Field(default=None, max_length=128)  # rasxod nomi
    amount: Decimal = Field(gt=0)
    expense_date: date
    note: str | None = Field(default=None, max_length=512)
    # Defaults to the current user's branch (400 if neither is set).
    branch_id: UUID | None = None

    @field_validator("category")
    @classmethod
    def _category_not_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("category must not be blank")
        return value


class ExpenseOut(BaseModel):
    id: UUID
    branch_id: UUID
    category: str
    name: str | None = None
    amount: Decimal
    expense_date: date
    note: str | None
    kind: str  # regular | payroll
    payroll_user_id: UUID | None
    payroll_month: str | None
    created_by_name: str | None
    created_at: datetime


# ── Expense types (admin-managed) ───────────────────────────────────────────


class ExpenseCategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    is_active: bool
    is_system: bool
    sort_order: int


class ExpenseCategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=64)
    is_active: bool = True
    sort_order: int = 0


class ExpenseCategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=64)
    is_active: bool | None = None
    sort_order: int | None = None


# ── Recurring (monthly) expenses ────────────────────────────────────────────


class RecurringExpenseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    category: str
    name: str
    amount: Decimal | None
    is_fixed: bool
    is_active: bool


class RecurringExpenseCreate(BaseModel):
    category: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=128)
    amount: Decimal | None = Field(default=None, ge=0)
    is_fixed: bool = True
    is_active: bool = True


class RecurringExpenseUpdate(BaseModel):
    category: str | None = Field(default=None, min_length=1, max_length=64)
    name: str | None = Field(default=None, min_length=1, max_length=128)
    amount: Decimal | None = Field(default=None, ge=0)
    is_fixed: bool | None = None
    is_active: bool | None = None


class RecurringExpensePostIn(BaseModel):
    """Materialise a recurring template into an Expense for a month.

    For a variable (is_fixed=False) template the amount is required here; for a
    fixed template it is optional (defaults to the template amount).
    """

    month: str = Field(pattern=MONTH_PATTERN)
    amount: Decimal | None = Field(default=None, gt=0)


class RecurringExpenseStatus(RecurringExpenseOut):
    """A recurring template plus whether it is already booked for a given month."""

    posted: bool
    posted_amount: Decimal | None


class PayrollRow(BaseModel):
    """One eligible employee's payroll line for a month, with the consult +
    operation breakdown (see app/features/finance.py for the maths)."""

    user_id: UUID
    full_name: str
    # Consultation side
    consult_salary_type: str | None  # percent | fixed | None
    consult_salary_value: Decimal | None
    consult_revenue: Decimal  # completed consult payments on the doctor's visits
    consult_pay: Decimal
    # Operation side (performed as surgeon)
    operation_salary_type: str | None
    operation_salary_value: Decimal | None
    operation_revenue: Decimal
    operation_count: int
    operation_pay: Decimal
    # Total + payout state
    salary: Decimal  # consult_pay + operation_pay (live, recomputed)
    paid: bool  # a payout Expense(kind="payroll") exists for this month
    paid_at: datetime | None
    paid_amount: Decimal | None  # amount actually booked at payout (frozen); None if unpaid


# ── Payroll detail (per-day, per-patient breakdown for printing) ────────────


class PayrollDetailPatient(BaseModel):
    visit_id: UUID
    patient_name: str
    amount: Decimal  # what the patient paid on this visit (in the period)
    share: Decimal  # the doctor's cut of it (0 for fixed-type pay)


class PayrollDetailDay(BaseModel):
    date: date
    patients: list[PayrollDetailPatient]
    revenue: Decimal  # sum of patient amounts for the day
    share: Decimal  # sum of doctor shares for the day


class PayrollDetailOperation(BaseModel):
    date: date
    patient_name: str
    type_name: str
    price: Decimal
    share: Decimal


class PayrollDetail(BaseModel):
    user_id: UUID
    full_name: str
    month: str
    consult_salary_type: str | None
    consult_salary_value: Decimal | None
    operation_salary_type: str | None
    operation_salary_value: Decimal | None
    days: list[PayrollDetailDay]
    operations: list[PayrollDetailOperation]
    consult_revenue: Decimal
    consult_pay: Decimal
    operation_revenue: Decimal
    operation_count: int
    operation_pay: Decimal
    salary: Decimal


class PayrollPayoutIn(BaseModel):
    user_id: UUID
    month: str = Field(pattern=MONTH_PATTERN)


class CashReport(BaseModel):
    """Cash-flow aggregate over one day or one month.

    `income_by_method` always carries the four canonical buckets
    (cash / card / qr / transfer), zero-filled.
    net = income_total - refund_total - expense_total.
    """

    income_by_method: dict[str, Decimal]
    income_total: Decimal
    refund_total: Decimal
    expense_total: Decimal
    net: Decimal


class DailyReport(CashReport):
    date: date


class MonthlyReport(CashReport):
    month: str
    # Isolated payroll spend (subset of expense_total). NULL for callers without
    # payroll.read — the cash report itself only needs expenses.read, but the
    # salary figure stays behind the payroll wall.
    payroll_total: Decimal | None
