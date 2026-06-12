"""Director dashboard — headline KPIs over live data.

This is a first, honest slice of the (large) KPI spec: today's revenue, average
check, patient/visit counts, live queue load, performed-operation counters and
warehouse alerts (low stock / expiring batches). The remaining KPIs (margins,
conversions, forecasts, per-doctor revenue …) are scheduled in later phases once
the Diagnostics / Treatment / Inventory modules feed the data they require.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dates import business_today
from app.core.deps import require_permission
from app.models.inventory import Product, StockBatch
from app.models.operation import Operation
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.queue import QueueTicket
from app.models.visit import Visit

router = APIRouter(prefix="/dashboard", tags=["Director Dashboard"])


class DashboardSummary(BaseModel):
    revenue_today: Decimal
    revenue_month: Decimal
    payments_today: int
    average_check_today: Decimal
    visits_today: int
    new_patients_today: int
    patients_total: int
    queue_waiting: int
    operations_today: int
    operations_month: int
    low_stock_count: int
    expiring_soon_count: int


def _day_start() -> datetime:
    return datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)


def _month_start() -> datetime:
    return _day_start().replace(day=1)


def _sum_payments(db: Session, since: datetime) -> Decimal:
    val = db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0))
        .where(Payment.status == "completed", Payment.created_at >= since)
    ).scalar_one()
    return Decimal(val)


def _count_operations_done(db: Session, since: datetime) -> int:
    """Performed operations since `since` (same UTC day/month boundaries as revenue)."""
    return db.execute(
        select(func.count()).select_from(Operation)
        .where(Operation.status == "done", Operation.performed_at >= since)
    ).scalar_one()


@router.get("/summary", response_model=DashboardSummary,
            dependencies=[Depends(require_permission("dashboard.view"))])
def summary(db: Annotated[Session, Depends(get_db)]) -> DashboardSummary:
    day, month = _day_start(), _month_start()

    revenue_today = _sum_payments(db, day)
    payments_today = db.execute(
        select(func.count()).select_from(Payment)
        .where(Payment.status == "completed", Payment.created_at >= day)
    ).scalar_one()
    visits_today = db.execute(
        select(func.count()).select_from(Visit).where(Visit.opened_at >= day)
    ).scalar_one()
    new_patients_today = db.execute(
        select(func.count()).select_from(Patient).where(Patient.created_at >= day)
    ).scalar_one()
    patients_total = db.execute(select(func.count()).select_from(Patient)).scalar_one()
    queue_waiting = db.execute(
        select(func.count()).select_from(QueueTicket).where(QueueTicket.status == "waiting")
    ).scalar_one()

    # ── Warehouse alerts (system-wide, matching the rest of the summary's scope) ──
    # "Usable" mirrors the FEFO engine's predicate in app.core.stock._usable_filter,
    # including the SAME business date (server-local) — a UTC date here disagreed
    # with the engine for ~5h/day on UTC+5 hosts.
    today = business_today()
    # min_stock is a PER-BRANCH threshold (notify.check_low_stock and the stock
    # view both evaluate it per branch) — so group per (product, branch) and
    # count products that are low in ANY stocked branch, plus active products
    # with no usable stock anywhere (the outerjoin NULL row).
    usable_qty = (
        select(
            StockBatch.product_id,
            StockBatch.branch_id,
            func.sum(StockBatch.quantity).label("qty"),
        )
        .where(
            StockBatch.quantity > 0,
            or_(StockBatch.expiry_date.is_(None), StockBatch.expiry_date >= today),
        )
        .group_by(StockBatch.product_id, StockBatch.branch_id)
        .subquery()
    )
    low_stock_count = db.execute(
        select(func.count(func.distinct(Product.id))).select_from(Product)
        .outerjoin(usable_qty, usable_qty.c.product_id == Product.id)
        .where(
            Product.is_active.is_(True),
            func.coalesce(usable_qty.c.qty, 0) <= Product.min_stock,
        )
    ).scalar_one()
    expiring_soon_count = db.execute(
        select(func.count()).select_from(StockBatch)
        .where(
            StockBatch.quantity > 0,
            StockBatch.expiry_date.is_not(None),
            StockBatch.expiry_date >= today,
            StockBatch.expiry_date <= today + timedelta(days=30),
        )
    ).scalar_one()

    avg_check = (revenue_today / payments_today) if payments_today else Decimal("0.00")

    return DashboardSummary(
        revenue_today=revenue_today,
        revenue_month=_sum_payments(db, month),
        payments_today=payments_today,
        average_check_today=avg_check.quantize(Decimal("0.01")),
        visits_today=visits_today,
        new_patients_today=new_patients_today,
        patients_total=patients_total,
        queue_waiting=queue_waiting,
        operations_today=_count_operations_done(db, day),
        operations_month=_count_operations_done(db, month),
        low_stock_count=low_stock_count,
        expiring_soon_count=expiring_soon_count,
    )
