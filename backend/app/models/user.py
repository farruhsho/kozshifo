"""User / staff account with role- and direct-permission resolution."""
from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import Boolean, ForeignKey, Numeric, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin
from app.models.rbac import Permission, Role, user_permissions, user_roles


class User(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    # The director / system owner. Superusers bypass permission checks.
    is_superuser: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), nullable=True
    )
    # Payroll (TZ Modul 8): doctor's cut of revenue from their visits, in
    # percent. NULL = not on percent-based pay.
    salary_percent: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    # Face ID / access control: this staff member's person id on the Hikvision
    # terminal(s). The mapping key between a recognition event (employeeNoString)
    # and our user. NULL = not enrolled on any terminal. See
    # docs/INTEGRATIONS_HIKVISION.md and features/access_control.py.
    faceid_employee_no: Mapped[str | None] = mapped_column(
        String(32), unique=True, index=True, nullable=True
    )

    roles: Mapped[list[Role]] = relationship(
        secondary=user_roles, back_populates="users", lazy="selectin"
    )
    direct_permissions: Mapped[list[Permission]] = relationship(
        secondary=user_permissions, lazy="selectin"
    )
    branch: Mapped["Branch | None"] = relationship(lazy="joined")  # noqa: F821

    def effective_permission_codes(self) -> set[str]:
        """Union of all role permissions and directly granted permissions."""
        codes: set[str] = {p.code for p in self.direct_permissions}
        for role in self.roles:
            codes.update(p.code for p in role.permissions)
        return codes
