"""Smart Search: ONE global endpoint behind the frontend search box.

Finds patients (name / MRN / phone), visits (by visit number) and receipts
(by receipt number) in a single round-trip. Like the timeline aggregation,
the response must not bypass module RBAC: `patients.read` is the base gate
(no search at all without it), the visits / receipts sections appear only
when the caller also holds `visits.read` / `payments.read`.

Phone smartness: receptionists type numbers with separators («+998 90 123»),
the DB stores them normalized («+998901234567») — so when the query looks
like a phone number we additionally match with every non-digit stripped.
"""
from __future__ import annotations

import re
from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.visit import Visit
from app.schemas.search import SearchOut, SearchPatient, SearchReceipt, SearchVisit

router = APIRouter(tags=["Search"])

# A query made only of digits, '+', spaces, dashes or parentheses is a phone.
_PHONEISH = re.compile(r"[\d+\s\-()]+")


def _parse_date(term: str) -> date | None:
    """Recognise a birth-date query in DD.MM.YYYY or YYYY-MM-DD form."""
    for fmt in ("%d.%m.%Y", "%Y-%m-%d", "%d/%m/%Y"):
        try:
            return datetime.strptime(term, fmt).date()
        except ValueError:
            continue
    return None


@router.get("/search", response_model=SearchOut)
def global_search(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("patients.read"))],
    q: str = Query(..., min_length=2, description="Name / MRN / phone / visit no / receipt no"),
    limit: int = Query(10, ge=1, le=25),
) -> SearchOut:
    codes = actor.effective_permission_codes()

    def allowed(code: str) -> bool:
        return actor.is_superuser or code in codes

    term = q.strip()
    like = f"%{term}%"

    # --- Patients (base permission, always present) -------------------------
    patient_clauses = [
        Patient.first_name.ilike(like),
        Patient.last_name.ilike(like),
        Patient.middle_name.ilike(like),
        Patient.mrn.ilike(like),
        Patient.patient_no.ilike(like),  # public 8-digit ID
        Patient.phone.ilike(like),
    ]
    if _PHONEISH.fullmatch(term):
        digits = re.sub(r"\D", "", term)
        if digits:  # «+998 90 123» must find «+998901234567»
            patient_clauses.append(Patient.phone.ilike(f"%{digits}%"))
    dob = _parse_date(term)
    if dob is not None:  # search by birth date (12.05.1990 or 1990-05-12)
        patient_clauses.append(Patient.birth_date == dob)
    patients = db.execute(
        select(Patient)
        .where(or_(*patient_clauses))
        .order_by(Patient.created_at.desc())
        .limit(limit)
    ).scalars().all()

    # --- Visits (visits.read only) ------------------------------------------
    visits: list[Visit] = []
    if allowed("visits.read"):
        visits = db.execute(
            select(Visit)
            .where(Visit.visit_no.ilike(like))
            .order_by(Visit.created_at.desc())
            .limit(limit)
        ).scalars().all()

    # --- Receipts (payments.read only) ---------------------------------------
    receipts: list[Payment] = []
    if allowed("payments.read"):
        receipts = db.execute(
            select(Payment)
            .where(Payment.receipt_no.ilike(like))
            .order_by(Payment.created_at.desc())
            .limit(limit)
        ).scalars().all()

    return SearchOut(
        patients=[SearchPatient.model_validate(p) for p in patients],
        visits=[
            SearchVisit(
                id=v.id,
                visit_no=v.visit_no,
                patient_id=v.patient_id,
                patient_name=v.patient.full_name,  # joined-loaded, no N+1
                flow_status=v.flow_status,
                status=v.status,
            )
            for v in visits
        ],
        receipts=[
            SearchReceipt(
                payment_id=p.id,
                receipt_no=p.receipt_no,
                amount=p.amount,
                visit_id=p.visit_id,
                patient_id=p.patient_id,
            )
            for p in receipts
        ],
    )
