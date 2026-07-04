"""Director dashboard — headline KPIs over live data.

This is a first, honest slice of the (large) KPI spec: today's revenue, average
check, patient/visit counts, live queue load, performed-operation counters and
warehouse alerts (low stock / expiring batches). The remaining KPIs (margins,
conversions, forecasts, per-doctor revenue …) are scheduled in later phases once
the Diagnostics / Treatment / Inventory modules feed the data they require.

It also hosts the self-improvement engine: `GET /dashboard/insights` distills
the same live data into an "attention list" for the owner's morning glance —
an empty list IS the good-morning state. Critical findings are additionally
pushed through the notification seam (Telegram when configured), debounced to
one alert per insight code per 24h.
"""
from __future__ import annotations

import logging
import re
import uuid
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from typing import Annotated, Literal, get_args

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import and_, case, func, or_, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.dates import (
    business_today,
    current_business_month,
    local_day_bounds_utc,
    local_month_bounds_utc,
    local_month_date_range,
)
from app.core.deps import CurrentUser, require_permission
from app.core.notify import notify
from app.models.attachment import Attachment
from app.models.call import CallDevice, CallRecord
from app.models.catalog import Service, ServiceCategory
from app.models.finance import Expense
from app.models.inventory import Product, StockBatch, StockMovement
from app.models.notification import Notification
from app.models.operation import Operation, OperationType, Treatment
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.queue import QueueTicket
from app.models.user import User
from app.models.visit import Visit, VisitItem
from app.schemas.patient import LeadSource

# Operation day-expenses are logged under this finance category (mirrors
# app.features.operations.OPERATIONS_EXPENSE_CATEGORY) — the operations P&L
# subtracts exactly these from operation revenue. Kept as a local constant to
# avoid a feature→feature import.
_OPERATIONS_EXPENSE_CATEGORY = "Операции"

# YYYY-MM month parameter validation (shared by the monthly analytics endpoints).
_MONTH_RE = re.compile(r"^\d{4}-\d{2}$")


def _resolve_month(month: str | None) -> str:
    """Validate an optional ``YYYY-MM`` query param, defaulting to this month."""
    if month is None:
        return current_business_month()
    if not _MONTH_RE.match(month):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "month must be YYYY-MM")
    return month

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/dashboard", tags=["Director Dashboard"])


class DashboardSummary(BaseModel):
    revenue_today: Decimal
    revenue_month: Decimal
    expenses_today: Decimal
    expenses_month: Decimal
    profit_today: Decimal
    profit_month: Decimal
    payments_today: int
    average_check_today: Decimal
    visits_today: int
    new_patients_today: int
    new_patients_week: int
    new_patients_month: int
    returning_today: int
    patients_total: int
    queue_waiting: int
    operations_today: int
    operations_month: int
    operations_scheduled_today: int
    low_stock_count: int
    expiring_soon_count: int


# Local business day/month start as a UTC instant — the SAME boundaries the
# finance cash reports use, so the owner's revenue KPIs and the cash reports
# agree on any host timezone (not just UTC).
def _day_start() -> datetime:
    return local_day_bounds_utc(business_today())[0]


def _month_start() -> datetime:
    return local_month_bounds_utc(current_business_month())[0]


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
        .where(Operation.status.in_(Operation.DONE_STATUSES), Operation.performed_at >= since)
    ).scalar_one()


def _usable_per_branch(today: date):
    """Usable stock per (product, branch) — mirrors app.core.stock._usable_filter.

    min_stock is a PER-BRANCH threshold (notify.check_low_stock and the stock
    view both evaluate it per branch), so quantities are grouped per
    (product, branch); the caller outerjoins it to also catch active products
    with no usable stock anywhere (the NULL row).
    """
    return (
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


@router.get("/summary", response_model=DashboardSummary,
            dependencies=[Depends(require_permission("dashboard.view"))])
def summary(db: Annotated[Session, Depends(get_db)]) -> DashboardSummary:
    day, month = _day_start(), _month_start()
    today = business_today()
    day_end = local_day_bounds_utc(today)[1]
    # "За неделю" — последние 7 локальных дней включая сегодня.
    week_start = local_day_bounds_utc(today - timedelta(days=6))[0]

    revenue_today = _sum_payments(db, day)
    revenue_month = _sum_payments(db, month)
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
    new_patients_week = db.execute(
        select(func.count()).select_from(Patient).where(Patient.created_at >= week_start)
    ).scalar_one()
    new_patients_month = db.execute(
        select(func.count()).select_from(Patient).where(Patient.created_at >= month)
    ).scalar_one()
    # Повторные сегодня: пациенты с визитом сегодня, у которых есть визит и РАНЬШЕ
    # сегодняшнего дня (т.е. вернулись, а не первичные).
    prior_visit_patients = (
        select(Visit.patient_id).where(Visit.opened_at < day).distinct()
    )
    returning_today = db.execute(
        select(func.count(func.distinct(Visit.patient_id)))
        .where(Visit.opened_at >= day, Visit.patient_id.in_(prior_visit_patients))
    ).scalar_one()
    patients_total = db.execute(select(func.count()).select_from(Patient)).scalar_one()
    queue_waiting = db.execute(
        select(func.count()).select_from(QueueTicket).where(QueueTicket.status == "waiting")
    ).scalar_one()
    # Назначено операций на сегодня (по scheduled_at, не отменённые).
    operations_scheduled_today = db.execute(
        select(func.count()).select_from(Operation).where(
            Operation.scheduled_at >= day,
            Operation.scheduled_at < day_end,
            Operation.status != "cancelled",
        )
    ).scalar_one()

    # ── Расходы и прибыль (касса): Expense.expense_date — локальная ДАТА ──
    month_first, month_next = local_month_date_range(current_business_month())
    expenses_today = Decimal(db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0))
        .where(Expense.expense_date == today)
    ).scalar_one())
    expenses_month = Decimal(db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0))
        .where(Expense.expense_date >= month_first, Expense.expense_date < month_next)
    ).scalar_one())

    # ── Warehouse alerts (system-wide, matching the rest of the summary's scope) ──
    # "Usable" mirrors the FEFO engine's predicate in app.core.stock._usable_filter,
    # including the SAME business date (server-local, `today` above) — a UTC date
    # here disagreed with the engine for ~5h/day on UTC+5 hosts.
    # Count products that are low in ANY stocked branch, plus active products
    # with no usable stock anywhere (the outerjoin NULL row) — see _usable_per_branch.
    usable_qty = _usable_per_branch(today)
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
        revenue_month=revenue_month,
        expenses_today=expenses_today,
        expenses_month=expenses_month,
        profit_today=revenue_today - expenses_today,
        profit_month=revenue_month - expenses_month,
        payments_today=payments_today,
        average_check_today=avg_check.quantize(Decimal("0.01")),
        visits_today=visits_today,
        new_patients_today=new_patients_today,
        new_patients_week=new_patients_week,
        new_patients_month=new_patients_month,
        returning_today=returning_today,
        patients_total=patients_total,
        queue_waiting=queue_waiting,
        operations_today=_count_operations_done(db, day),
        operations_month=_count_operations_done(db, month),
        operations_scheduled_today=operations_scheduled_today,
        low_stock_count=low_stock_count,
        expiring_soon_count=expiring_soon_count,
    )


# ════════════════════════════════════════════════════════════════════════════
# Lead-source analytics — where this period's patients came from (CRM channels).
# ════════════════════════════════════════════════════════════════════════════

# RU labels for every canonical channel + the synthetic "unknown" bucket (NULL
# lead_source). Order here is the canonical channel order; the response is
# re-sorted by count desc so the director sees the busiest channel first.
_LEAD_SOURCE_LABELS: dict[str, str] = {
    "instagram": "Instagram",
    "telegram": "Telegram",
    "google": "Google",
    "referral": "Рекомендация",
    "banner": "Баннер",
    "walk_in": "Проходил мимо",
    "other": "Другое",
    "unknown": "Не указан",
}
# Synthetic bucket key for patients with no lead_source recorded.
_UNKNOWN_SOURCE = "unknown"


