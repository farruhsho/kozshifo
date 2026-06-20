"""drop_lab_orders

Removes the Laboratory referrals vertical (lab_orders) entirely (per owner
request), mirroring the earlier removal of the Optics/Cameras verticals in
b2f7c0a91d34. The lab_orders table was created in c3f1a9b27e40; downgrade
recreates it (and its indexes) exactly as that migration did.

Revision ID: 32eb64bbf044
Revises: 3f7348baf0c4
Create Date: 2026-06-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '32eb64bbf044'
down_revision: Union[str, Sequence[str], None] = '3f7348baf0c4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Drop the lab_orders table (and its indexes)."""
    with op.batch_alter_table('lab_orders', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_lab_orders_status'))
        batch_op.drop_index(batch_op.f('ix_lab_orders_doctor_id'))
        batch_op.drop_index(batch_op.f('ix_lab_orders_patient_id'))
        batch_op.drop_index(batch_op.f('ix_lab_orders_branch_id'))
        batch_op.drop_index(batch_op.f('ix_lab_orders_order_no'))
    op.drop_table('lab_orders')


def downgrade() -> None:
    """Recreate lab_orders exactly as c3f1a9b27e40 created it."""
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
