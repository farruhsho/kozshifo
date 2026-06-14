"""reception v2: patient_no, study_place, visit/ticket priority

Revision ID: b8e2d4c19f5a
Revises: c3f1a9b27e40
Create Date: 2026-06-14 18:40:00.000000

Additive only. patients.patient_no is the public 8-digit ID (backfilled here for
existing rows, sequential by created_at). visits.priority + reason and
queue_tickets.priority_reason carry the reception EMERGENCY intake.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b8e2d4c19f5a'
down_revision: Union[str, Sequence[str], None] = 'c3f1a9b27e40'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # ── patients: patient_no (public 8-digit) + study_place ──────────────────
    with op.batch_alter_table('patients', schema=None) as batch_op:
        batch_op.add_column(sa.Column('patient_no', sa.String(length=8), nullable=True))
        batch_op.add_column(sa.Column('study_place', sa.String(length=255), nullable=True))

    # Backfill patient_no sequentially (oldest patient = 00000001).
    conn = op.get_bind()
    rows = conn.execute(sa.text("SELECT id FROM patients ORDER BY created_at, id")).fetchall()
    for i, row in enumerate(rows, start=1):
        conn.execute(
            sa.text("UPDATE patients SET patient_no = :no WHERE id = :id"),
            {"no": f"{i:08d}", "id": row[0]},
        )

    with op.batch_alter_table('patients', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_patients_patient_no'), ['patient_no'], unique=True)

    # ── visits: emergency priority + reason ──────────────────────────────────
    with op.batch_alter_table('visits', schema=None) as batch_op:
        batch_op.add_column(sa.Column('priority', sa.Integer(), nullable=False, server_default='0'))
        batch_op.add_column(sa.Column('priority_reason', sa.String(length=128), nullable=True))

    # ── queue_tickets: emergency reason carried onto the ticket ──────────────
    with op.batch_alter_table('queue_tickets', schema=None) as batch_op:
        batch_op.add_column(sa.Column('priority_reason', sa.String(length=128), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table('queue_tickets', schema=None) as batch_op:
        batch_op.drop_column('priority_reason')

    with op.batch_alter_table('visits', schema=None) as batch_op:
        batch_op.drop_column('priority_reason')
        batch_op.drop_column('priority')

    with op.batch_alter_table('patients', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_patients_patient_no'))
        batch_op.drop_column('study_place')
        batch_op.drop_column('patient_no')