class LeadSourceCount(BaseModel):
    source: str
    label: str
    count: int


class LeadSourceReport(BaseModel):
    total: int
    sources: list[LeadSourceCount]


@router.get("/lead-sources", response_model=LeadSourceReport,
            dependencies=[Depends(require_permission("dashboard.view"))])
def lead_sources(
    db: Annotated[Session, Depends(get_db)],
    date_from: date | None = Query(None, description="Local start date (inclusive)"),
    date_to: date | None = Query(None, description="Local end date (inclusive)"),
) -> LeadSourceReport:
    """Patient counts per CRM lead-source channel over a LOCAL day range.

    Default range is the current month-to-date. ``date_from`` alone means "that
    day onward". Local dates are converted to UTC instants (Patient.created_at is
    stored aware-UTC) so the window agrees with the rest of the dashboard on any
    host timezone. Every canonical channel is always present (zero-count
    included) plus an ``unknown`` bucket for patients with no lead_source.
    """
    if date_from and date_to and date_from > date_to:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "date_from must be <= date_to")

    # Resolve the [start, end) UTC instant window from the local date range.
    if date_from is None and date_to is None:
        start, end = local_month_bounds_utc(current_business_month())
    else:
        start = local_day_bounds_utc(date_from)[0] if date_from else None
        # date_to is INCLUSIVE → end of that local day = start of the next day.
        end = local_day_bounds_utc(date_to)[1] if date_to else None

    stmt = select(Patient.lead_source, func.count()).group_by(Patient.lead_source)
    if start is not None:
        stmt = stmt.where(Patient.created_at >= start)
    if end is not None:
        stmt = stmt.where(Patient.created_at < end)

    # NULL lead_source folds into the synthetic "unknown" bucket.
    counts: dict[str, int] = {}
    for source, count in db.execute(stmt).all():
        key = source if source else _UNKNOWN_SOURCE
        counts[key] = counts.get(key, 0) + count

    # Canonical channels (always shown, zeros included) + unknown bucket.
    keys = list(get_args(LeadSource)) + [_UNKNOWN_SOURCE]
    sources = [
        LeadSourceCount(source=k, label=_LEAD_SOURCE_LABELS[k], count=counts.get(k, 0))
        for k in keys
    ]
    sources.sort(key=lambda s: s.count, reverse=True)
    return LeadSourceReport(total=sum(s.count for s in sources), sources=sources)


# ════════════════════════════════════════════════════════════════════════════
# Patients by region — geographic audience for the director's marketing view.
# ════════════════════════════════════════════════════════════════════════════

_UNKNOWN_REGION = "Не указано"


class RegionCount(BaseModel):
    region: str
    new_count: int       # registered / single-visit patients (новые)
    returning_count: int  # patients with more than one visit (посещавшие)
    total: int


class RegionReport(BaseModel):
    total: int
    regions: list[RegionCount]


@router.get("/patients-by-region", response_model=RegionReport,
            dependencies=[Depends(require_permission("dashboard.view"))])
def patients_by_region(db: Annotated[Session, Depends(get_db)]) -> RegionReport:
    """Patients grouped by region, split into new vs returning — so the director
    can see which audience to market to.

    "Returning" (посещавшие) = a patient with more than one visit; "new" (новые)
    = everyone else (freshly registered or single-visit). NULL region folds into a
    «Не указано» bucket. All-time counts (no date window) for a complete
    geographic picture; sorted by total descending."""
    visit_counts = (
        select(Visit.patient_id, func.count().label("vc"))
        .group_by(Visit.patient_id)
        .subquery()
    )
    rows = db.execute(
        select(
            Patient.region,
            func.count(Patient.id),
            func.coalesce(
                func.sum(case((func.coalesce(visit_counts.c.vc, 0) > 1, 1), else_=0)), 0
            ),
        )
        .select_from(Patient)
        .outerjoin(visit_counts, visit_counts.c.patient_id == Patient.id)
        .group_by(Patient.region)
    ).all()

    regions: list[RegionCount] = []
    for region, total, returning in rows:
        total = int(total)
        returning = int(returning)
        regions.append(RegionCount(
            region=region if region else _UNKNOWN_REGION,
            new_count=total - returning,
            returning_count=returning,
            total=total,
        ))
    regions.sort(key=lambda r: r.total, reverse=True)
    return RegionReport(total=sum(r.total for r in regions), regions=regions)


# ════════════════════════════════════════════════════════════════════════════
# Revenue trend — daily completed-payment revenue (dashboard line chart).
# ════════════════════════════════════════════════════════════════════════════


class RevenuePoint(BaseModel):
    date: date
    revenue: Decimal


class RevenueTrend(BaseModel):
    points: list[RevenuePoint]


@router.get("/revenue-trend", response_model=RevenueTrend,
            dependencies=[Depends(require_permission("dashboard.view"))])
def revenue_trend(
    db: Annotated[Session, Depends(get_db)],
    days: int = Query(14, ge=1, le=90),
) -> RevenueTrend:
    """Completed-payment revenue per LOCAL day for the last ``days`` days — feeds
    the dashboard's revenue trend chart. Each day uses the same local→UTC instant
    window the cash reports use, so the trend agrees with the rest of the board."""
    today = business_today()
    points: list[RevenuePoint] = []
    for offset in range(days - 1, -1, -1):
        day = today - timedelta(days=offset)
        start, end = local_day_bounds_utc(day)
        rev = db.execute(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                Payment.status == "completed",
                Payment.created_at >= start,
                Payment.created_at < end,
            )
        ).scalar_one()
        points.append(RevenuePoint(date=day, revenue=Decimal(rev)))
    return RevenueTrend(points=points)


# ════════════════════════════════════════════════════════════════════════════
# Top services — this month's revenue per service (Analytics screen).
# ════════════════════════════════════════════════════════════════════════════

# Billed line items that represent real, taken revenue (ordered items aren't
# money yet). Same statuses the till advances an item through after payment.
_BILLED_ITEM_STATUSES = ("paid", "in_progress", "done")


class TopServiceRow(BaseModel):
    service: str
    revenue: Decimal
    count: int


@router.get("/top-services", response_model=list[TopServiceRow],
            dependencies=[Depends(require_permission("dashboard.view"))])
def top_services(
    db: Annotated[Session, Depends(get_db)],
    limit: int = Query(8, ge=1, le=50),
) -> list[TopServiceRow]:
    """Revenue per service over the current LOCAL month, busiest first.

    Sums billed ``visit_items`` (paid line items only) grouped by the snapshot
    service name — honest revenue, not catalog list prices. Month bounds are the
    same local→UTC instants the cash reports use, so it agrees with the P&L.
    """
    start, end = local_month_bounds_utc(current_business_month())
    rows = db.execute(
        select(
            VisitItem.service_name,
            func.coalesce(func.sum(VisitItem.total), 0).label("revenue"),
            func.count().label("count"),
        )
        .where(
            VisitItem.status.in_(_BILLED_ITEM_STATUSES),
            VisitItem.created_at >= start,
            VisitItem.created_at < end,
        )
        .group_by(VisitItem.service_name)
        .order_by(func.coalesce(func.sum(VisitItem.total), 0).desc())
        .limit(limit)
    ).all()
    return [
        TopServiceRow(service=name, revenue=Decimal(revenue), count=count)
        for name, revenue, count in rows
    ]


# ════════════════════════════════════════════════════════════════════════════
# Self-improvement insights — "what needs the owner's attention TODAY".
# ════════════════════════════════════════════════════════════════════════════

# Rule thresholds (one tunable place; each comment is the business meaning):
_EXPIRY_WINDOW_DAYS = 30                   # a lot expiring within this many days needs action (use FEFO / return)
_QUEUE_OVERLOAD_WAITING = 10               # waiting tickets on ONE track today beyond this = overload
_STALE_VISIT_AGE = timedelta(hours=24)     # an open visit older than this has stalled (money/process stuck)
_CANCEL_WINDOW = timedelta(days=7)         # cancellation-spike lookback window
_CANCEL_RATE = Decimal("0.20")             # cancelled share of the window's visits that triggers the spike…
_CANCEL_MIN = 3                            # …but only with at least this many cancellations (no 1-of-2 noise)
_REVENUE_DROP_RATIO = Decimal("0.60")      # this month's daily average below 60% of last month's = drop
_INSIGHT_DEBOUNCE = timedelta(hours=24)    # at most one notification per critical insight code per 24h
_MISSED_CALLS_TODAY = 5                     # missed incoming calls today beyond this = front-desk not answering


