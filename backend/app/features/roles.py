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
from app.core.visibility import OWNER_ROLE, caller_is_owner, owner_user_id_set
from app.models.rbac import Permission, Role, user_roles
from app.models.user import User
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


def _actor_is_owner(db: Session, actor: User) -> bool:
    """Owner tier = a superuser OR a holder of the Superadmin (owner) role. The
    owner is exempt from the subset / ghost / privilege-escalation guards."""
    return caller_is_owner(actor, owner_user_id_set(db))


def _guard_permission_subset(db: Session, actor: User, codes: list[str]) -> None:
    """Anti privilege-escalation: a non-owner may not put any permission code into
    a role that they do not themselves already hold. Otherwise a delegate with
    roles.update could mint rights they lack (users.delete, payments.refund …) and
    then assign the beefed-up role to themselves. Owner / superuser is exempt."""
    if _actor_is_owner(db, actor):
        return
    own = actor.effective_permission_codes()
    escalated = sorted(set(codes) - own)
    if escalated:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"Нельзя выдать права, которых у вас нет: {', '.join(escalated)}",
        )


@router.get("", response_model=list[RoleOut], dependencies=[Depends(require_permission("roles.read"))])
def list_roles(
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
) -> list[Role]:
    stmt = select(Role).order_by(Role.name)
    if not _actor_is_owner(db, actor):
        # Ghost invariant: the owner (Superadmin) role — and its whole permission
        # set — must never be revealed to a non-owner (incl. the Director).
        stmt = stmt.where(Role.name != OWNER_ROLE)
    return list(db.execute(stmt).scalars().all())


@router.post("", response_model=RoleOut, status_code=status.HTTP_201_CREATED)
def create_role(
    payload: RoleCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("roles.create"))],
) -> Role:
    if db.execute(select(Role).where(Role.name == payload.name)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Role name already exists")
    _guard_permission_subset(db, actor, payload.permission_codes)
    role = Role(name=payload.name, description=payload.description, is_system=False)
    role.permissions = _resolve_permissions(db, payload.permission_codes)
    db.add(role)
    db.flush()
    added = sorted(payload.permission_codes)
    record_audit(db, action="create", entity_type="role", entity_id=role.id, actor_id=actor.id,
                 summary=f"Created role {role.name} (+{len(added)} прав)",
                 changes={"added": added, "removed": []})
    db.commit()
    db.refresh(role)
    return role


@router.get("/{role_id}", response_model=RoleOut, dependencies=[Depends(require_permission("roles.read"))])
def get_role(
    role_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: CurrentUser,
) -> Role:
    role = db.get(Role, role_id)
    if role is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Role not found")
    # Ghost invariant: to a non-owner the owner role must appear not to exist (404,
    # not 403) — never reveal that it is there.
    if role.name == OWNER_ROLE and not _actor_is_owner(db, actor):
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
    # Ghost invariant: a non-owner must not even discover the owner role exists.
    if role.name == OWNER_ROLE and not _actor_is_owner(db, actor):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Role not found")
    if role.is_system:
        raise HTTPException(status.HTTP_409_CONFLICT, "System roles cannot be edited")
    if payload.description is not None:
        role.description = payload.description
    changes: dict | None = None
    if payload.permission_codes is not None:
        _guard_permission_subset(db, actor, payload.permission_codes)
        # Diff the old vs new permission sets BEFORE reassigning, so the audit
        # records exactly which rights this mutation added / removed.
        before = {p.code for p in role.permissions}
        after = set(payload.permission_codes)
        added = sorted(after - before)
        removed = sorted(before - after)
        changes = {"added": added, "removed": removed}
        role.permissions = _resolve_permissions(db, payload.permission_codes)
    summary = f"Updated role {role.name}"
    if changes:
        summary += f" (+{len(changes['added'])} / -{len(changes['removed'])} прав)"
    record_audit(db, action="update", entity_type="role", entity_id=role.id, actor_id=actor.id,
                 summary=summary, changes=changes)
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
    # Ghost invariant: hide the owner role from a non-owner (404, never 403).
    if role.name == OWNER_ROLE and not _actor_is_owner(db, actor):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Role not found")
    if role.is_system:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "System roles cannot be deleted")

    def _count_assignments() -> int:
        return db.execute(
            select(func.count()).select_from(user_roles).where(user_roles.c.role_id == role_id)
        ).scalar_one()

    if _count_assignments():
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Роль назначена {_count_assignments()} пользователям — снимите назначение перед удалением",
        )
    record_audit(db, action="delete", entity_type="role", entity_id=role.id, actor_id=actor.id,
                 summary=f"Deleted role {role.name}")
    # TOCTOU re-check: an assignment may have been committed by a concurrent
    # request between the first count and here. Re-count immediately before the
    # delete and refuse if any appeared — user_roles.role_id is ondelete=CASCADE,
    # so without this a fresh assignment would be silently stripped. (For a
    # water-tight guarantee the FK should be RESTRICT — see the handoff note.)
    if _count_assignments():
        db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Роль была назначена пользователю во время удаления — повторите после снятия назначения",
        )
    db.delete(role)
    db.commit()
