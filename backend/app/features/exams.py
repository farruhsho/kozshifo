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
from app.core.print_forms import build_exam_card_pdf, build_prescription_pdf
from app.models.diagnosis import Diagnosis, VisitDiagnosis
from app.models.exam import EyeExam
from app.models.exam_template import ExamTemplate
from app.models.patient import Patient
from app.models.visit import Visit
from app.schemas.common import Message
from app.schemas.exam import (
    EyeExamOut,
    EyeExamUpsert,
    DiagnosticConclusionCreate,
    VisitDiagnosisCreate,
    VisitDiagnosisOut,
)
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


# ── Visit diagnoses (TZ §7.1.5 — a visit accumulates many) ───────────────────
def _visit_diagnoses(db: Session, visit_id: UUID) -> list[VisitDiagnosis]:
    return list(
        db.execute(
            select(VisitDiagnosis)
            .where(VisitDiagnosis.visit_id == visit_id)
            .order_by(VisitDiagnosis.created_at.asc())
        ).scalars().all()
    )


@router.get(
    "/visits/{visit_id}/diagnoses",
    response_model=list[VisitDiagnosisOut],
    dependencies=[Depends(require_permission("exams.read"))],
)
def list_diagnoses(visit_id: UUID, db: Annotated[Session, Depends(get_db)]) -> list[VisitDiagnosis]:
    get_or_404_visit(db, visit_id)
    return _visit_diagnoses(db, visit_id)


@router.post("/visits/{visit_id}/diagnoses", response_model=VisitDiagnosisOut,
             status_code=status.HTTP_201_CREATED)
def add_diagnosis(
    visit_id: UUID,
    payload: VisitDiagnosisCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.write"))],
) -> VisitDiagnosis:
    visit = get_or_404_visit(db, visit_id)
    diagnosis = VisitDiagnosis(
        visit_id=visit.id,
        patient_id=visit.patient_id,
        doctor_id=actor.id,
        diagnosis=payload.diagnosis.strip(),
        icd10=(payload.icd10.strip() if payload.icd10 and payload.icd10.strip() else None),
        cabinet=actor.cabinet,
    )
    db.add(diagnosis)
    db.flush()
    record_audit(db, action="create", entity_type="visit_diagnosis",
                 entity_id=diagnosis.id, actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Added diagnosis «{diagnosis.diagnosis}» to visit {visit.visit_no}")
    db.commit()
    db.refresh(diagnosis)
    return diagnosis


@router.post("/visits/{visit_id}/diagnostic-conclusion", response_model=VisitDiagnosisOut,
             status_code=status.HTTP_201_CREATED)
def record_diagnostic_conclusion(
    visit_id: UUID,
    payload: DiagnosticConclusionCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("diagnoses.record"))],
) -> VisitDiagnosis:
    """A diagnostician (e.g. УЗИ) records a conclusion on the visit, chosen from the
    catalog scoped to their allowed diagnoses (`user_diagnoses`), or typed free-form
    when unrestricted. Stored as a `VisitDiagnosis` authored by the recorder, so it
    shows on the doctor card and patient timeline next to the УЗИ PDF — separate
    from `exams.write` (the diagnostician doesn't author the full 025-8 exam)."""
    visit = get_or_404_visit(db, visit_id)
    text: str
    icd10: str | None = None
    if payload.diagnosis_id is not None:
        catalog = db.get(Diagnosis, payload.diagnosis_id)
        if catalog is None or not catalog.is_active:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown or inactive diagnosis")
        # Enforce the recorder's allowed subset (empty membership = unrestricted).
        allowed = {d.id for d in actor.diagnoses}
        if allowed and catalog.id not in allowed:
            raise HTTPException(status.HTTP_403_FORBIDDEN,
                                "Этот диагноз не разрешён для вашего профиля")
        text = catalog.name
        icd10 = catalog.icd10
    elif payload.diagnosis and payload.diagnosis.strip():
        # A restricted user must pick from their allowed catalog, not free-type.
        if actor.diagnoses:
            raise HTTPException(status.HTTP_403_FORBIDDEN,
                                "Выберите заключение из вашего разрешённого списка")
        text = payload.diagnosis.strip()
        icd10 = payload.icd10.strip() if payload.icd10 and payload.icd10.strip() else None
    else:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            "Provide diagnosis_id (from the catalog) or diagnosis text")
    conclusion = VisitDiagnosis(
        visit_id=visit.id, patient_id=visit.patient_id, doctor_id=actor.id,
        diagnosis=text, icd10=icd10, cabinet=actor.cabinet,
    )
    db.add(conclusion)
    db.flush()
    record_audit(db, action="create", entity_type="visit_diagnosis", entity_id=conclusion.id,
                 actor_id=actor.id, branch_id=visit.branch_id,
                 summary=f"Recorded conclusion «{text}» on visit {visit.visit_no}")
    db.commit()
    db.refresh(conclusion)
    return conclusion