def _within_work_hours(local_now: datetime) -> bool:
    """True if the clinic is open now (work_day_start ≤ local time < work_day_end).

    Bounds the "reception phone offline" alert to working hours — a phone is
    expected to be off at night, so a stale heartbeat then is normal.
    """
    try:
        sh, sm = (int(x) for x in settings.work_day_start.split(":"))
        eh, em = (int(x) for x in settings.work_day_end.split(":"))
    except (ValueError, AttributeError):
        return True  # misconfigured window → don't suppress the alert
    minutes = local_now.hour * 60 + local_now.minute
    return sh * 60 + sm <= minutes < eh * 60 + em


_SEVERITY_RANK = {"critical": 0, "warning": 1, "info": 2}

# Human labels for queue tracks (detail strings name the track explicitly).
_TRACK_LABELS = {"doctor": "врачебная очередь", "diagnostic": "диагностика"}


class InsightOut(BaseModel):
    code: str
    severity: Literal["info", "warning", "critical"]
    title: str
    detail: str
    value: str | None = None
    # Client deep-link: tapping the insight card opens this director-accessible
    # section so the problem can be fixed at once. Resolved by code (below).
    route: str | None = None


# Each insight code → the section the director jumps to when the card is tapped.
# Every target is reachable by the Director role (dashboard.view + reads).
_INSIGHT_ROUTES: dict[str, str] = {
    "low_stock": "/inventory",
    "expiring_lots": "/inventory",
    "queue_overload": "/queue",
    "stale_open_visits": "/patients",
    "unpaid_balance": "/finance",
    "cancellation_spike": "/analytics",
    "revenue_drop": "/analytics",
    "missed_calls": "/calls",
    "call_device_offline": "/calls",
    "missing_primary_doctor": "/patients",
    "unfilled_treatments": "/patients",
    "stale_operations": "/operations",
    "missing_diagnostic_attachments": "/patients",
}


def _notify_critical_insights(db: Session, criticals: list[InsightOut]) -> None:
    """Push critical insights through the notification seam (log + Telegram).

    Debounce: at most one notification per insight code per 24h — the same
    idiom as notify.check_low_stock. Fully wrapped: a notification (or
    debounce-query) failure must never break the dashboard endpoint.
    """
    try:
        since = datetime.now(timezone.utc) - _INSIGHT_DEBOUNCE
        for insight in criticals:
            event = f"insight_{insight.code}"
            already = db.execute(
                select(Notification.id)
                .where(Notification.event == event, Notification.created_at >= since)
                .limit(1)
            ).scalar_one_or_none()
            if already is not None:
                continue
            notify(db, event=event, title=insight.title, body=insight.detail, branch_id=None)
    except Exception:  # never break the endpoint over a notification
        logger.exception("insight notifications failed")
        try:
            db.rollback()
        except Exception:
            pass


