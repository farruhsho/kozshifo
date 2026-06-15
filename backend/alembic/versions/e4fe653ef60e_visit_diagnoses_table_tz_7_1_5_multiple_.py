"""visit_diagnoses table (TZ 7.1.5 multiple diagnoses)

Revision ID: e4fe653ef60e
Revises: b8e2d4c19f5a
Create Date: 2026-06-15 22:33:59.161215

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e4fe653ef60e'
down_revision: Union[str, Sequence[str], None] = 'b8e2d4c19f5a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'visit_diagnoses',
        sa.Column('visit_id', sa.Uuid(), nullable=False),
        sa.Column('patient_id', sa.Uuid(), nullable=False),
        sa.Column('doctor_id', sa.Uuid(), nullable=True),
        sa.Column('diagnosis', sa.Text(), nullable=False),
        sa.Column('icd10', sa.String(length=16), nullable=True),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(['visit_id'], ['visits.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['patient_id'], ['patients.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['doctor_id'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    with op.batch_alter_table('visit_diagnoses', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_visit_diagnoses_visit_id'), ['visit_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_visit_diagnoses_patient_id'), ['patient_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table('visit_diagnoses', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_visit_diagnoses_patient_id'))
        batch_op.drop_index(batch_op.f('ix_visit_diagnoses_visit_id'))
    op.drop_table('visit_diagnoses')
