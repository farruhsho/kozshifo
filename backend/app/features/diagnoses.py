"""Diagnosis / conclusion catalog (справочник заключений).

A reusable reference list of diagnoses/conclusions the director maintains. Staff
pick from it instead of free-typing; a diagnostician's allowed subset (see
`user_diagnoses`) scopes the «Приём» picker. Distinct from `visit_diagnoses`
(the per-visit instances the doctor records).
"""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.diagnosis import Diagnosis
from app.schemas.diagnosis import DiagnosisCreate, DiagnosisOut, DiagnosisUpdate

router = APIRouter(prefix="/diagnoses", tags=["Diagnoses"])


@router.get("", response_model=list[DiagnosisOut],
            dependencies=[Depends(require_permission("diagnoses.read"))])
def list_diagnoses(
    db: Annotated[Session, Depends(get_db)],
    q: str | None = Query(None, description="Search by code or name"),
    category: str | None = None,
    active_only: bool = True,
) -> list[Diagnosis]:
    stmt = select(Diagnosis)
    if active_only:
        stmt = stmt.where(Diagnosis.is_active.is_(True))
    if category:
        stmt = stmt.where(Diagnosis.category == category)
    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(or_(Diagnosis.code.ilike(like), Diagnosis.name.ilike(like)))
    rows = db.execute(stmt.order_by(Diagnosis.category, Diagnosis.name)).scalars().all()
    return list(rows)


@router.get("/mine", response_model=list[DiagnosisOut],
            dependencies=[Depends(require_permission("diagnoses.read"))])
def my_diagnoses(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("diagnoses.read"))],
) -> list[Diagnosis]:
    """The current user's ALLOWED diagnoses (user_diagnoses) for the «Приём»
    conclusion picker. Empty allowed set = unrestricted → all active diagnoses."""
    if actor.diagnoses:
        return sorted(
            [d for d in actor.diagnoses if d.is_active],
            key=lambda d: (d.category or "", d.name),
        )
    return list(
        db.execute(
            select(Diagnosis).where(Diagnosis.is_active.is_(True))
            .order_by(Diagnosis.category, Diagnosis.name)
        ).scalars().all()
    )


@router.post("", response_model=DiagnosisOut, status_code=status.HTTP_201_CREATED)
def create_diagnosis(
    payload: DiagnosisCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("diagnoses.manage"))],
) -> Diagnosis:
    if db.execute(select(Diagnosis).where(Diagnosis.code == payload.code)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, f"Diagnosis code {payload.code} already exists")
    diagnosis = Diagnosis(**payload.model_dump())
    db.add(diagnosis)
    db.flush()
    record_audit(db, action="create", entity_type="diagnosis", entity_id=diagnosis.id,
                 actor_id=actor.id, summary=f"Created diagnosis {diagnosis.code} — {diagnosis.name}")
    db.commit()
    db.refresh(diagnosis)
    return diagnosis


@router.patch("/{diagnosis_id}", response_model=DiagnosisOut)
def update_diagnosis(
    diagnosis_id: UUID,
    payload: DiagnosisUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("diagnoses.manage"))],
) -> Diagnosis:
    diagnosis = db.get(Diagnosis, diagnosis_id)
    if diagnosis is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Diagnosis not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(diagnosis, field, value)
    record_audit(db, action="update", entity_type="diagnosis", entity_id=diagnosis.id,
                 actor_id=actor.id, summary=f"Updated diagnosis {diagnosis.code}")
    db.commit()
    db.refresh(diagnosis)
    return diagnosis