def compute_insights(db: Session) -> list[InsightOut]:
    """The live "what needs attention now" set — every rule that fired, ordered
    critical → info.

    PURE and self-resolving: each rule is a set-based query over CURRENT data, so
    an insight exists ONLY while its problem exists (an empty list is the good
    state). Same UTC day/month conventions as /summary, same business date as the
    FEFO engine for stock rules. Single source of truth shared by
    GET /dashboard/insights and the self-clearing GET /notifications/active.
    """
    now = datetime.now(timezone.utc)
    day = _day_start()
    today = business_today()
    found: list[InsightOut] = []

    # ── low_stock (critical): products at/below min_stock in a stocked branch,
    #    or active products with no usable stock anywhere — same per-branch
    #    logic as /summary's low_stock_count, plus names for the detail line.
    usable_qty = _usable_per_branch(today)
    low_products = db.execute(
        select(Product.id, Product.name).distinct()
        .select_from(Product)
        .outerjoin(usable_qty, usable_qty.c.product_id == Product.id)
        .where(
            Product.is_active.is_(True),
            func.coalesce(usable_qty.c.qty, 0) <= Product.min_stock,
        )
        .order_by(Product.name)
    ).all()
    if low_products:
        names = [name for _, name in low_products[:5]]
        extra = len(low_products) - len(names)
        detail = "Под минимумом: " + ", ".join(names)
        if extra > 0:
            detail += f" и ещё {extra}"
        found.append(InsightOut(
            code="low_stock", severity="critical",
            title="Дефицит на складе",
            detail=detail, value=str(len(low_products)),
        ))

    # ── expiring_lots (warning): batches with stock expiring within the window.
    expiring = db.execute(
        select(func.count()).select_from(StockBatch)
        .where(
            StockBatch.quantity > 0,
            StockBatch.expiry_date.is_not(None),
            StockBatch.expiry_date >= today,
            StockBatch.expiry_date <= today + timedelta(days=_EXPIRY_WINDOW_DAYS),
        )
    ).scalar_one()
    if expiring:
        found.append(InsightOut(
            code="expiring_lots", severity="warning",
            title="Истекающие партии",
            detail=f"Партий со сроком годности ≤ {_EXPIRY_WINDOW_DAYS} дней: {expiring} — "
                   "израсходовать в первую очередь или вернуть поставщику",
            value=str(expiring),
        ))

    # ── queue_overload (warning, per track): too many waiting tickets TODAY.
    waiting_by_track = db.execute(
        select(QueueTicket.track, func.count())
        .where(QueueTicket.status == "waiting", QueueTicket.created_at >= day)
        .group_by(QueueTicket.track)
        .order_by(QueueTicket.track)
    ).all()
    for track, count in waiting_by_track:
        if count > _QUEUE_OVERLOAD_WAITING:
            label = _TRACK_LABELS.get(track, track)
            found.append(InsightOut(
                code="queue_overload", severity="warning",
                title="Очередь перегружена",
                detail=f"{label} ({track}): {count} ожидающих в очереди "
                       f"(порог {_QUEUE_OVERLOAD_WAITING}) — добавить приёмные мощности",
                value=str(count),
            ))

    # ── stale_open_visits (warning): visits stuck open for >24h —
    #    деньги и процессы зависли.
    stale = db.execute(
        select(func.count()).select_from(Visit)
        .where(Visit.status == "open", Visit.opened_at < now - _STALE_VISIT_AGE)
    ).scalar_one()
    if stale:
        found.append(InsightOut(
            code="stale_open_visits", severity="warning",
            title="Зависшие визиты",
            detail=f"Визитов открыто дольше 24 часов: {stale} — деньги и процессы "
                   "зависли, закройте или отмените их",
            value=str(stale),
        ))

    # ── unpaid_balance (info): outstanding money over open visits.
    #    Due = payable (total minus reception discount), mirroring Visit.payable.
    # Mirror Visit.discount_value exactly: the percent branch quantizes to 0.01
    # (func.round) so SQL payable matches the Python source of truth and a
    # fully-paid discounted visit isn't reported as a fractional-cent debt.
    _discount = case(
        (Visit.discount_percent.is_not(None),
         func.round(Visit.total_amount * Visit.discount_percent / 100, 2)),
        (Visit.discount_amount.is_not(None),
         case((Visit.discount_amount > Visit.total_amount, Visit.total_amount),
              else_=Visit.discount_amount)),
        else_=0,
    )
    _payable = Visit.total_amount - _discount
    outstanding = Decimal(db.execute(
        select(func.coalesce(func.sum(_payable - Visit.paid_amount), 0))
        .where(Visit.status == "open", _payable > Visit.paid_amount)
    ).scalar_one()).quantize(Decimal("0.01"))
    if outstanding > 0:
        found.append(InsightOut(
            code="unpaid_balance", severity="info",
            title="Неоплаченный остаток",
            detail=f"По открытым визитам не оплачено {outstanding} — "
                   "проверить дебиторку на ресепшене",
            value=str(outstanding),
        ))

    # ── cancellation_spike (warning): too many cancellations in the last 7 days.
    week_ago = now - _CANCEL_WINDOW
    visits_week = db.execute(
        select(func.count()).select_from(Visit).where(Visit.opened_at >= week_ago)
    ).scalar_one()
    cancelled_week = db.execute(
        select(func.count()).select_from(Visit)
        .where(Visit.opened_at >= week_ago, Visit.status == "cancelled")
    ).scalar_one()
    if visits_week and cancelled_week >= _CANCEL_MIN:
        rate = Decimal(cancelled_week) / Decimal(visits_week)
        if rate > _CANCEL_RATE:
            found.append(InsightOut(
                code="cancellation_spike", severity="warning",
                title="Всплеск отмен",
                detail=f"За 7 дней отменено {cancelled_week} из {visits_week} визитов "
                       f"({rate:.0%}) — выяснить причину (сервис? цены? врач?)",
                value=f"{rate:.0%}",
            ))

    # ── revenue_drop (critical): this month's daily-average revenue collapsed
    #    versus last month's. Computed over COMPLETED days only — the morning
    #    of day 1-2 has no completed days yet, and counting the just-started
    #    day as fully elapsed fired a guaranteed false «-100%» critical (with
    #    a Telegram push) every month start.
    month_start = _month_start()
    prev_month_start = (month_start - timedelta(days=1)).replace(day=1)
    prev_days = (month_start - prev_month_start).days
    prev_revenue = Decimal(db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0))
        .where(
            Payment.status == "completed",
            Payment.created_at >= prev_month_start,
            Payment.created_at < month_start,
        )
    ).scalar_one())
    days_completed = now.day - 1
    if prev_revenue > 0 and days_completed >= 2:
        # Month-to-yesterday revenue: today's partial day must not dilute the average.
        revenue_completed = _sum_payments(db, month_start) - _sum_payments(db, _day_start())
        this_avg = revenue_completed / days_completed
        prev_avg = prev_revenue / prev_days
        if this_avg < prev_avg * _REVENUE_DROP_RATIO:
            drop = Decimal(1) - this_avg / prev_avg
            found.append(InsightOut(
                code="revenue_drop", severity="critical",
                title="Падение выручки",
                detail=f"Средняя дневная выручка этого месяца ниже прошлого на {drop:.0%} "
                       f"({this_avg:.0f} против {prev_avg:.0f} в день)",
                value=f"-{drop:.0%}",
            ))

    # ── missed_calls (warning): too many unanswered incoming calls TODAY —
    #    the front desk is letting patient calls ring out.
    missed_today = db.execute(
        select(func.count()).select_from(CallRecord)
        .where(CallRecord.started_at >= day, CallRecord.status == "missed",
               CallRecord.direction == "in")
    ).scalar_one()
    if missed_today >= _MISSED_CALLS_TODAY:
        found.append(InsightOut(
            code="missed_calls", severity="warning",
            title="Пропущенные звонки",
            detail=f"Сегодня пропущено {missed_today} входящих звонков — "
                   "ресепшен не отвечает вовремя, проверьте загрузку",
            value=str(missed_today),
        ))

    # ── call_device_offline (critical): a reception phone stopped reporting
    #    DURING working hours — calls are being lost invisibly (dead battery /
    #    app killed). Suppressed off-hours (a phone is meant to be off at night).
    if _within_work_hours(now.astimezone()):
        offline_cutoff = now - timedelta(minutes=settings.call_device_offline_minutes)
        offline = db.execute(
            select(CallDevice.label).where(
                CallDevice.is_active.is_(True),
                or_(CallDevice.last_seen_at.is_(None), CallDevice.last_seen_at < offline_cutoff),
            ).order_by(CallDevice.label)
        ).scalars().all()
        if offline:
            names = ", ".join(offline[:5])
            extra = len(offline) - min(len(offline), 5)
            detail = f"Не на связи: {names}" + (f" и ещё {extra}" if extra > 0 else "")
            found.append(InsightOut(
                code="call_device_offline", severity="critical",
                title="Телефон ресепшена офлайн",
                detail=detail + " — звонки могут теряться, проверьте телефон",
                value=str(len(offline)),
            ))

    # ── missing_primary_doctor (warning): visits held «Ожидает назначения» —
    #    a patient registered but with no doctor assigned yet (Phase-3 hold).
    no_doctor = db.execute(
        select(func.count()).select_from(Visit)
        .where(Visit.status == "open", Visit.flow_status == "awaiting_assignment")
    ).scalar_one()
    if no_doctor:
        found.append(InsightOut(
            code="missing_primary_doctor", severity="warning",
            title="Пациент без врача",
            detail=f"Визитов без назначенного врача: {no_doctor} — направьте к врачу",
            value=str(no_doctor),
        ))

    # ── missing_diagnostic_attachments (warning): visits whose diagnostics were
    #    completed today but no result file (УЗИ/ВИЧ/анализ) is attached.
    done_diag = (
        select(QueueTicket.visit_id)
        .where(QueueTicket.track == "diagnostic", QueueTicket.status == "done",
               QueueTicket.created_at >= day, QueueTicket.visit_id.is_not(None))
        .distinct().subquery()
    )
    no_results = db.execute(
        select(func.count()).select_from(done_diag)
        .outerjoin(Attachment, Attachment.visit_id == done_diag.c.visit_id)
        .where(Attachment.id.is_(None))
    ).scalar_one()
    if no_results:
        found.append(InsightOut(
            code="missing_diagnostic_attachments", severity="warning",
            title="Нет результатов диагностики",
            detail=f"Визитов без прикреплённых результатов: {no_results} — "
                   "загрузите УЗИ/ВИЧ/анализы",
            value=str(no_results),
        ))

    # ── stale_operations (warning): operations performed/in-progress but not
    #    closed (результат не внесён, операция не завершена).
    open_ops = db.execute(
        select(func.count()).select_from(Operation)
        .where(Operation.status.in_(("in_progress", "performed")))
    ).scalar_one()
    if open_ops:
        found.append(InsightOut(
            code="stale_operations", severity="warning",
            title="Операция не закрыта",
            detail=f"Операций не завершено: {open_ops} — внесите результат и закройте",
            value=str(open_ops),
        ))

    # ── unfilled_treatments (warning): prescriptions awaiting dispensing —
    #    лечение назначено, но не заполнено/не выдано.
    unfilled = db.execute(
        select(func.count()).select_from(Treatment)
        .where(Treatment.status == "prescribed")
    ).scalar_one()
    if unfilled:
        found.append(InsightOut(
            code="unfilled_treatments", severity="warning",
            title="Лечение не заполнено",
            detail=f"Назначений лечения ожидает выполнения: {unfilled} — заполните/выдайте",
            value=str(unfilled),
        ))

    # Attach the click-through route to every fired insight (clickable cards).
    for i in found:
        i.route = _INSIGHT_ROUTES.get(i.code)

    # Critical first, info last; stable sort keeps the rule order within a tier.
    found.sort(key=lambda i: _SEVERITY_RANK[i.severity])
    return found


@router.get("/insights", response_model=list[InsightOut],
            dependencies=[Depends(require_permission("dashboard.view"))])
def insights(db: Annotated[Session, Depends(get_db)]) -> list[InsightOut]:
    """Director's morning attention list. Computes the live insight set and, as a
    side effect, pushes any CRITICAL ones through the notification seam (log +
    Telegram, 24h-debounced). The pure set lives in compute_insights()."""
    found = compute_insights(db)
    _notify_critical_insights(db, [i for i in found if i.severity == "critical"])
    return found


# ════════════════════════════════════════════════════════════════════════════
# Hanging visits — «застрявшие» случаи, сгруппированные по 5 категориям
# (owner brief 2026-06-20). В отличие от инсайтов-счётчиков, отдаёт КОНКРЕТНЫХ
# пациентов, чтобы директор видел и мог открыть каждый зависший визит.
# ════════════════════════════════════════════════════════════════════════════

