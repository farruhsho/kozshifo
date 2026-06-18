"""drop optics_orders and cameras tables

Removes the Optics salon vertical and the IP-cameras ("video") screen entirely
(per owner request). The lab_orders table from c3f1a9b27e40 is kept — only the
optics half of that pair is dropped here.

Revision ID: b2f7c0a91d34
Revises: d3a7c1f4b920
Create Date: 2026-06-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b2f7c0a91d34'
down_revision: Union[str, Sequence[str], None] = 'd3a7c1f4b920'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Drop the optics_orders and cameras tables (and their indexes)."""
    op.drop_table('optics_orders')
    op.drop_table('cameras')


def downgrade() -> None:
    """Recreate optics_orders and cameras as they were before removal."""
    op.create_table(
        'cameras',
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('host', sa.String(length=255), nullable=False),
        sa.Column('port', sa.Integer(), nullable=False),
        sa.Column('username', sa.String(length=128), nullable=False),
        sa.Column('password', sa.String(length=255), nullable=False),
        sa.Column('use_https', sa.Boolean(), nullable=False),
        sa.Column('vendor', sa.String(length=16), nullable=False),
        sa.Column('channel_no', sa.Integer(), nullable=False),
        sa.Column('snapshot_path', sa.String(length=255), nullable=True),
        sa.Column('branch_id', sa.Uuid(), nullable=True),
        sa.Column('status', sa.String(length=16), nullable=False),
        sa.Column('online', sa.Boolean(), nullable=False),
        sa.Column('last_seen', sa.DateTime(timezone=True), nullable=True),
        sa.Column('device_info', sa.JSON(), nullable=True),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(['branch_id'], ['branches.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    with op.batch_alter_table('cameras', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_cameras_status'), ['status'], unique=False)

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
