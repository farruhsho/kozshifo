"""Owner (Super Admin) visibility helpers.

The Super Admin is a *ghost*: per the owner's model other users must not see that
it exists. It is filtered out of staff lists for non-owners and out of EVERY
clinical picker (specialists, assignable doctors, surgeons) unconditionally — the
owner account is never a real doctor/diagnost/surgeon, so it has no place there.
"""
from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.rbac import Role, user_roles
from app.models.user import User

OWNER_ROLE = "Superadmin"


def owner_user_ids():
    """Subquery of user ids holding the owner (Superadmin) role."""
    return (
        select(user_roles.c.user_id)
        .join(Role, Role.id == user_roles.c.role_id)
        .where(Role.name == OWNER_ROLE)
    )


def owner_user_id_set(db: Session) -> set[UUID]:
    """Materialised set of owner (Superadmin) user ids — for in-Python filtering
    where a scalar subquery is awkward (e.g. hiding rows already loaded into
    DTOs, or an in-memory «online» registry).
    """
    return set(db.execute(owner_user_ids()).scalars().all())


def caller_is_owner(actor: User, owner_ids: set[UUID]) -> bool:
    """The owner sees himself; everyone else must not see the ghost account."""
    return actor.is_superuser or actor.id in owner_ids
