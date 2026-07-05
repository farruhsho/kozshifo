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
from app.core.visibility import OWNER_ROLE, caller_is_owner, owner_user_id_set, owner_user_ids
from app.models.catalog import Service
from app.models.diagnosis import Diagnosis
from app.models.rbac import Role
from app.models.user import User
from app.schemas.common import Page
from app.schemas.user import UserCreate, UserOut, UserSetPassword, UserUpdate

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


def _actor_is_owner(db: Session, actor: User) -> bool:
    """Owner tier = a superuser OR a holder of the Superadmin (owner) role — the
    only tier exempt from the privilege-subset guard below."""
    return caller_is_owner(actor, owner_user_id_set(db))


def _guard_permission_subset(db: Session, actor: User, role_names: list[str]) -> None:
    """Anti privilege-escalation: a non-owner may not assign a user (incl. self) a
    set of roles whose combined permissions exceed the actor's own effective
    permissions. Otherwise a delegate with users.update could grant rights they
    lack (directly or via a role they retuned). Owner / superuser is exempt."""
    if _actor_is_owner(db, actor):
        return
    if not role_names:
        return
    roles = list(db.execute(select(Role).where(Role.name.in_(role_names))).scalars().all())
    granted: set[str] = set()
    for role in roles:
        granted.update(p.code for p in role.permissions)
    escalated = sorted(granted - actor.effective_permission_codes())
    if escalated:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"Нельзя выдать права, которых у вас нет: {', '.join(escalated)}",
        )


def _would_strip_an_owner_marker(target: User, data: dict) -> bool:
    """True if this update would remove ANY owner marker the target currently
    holds: clear the is_superuser flag, or drop the Superadmin (owner) role. Both
    define ownership (owner_user_ids() is role-based, so losing the role breaks the
    owner set even if the flag lingers), so removing either from the last owner is
    what the guard protects against."""
    clears_superuser = (
        target.is_superuser and data.get("is_superuser", target.is_superuser) is False
    )
    had_owner_role = any(r.name == OWNER_ROLE for r in target.roles)
    drops_owner_role = (
        had_owner_role
        and "role_names" in data
        and OWNER_ROLE not in set(data.get("role_names") or [])
    )
    return clears_superuser or drops_owner_role


def _guard_last_owner(db: Session, target: User, data: dict) -> None:
    """Never let the organisation lose its last owner: if this update would strip
    an owner marker from the sole owner (no other owner account remains), refuse
    with 409. Transferring ownership first (promote a second owner, then demote the
    first) stays possible because the owner count is then > 1."""
    owner_ids = set(owner_user_id_set(db))
    is_owner_target = target.is_superuser or target.id in owner_ids
    if not is_owner_target:
        return
    if not _would_strip_an_owner_marker(target, data):
        return
    # `owner_ids` counts Superadmin-role holders; add a bare superuser (defensive)
    # so the last-owner count is never under-estimated.
    if target.is_superuser:
        owner_ids.add(target.id)
    if len(owner_ids) <= 1:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Нельзя оставить систему без владельца",
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
    _guard_permission_subset(db, actor, payload.role_names)
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
        _guard_permission_subset(db, actor, data.get("role_names") or [])
    # Never let the last owner demote themselves (or be demoted) into a non-owner,
    # which would lock the whole org out of owner-only functions.
    _guard_last_owner(db, user, data)
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


@router.post("/{user_id}/set-password", status_code=status.HTTP_204_NO_CONTENT)
def set_user_password(
    user_id: UUID,
    payload: UserSetPassword,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("users.update"))],
) -> None:
    """Admin password reset — the only post-creation way to change a staff
    password. Audited WITHOUT the password itself. Bumping token_version
    immediately revokes every previously-issued access/refresh token for this
    user (they carry the old `ver` claim → 401), so a stolen refresh token dies
    the moment the password is reset."""
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    _guard_owner_target(actor, user)
    user.hashed_password = hash_password(payload.password)
    user.token_version = (user.token_version or 0) + 1
    record_audit(db, action="password_reset", entity_type="user", entity_id=user.id,
                 actor_id=actor.id, summary=f"Password reset for {user.email}")
    db.commit()
