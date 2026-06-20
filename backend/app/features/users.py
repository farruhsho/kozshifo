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
from app.core.visibility import owner_user_ids
from app.models.catalog import Service
from app.models.diagnosis import Diagnosis
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


def _resolve_diagnoses(db: Session, ids: list[UUID]) -> list[Diagnosis]:
    """Resolve the diagnoses/conclusions a staff member may record (validated)."""
    if not ids:
        return []
    found = list(db.execute(select(Diagnosis).where(Diagnosis.id.in_(ids))).scalars().all())
    missing = set(ids) - {d.id for d in found}
    if missing:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            f"Unknown diagnosis ids: {sorted(map(str, missing))}")
    return found


def _default_prefix(full_name: str) -> str | None:
    """Queue-ticket prefix derived from the first letter of the name (Сарвар → С)."""
    name = (full_name or "").strip()
    return name[0].upper() if name else None


def _is_owner(user: User) -> bool:
    """Owner tier = the Superadmin role (the only is_superuser account). The
    Director is a non-owner, so the rules below still hide and protect the
    Superadmin account from the Director and everyone below."""
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
        owner_ids = owner_user_ids()
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
        queue_prefix=payload.queue_prefix or _default_prefix(payload.full_name),
        is_external_surgeon=payload.is_external_surgeon,
        consult_salary_type=payload.consult_salary_type,
        consult_salary_value=payload.consult_salary_value,
        operation_salary_type=payload.operation_salary_type,
        operation_salary_value=payload.operation_salary_value,
    )
    user.roles = _resolve_roles(db, payload.role_names)
    user.services = _resolve_services(db, payload.service_ids)
    user.diagnoses = _resolve_diagnoses(db, payload.diagnosis_ids)
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
    if "diagnosis_ids" in data:
        user.diagnoses = _resolve_diagnoses(db, data.pop("diagnosis_ids") or [])
    for field, value in data.items():
        setattr(user, field, value)
    # Back-compat: a legacy `salary_percent` write (without an explicit consult
    # pay in the same request) mirrors into the new consult-percent pay, so old
    # API clients keep working. Clearing it clears the percent-consult side.
    if "salary_percent" in data and "consult_salary_type" not in data:
        if data["salary_percent"] is None:
            if user.consult_salary_type == "percent":
                user.consult_salary_type = None
                user.consult_salary_value = None
        else:
            user.consult_salary_type = "percent"
            user.consult_salary_value = data["salary_percent"]
    record_audit(db, action="update", entity_type="user", entity_id=user.id, actor_id=actor.id,
                 summary=f"Updated user {user.email}")
    db.commit()
    db.refresh(user)
    return user
