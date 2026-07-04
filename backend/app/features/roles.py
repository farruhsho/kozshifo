"""Role management — fully dynamic; permissions attached by code."""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.rbac import Permission, Role, user_roles
from app.schemas.rbac import RoleCreate, RoleOut, RoleUpdate

router = APIRouter(prefix="/roles", tags=["Identity & Access"])


def _resolve_permissions(db: Session, codes: list[str]) -> list[Permission]:
    if not codes:
        return []
    found = list(db.execute(select(Permission).where(Permission.code.in_(codes))).scalars().all())
    missing = set(codes) - {p.code for p in found}
    if missing:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, f"Unknown permission codes: {sorted(missing)}")
    return found


@router.get("", response_model=list[RoleOut], dependencies=[Depends(require_permission("roles.read"))])
def list_roles(db: Annotated[Session, Depends(get_db)]) -> list[Role]:
    return list(db.execute(select(Role).order_by(Role.name)).scalars().all())


@router.post("", response_model=RoleOut, status_code=status.HTTP_201_CREATED)
def create_role(
    payload: RoleCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("roles.create"))],
) -> Role:
    if db.execute(select(Role).where(Role.name == payload.name)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Role name already exists")
    role = Role(name=payload.name, description=payload.description, is_system=False)
    role.permissions = _resolve_permissions(db, payload.permission_codes)
    db.add(role)
    db.flush()
    record_audit(db, action="create", entity_type="role", entity_id=role.id, actor_id=actor.id,
                 summary=f"Created role {role.name}")
    db.commit()
    db.refresh(role)
    return role


@router.get("/{role_id}", response_model=RoleOut, dependencies=[Depends(require_permission("roles.read"))])
def get_role(role_id: UUID, db: Annotated[Session, Depends(get_db)]) -> Role:
    role = db.get(Role, role_id)
    if role is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Role not found")
    return role


@router.patch("/{role_id}", response_model=RoleOut)
def update_role(
    role_id: UUID,
    payload: RoleUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("roles.update"))],
) -> Role:
    role = db.get(Role, role_id)
    if role is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Role not found")
    if role.is_system:
        raise HTTPException(status.HTTP_409_CONFLICT, "System roles cannot be edited")
    if payload.description is not None:
        role.description = payload.description
    if payload.permission_codes is not None:
        role.permissions = _resolve_permissions(db, payload.permission_codes)
    record_audit(db, action="update", entity_type="role", entity_id=role.id, actor_id=actor.id,
                 summary=f"Updated role {role.name}")
    db.commit()
    db.refresh(role)
    return role


@router.delete("/{role_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_role(
    role_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("roles.delete"))],
) -> None:
    role = db.get(Role, role_id)
    if role is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Role not found")
    if role.is_system:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "System roles cannot be deleted")
    assigned = db.execute(
        select(func.count()).select_from(user_roles).where(user_roles.c.role_id == role_id)
    ).scalar_one()
    if assigned:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Роль назначена {assigned} пользователям — снимите назначение перед удалением",
        )
    record_audit(db, action="delete", entity_type="role", entity_id=role.id, actor_id=actor.id,
                 summary=f"Deleted role {role.name}")
    db.delete(role)
    db.commit()
