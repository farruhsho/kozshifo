"""Dynamic RBAC: Permissions, Roles, and their association tables.

No role is hardcoded in application logic. Authorization always resolves to a
set of permission *codes* (e.g. "patients.create"). Roles bundle permissions;
users get roles and/or directly granted permissions.
"""
from __future__ import annotations

import uuid

from sqlalchemy import Boolean, Column, ForeignKey, String, Table, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin

role_permissions = Table(
    "role_permissions",
    Base.metadata,
    Column("role_id", Uuid, ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
    Column("permission_id", Uuid, ForeignKey("permissions.id", ondelete="CASCADE"), primary_key=True),
)

user_roles = Table(
    "user_roles",
    Base.metadata,
    Column("user_id", Uuid, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("role_id", Uuid, ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
)

user_permissions = Table(
    "user_permissions",
    Base.metadata,
    Column("user_id", Uuid, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("permission_id", Uuid, ForeignKey("permissions.id", ondelete="CASCADE"), primary_key=True),
)


class Permission(UUIDPKMixin, Base):
    __tablename__ = "permissions"

    code: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    module: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)


class Role(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "roles"

    name: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_system: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    permissions: Mapped[list[Permission]] = relationship(
        secondary=role_permissions, lazy="selectin"
    )
    users: Mapped[list["User"]] = relationship(  # noqa: F821
        secondary=user_roles, back_populates="roles"
    )
