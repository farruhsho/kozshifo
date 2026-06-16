"""Staff user management with role assignment by name."""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.security import hash_password
from app.models.catalog import Service
from app.models.rbac import Role, user_roles
from app.models.user import User
from app.schemas.common import Page
from app.schemas.user import UserCreate, UserOut, UserUpdate

router = APIRouter(prefix="/users", tags=["Identity & Access"])


def _resolve_roles(db: Session, names: list[str]) -> list[Role]:
    if not names:
        return []
    found = list(db.execute(select(Role).where(Role.name.in_(names))).scalars().all())
    missing = set(names) - {r.name for r in found}
    if missing:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, f"Unknown role names: {sorted(missing)}")
    return found


def _resolve_services(db: Session, ids: list[UUID]) -> list[Service]:
    """Resolve the services a doctor provides (validated)."""
    if not ids:
        return []
    found = list(db.execute(select(Service).where(Service.id.in_(ids))).scalars().all())
    missing = set(ids) - {s.id for s in found}
    if missing:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            f"Unknown service ids: {sorted(map(str, missing))}")
    return found


def _is_owner(user: User) -> bool:
    """Owner tier = the Superadmin role. The Director is also is_superuser (full
    permission bypass) but is NOT an owner, so the rules below still hide and
    protect the Superadmin account from the Director and everyone below."""
    return any(r.name == "Superadmin" for r in user.roles)


def _guard_owner_target(actor: User, target: User) -> None:
    """A non-owner (e.g. the Director) may not view or manage a Superadmin owner.
    Raises 404 — not 403 — so the owner account is never even revealed."""
    if _is_owner(target) and not _is_owner(actor):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")


def _guard_owner_grant(actor: User, *, is_superuser: bool, role_names: list[str]) -> None:
    """Only an owner may mint a superuser or hand out the Superadmin role — the
    Director manages staff but cannot create an owner-tier account."""
    if _is_owner(actor):
        return
    if is_superuser or "Superadmin" in (role_names or []):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Only the Superadmin can grant superuser status or the Superadmin role",
        )


@router.get("", response_model=Page[UserOut])
def list_users(
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("users.read"))],
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[UserOut]:
    stmt = select(User)
    count_stmt = select(func.count()).select_from(User)
    if not _is_owner(actor):
        # The Director (and below) never see the owner/Superadmin account(s).
        owner_ids = (
            select(user_roles.c.user_id)
            .join(Role, Role.id == user_roles.c.role_id)
            .where(Role.name == "Superadmin")
        )
        stmt = stmt.where(User.id.not_in(owner_ids))
        count_stmt = count_stmt.where(User.id.not_in(owner_ids))
    total = db.execute(count_stmt).scalar_one()
    rows = list(db.execute(stmt.order_by(User.full_name).offset(offset).limit(limit)).scalars().all())
    return Page(items=[UserOut.model_validate(u) for u in rows], total=total, offset=offset, limit=limit)


@router.post("", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_user(
    payload: UserCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("users.create"))],
) -> User:
    if db.execute(select(User).where(User.email == payload.email)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered")
    _guard_owner_grant(actor, is_superuser=payload.is_superuser, role_names=payload.role_names)
    user = User(
        email=payload.email,
        full_name=payload.full_name,
        hashed_password=hash_password(payload.password),
        phone=payload.phone,
        branch_id=payload.branch_id,
        is_superuser=payload.is_superuser,
        cabinet=payload.cabinet,
    )
    user.roles = _resolve_roles(db, payload.role_names)
    user.services = _resolve_services(db, payload.service_ids)
    db.add(user)
    db.flush()
    record_audit(db, action="create", entity_type="user", entity_id=user.id, actor_id=actor.id,
                 summary=f"Created user {user.email}")
    db.commit()
    db.refresh(user)
    return user


@router.get("/{user_id}", response_model=UserOut)
def get_user(
    user_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("users.read"))],
) -> User:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    _guard_owner_target(actor, user)
    return user


@router.patch("/{user_id}", response_model=UserOut)
def update_user(
    user_id: UUID,
    payload: UserUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("users.update"))],
) -> User:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    _guard_owner_target(actor, user)
    data = payload.model_dump(exclude_unset=True)
    _guard_owner_grant(
        actor,
        is_superuser=bool(data.get("is_superuser", False)),
        role_names=data.get("role_names") or [],
    )
    if "role_names" in data:
        user.roles = _resolve_roles(db, data.pop("role_names") or [])
    if "service_ids" in data:
        user.services = _resolve_services(db, data.pop("service_ids") or [])
    for field, value in data.items():
        setattr(user, field, value)
    record_audit(db, action="update", entity_type="user", entity_id=user.id, actor_id=actor.id,
                 summary=f"Updated user {user.email}")
    db.commit()
    db.refresh(user)
    return user
