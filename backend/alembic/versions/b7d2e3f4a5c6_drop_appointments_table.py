"""drop appointments table (time-based scheduling removed)

Revision ID: b7d2e3f4a5c6
Revises: f1ca11d09e10
Create Date: 2026-06-20

Per the owner's brief (2026-06-19): the appointments/scheduling module is removed
entirely — a medical reception cannot be pinned to a fixed time slot (a visit may
run 10 min or 2 h), so the clinic runs on a LIVE QUEUE + patient statuses. The
operations DAY board (no time-of-day) stays. The downgrade recreates the table
(mirrors d792392427d2) so the migration is reversible.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b7d2e3f4a5c6"
down_revision: Union[str, Sequence[str], None] = "f1ca11d09e10"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("appointments", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_appointments_status"))
        batch_op.drop_index(batch_op.f("ix_appointments_starts_at"))
        batch_op.drop_index(batch_op.f("ix_appointments_patient_id"))
        batch_op.drop_index(batch_op.f("ix_appointments_doctor_id"))
        batch_op.drop_index(batch_op.f("ix_appointments_branch_id"))
        batch_op.drop_index(batch_op.f("ix_appointments_appointment_no"))
    op.drop_table("appointments")


def downgrade() -> None:
    op.create_table(
        "appointments",
        sa.Column("appointment_no", sa.String(length=32), nullable=False),
        sa.Column("branch_id", sa.Uuid(), nullable=False),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("doctor_id", sa.Uuid(), nullable=True),
        sa.Column("cabinet", sa.String(length=32), nullable=True),
        sa.Column("service", sa.String(length=255), nullable=True),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("notes", sa.String(length=512), nullable=True),
        sa.Column("created_by_id", sa.Uuid(), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.ForeignKeyConstraint(["branch_id"], ["branches.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["created_by_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["doctor_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["patient_id"], ["patients.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    with op.batch_alter_table("appointments", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_appointments_appointment_no"), ["appointment_no"], unique=True)
        batch_op.create_index(batch_op.f("ix_appointments_branch_id"), ["branch_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_appointments_doctor_id"), ["doctor_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_appointments_patient_id"), ["patient_id"], unique=False)
        batch_op.create_index(batch_op.f("ix_appointments_starts_at"), ["starts_at"], unique=False)
        batch_op.create_index(batch_op.f("ix_appointments_status"), ["status"], unique=False)
