"""Cabinet (consulting room) management.

Cabinets are created/edited ONLY by the Super Admin (`cabinets.manage`). Everyone
who calls patients (reception, doctor, diagnost, treatment room, director) can
READ the list (`cabinets.read`) to populate the «Мой кабинет» login picker.
"""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.branch import Branch
from app.models.cabinet import Cabinet
from app.schemas.cabinet import CabinetCreate, CabinetOut, CabinetUpdate

router = APIRouter(prefix="/cabinets", tags=["Cabinets"])


def _dupe_name(db: Session, branch_id: UUID, name: str, exclude_id: UUID | None = None) -> bool:
    stmt = select(Cabinet.id).where(Cabinet.branch_id == branch_id, Cabinet.name == name)
    if exclude_id is not None:
        stmt = stmt.where(Cabinet.id != exclude_id)
    return db.execute(stmt.limit(1)).first() is not None


@router.get("", response_model=list[CabinetOut],
            dependencies=[Depends(require_permission("cabinets.read"))])
def list_cabinets(
    db: Annotated[Session, Depends(get_db)],
    branch_id: UUID | None = Query(None),
    include_inactive: bool = Query(False),
) -> list[Cabinet]:
    stmt = select(Cabinet)
    if branch_id is not None:
        stmt = stmt.where(Cabinet.branch_id == branch_id)
    if not include_inactive:
        stmt = stmt.where(Cabinet.is_active.is_(True))
    return list(db.execute(stmt.order_by(Cabinet.name)).scalars().all())


@router.post("", response_model=CabinetOut, status_code=status.HTTP_201_CREATED)
def create_cabinet(
    payload: CabinetCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("cabinets.manage"))],
) -> Cabinet:
    if db.get(Branch, payload.branch_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Branch not found")
    if _dupe_name(db, payload.branch_id, payload.name):
        raise HTTPException(status.HTTP_409_CONFLICT, "Cabinet name already exists in this branch")
    cabinet = Cabinet(branch_id=payload.branch_id, name=payload.name, kind=payload.kind)
    db.add(cabinet)
    db.flush()
    record_audit(db, action="create", entity_type="cabinet", entity_id=cabinet.id, actor_id=actor.id,
                 branch_id=cabinet.branch_id, summary=f"Created cabinet {cabinet.name}")
    db.commit()
    db.refresh(cabinet)
    return cabinet


@router.patch("/{cabinet_id}", response_model=CabinetOut)
def update_cabinet(
    cabinet_id: UUID,
    payload: CabinetUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("cabinets.manage"))],
) -> Cabinet:
    cabinet = db.get(Cabinet, cabinet_id)
    if cabinet is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cabinet not found")
    data = payload.model_dump(exclude_unset=True)
    if "name" in data and data["name"] != cabinet.name and _dupe_name(
        db, cabinet.branch_id, data["name"], exclude_id=cabinet.id
    ):
        raise HTTPException(status.HTTP_409_CONFLICT, "Cabinet name already exists in this branch")
    for field, value in data.items():
        setattr(cabinet, field, value)
    record_audit(db, action="update", entity_type="cabinet", entity_id=cabinet.id, actor_id=actor.id,
                 branch_id=cabinet.branch_id, summary=f"Updated cabinet {cabinet.name}")
    db.commit()
    db.refresh(cabinet)
    return cabinet
