"""Director dashboard — headline KPIs over live data.

This is a first, honest slice of the (large) KPI spec: today's revenue, average
check, patient/visit counts and live queue load. The remaining KPIs (margins,
conversions, forecasts, per-doctor revenue …) are scheduled in later phases once
the Diagnostics / Treatment / Inventory modules feed the data they require.
"""
from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_permission
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
    )
