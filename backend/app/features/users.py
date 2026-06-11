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
from app.models.rbac import Role
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


@router.get("", response_model=Page[UserOut], dependencies=[Depends(require_permission("users.read"))])
def list_users(
    db: Annotated[Session, Depends(get_db)],
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
) -> Page[UserOut]:
    total = db.execute(select(func.count()).select_from(User)).scalar_one()
    rows = list(db.execute(select(User).order_by(User.full_name).offset(offset).limit(limit)).scalars().all())
    return Page(items=[UserOut.model_validate(u) for u in rows], total=total, offset=offset, limit=limit)


@router.post("", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_user(
    payload: UserCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("users.create"))],
) -> User:
    if db.execute(select(User).where(User.email == payload.email)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered")
    user = User(
        email=payload.email,
        full_name=payload.full_name,
        hashed_password=hash_password(payload.password),
        phone=payload.phone,
        branch_id=payload.branch_id,
        is_superuser=payload.is_superuser,
    )
    user.roles = _resolve_roles(db, payload.role_names)
    db.add(user)
    db.flush()
    record_audit(db, action="create", entity_type="user", entity_id=user.id, actor_id=actor.id,
                 summary=f"Created user {user.email}")
    db.commit()
    db.refresh(user)
    return user


@router.get("/{user_id}", response_model=UserOut, dependencies=[Depends(require_permission("users.read"))])
def get_user(user_id: UUID, db: Annotated[Session, Depends(get_db)]) -> User:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
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
    data = payload.model_dump(exclude_unset=True)
    if "role_names" in data:
        user.roles = _resolve_roles(db, data.pop("role_names") or [])
    for field, value in data.items():
        setattr(user, field, value)
    record_audit(db, action="update", entity_type="user", entity_id=user.id, actor_id=actor.id,
                 summary=f"Updated user {user.email}")
    db.commit()
    db.refresh(user)
    return user