@router.delete("/visits/{visit_id}/diagnostic-conclusion/{conclusion_id}",
               status_code=status.HTTP_204_NO_CONTENT)
def delete_diagnostic_conclusion(
    visit_id: UUID,
    conclusion_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("diagnoses.record"))],
) -> None:
    """Medical-safety amend: let a diagnostician remove a WRONG conclusion they
    themselves just recorded on THIS visit, under `diagnoses.record` (no need for
    the doctor-only `exams.write`). Guards keep it narrow:

    * only the record's own author (`doctor_id == actor.id`) — never someone
      else's / the doctor's conclusion (404, indistinguishable from «not found»);
    * only while the visit is still live (not completed/cancelled) — a closed
      legal document isn't retro-edited.

    Audited as `delete` so the removal is traceable."""
    visit = get_or_404_visit(db, visit_id)
    conclusion = db.get(VisitDiagnosis, conclusion_id)
    if conclusion is None or conclusion.visit_id != visit_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Conclusion not found")
    # Only the author may amend their own record; hide others' as «not found».
    if conclusion.doctor_id != actor.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Conclusion not found")
    if visit.status in ("completed", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Визит завершён — заключение изменить нельзя")
    summary = f"Removed own conclusion «{conclusion.diagnosis}» from visit {visit.visit_no}"
    db.delete(conclusion)
    record_audit(db, action="delete", entity_type="visit_diagnosis",
                 entity_id=conclusion_id, actor_id=actor.id, branch_id=visit.branch_id,
                 summary=summary)
    db.commit()


@router.delete("/diagnoses/{diagnosis_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_diagnosis(
    diagnosis_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.write"))],
) -> None:
    diagnosis = db.get(VisitDiagnosis, diagnosis_id)
    if diagnosis is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Diagnosis not found")
    visit = db.get(Visit, diagnosis.visit_id)
    summary = f"Removed diagnosis «{diagnosis.diagnosis}»"
    db.delete(diagnosis)
    record_audit(db, action="delete", entity_type="visit_diagnosis",
                 entity_id=diagnosis_id, actor_id=actor.id,
                 branch_id=visit.branch_id if visit else None, summary=summary)
    db.commit()


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
    pdf = build_exam_card_pdf(exam, diagnoses=_visit_diagnoses(db, visit_id))
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="card-025-8-{visit.visit_no}.pdf"'},
    )


@router.get(
    "/exams/{exam_id}/prescription.pdf",
    dependencies=[Depends(require_permission("exams.read"))],
    response_class=Response,
)
def exam_prescription_pdf(exam_id: UUID, db: Annotated[Session, Depends(get_db)]) -> Response:
    """Printable prescription (РЕЦЕПТ) — очки refraction + назначения — for one exam."""
    exam = db.get(EyeExam, exam_id)
    if exam is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Exam not found")
    pdf = build_prescription_pdf(exam, diagnoses=_visit_diagnoses(db, exam.visit_id))
    visit_no = exam.visit.visit_no if exam.visit else str(exam_id)
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="prescription-{visit_no}.pdf"'},
    )


# NOTE: literal path — matches before /exams/{exam_id}/prescription.pdf because
# «frequent-diagnoses» has no /prescription.pdf suffix; the two never collide.
@router.get("/exams/frequent-diagnoses", response_model=list[FrequentDiagnosis])
def frequent_diagnoses(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("exams.read"))],
) -> list[FrequentDiagnosis]:
    """The CURRENT doctor's top-10 most-used diagnoses, for one-click reuse."""
    rows = db.execute(
        select(VisitDiagnosis.diagnosis, func.count().label("cnt"))
        .where(
            VisitDiagnosis.doctor_id == actor.id,
            func.trim(VisitDiagnosis.diagnosis) != "",
        )
        .group_by(VisitDiagnosis.diagnosis)
        .order_by(func.count().desc(), VisitDiagnosis.diagnosis.asc())
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
