"""Branch / clinic location management."""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_any_permission, require_permission
from app.models.branch import Branch
from app.schemas.branch import BranchCreate, BranchOut, BranchUpdate

router = APIRouter(prefix="/branches", tags=["Branches"])


@router.get("", response_model=list[BranchOut])
def list_branches(
    db: Annotated[Session, Depends(get_db)],
    # Warehouse roles (inventory.manage, no branches.read) must be able to load the
    # destination-branch list for the stock-transfer dialog — so ANY of these
    # inventory/branch read rights unlocks the listing. Mutation endpoints below
    # keep their strict per-branch permission.
    _actor: Annotated[
        CurrentUser,
        Depends(require_any_permission("branches.read", "inventory.read", "inventory.manage")),
    ],
) -> list[Branch]:
    return list(db.execute(select(Branch).order_by(Branch.name)).scalars().all())


@router.post("", response_model=BranchOut, status_code=status.HTTP_201_CREATED)
def create_branch(
    payload: BranchCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("branches.create"))],
) -> Branch:
    if db.execute(select(Branch).where(Branch.code == payload.code)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Branch code already exists")
    branch = Branch(**payload.model_dump())
    db.add(branch)
    db.flush()
    record_audit(db, action="create", entity_type="branch", entity_id=branch.id, actor_id=actor.id,
                 summary=f"Created branch {branch.name}")
    db.commit()
    db.refresh(branch)
    return branch


@router.patch("/{branch_id}", response_model=BranchOut)
def update_branch(
    branch_id: UUID,
    payload: BranchUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("branches.update"))],
) -> Branch:
    branch = db.get(Branch, branch_id)
    if branch is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Branch not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(branch, field, value)
    record_audit(db, action="update", entity_type="branch", entity_id=branch.id, actor_id=actor.id,
                 summary=f"Updated branch {branch.name}")
    db.commit()
    db.refresh(branch)
    return branch