# Стадия считается «зависшей» после этого времени (свежая работа — это норма).
_HANGING_NO_DOCTOR_AGE = timedelta(hours=4)   # зарегистрирован, к врачу не попал
_HANGING_IN_DOCTOR_AGE = timedelta(hours=3)   # на приёме, не завершён
_HANGING_REFERRAL_AGE = timedelta(hours=24)   # направлен на операцию, не запланирована
_HANGING_POST_OP_AGE = timedelta(hours=3)     # операция выполнена, визит не завершён
_HANGING_ROW_CAP = 50                         # максимум строк-пациентов на категорию

# flow_status пациента, который ещё НЕ дошёл до врача (до in_doctor).
_PRE_DOCTOR_FLOW = (
    "registered", "awaiting_assignment", "waiting_diagnostic",
    "in_diagnostic", "waiting_doctor",
)


class HangingVisitRow(BaseModel):
    visit_id: uuid.UUID
    visit_no: str
    patient_id: uuid.UUID
    patient_name: str
    flow_status: str
    opened_at: datetime
    detail: str


class HangingCategory(BaseModel):
    # no_doctor | in_doctor | diag_no_result | op_not_closed |
    # post_op_not_finished | treatment_unfinished | done_not_closed
    category: str
    label: str
    severity: Literal["info", "warning", "critical"]
    count: int  # total matched (visits list may be capped at _HANGING_ROW_CAP)
    route: str | None = None
    visits: list[HangingVisitRow]


def _hanging_row(visit: Visit, detail: str) -> HangingVisitRow:
    return HangingVisitRow(
        visit_id=visit.id, visit_no=visit.visit_no,
        patient_id=visit.patient_id, patient_name=visit.patient.full_name,
        flow_status=visit.flow_status, opened_at=visit.opened_at, detail=detail,
    )


def _category(category: str, label: str, severity: str, route: str | None,
              rows: list[HangingVisitRow]) -> HangingCategory | None:
    """Build a category, capping the visit rows; None when nothing is stuck."""
    if not rows:
        return None
    return HangingCategory(category=category, label=label, severity=severity,
                           route=route, count=len(rows), visits=rows[:_HANGING_ROW_CAP])


@router.get("/hanging-visits", response_model=list[HangingCategory],
            dependencies=[Depends(require_permission("dashboard.view"))])
def hanging_visits(db: Annotated[Session, Depends(get_db)]) -> list[HangingCategory]:
    """Зависшие визиты в семи категориях, с конкретными пациентами:
    (1) зарегистрирован, но не дошёл до врача; (2) был у врача, приём не завершён;
    (3) назначена диагностика, но нет результата; (4) операция не закрыта
    (вкл. направление >24 ч без даты); (5) операция выполнена, визит не завершён;
    (6) лечение не завершено; (7) флоу завершён, визит открыт с долгом.
    Самоочищается — визит исчезает, как только проблема решена (вычисляется на
    чтение по текущему состоянию)."""
    now = datetime.now(timezone.utc)
    out: list[HangingCategory] = []

    def _hours(opened: datetime) -> int:
        delta = now - (opened if opened.tzinfo else opened.replace(tzinfo=timezone.utc))
        return max(0, int(delta.total_seconds() // 3600))

    # ── (1) Зарегистрирован, но не дошёл до врача (до in_doctor, открыт >4ч).
    cat1 = db.execute(
        select(Visit).where(
            Visit.status == "open",
            Visit.flow_status.in_(_PRE_DOCTOR_FLOW),
            Visit.opened_at < now - _HANGING_NO_DOCTOR_AGE,
        ).order_by(Visit.opened_at)
    ).scalars().all()
    out.append(_category(
        "no_doctor", "Зарегистрирован, не дошёл до врача", "critical", "/patients",
        [_hanging_row(v, f"В системе уже {_hours(v.opened_at)} ч, к врачу не попал")
         for v in cat1]))

    # ── (2) Был у врача, но приём не завершён (in_doctor дольше порога).
    cat2 = db.execute(
        select(Visit).where(
            Visit.status == "open",
            Visit.flow_status == "in_doctor",
            Visit.opened_at < now - _HANGING_IN_DOCTOR_AGE,
        ).order_by(Visit.opened_at)
    ).scalars().all()
    out.append(_category(
        "in_doctor", "На приёме, не завершён", "warning", "/patients",
        [_hanging_row(v, f"На приёме, приём не закрыт ({_hours(v.opened_at)} ч)")
         for v in cat2]))

    # ── (3) Назначена диагностика, но НЕТ результата: диагностический талон
    #    выполнен (done), но к визиту не прикреплён ни один файл-результат.
    #    Окно «только сегодня» снято — ловим и вчерашние зависшие случаи.
    done_diag = (
        select(QueueTicket.visit_id)
        .where(QueueTicket.track == "diagnostic", QueueTicket.status == "done",
               QueueTicket.visit_id.is_not(None))
        .distinct().subquery()
    )
    no_result_ids = db.execute(
        select(done_diag.c.visit_id)
        .outerjoin(Attachment, Attachment.visit_id == done_diag.c.visit_id)
        .where(Attachment.id.is_(None))
    ).scalars().all()
    cat3 = db.execute(
        select(Visit).where(Visit.id.in_(no_result_ids), Visit.status == "open")
        .order_by(Visit.opened_at)
    ).scalars().all() if no_result_ids else []
    out.append(_category(
        "diag_no_result", "Диагностика без результата", "warning", "/patients",
        [_hanging_row(v, "Диагностика выполнена, результат не прикреплён")
         for v in cat3]))

    # ── (4) Операция не закрыта: выполняется/выполнена, но не завершена, ИЛИ
    #    запланирована на прошедшую дату (не состоялась/забыта), ИЛИ направление
    #    выдано >24 ч назад, а дата так и не назначена (referred без scheduled).
    ops = db.execute(
        select(Operation).where(
            or_(
                Operation.status.in_(("in_progress", "performed")),
                and_(Operation.status == "scheduled",
                     Operation.scheduled_at.is_not(None),
                     Operation.scheduled_at < now),
                and_(Operation.status == "referred",
                     Operation.created_at < now - _HANGING_REFERRAL_AGE),
            )
        )
    ).scalars().all()
    visits4 = {
        v.id: v for v in db.execute(
            select(Visit).where(Visit.id.in_({op.visit_id for op in ops}))
        ).scalars().all()
    } if ops else {}
    _OP_STATUS_RU = {"scheduled": "запланирована", "in_progress": "идёт",
                     "performed": "выполнена"}

    def _op_candidate(op: Operation, visit: Visit) -> tuple[int, str] | None:
        """Приоритет и текст зависшей операции; None — не показывать.
        Приоритет 0 = реальная просрочка (важнее просроченного направления 1),
        чтобы при двух операциях одного визита не потерять просроченную из-за
        свежего referred и не зависеть от NULL-порядка scheduled_at в БД."""
        if op.status == "referred":
            # Только реально зависшее направление: флоу визита всё ещё
            # surgery_assigned (дата не назначалась, визит не ушёл дальше).
            if visit.flow_status != "surgery_assigned":
                return None
            return (1, f"Операция «{op.type_name}» — направление старше 24 ч, дата не назначена")
        if op.status == "performed" and visit.flow_status == "surgery_completed":
            # Такой визит принадлежит категории (4б) — не дублируем его здесь.
            return None
        if op.status == "scheduled":
            return (0, f"Операция «{op.type_name}» запланирована, дата прошла — не состоялась/не закрыта")
        return (0, f"Операция «{op.type_name}» — {_OP_STATUS_RU.get(op.status, op.status)}, не закрыта")

    best4: dict[uuid.UUID, tuple[int, str]] = {}
    for op in ops:
        visit = visits4.get(op.visit_id)
        if visit is None:
            continue
        cand = _op_candidate(op, visit)
        if cand is None:
            continue
        prev = best4.get(op.visit_id)
        if prev is None or cand[0] < prev[0]:
            best4[op.visit_id] = cand
    rows4 = [_hanging_row(visits4[vid], detail) for vid, (_p, detail) in best4.items()]
    out.append(_category(
        "op_not_closed", "Операция не закрыта", "warning", "/operations", rows4))

    # ── (4б) Операция выполнена, а визит так и не завершён: флоу дошёл до
    #    surgery_completed, но дольше порога никто не закрыл приём/визит.
    post_op_pairs = db.execute(
        select(Visit, Operation)
        .join(Operation, Operation.visit_id == Visit.id)
        .where(
            Visit.status == "open",
            Visit.flow_status == "surgery_completed",
            Operation.status.in_(Operation.DONE_STATUSES),
            Operation.performed_at.is_not(None),
            Operation.performed_at < now - _HANGING_POST_OP_AGE,
        ).order_by(Operation.performed_at)
    ).all()
    seen_post_op: set[uuid.UUID] = set()
    rows_post: list[HangingVisitRow] = []
    for visit, op in post_op_pairs:
        if visit.id in seen_post_op:
            continue
        seen_post_op.add(visit.id)
        rows_post.append(_hanging_row(
            visit, f"Операция «{op.type_name}» выполнена, визит не завершён"))
    out.append(_category(
        "post_op_not_finished", "После операции визит не завершён", "warning",
        "/operations", rows_post))

    # ── (5) Лечение назначено, но не завершено (status prescribed).
    treatments = db.execute(
        select(Treatment).where(Treatment.status == "prescribed")
        .order_by(Treatment.created_at)
    ).scalars().all()
    tr_by_visit: dict[uuid.UUID, Treatment] = {}
    for tr in treatments:
        tr_by_visit.setdefault(tr.visit_id, tr)
    visits5 = {
        v.id: v for v in db.execute(
            select(Visit).where(Visit.id.in_(tr_by_visit.keys()))
        ).scalars().all()
    } if tr_by_visit else {}
    rows5 = [
        _hanging_row(v, f"Лечение «{tr_by_visit[vid].name}» назначено, не выполнено")
        for vid, v in visits5.items()
    ]
    out.append(_category(
        "treatment_unfinished", "Лечение не завершено", "warning", "/patients", rows5))

    # ── (7) Флоу завершён, но визит не закрыт И остался долг: пациент ушёл,
    #    деньги не собраны. Без долга открытый завершённый визит — норма
    #    (его закроет авто-закрытие), поэтому не показываем.
    cat7 = db.execute(
        select(Visit).where(
            Visit.status == "open",
            Visit.flow_status.in_(("completed", "follow_up")),
        ).order_by(Visit.opened_at)
    ).scalars().all()
    rows7 = [
        _hanging_row(v, f"Приём завершён, визит не закрыт — долг {v.balance}")
        for v in cat7 if v.balance > 0
    ]
    out.append(_category(
        "done_not_closed", "Завершён, не закрыт — есть долг", "info",
        "/patients", rows7))

    # Только непустые категории; критичные — первыми, info — в конце.
    _SEVERITY_ORDER = {"critical": 0, "warning": 1, "info": 2}
    result = [c for c in out if c is not None]
    result.sort(key=lambda c: _SEVERITY_ORDER.get(c.severity, 3))
    return result


# ════════════════════════════════════════════════════════════════════════════
# Period summary — заголовочные метрики за выбранный период (owner brief
# 2026-06-20): Сегодня / Вчера / Неделя / Месяц / Квартал / Год / Произвольный.
# Все диаграммы дашборда могут пересчитываться за период через эту ручку.
# ════════════════════════════════════════════════════════════════════════════

_PERIOD_PRESETS = ("today", "yesterday", "week", "month", "quarter", "year", "custom")


def _resolve_period_dates(
    period: str, date_from: date | None, date_to: date | None,
) -> tuple[datetime, datetime, date, date]:
    """Map a period preset (+ optional custom dates) to a half-open UTC instant
    window [start, end) AND the inclusive local DATE range [from, to] (the latter
    for plain DATE columns like Expense.expense_date). Presets are «to date»
    (through the end of the local today)."""
    today = business_today()
    if period == "custom":
        if date_from is None or date_to is None:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                                "custom period requires date_from and date_to")
        if date_to < date_from:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                                "date_to must be on or after date_from")
        df, dt = date_from, date_to
    elif period == "today":
        df = dt = today
    elif period == "yesterday":
        df = dt = today - timedelta(days=1)
    elif period == "week":
        df, dt = today - timedelta(days=6), today  # rolling 7 days incl. today
    elif period == "month":
        df, dt = today.replace(day=1), today
    elif period == "quarter":
        q_first = 3 * ((today.month - 1) // 3) + 1
        df, dt = today.replace(month=q_first, day=1), today
    elif period == "year":
        df, dt = today.replace(month=1, day=1), today
    else:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            f"unknown period {period!r} (allowed: {', '.join(_PERIOD_PRESETS)})")
    start = local_day_bounds_utc(df)[0]
    end = local_day_bounds_utc(dt)[1]
    return start, end, df, dt


