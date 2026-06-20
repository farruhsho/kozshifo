"""Director reports hub — date-range reports across finance, clinical & CRM.

A single place the director pulls hard numbers from, over an arbitrary LOCAL date
range, with CSV export for every report (Excel-friendly UTF-8 BOM). Distinct from
the live dashboard (today/this-month snapshot): here you pick a window and drill.

Reports:
  • financial      — income (by method) − expenses (by category) = profit
  • by-doctor      — revenue + visits attributed to each attending doctor
  • by-diagnostician — conclusions recorded by each diagnostician/doctor
  • by-patient     — top patients by spend over the window (LTV slice)
  • by-region      — new patients per region in the window (CRM acquisition)
  • by-operation   — performed operations count/revenue + by-surgeon

All monetary values are Decimal → JSON decimal strings; counts are ints.
"""
from __future__ import annotations

import csv
import io
import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Iterable, Sequence

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.dates import business_today, local_day_bounds_utc
from app.core.database import get_db
from app.core.deps import require_permission
from app.models.diagnosis import VisitDiagnosis
from app.models.finance import Expense
from app.models.operation import Operation
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.user import User
from app.models.visit import Visit

router = APIRouter(
    prefix="/reports",
    tags=["Director Reports"],
    dependencies=[Depends(require_permission("reports.view"))],
)


# ════════════════════════════════════════════════════════════════════════════
# Shared: date-range resolution + CSV response.
# ════════════════════════════════════════════════════════════════════════════


def _resolve_range(date_from: date | None, date_to: date | None) -> tuple[date, date, datetime, datetime]:
    """Resolve an inclusive LOCAL [date_from, date_to] window (default: this month
    to today) into both the local dates and the [start, end) UTC instant bounds."""
    today = business_today()
    df = date_from or today.replace(day=1)
    dt = date_to or today
    if df > dt:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "date_from must be <= date_to")
    start = local_day_bounds_utc(df)[0]
    end = local_day_bounds_utc(dt)[1]  # exclusive: start of the day AFTER date_to
    return df, dt, start, end


