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


def next_receipt_no(db: Session) -> str:
    day = _today_str()
    n = db.execute(select(func.count()).select_from(Payment)).scalar_one()
    while True:
        n += 1
        candidate = f"R-{day}-{n:05d}"
        if db.execute(select(Payment.id).where(Payment.receipt_no == candidate)).first() is None:
            return candidate


def next_ticket_number(db: Session, branch_id: UUID) -> str:
    """Per-branch daily counter, formatted like A-001."""
    start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    count = db.execute(
        select(func.count())
        .select_from(QueueTicket)
        .where(QueueTicket.branch_id == branch_id, QueueTicket.created_at >= start)
    ).scalar_one()
    return f"A-{count + 1:03d}"
