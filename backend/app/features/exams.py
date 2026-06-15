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
from app.models.exam_template import ExamTemplate
from app.models.patient import Patient
from app.models.visit import Visit
from app.schemas.common import Message
from app.schemas.exam import EyeExamOut, EyeExamUpsert
from app.schemas.exam_template import ExamTemplateCreate, ExamTemplateOut
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


# ── Exam-conclusion templates (reusable назначения) ──────────────────────────
# A doctor saves the current diagnosis/ICD-10/recommendations under a name and
# reuses it on the next patient instead of retyping. Scoped to the owner.

@router.get("/exam-templates", response_model=list[ExamTemplateOut])
def list_exam_templates(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.write"))],
) -> list[ExamTemplate]:
    """The current doctor's saved conclusion templates, newest first."""
    return list(db.execute(
        select(ExamTemplate)
        .where(ExamTemplate.doctor_id == actor.id)
        .order_by(ExamTemplate.created_at.desc())
    ).scalars().all())


@router.post("/exam-templates", response_model=ExamTemplateOut, status_code=status.HTTP_201_CREATED)
def create_exam_template(
    payload: ExamTemplateCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.write"))],
) -> ExamTemplate:
    """Save the current conclusion as a named template. Re-using a name replaces it."""
    existing = db.execute(
        select(ExamTemplate).where(
            ExamTemplate.doctor_id == actor.id, ExamTemplate.name == payload.name
        )
    ).scalar_one_or_none()
    template = existing or ExamTemplate(doctor_id=actor.id, name=payload.name)
    template.diagnosis = payload.diagnosis
    template.icd10 = payload.icd10
    template.recommendations = payload.recommendations
    if existing is None:
        db.add(template)
    db.flush()
    record_audit(db, action="create" if existing is None else "update",
                 entity_type="exam_template", entity_id=template.id, actor_id=actor.id,
                 summary=f"Saved exam template '{template.name}'")
    db.commit()
    db.refresh(template)
    return template


@router.delete("/exam-templates/{template_id}", response_model=Message)
def delete_exam_template(
    template_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.write"))],
) -> Message:
    template = db.get(ExamTemplate, template_id)
    if template is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Template not found")
    if template.doctor_id != actor.id and not actor.is_superuser:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your template")
    record_audit(db, action="delete", entity_type="exam_template", entity_id=template.id,
                 actor_id=actor.id, summary=f"Deleted exam template '{template.name}'")
    db.delete(template)
    db.commit()
    return Message(detail="Template deleted")


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
