"""Human-readable identifier generation (MRN, visit no, receipt no, ticket no).

Count-based generation with a uniqueness re-check. This is intentionally simple
for the foundation; under heavy concurrency a dedicated Postgres SEQUENCE (or a
counters table with row locking) is the production-grade replacement.
"""
from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.appointment import Appointment
from app.models.lab import LabOrder
from app.models.optics import OpticsOrder
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.queue import QueueTicket
from app.models.visit import Visit


def _today_str() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d")


def next_mrn(db: Session) -> str:
    n = db.execute(select(func.count()).select_from(Patient)).scalar_one()
    while True:
        n += 1
        candidate = f"P-{n:06d}"
        if db.execute(select(Patient.id).where(Patient.mrn == candidate)).first() is None:
            return candidate


def next_visit_no(db: Session) -> str:
    day = _today_str()
    n = db.execute(select(func.count()).select_from(Visit)).scalar_one()
    while True:
        n += 1
        candidate = f"V-{day}-{n:05d}"
        if db.execute(select(Visit.id).where(Visit.visit_no == candidate)).first() is None:
            return candidate


def next_appointment_no(db: Session) -> str:
    day = _today_str()
    n = db.execute(select(func.count()).select_from(Appointment)).scalar_one()
    while True:
        n += 1
        candidate = f"AP-{day}-{n:05d}"
        if db.execute(select(Appointment.id).where(Appointment.appointment_no == candidate)).first() is None:
            return candidate


def next_optics_no(db: Session) -> str:
    day = _today_str()
    n = db.execute(select(func.count()).select_from(OpticsOrder)).scalar_one()
    while True:
        n += 1
        candidate = f"OPT-{day}-{n:05d}"
        if db.execute(select(OpticsOrder.id).where(OpticsOrder.order_no == candidate)).first() is None:
            return candidate


def next_lab_no(db: Session) -> str:
    day = _today_str()
    n = db.execute(select(func.count()).select_from(LabOrder)).scalar_one()
    while True:
        n += 1
        candidate = f"LAB-{day}-{n:05d}"
        if db.execute(select(LabOrder.id).where(LabOrder.order_no == candidate)).first() is None:
            return candidate


def next_receipt_no(db: Session) -> str:
    day = _today_str()
    n = db.execute(select(func.count()).select_from(Payment)).scalar_one()
    while True:
        n += 1
        candidate = f"R-{day}-{n:05d}"
        if db.execute(select(Payment.id).where(Payment.receipt_no == candidate)).first() is None:
            return candidate


# Queue tracks: "doctor" -> V-001…, "diagnostic" -> D-001… (independent counters).
_TICKET_PREFIX = {"doctor": "V", "diagnostic": "D"}


def next_ticket_number(db: Session, branch_id: UUID, track: str = "doctor") -> str:
    """Per-branch, per-track daily counter, formatted like D-001 / V-001."""
    prefix = _TICKET_PREFIX[track]
    start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    count = db.execute(
        select(func.count())
        .select_from(QueueTicket)
        .where(
            QueueTicket.branch_id == branch_id,
            QueueTicket.track == track,
            QueueTicket.created_at >= start,
        )
    ).scalar_one()
    return f"{prefix}-{count + 1:03d}"