class PeriodSummary(BaseModel):
    period: str
    date_from: date
    date_to: date
    revenue: Decimal     # Σ completed payments in window
    expenses: Decimal    # Σ expenses (by expense_date) in window
    profit: Decimal      # revenue − expenses
    new_patients: int    # patients registered in window
    visits: int          # visits opened in window
    operations: int      # operations performed in window
    diagnostics: int     # diagnostic tickets completed in window
    treatments: int      # treatments performed in window


@router.get("/period-summary", response_model=PeriodSummary,
            dependencies=[Depends(require_permission("dashboard.view"))])
def period_summary(
    db: Annotated[Session, Depends(get_db)],
    period: str = Query("month", description="today|yesterday|week|month|quarter|year|custom"),
    date_from: date | None = Query(None, description="custom period start (local date)"),
    date_to: date | None = Query(None, description="custom period end (local date, inclusive)"),
) -> PeriodSummary:
    """Headline metrics recomputed for ANY period — powers the dashboard's period
    filter. Каждая метрика считается за выбранное окно (auto-recalc на клиенте при
    смене периода)."""
    start, end, df, dt = _resolve_period_dates(period, date_from, date_to)

    def _count(model, ts_col, *extra) -> int:
        return int(db.execute(
            select(func.count()).select_from(model)
            .where(ts_col >= start, ts_col < end, *extra)
        ).scalar_one())

    revenue = Decimal(db.execute(
        select(func.coalesce(func.sum(Payment.amount), 0))
        .where(Payment.status == "completed",
               Payment.created_at >= start, Payment.created_at < end)
    ).scalar_one())
    expenses = Decimal(db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0))
        .where(Expense.expense_date >= df, Expense.expense_date <= dt)
    ).scalar_one())

    return PeriodSummary(
        period=period, date_from=df, date_to=dt,
        revenue=revenue, expenses=expenses, profit=revenue - expenses,
        new_patients=_count(Patient, Patient.created_at),
        visits=_count(Visit, Visit.opened_at),
        operations=_count(Operation, Operation.performed_at,
                          Operation.status.in_(Operation.DONE_STATUSES)),
        diagnostics=_count(QueueTicket, QueueTicket.created_at,
                           QueueTicket.track == "diagnostic", QueueTicket.status == "done"),
        treatments=_count(Treatment, Treatment.performed_at, Treatment.status == "done"),
    )


# ════════════════════════════════════════════════════════════════════════════
# Finance by direction — доход/расход/прибыль split across the 4 clinic
# directions (Приём / Диагностика / Лечение / Операции) for day/week/month/year.
# ════════════════════════════════════════════════════════════════════════════

# (key, RU label). «lechenie» revenue comes from services categorised «Лечение».
_FINANCE_DIRECTIONS: list[tuple[str, str]] = [
    ("priem", "Приём врачей"),
    ("diagnostika", "Диагностика"),
    ("lechenie", "Лечение"),
    ("operatsii", "Операции"),
]


class DirectionFinanceRow(BaseModel):
    direction: str
    label: str
    revenue: Decimal
    expense: Decimal
    profit: Decimal


