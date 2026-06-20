"""Owner (Super Admin) visibility helpers.

The Super Admin is a *ghost*: per the owner's model other users must not see that
it exists. It is filtered out of staff lists for non-owners and out of EVERY
clinical picker (specialists, assignable doctors, surgeons) unconditionally — the
owner account is never a real doctor/diagnost/surgeon, so it has no place there.
"""
from __future__ import annotations

from sqlalchemy import select

from app.models.rbac import Role, user_roles

OWNER_ROLE = "Superadmin"


def owner_user_ids():
    """Subquery of user ids holding the owner (Superadmin) role."""
    return (
        select(user_roles.c.user_id)
        .join(Role, Role.id == user_roles.c.role_id)
        .where(Role.name == OWNER_ROLE)
    )
