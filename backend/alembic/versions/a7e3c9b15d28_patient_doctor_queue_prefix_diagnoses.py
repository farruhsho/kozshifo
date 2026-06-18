"""patient primary_doctor, user queue_prefix + external surgeon, diagnosis catalog

Phase 2 of the patient-flow overhaul:
- patients.primary_doctor_id  (лечащий врач, FK users)
- users.queue_prefix          (ticket prefix, e.g. Сарвар → С-001)
- users.is_external_surgeon   (visiting surgeon from out of town)
- diagnoses                   (справочник заключений) + user_diagnoses M2M

Revision ID: a7e3c9b15d28
Revises: c4d8e1f0a2b6
Create Date: 2026-06-18 01:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a7e3c9b15d28'
down_revision: Union[str, Sequence[str], None] = 'c4d8e1f0a2b6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add the doctor-of-patient field, queue prefix / external-surgeon flag,
    and the diagnosis catalog tables."""
    with op.batch_alter_table('patients', schema=None) as batch_op:
        batch_op.add_column(sa.Column('primary_doctor_id', sa.Uuid(), nullable=True))
        batch_op.create_foreign_key(
            'fk_patients_primary_doctor_id_users', 'users',
            ['primary_doctor_id'], ['id'], ondelete='SET NULL')

    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('queue_prefix', sa.String(length=8), nullable=True))
        batch_op.add_column(sa.Column(
            'is_external_surgeon', sa.Boolean(), nullable=False, server_default=sa.false()))

    op.create_table(
        'diagnoses',
        sa.Column('code', sa.String(length=32), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('category', sa.String(length=64), nullable=True),
        sa.Column('icd10', sa.String(length=16), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    with op.batch_alter_table('diagnoses', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_diagnoses_code'), ['code'], unique=True)
        batch_op.create_index(batch_op.f('ix_diagnoses_category'), ['category'], unique=False)

    op.create_table(
        'user_diagnoses',
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('diagnosis_id', sa.Uuid(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['diagnosis_id'], ['diagnoses.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('user_id', 'diagnosis_id'),
    )


def downgrade() -> None:
    op.drop_table('user_diagnoses')
    with op.batch_alter_table('diagnoses', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_diagnoses_category'))
        batch_op.drop_index(batch_op.f('ix_diagnoses_code'))
    op.drop_table('diagnoses')

    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('is_external_surgeon')
        batch_op.drop_column('queue_prefix')

    with op.batch_alter_table('patients', schema=None) as batch_op:
        batch_op.drop_constraint('fk_patients_primary_doctor_id_users', type_='foreignkey')
        batch_op.drop_column('primary_doctor_id')