class FinanceByDirectionReport(BaseModel):
    period: str                 # day | week | month | year (ending on `date`)
    date_from: date
    date_to: date
    rows: list[DirectionFinanceRow]
    total_revenue: Decimal
    total_expense: Decimal      # ВСЕ расходы клиники за период + COGS операций
    total_profit: Decimal


@router.get("/finance-by-direction", response_model=FinanceByDirectionReport,
            dependencies=[Depends(require_permission("dashboard.view"))])
def finance_by_direction(
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
    period: Literal["day", "week", "month", "year"] = "month",
    d: date | None = Query(None, alias="date"),
    branch_id: uuid.UUID | None = None,
) -> FinanceByDirectionReport:
    """Director finance panel: per-direction Доход/Расход/Прибыль + a clinic total.

    Доход — Σ billed (paid+) visit-item amounts, bucketed by the item's service:
    operations (services linked to an OperationType) → Операции; is_diagnostic →
    Диагностика; category «Лечение» → Лечение; else → Приём. Direct Расход is
    modelled for Операции only (consumables COGS + finance «Операции» expenses) —
    other directions' costs are shared overhead, captured in total_expense (ВСЕ
    expenses of the period + COGS). Window ends on `date` (default today):
    day = that day · week = trailing 7 days · month = MTD · year = YTD.
    """
    today = d or business_today()
    if period == "day":
        df = today
    elif period == "week":
        df = today - timedelta(days=6)
    elif period == "month":
        df = today.replace(day=1)
    else:
        df = today.replace(month=1, day=1)
    start = local_day_bounds_utc(df)[0]
    end = local_day_bounds_utc(today)[1]
    branch = branch_id if branch_id is not None else (
        None if actor.is_superuser else actor.branch_id)

    op_service_ids = set(db.execute(
        select(OperationType.service_id).where(OperationType.service_id.is_not(None))
    ).scalars().all())

    def _direction_of(sid, is_diag: bool, cat_name: str | None) -> str:
        if sid in op_service_ids:
            return "operatsii"
        if is_diag:
            return "diagnostika"
        if cat_name and "леч" in cat_name.lower():
            return "lechenie"
        return "priem"

    revenue = {key: Decimal("0") for key, _ in _FINANCE_DIRECTIONS}
    item_stmt = (
        select(VisitItem.total, VisitItem.service_id, Service.is_diagnostic,
               ServiceCategory.name)
        .join(Visit, VisitItem.visit_id == Visit.id)
        .join(Service, VisitItem.service_id == Service.id)
        .outerjoin(ServiceCategory, Service.category_id == ServiceCategory.id)
        .where(Visit.opened_at >= start, Visit.opened_at < end,
               VisitItem.status.in_(("paid", "in_progress", "done")))
    )
    if branch is not None:
        item_stmt = item_stmt.where(Visit.branch_id == branch)
    for total, sid, is_diag, cat_name in db.execute(item_stmt).all():
        revenue[_direction_of(sid, bool(is_diag), cat_name)] += Decimal(total)

    # Операции direct cost: COGS of consumables written off for operations
    # performed in the window + finance expenses logged under «Операции».
    op_stmt = (
        select(Operation.id)
        .join(Visit, Operation.visit_id == Visit.id)
        .where(Operation.status.in_(Operation.DONE_STATUSES),
               Operation.performed_at >= start, Operation.performed_at < end)
    )
    if branch is not None:
        op_stmt = op_stmt.where(Visit.branch_id == branch)
    op_ids = list(db.execute(op_stmt).scalars().all())
    cogs = Decimal("0")
    if op_ids:
        cogs = Decimal(db.execute(
            select(func.coalesce(
                func.sum(func.abs(StockMovement.quantity) * StockBatch.unit_cost), 0))
            .select_from(StockMovement)
            .join(StockBatch, StockBatch.id == StockMovement.batch_id)
            .where(StockMovement.ref_type == "operation",
                   StockMovement.ref_id.in_(op_ids),
                   StockMovement.movement_type == "write_off")
        ).scalar_one())

    def _expense_sum(category: str | None) -> Decimal:
        stmt = select(func.coalesce(func.sum(Expense.amount), 0)).where(
            Expense.expense_date >= df, Expense.expense_date <= today)
        if category is not None:
            stmt = stmt.where(Expense.category == _OPERATIONS_EXPENSE_CATEGORY)
        if branch is not None:
            stmt = stmt.where(Expense.branch_id == branch)
        return Decimal(db.execute(stmt).scalar_one())

    ops_expense = cogs + _expense_sum(_OPERATIONS_EXPENSE_CATEGORY)
    expense = {key: Decimal("0") for key, _ in _FINANCE_DIRECTIONS}
    expense["operatsii"] = ops_expense

    rows = [
        DirectionFinanceRow(direction=key, label=label,
                            revenue=revenue[key], expense=expense[key],
                            profit=revenue[key] - expense[key])
        for key, label in _FINANCE_DIRECTIONS
    ]
    total_revenue = sum(revenue.values(), Decimal("0"))
    total_expense = _expense_sum(None) + cogs   # all overhead + operations COGS
    return FinanceByDirectionReport(
        period=period, date_from=df, date_to=today, rows=rows,
        total_revenue=total_revenue, total_expense=total_expense,
        total_profit=total_revenue - total_expense,
    )


# ════════════════════════════════════════════════════════════════════════════
# Revenue by doctor — completed-payment revenue per лечащий врач (this month).
# ════════════════════════════════════════════════════════════════════════════


class DoctorRevenueRow(BaseModel):
    doctor_id: uuid.UUID
    doctor_name: str
    revenue: Decimal


class DoctorRevenueReport(BaseModel):
    month: str
    total: Decimal
    doctors: list[DoctorRevenueRow]


@router.get("/revenue-by-doctor", response_model=DoctorRevenueReport,
            dependencies=[Depends(require_permission("dashboard.view"))])
def revenue_by_doctor(
    db: Annotated[Session, Depends(get_db)],
    month: str | None = Query(None, description="YYYY-MM (default: current month)"),
) -> DoctorRevenueReport:
    """Completed-payment revenue attributed to each visit's doctor over a LOCAL
    month, busiest first — the director's «доход по врачам» chart. Same source as
    the payroll revenue base (Visit.doctor_id × completed Payments), so the
    dashboard and payroll agree."""
    month = _resolve_month(month)
    start, end = local_month_bounds_utc(month)
    rows = db.execute(
        select(Visit.doctor_id, func.coalesce(func.sum(Payment.amount), 0))
        .join(Visit, Visit.id == Payment.visit_id)
        .where(
            Payment.status == "completed",
            Payment.created_at >= start,
            Payment.created_at < end,
            Visit.doctor_id.is_not(None),
        )
        .group_by(Visit.doctor_id)
    ).all()
    names = {
        u.id: u.full_name
        for u in db.execute(
            select(User).where(User.id.in_([r[0] for r in rows]))
        ).scalars().all()
    } if rows else {}
    doctors = [
        DoctorRevenueRow(
            doctor_id=doctor_id,
            doctor_name=names.get(doctor_id, "—"),
            revenue=Decimal(total),
        )
        for doctor_id, total in rows
    ]
    doctors.sort(key=lambda d: d.revenue, reverse=True)
    return DoctorRevenueReport(
        month=month,
        total=sum((d.revenue for d in doctors), Decimal("0")),
        doctors=doctors,
    )


# ════════════════════════════════════════════════════════════════════════════
# Operations summary — month funnel (назначено / выполнено / отменено) + P&L.
# ════════════════════════════════════════════════════════════════════════════


class OperationsSummary(BaseModel):
    month: str
    scheduled: int   # назначено (status scheduled/in_progress with a date this month)
    performed: int   # выполнено (performed/completed this month)
    cancelled: int   # отменено (cancelled, had been scheduled for this month)
    revenue: Decimal
    cogs: Decimal
    expenses: Decimal
    profit: Decimal


@router.get("/operations-summary", response_model=OperationsSummary,
            dependencies=[Depends(require_permission("dashboard.view"))])