def _csv(filename: str, header: Sequence[str], rows: Iterable[Sequence]) -> Response:
    """UTF-8 CSV with a BOM so Excel opens Cyrillic columns correctly (mirrors
    finance._csv_response)."""
    buf = io.StringIO()
    writer = csv.writer(buf, lineterminator="\r\n")
    writer.writerow(header)
    writer.writerows(rows)
    return Response(
        content="﻿" + buf.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


_DateFrom = Annotated[date | None, Query(description="Local start date (inclusive)")]
_DateTo = Annotated[date | None, Query(description="Local end date (inclusive)")]


# ════════════════════════════════════════════════════════════════════════════
# Financial — income (by method) − expenses (by category) = profit.
# ════════════════════════════════════════════════════════════════════════════


class AmountRow(BaseModel):
    label: str
    amount: Decimal


class FinancialReport(BaseModel):
    date_from: date
    date_to: date
    income: Decimal
    expenses: Decimal
    profit: Decimal
    by_method: list[AmountRow]
    by_category: list[AmountRow]


_METHOD_LABELS = {"cash": "Наличные", "card": "Карта", "qr": "QR", "transfer": "Перевод"}


def _financial(db: Session, df: date, dt: date, start: datetime, end: datetime) -> FinancialReport:
    method_rows = db.execute(
        select(Payment.method, func.coalesce(func.sum(Payment.amount), 0))
        .where(Payment.status == "completed", Payment.created_at >= start, Payment.created_at < end)
        .group_by(Payment.method)
        .order_by(func.coalesce(func.sum(Payment.amount), 0).desc())
    ).all()
    by_method = [AmountRow(label=_METHOD_LABELS.get(m, m or "—"), amount=Decimal(a)) for m, a in method_rows]
    income = sum((r.amount for r in by_method), Decimal("0"))

    cat_rows = db.execute(
        select(Expense.category, func.coalesce(func.sum(Expense.amount), 0))
        .where(Expense.expense_date >= df, Expense.expense_date <= dt)
        .group_by(Expense.category)
        .order_by(func.coalesce(func.sum(Expense.amount), 0).desc())
    ).all()
    by_category = [AmountRow(label=c, amount=Decimal(a)) for c, a in cat_rows]
    expenses = sum((r.amount for r in by_category), Decimal("0"))

    return FinancialReport(
        date_from=df, date_to=dt,
        income=income, expenses=expenses, profit=income - expenses,
        by_method=by_method, by_category=by_category,
    )


@router.get("/financial", response_model=FinancialReport)
def financial_report(db: Annotated[Session, Depends(get_db)],
                     date_from: _DateFrom = None, date_to: _DateTo = None) -> FinancialReport:
    df, dt, start, end = _resolve_range(date_from, date_to)
    return _financial(db, df, dt, start, end)


@router.get("/financial.csv")
def financial_report_csv(db: Annotated[Session, Depends(get_db)],
                         date_from: _DateFrom = None, date_to: _DateTo = None) -> Response:
    df, dt, start, end = _resolve_range(date_from, date_to)
    r = _financial(db, df, dt, start, end)
    rows = [["Доход", "", r.income]]
    rows += [["  Доход — метод", m.label, m.amount] for m in r.by_method]
    rows += [["Расход", "", r.expenses]]
    rows += [["  Расход — категория", c.label, c.amount] for c in r.by_category]
    rows += [["Прибыль", "", r.profit]]
    return _csv(f"financial_{df}_{dt}.csv", ["Раздел", "Статья", "Сумма"], rows)


# ════════════════════════════════════════════════════════════════════════════
# By-doctor — revenue + visits attributed to each attending doctor.
# ════════════════════════════════════════════════════════════════════════════


class DoctorRow(BaseModel):
    doctor_id: uuid.UUID
    doctor_name: str
    revenue: Decimal
    visits: int
    payroll_expense: Decimal  # salary paid out to this doctor in the window
    net_profit: Decimal  # revenue − payroll_expense (the clinic's cut)


def _by_doctor(db: Session, df: date, dt: date, start: datetime, end: datetime) -> list[DoctorRow]:
    revenue = {
        did: Decimal(total) for did, total in db.execute(
            select(Visit.doctor_id, func.coalesce(func.sum(Payment.amount), 0))
            .join(Visit, Visit.id == Payment.visit_id)
            .where(Payment.status == "completed", Payment.created_at >= start,
                   Payment.created_at < end, Visit.doctor_id.is_not(None))
            .group_by(Visit.doctor_id)
        ).all()
    }
    visits = {
        did: int(n) for did, n in db.execute(
            select(Visit.doctor_id, func.count())
            .where(Visit.doctor_id.is_not(None), Visit.opened_at >= start, Visit.opened_at < end)
            .group_by(Visit.doctor_id)
        ).all()
    }
    # Salary actually paid to each doctor in the window (kind="payroll" expenses).
    payroll = {
        uid: Decimal(total) for uid, total in db.execute(
            select(Expense.payroll_user_id, func.coalesce(func.sum(Expense.amount), 0))
            .where(Expense.kind == "payroll", Expense.payroll_user_id.is_not(None),
                   Expense.expense_date >= df, Expense.expense_date <= dt)
            .group_by(Expense.payroll_user_id)
        ).all()
    }
    ids = set(revenue) | set(visits) | set(payroll)
    names = {u.id: u.full_name for u in db.execute(select(User).where(User.id.in_(ids))).scalars().all()} if ids else {}
    rows = []
    for did in ids:
        rev = revenue.get(did, Decimal("0"))
        exp = payroll.get(did, Decimal("0"))
        rows.append(DoctorRow(
            doctor_id=did, doctor_name=names.get(did, "—"),
            revenue=rev, visits=visits.get(did, 0),
            payroll_expense=exp, net_profit=rev - exp,
        ))
    rows.sort(key=lambda r: (r.revenue, r.visits), reverse=True)
    return rows


@router.get("/by-doctor", response_model=list[DoctorRow])
def by_doctor(db: Annotated[Session, Depends(get_db)],
              date_from: _DateFrom = None, date_to: _DateTo = None) -> list[DoctorRow]:
    df, dt, start, end = _resolve_range(date_from, date_to)
    return _by_doctor(db, df, dt, start, end)


@router.get("/by-doctor.csv")
def by_doctor_csv(db: Annotated[Session, Depends(get_db)],
                  date_from: _DateFrom = None, date_to: _DateTo = None) -> Response:
    df, dt, start, end = _resolve_range(date_from, date_to)
    rows = [[r.doctor_name, r.revenue, r.visits, r.payroll_expense, r.net_profit]
            for r in _by_doctor(db, df, dt, start, end)]
    return _csv(f"by_doctor_{df}_{dt}.csv",
                ["Врач", "Выручка", "Визитов", "Зарплата", "Чистая прибыль"], rows)


# ════════════════════════════════════════════════════════════════════════════
# By-diagnostician — conclusions recorded by each diagnostician / doctor.
# ════════════════════════════════════════════════════════════════════════════


class DiagnosticianRow(BaseModel):
    user_id: uuid.UUID | None
    name: str
    conclusions: int


def _by_diagnostician(db: Session, start: datetime, end: datetime) -> list[DiagnosticianRow]:
    rows = db.execute(
        select(VisitDiagnosis.doctor_id, func.count())
        .where(VisitDiagnosis.created_at >= start, VisitDiagnosis.created_at < end)
        .group_by(VisitDiagnosis.doctor_id)
    ).all()
    ids = {did for did, _ in rows if did is not None}
    names = {u.id: u.full_name for u in db.execute(select(User).where(User.id.in_(ids))).scalars().all()} if ids else {}
    out = [
        DiagnosticianRow(user_id=did, name=names.get(did, "—") if did else "Без автора", conclusions=int(n))
        for did, n in rows
    ]
    out.sort(key=lambda r: r.conclusions, reverse=True)
    return out


@router.get("/by-diagnostician", response_model=list[DiagnosticianRow])
def by_diagnostician(db: Annotated[Session, Depends(get_db)],
                     date_from: _DateFrom = None, date_to: _DateTo = None) -> list[DiagnosticianRow]:
    _, _, start, end = _resolve_range(date_from, date_to)
    return _by_diagnostician(db, start, end)


@router.get("/by-diagnostician.csv")
def by_diagnostician_csv(db: Annotated[Session, Depends(get_db)],
                         date_from: _DateFrom = None, date_to: _DateTo = None) -> Response:
    df, dt, start, end = _resolve_range(date_from, date_to)
    rows = [[r.name, r.conclusions] for r in _by_diagnostician(db, start, end)]
    return _csv(f"by_diagnostician_{df}_{dt}.csv", ["Диагност", "Заключений"], rows)


# ════════════════════════════════════════════════════════════════════════════
# By-patient — top patients by spend over the window (LTV slice).
# ════════════════════════════════════════════════════════════════════════════


class PatientSpendRow(BaseModel):
    patient_id: uuid.UUID
    mrn: str | None
    full_name: str
    total_paid: Decimal
    visits: int


def _by_patient(db: Session, start: datetime, end: datetime, limit: int) -> list[PatientSpendRow]:
    rows = db.execute(
        select(
            Payment.patient_id,
            func.coalesce(func.sum(Payment.amount), 0),
            func.count(func.distinct(Payment.visit_id)),
        )
        .where(Payment.status == "completed", Payment.created_at >= start, Payment.created_at < end)
        .group_by(Payment.patient_id)
        .order_by(func.coalesce(func.sum(Payment.amount), 0).desc())
        .limit(limit)
    ).all()
    ids = [pid for pid, _, _ in rows]
    patients = {p.id: p for p in db.execute(select(Patient).where(Patient.id.in_(ids))).scalars().all()} if ids else {}
    out: list[PatientSpendRow] = []
    for pid, total, visits in rows:
        p = patients.get(pid)
        out.append(PatientSpendRow(
            patient_id=pid,
            mrn=p.mrn if p else None,
            full_name=p.full_name if p else "—",
            total_paid=Decimal(total),
            visits=int(visits),
        ))
    return out


@router.get("/by-patient", response_model=list[PatientSpendRow])
def by_patient(db: Annotated[Session, Depends(get_db)],
               date_from: _DateFrom = None, date_to: _DateTo = None,
               limit: int = Query(50, ge=1, le=500)) -> list[PatientSpendRow]:
    _, _, start, end = _resolve_range(date_from, date_to)
    return _by_patient(db, start, end, limit)


@router.get("/by-patient.csv")
def by_patient_csv(db: Annotated[Session, Depends(get_db)],
                   date_from: _DateFrom = None, date_to: _DateTo = None,
                   limit: int = Query(500, ge=1, le=2000)) -> Response:
    df, dt, start, end = _resolve_range(date_from, date_to)
    rows = [[r.mrn or "", r.full_name, r.total_paid, r.visits] for r in _by_patient(db, start, end, limit)]
    return _csv(f"by_patient_{df}_{dt}.csv", ["MRN", "Пациент", "Оплачено", "Визитов"], rows)


# ════════════════════════════════════════════════════════════════════════════
# By-region — new patients per region registered in the window (CRM acquisition).
# ════════════════════════════════════════════════════════════════════════════


_UNKNOWN_REGION = "Не указано"


class RegionRow(BaseModel):
    region: str
    new_patients: int


def _by_region(db: Session, start: datetime, end: datetime) -> list[RegionRow]:
    rows = db.execute(
        select(Patient.region, func.count())
        .where(Patient.created_at >= start, Patient.created_at < end)
        .group_by(Patient.region)
    ).all()
    out = [RegionRow(region=r or _UNKNOWN_REGION, new_patients=int(n)) for r, n in rows]
    out.sort(key=lambda r: r.new_patients, reverse=True)
    return out


@router.get("/by-region", response_model=list[RegionRow])
def by_region(db: Annotated[Session, Depends(get_db)],
              date_from: _DateFrom = None, date_to: _DateTo = None) -> list[RegionRow]:
    _, _, start, end = _resolve_range(date_from, date_to)
    return _by_region(db, start, end)


@router.get("/by-region.csv")
def by_region_csv(db: Annotated[Session, Depends(get_db)],
                  date_from: _DateFrom = None, date_to: _DateTo = None) -> Response:
    df, dt, start, end = _resolve_range(date_from, date_to)
    rows = [[r.region, r.new_patients] for r in _by_region(db, start, end)]
    return _csv(f"by_region_{df}_{dt}.csv", ["Регион", "Новых пациентов"], rows)


# ════════════════════════════════════════════════════════════════════════════
# By-operation — performed operations + revenue, with a by-surgeon breakdown.
# ════════════════════════════════════════════════════════════════════════════


class SurgeonRow(BaseModel):
    surgeon_id: uuid.UUID | None
    surgeon_name: str
    count: int
    revenue: Decimal


class OperationsReport(BaseModel):
    date_from: date
    date_to: date
    count: int
    revenue: Decimal
    by_surgeon: list[SurgeonRow]


def _by_operation(db: Session, df: date, dt: date, start: datetime, end: datetime) -> OperationsReport:
    base = (
        Operation.status.in_(Operation.DONE_STATUSES),
        Operation.performed_at >= start,
        Operation.performed_at < end,
    )
    count, revenue = db.execute(
        select(func.count(), func.coalesce(func.sum(Operation.price), 0)).where(*base)
    ).one()
    rows = db.execute(
        select(Operation.surgeon_id, func.count(), func.coalesce(func.sum(Operation.price), 0))
        .where(*base).group_by(Operation.surgeon_id)
    ).all()
    ids = {sid for sid, _, _ in rows if sid is not None}
    names = {u.id: u.full_name for u in db.execute(select(User).where(User.id.in_(ids))).scalars().all()} if ids else {}
    by_surgeon = [
        SurgeonRow(surgeon_id=sid, surgeon_name=names.get(sid, "—") if sid else "Без хирурга",
                   count=int(c), revenue=Decimal(rev))
        for sid, c, rev in rows
    ]
    by_surgeon.sort(key=lambda s: s.revenue, reverse=True)
    return OperationsReport(date_from=df, date_to=dt, count=int(count),
                            revenue=Decimal(revenue), by_surgeon=by_surgeon)


@router.get("/by-operation", response_model=OperationsReport)
def by_operation(db: Annotated[Session, Depends(get_db)],
                 date_from: _DateFrom = None, date_to: _DateTo = None) -> OperationsReport:
    df, dt, start, end = _resolve_range(date_from, date_to)
    return _by_operation(db, df, dt, start, end)


@router.get("/by-operation.csv")
def by_operation_csv(db: Annotated[Session, Depends(get_db)],
                     date_from: _DateFrom = None, date_to: _DateTo = None) -> Response:
    df, dt, start, end = _resolve_range(date_from, date_to)
    r = _by_operation(db, df, dt, start, end)
    rows = [[s.surgeon_name, s.count, s.revenue] for s in r.by_surgeon]
    rows.append(["ИТОГО", r.count, r.revenue])
    return _csv(f"by_operation_{df}_{dt}.csv", ["Хирург", "Операций", "Выручка"], rows)
