"""User / staff account with role- and direct-permission resolution."""
from __future__ import annotations

import uuid
from decimal import Decimal

from sqlalchemy import Boolean, ForeignKey, Integer, Numeric, String, Uuid
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
    # percent. NULL = not on percent-based pay. LEGACY — kept for back-compat and
    # migrated into consult_salary_type/value; the payroll engine reads the
    # consult_*/operation_* pair below.
    salary_percent: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    # Flexible doctor pay (admin-set, per doctor): SEPARATELY for consultations
    # («приём») and for operations the doctor performs as surgeon. Each side is
    # either a PERCENT of that side's revenue, or a FIXED sum. NULL type = that
    # side is not paid out.
    #   consult_salary_type:   'percent' -> % of consult revenue (per month)
    #                          'fixed'   -> flat monthly sum
    #   operation_salary_type: 'percent' -> % of performed-operation revenue
    #                          'fixed'   -> flat sum PER performed operation
    consult_salary_type: Mapped[str | None] = mapped_column(String(8), nullable=True)
    consult_salary_value: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    operation_salary_type: Mapped[str | None] = mapped_column(String(8), nullable=True)
    operation_salary_value: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    # Face ID / access control: this staff member's person id on the Hikvision
    # terminal(s). The mapping key between a recognition event (employeeNoString)
    # and our user. NULL = not enrolled on any terminal. See
    # docs/INTEGRATIONS_HIKVISION.md and features/access_control.py.
    faceid_employee_no: Mapped[str | None] = mapped_column(
        String(32), unique=True, index=True, nullable=True
    )
    # The doctor's consulting room (e.g. "Каб. 1", "Офтальмолог"). When a doctor
    # calls a queue ticket the patient is routed to THIS cabinet, so reception
    # never picks a cabinet at payment time. NULL for non-clinical staff.
    cabinet: Mapped[str | None] = mapped_column(String(64), nullable=True)
    # Queue-ticket prefix for THIS doctor's track (e.g. "С" for Сарвар → С-001).
    # NULL = derive from the first letter of full_name at ticket-creation time.
    queue_prefix: Mapped[str | None] = mapped_column(String(8), nullable=True)
    # Visiting / external surgeon (e.g. приезжает из Ташкента делать операции).
    # Surfaced in surgeon pickers; such an account may exist only as a directory
    # entry (no real login).
    is_external_surgeon: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    # Session-revocation counter baked into every issued access/refresh token as
    # the `ver` claim. An admin password reset increments it, so all previously
    # minted tokens (incl. stolen refresh tokens) fail the version check → 401.
    token_version: Mapped[int] = mapped_column(
        Integer, default=0, server_default="0", nullable=False
    )

    roles: Mapped[list[Role]] = relationship(
        secondary=user_roles, back_populates="users", lazy="selectin"
    )
    direct_permissions: Mapped[list[Permission]] = relationship(
        secondary=user_permissions, lazy="selectin"
    )
    branch: Mapped["Branch | None"] = relationship(lazy="joined")  # noqa: F821
    # Services this doctor provides (M2M). A paid service's queue ticket is
    # claimable by any of its eligible doctors; the cabinet then comes from the
    # doctor (see `cabinet`). Empty = open pool.
    services: Mapped[list["Service"]] = relationship(  # noqa: F821
        secondary="service_doctors", back_populates="doctors", lazy="selectin"
    )
    # Diagnoses/conclusions this staff member is allowed to record (M2M). For a
    # diagnostician this scopes the picker in the «Приём» form (e.g. a UZI
    # diagnost only sees УЗИ conclusions). Empty = unrestricted.
    diagnoses: Mapped[list["Diagnosis"]] = relationship(  # noqa: F821
        secondary="user_diagnoses", lazy="selectin"
    )

    def effective_permission_codes(self) -> set[str]:
        """Union of all role permissions and directly granted permissions."""
        codes: set[str] = {p.code for p in self.direct_permissions}
        for role in self.roles:
            codes.update(p.code for p in role.permissions)
        return codes
