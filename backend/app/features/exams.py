"""EMR: ophthalmology exam (Form 025-8) attached one-to-one to a visit.

Upsert semantics: PUT creates the exam on first call and updates it in place
afterwards — the card is a single legal document per visit, not a series.
"""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.print_forms import build_exam_card_pdf
from app.models.exam import EyeExam
from app.models.patient import Patient
from app.models.visit import Visit
from app.schemas.exam import EyeExamOut, EyeExamUpsert
from app.schemas.search import FrequentDiagnosis

router = APIRouter(tags=["EMR"])


def get_or_404_visit(db: Session, visit_id: UUID) -> Visit:
    visit = db.get(Visit, visit_id)
    if visit is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Visit not found")
    return visit


@router.put("/visits/{visit_id}/exam", response_model=EyeExamOut)
def upsert_exam(
    visit_id: UUID,
    payload: EyeExamUpsert,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.write"))],
) -> EyeExam:
    visit = get_or_404_visit(db, visit_id)
    exam = db.execute(select(EyeExam).where(EyeExam.visit_id == visit_id)).scalar_one_or_none()

    data = payload.model_dump(exclude_unset=True)
    created = exam is None
    if created:
        exam = EyeExam(
            visit_id=visit.id,
            patient_id=visit.patient_id,
            doctor_id=data.pop("doctor_id", None) or actor.id,
        )
        for field, value in data.items():
            setattr(exam, field, value)
        db.add(exam)
    else:
        if data.get("doctor_id") is None:
            data.pop("doctor_id", None)
        for field, value in data.items():
            setattr(exam, field, value)

    db.flush()
    record_audit(db, action="create" if created else "update", entity_type="eye_exam",
                 entity_id=exam.id, actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"{'Created' if created else 'Updated'} eye exam for visit {visit.visit_no}")
    db.commit()
    db.refresh(exam)
    return exam


@router.get(
    "/visits/{visit_id}/exam",
    response_model=EyeExamOut,
    dependencies=[Depends(require_permission("exams.read"))],
)
def get_exam(visit_id: UUID, db: Annotated[Session, Depends(get_db)]) -> EyeExam:
    get_or_404_visit(db, visit_id)
    exam = db.execute(select(EyeExam).where(EyeExam.visit_id == visit_id)).scalar_one_or_none()
    if exam is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No exam recorded for this visit")
    return exam


@router.get(
    "/visits/{visit_id}/exam/card.pdf",
    dependencies=[Depends(require_permission("exams.read"))],
    response_class=Response,
)
def exam_card_pdf(visit_id: UUID, db: Annotated[Session, Depends(get_db)]) -> Response:
    """Printable MoH Form 025-8 for the visit's exam."""
    visit = get_or_404_visit(db, visit_id)
    exam = db.execute(select(EyeExam).where(EyeExam.visit_id == visit_id)).scalar_one_or_none()
    if exam is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No exam recorded for this visit")
    pdf = build_exam_card_pdf(exam)
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="card-025-8-{visit.visit_no}.pdf"'},
    )


# NOTE: literal path — safe from route shadowing because this router has no
# parameterized /exams/{...} sibling (its routes live under /visits/{id}/exam
# and /patients/{id}/exams).
@router.get("/exams/frequent-diagnoses", response_model=list[FrequentDiagnosis])
def frequent_diagnoses(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.read"))],
) -> list[FrequentDiagnosis]:
    """The CURRENT doctor's top-10 most-used diagnoses, for one-click reuse."""
    rows = db.execute(
        select(EyeExam.diagnosis, func.count().label("cnt"))
        .where(
            EyeExam.doctor_id == actor.id,
            EyeExam.diagnosis.is_not(None),
            func.trim(EyeExam.diagnosis) != "",
        )
        .group_by(EyeExam.diagnosis)
        .order_by(func.count().desc(), EyeExam.diagnosis.asc())
        .limit(10)
    ).all()
    return [FrequentDiagnosis(diagnosis=diagnosis, count=count) for diagnosis, count in rows]


@router.get(
    "/patients/{patient_id}/exams",
    response_model=list[EyeExamOut],
    dependencies=[Depends(require_permission("exams.read"))],
)
def patient_exam_history(patient_id: UUID, db: Annotated[Session, Depends(get_db)]) -> list[EyeExam]:
    if db.get(Patient, patient_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Patient not found")
    rows = db.execute(
        select(EyeExam)
        .where(EyeExam.patient_id == patient_id)
        .order_by(EyeExam.exam_date.desc(), EyeExam.created_at.desc())
    ).scalars().all()
    return list(rows)