def operations_summary(
    db: Annotated[Session, Depends(get_db)],
    month: str | None = Query(None, description="YYYY-MM (default: current month)"),
) -> OperationsSummary:
    """Operations funnel + P&L for a LOCAL month: назначено/выполнено/отменено
    counts and revenue − COGS − expenses = profit. Performed is counted by
    performed_at; scheduled & cancelled by scheduled_at (the planned month)."""
    month = _resolve_month(month)
    start, end = local_month_bounds_utc(month)

    performed = db.execute(
        select(func.count()).select_from(Operation).where(
            Operation.status.in_(Operation.DONE_STATUSES),
            Operation.performed_at >= start,
            Operation.performed_at < end,
        )
    ).scalar_one()
    scheduled = db.execute(
        select(func.count()).select_from(Operation).where(
            Operation.status.in_(("scheduled", "in_progress")),
            Operation.scheduled_at >= start,
            Operation.scheduled_at < end,
        )
    ).scalar_one()
    cancelled = db.execute(
        select(func.count()).select_from(Operation).where(
            Operation.status == "cancelled",
            Operation.scheduled_at >= start,
            Operation.scheduled_at < end,
        )
    ).scalar_one()

    # Revenue = Σ price of PERFORMED ops this month; COGS = their FEFO write-offs.
    op_rows = db.execute(
        select(Operation.id, Operation.price).where(
            Operation.status.in_(Operation.DONE_STATUSES),
            Operation.performed_at >= start,
            Operation.performed_at < end,
        )
    ).all()
    op_ids = [r[0] for r in op_rows]
    revenue = sum((r[1] for r in op_rows if r[1] is not None), Decimal("0"))
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

    month_first, month_next = local_month_date_range(month)
    expenses = Decimal(db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(
            Expense.category == _OPERATIONS_EXPENSE_CATEGORY,
            Expense.expense_date >= month_first,
            Expense.expense_date < month_next,
        )
    ).scalar_one())

    return OperationsSummary(
        month=month,
        scheduled=scheduled,
        performed=performed,
        cancelled=cancelled,
        revenue=revenue,
        cogs=cogs,
        expenses=expenses,
        profit=revenue - cogs - expenses,
    )


# ════════════════════════════════════════════════════════════════════════════
# Expense breakdown — this month's expenses grouped by category.
# ════════════════════════════════════════════════════════════════════════════


class ExpenseCategoryRow(BaseModel):
    category: str
    amount: Decimal


class ExpenseBreakdown(BaseModel):
    month: str
    total: Decimal
    categories: list[ExpenseCategoryRow]


@router.get("/expense-breakdown", response_model=ExpenseBreakdown,
            dependencies=[Depends(require_permission("dashboard.view"))])
def expense_breakdown(
    db: Annotated[Session, Depends(get_db)],
    month: str | None = Query(None, description="YYYY-MM (default: current month)"),
) -> ExpenseBreakdown:
    """This LOCAL month's expenses grouped by category, biggest first — the
    director's «структура расходов» chart (includes payroll payouts as their
    own «kind=payroll» rows under their category)."""
    month = _resolve_month(month)
    first, nxt = local_month_date_range(month)
    rows = db.execute(
        select(Expense.category, func.coalesce(func.sum(Expense.amount), 0))
        .where(Expense.expense_date >= first, Expense.expense_date < nxt)
        .group_by(Expense.category)
        .order_by(func.coalesce(func.sum(Expense.amount), 0).desc())
    ).all()
    categories = [
        ExpenseCategoryRow(category=cat, amount=Decimal(amount)) for cat, amount in rows
    ]
    return ExpenseBreakdown(
        month=month,
        total=sum((c.amount for c in categories), Decimal("0")),
        categories=categories,
    )


# ════════════════════════════════════════════════════════════════════════════
# Region trend — new patients per region this month vs last (growing/declining).
# ════════════════════════════════════════════════════════════════════════════


def _prev_month(month: str) -> str:
    year, mon = int(month[:4]), int(month[5:7])
    if mon == 1:
        return f"{year - 1:04d}-12"
    return f"{year:04d}-{mon - 1:02d}"


class RegionTrendRow(BaseModel):
    region: str
    current_new: int       # новые пациенты этого месяца
    previous_new: int      # новые пациенты прошлого месяца
    delta: int             # current − previous (растёт/падает)


class RegionTrendReport(BaseModel):
    month: str
    previous_month: str
    regions: list[RegionTrendRow]


@router.get("/region-trend", response_model=RegionTrendReport,
            dependencies=[Depends(require_permission("dashboard.view"))])
def region_trend(
    db: Annotated[Session, Depends(get_db)],
    month: str | None = Query(None, description="YYYY-MM (default: current month)"),
) -> RegionTrendReport:
    """New-patient acquisition per region this LOCAL month vs the previous month —
    so the director sees which regions are GROWING (positive delta) or DECLINING
    (negative). «New» = patients registered (created_at) in that month."""
    month = _resolve_month(month)
    prev = _prev_month(month)
    cur_start, cur_end = local_month_bounds_utc(month)
    prev_start, prev_end = local_month_bounds_utc(prev)

    def _by_region(start: datetime, end: datetime) -> dict[str, int]:
        rows = db.execute(
            select(Patient.region, func.count())
            .where(Patient.created_at >= start, Patient.created_at < end)
            .group_by(Patient.region)
        ).all()
        return {(r if r else _UNKNOWN_REGION): int(c) for r, c in rows}

    cur = _by_region(cur_start, cur_end)
    old = _by_region(prev_start, prev_end)
    regions = [
        RegionTrendRow(
            region=region,
            current_new=cur.get(region, 0),
            previous_new=old.get(region, 0),
            delta=cur.get(region, 0) - old.get(region, 0),
        )
        for region in sorted(set(cur) | set(old))
    ]
    # Busiest-this-month first; ties keep the larger swing on top.
    regions.sort(key=lambda r: (r.current_new, abs(r.delta)), reverse=True)
    return RegionTrendReport(month=month, previous_month=prev, regions=regions)


# ════════════════════════════════════════════════════════════════════════════
# Patients by district — drill-down within one region (new vs returning).
# ════════════════════════════════════════════════════════════════════════════

# The clinic's home region — the default district drill-down (most patients).
_HOME_REGION = "Ферганская"
_UNKNOWN_DISTRICT = "Не указано"


class DistrictCount(BaseModel):
    district: str
    new_count: int
    returning_count: int
    total: int


class DistrictReport(BaseModel):
    region: str
    total: int
    districts: list[DistrictCount]


@router.get("/patients-by-district", response_model=DistrictReport,
            dependencies=[Depends(require_permission("dashboard.view"))])
def patients_by_district(
    db: Annotated[Session, Depends(get_db)],
    region: str = Query(_HOME_REGION, description="Region to drill into (default: home region)"),
) -> DistrictReport:
    """Patients of ONE region grouped by district, split new vs returning — the
    district drill-down for the director's geographic view. Mirrors
    /patients-by-region but scoped to a single region's districts."""
    visit_counts = (
        select(Visit.patient_id, func.count().label("vc"))
        .group_by(Visit.patient_id)
        .subquery()
    )
    rows = db.execute(
        select(
            Patient.district,
            func.count(Patient.id),
            func.coalesce(
                func.sum(case((func.coalesce(visit_counts.c.vc, 0) > 1, 1), else_=0)), 0
            ),
        )
        .select_from(Patient)
        .outerjoin(visit_counts, visit_counts.c.patient_id == Patient.id)
        .where(Patient.region == region)
        .group_by(Patient.district)
    ).all()

    districts: list[DistrictCount] = []
    for district, total, returning in rows:
        total = int(total)
        returning = int(returning)
        districts.append(DistrictCount(
            district=district if district else _UNKNOWN_DISTRICT,
            new_count=total - returning,
            returning_count=returning,
            total=total,
        ))
    districts.sort(key=lambda d: d.total, reverse=True)
    return DistrictReport(
        region=region,
        total=sum(d.total for d in districts),
        districts=districts,
    )
