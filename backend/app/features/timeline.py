"""Patient Timeline: the patient's ENTIRE history as one chronological feed.

Read-only aggregation assembled on the fly from existing tables — visits,
payments, eye exams, device results, operations and treatments. No new writes,
no new models: one straightforward select per source table (each filtered by
patient_id), merged and sorted DESC in Python. Relationship names (e.g. the
operation's type) come through the already-configured joined loads, so there
is no N+1.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.device import DeviceResult
from app.models.exam import EyeExam
from app.models.operation import Operation, Treatment
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.visit import Visit
from app.schemas.timeline import TimelineEvent, TimelineOut

router = APIRouter(tags=["Timeline"])


def _utc(ts: datetime) -> datetime:
    """Normalize to aware UTC.

    On SQLite, server_default timestamps come back *naive* while Python-set
    ones (closed_at, performed_at) are *aware* — mixing them breaks sorting.
    Naive values are stored as UTC here, so tagging them UTC is lossless.
    """
    return ts.replace(tzinfo=timezone.utc) if ts.tzinfo is None else ts


@router.get(
    "/patients/{patient_id}/timeline",
    response_model=TimelineOut,
)
def patient_timeline(
    patient_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("patients.read"))],
    limit: int = Query(200, ge=1, le=500),
) -> TimelineOut:
    if db.get(Patient, patient_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")

    # The aggregation must not bypass module RBAC: each section appears only
    # when the caller holds that module's read code (finance stays invisible
    # to a Doctor, diagnoses stay invisible to a Cashier, etc.).
    codes = actor.effective_permission_codes()

    def allowed(code: str) -> bool:
        return actor.is_superuser or code in codes

    events: list[TimelineEvent] = []

    def add(
        ts: datetime,
        kind: str,
        title: str,
        *,
        detail: str | None = None,
        visit_id: UUID | None = None,
        ref_id: UUID | None = None,
    ) -> None:
        events.append(
            TimelineEvent(ts=_utc(ts), kind=kind, title=title, detail=detail,
                          visit_id=visit_id, ref_id=ref_id)
        )

    # Visits: opened always; closed/cancelled when the visit has been finished.
    visits = db.execute(select(Visit).where(Visit.patient_id == patient_id)).scalars().all()
    for v in visits:
        add(v.opened_at, "visit_opened", f"Визит {v.visit_no} открыт",
            visit_id=v.id, ref_id=v.id)
        if v.closed_at is not None:
            if v.status == "cancelled":
                add(v.closed_at, "visit_cancelled", "Визит отменён",
                    detail=v.visit_no, visit_id=v.id, ref_id=v.id)
            else:
                add(v.closed_at, "visit_closed", "Визит завершён",
                    detail=v.visit_no, visit_id=v.id, ref_id=v.id)

    # Payments (finance — payments.read only): the original payment is history
    # and must never vanish; a refund is a SECOND event at its own time
    # (refund mutates the row in place, so updated_at is the refund moment).
    if allowed("payments.read"):
        payments = db.execute(
            select(Payment).where(Payment.patient_id == patient_id)
        ).scalars().all()
        for p in payments:
            add(p.created_at, "payment", f"Оплата {p.amount} ({p.method})",
                detail=p.receipt_no, visit_id=p.visit_id, ref_id=p.id)
            if p.status == "refunded":
                add(p.updated_at, "refund", f"Возврат {p.amount} ({p.method})",
                    detail=p.receipt_no, visit_id=p.visit_id, ref_id=p.id)

    # Eye exams (EMR — exams.read only: the diagnosis travels in detail).
    if allowed("exams.read"):
        exams = db.execute(
            select(EyeExam).where(EyeExam.patient_id == patient_id)
        ).scalars().all()
        for e in exams:
            add(e.created_at, "exam", "Осмотр окулиста (025-8)",
                detail=e.diagnosis, visit_id=e.visit_id, ref_id=e.id)

    # Device results (refraction / biometry / B-scan files...).
    if allowed("device_results.read"):
        results = db.execute(
            select(DeviceResult).where(DeviceResult.patient_id == patient_id)
        ).scalars().all()
        for r in results:
            original_name = (r.payload or {}).get("original_name")
            add(r.measured_at, "device_result", f"Результат прибора: {r.result_type}",
                detail=original_name, visit_id=r.visit_id, ref_id=r.id)

    # Operations: prescribed always; performed/cancelled as extra events.
    if allowed("operations.read"):
        operations = db.execute(
            select(Operation).where(Operation.patient_id == patient_id)
        ).scalars().all()
        for op in operations:
            name = op.type_name  # via the joined-loaded operation_type relationship
            add(op.created_at, "operation_prescribed", f"Назначена операция: {name}",
                visit_id=op.visit_id, ref_id=op.id)
            if op.performed_at is not None:
                add(op.performed_at, "operation_performed", f"Операция выполнена: {name}",
                    visit_id=op.visit_id, ref_id=op.id)
            if op.status == "cancelled":
                add(op.updated_at, "operation_cancelled", f"Операция отменена: {name}",
                    visit_id=op.visit_id, ref_id=op.id)

    # Treatments: prescription always; dispense/complete as a second event.
    if allowed("treatments.read"):
        treatments = db.execute(
            select(Treatment).where(Treatment.patient_id == patient_id)
        ).scalars().all()
        for t in treatments:
            add(t.created_at, "treatment_prescribed", f"Назначение: {t.name}",
                detail=t.instructions, visit_id=t.visit_id, ref_id=t.id)
            if t.status == "done" and t.performed_at is not None:
                add(t.performed_at, "treatment_done", f"Выполнено/выдано: {t.name}",
                    visit_id=t.visit_id, ref_id=t.id)

    events.sort(key=lambda ev: ev.ts, reverse=True)
    return TimelineOut(patient_id=patient_id, events=events[:limit])
