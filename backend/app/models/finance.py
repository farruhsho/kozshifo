"""Clinic expenses — rashodlar (TZ Modul 8).

Every outflow is one Expense row; payroll payouts are expenses too
(kind="payroll") so the cash balance maths stays one query. A payroll payout
is idempotent per (employee, month) via the unique constraint.
"""
from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import Boolean, Date, ForeignKey, Integer, Numeric, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class ExpenseCategory(UUIDPKMixin, TimestampMixin, Base):
    """Admin-managed expense type (rasxod turi). The director maintains the list;
    the expense form picks an active type from here. `is_system` types (e.g.
    «Зарплата») are protected from deletion — they can only be deactivated."""

    __tablename__ = "expense_categories"

    name: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_system: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class RecurringExpense(UUIDPKMixin, TimestampMixin, Base):
    """Template for a monthly recurring expense (постоянный расход).

    `is_fixed=True` → the same `amount` every month (rent, salaries); the
    director just "posts" it. `is_fixed=False` → the amount is entered at
    post time (utilities that vary). Posting materialises an `Expense` row.
    """

    __tablename__ = "recurring_expenses"

    category: Mapped[str] = mapped_column(String(64), nullable=False)
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    amount: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    is_fixed: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), nullable=True
    )


class Expense(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "expenses"
    __table_args__ = (
        UniqueConstraint("payroll_user_id", "payroll_month", name="uq_expense_payroll_user_month"),
    )

    branch_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    category: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    # Specific expense name (rasxod nomi), separate from the category/type.
    name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    expense_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    note: Mapped[str | None] = mapped_column(String(512), nullable=True)
    created_by_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    kind: Mapped[str] = mapped_column(String(16), default="regular", nullable=False)  # regular|payroll
    payroll_user_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    payroll_month: Mapped[str | None] = mapped_column(String(7), nullable=True)  # YYYY-MM

    payroll_user: Mapped["User | None"] = relationship(  # noqa: F821
        foreign_keys=[payroll_user_id], lazy="joined"
    )
