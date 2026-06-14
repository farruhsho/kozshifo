"""optics_orders + lab_orders tables

Revision ID: c3f1a9b27e40
Revises: d792392427d2
Create Date: 2026-06-14 15:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c3f1a9b27e40'
down_revision: Union[str, Sequence[str], None] = 'd792392427d2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'optics_orders',
        sa.Column('order_no', sa.String(length=32), nullable=False),
        sa.Column('branch_id', sa.Uuid(), nullable=False),
        sa.Column('patient_id', sa.Uuid(), nullable=False),
        sa.Column('doctor_id', sa.Uuid(), nullable=True),
        sa.Column('kind', sa.String(length=16), nullable=False),
        sa.Column('rx', sa.String(length=512), nullable=True),
        sa.Column('frame', sa.String(length=255), nullable=True),
        sa.Column('price', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('status', sa.String(length=16), nullable=False),
        sa.Column('notes', sa.String(length=512), nullable=True),
        sa.Column('created_by_id', sa.Uuid(), nullable=True),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(['branch_id'], ['branches.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['created_by_id'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['doctor_id'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['patient_id'], ['patients.id'], ondelete='RESTRICT'),
        sa.PrimaryKeyConstraint('id'),
    )
    with op.batch_alter_table('optics_orders', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_optics_orders_order_no'), ['order_no'], unique=True)
        batch_op.create_index(batch_op.f('ix_optics_orders_branch_id'), ['branch_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_optics_orders_patient_id'), ['patient_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_optics_orders_doctor_id'), ['doctor_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_optics_orders_status'), ['status'], unique=False)

    op.create_table(
        'lab_orders',
        sa.Column('order_no', sa.String(length=32), nullable=False),
        sa.Column('branch_id', sa.Uuid(), nullable=False),
        sa.Column('patient_id', sa.Uuid(), nullable=False),
        sa.Column('doctor_id', sa.Uuid(), nullable=True),
        sa.Column('test_name', sa.String(length=255), nullable=False),
        sa.Column('status', sa.String(length=16), nullable=False),
        sa.Column('result', sa.String(length=2000), nullable=True),
        sa.Column('notes', sa.String(length=512), nullable=True),
        sa.Column('created_by_id', sa.Uuid(), nullable=True),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(['branch_id'], ['branches.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['created_by_id'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['doctor_id'], ['users.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['patient_id'], ['patients.id'], ondelete='RESTRICT'),
        sa.PrimaryKeyConstraint('id'),
    )
    with op.batch_alter_table('lab_orders', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_lab_orders_order_no'), ['order_no'], unique=True)
        batch_op.create_index(batch_op.f('ix_lab_orders_branch_id'), ['branch_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_lab_orders_patient_id'), ['patient_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_lab_orders_doctor_id'), ['doctor_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_lab_orders_status'), ['status'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table('lab_orders', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_lab_orders_status'))
        batch_op.drop_index(batch_op.f('ix_lab_orders_doctor_id'))
        batch_op.drop_index(batch_op.f('ix_lab_orders_patient_id'))
        batch_op.drop_index(batch_op.f('ix_lab_orders_branch_id'))
        batch_op.drop_index(batch_op.f('ix_lab_orders_order_no'))
    op.drop_table('lab_orders')

    with op.batch_alter_table('optics_orders', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_optics_orders_status'))
        batch_op.drop_index(batch_op.f('ix_optics_orders_doctor_id'))
        batch_op.drop_index(batch_op.f('ix_optics_orders_patient_id'))
        batch_op.drop_index(batch_op.f('ix_optics_orders_branch_id'))
        batch_op.drop_index(batch_op.f('ix_optics_orders_order_no'))
    op.drop_table('optics_orders')
