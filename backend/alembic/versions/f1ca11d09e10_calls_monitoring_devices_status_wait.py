"""calls monitoring: reception-phone devices + call status/wait/branch

Adds the per-phone agent path on top of the existing PBX call log:

* new ``call_devices`` table — one row per reception Android phone (label, SIM,
  branch, hashed device key, last_seen heartbeat).
* ``call_records`` gains ``status`` (answered/missed/rejected/outgoing),
  ``wait_seconds`` (ring time before pickup), ``ended_at``, ``device_id``,
  ``external_id`` (idempotency) and a denormalized ``branch_id``.

Revision ID: f1ca11d09e10
Revises: e8c2a4f9b73d
Create Date: 2026-06-18 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f1ca11d09e10'
down_revision: Union[str, Sequence[str], None] = 'e8c2a4f9b73d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'call_devices',
        sa.Column('label', sa.String(length=120), nullable=False),
        sa.Column('phone_number', sa.String(length=32), nullable=True),
        sa.Column('branch_id', sa.Uuid(), nullable=True),
        sa.Column('api_key_hash', sa.String(length=64), nullable=False),
        sa.Column('last_seen_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('app_version', sa.String(length=32), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(['branch_id'], ['branches.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    with op.batch_alter_table('call_devices', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_call_devices_api_key_hash'),
                              ['api_key_hash'], unique=True)
        batch_op.create_index(batch_op.f('ix_call_devices_branch_id'),
                              ['branch_id'], unique=False)

    with op.batch_alter_table('call_records', schema=None) as batch_op:
        batch_op.add_column(sa.Column('status', sa.String(length=12), nullable=False,
                                      server_default='answered'))
        batch_op.add_column(sa.Column('ended_at', sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(sa.Column('wait_seconds', sa.Integer(), nullable=False,
                                      server_default='0'))
        batch_op.add_column(sa.Column('device_id', sa.Uuid(), nullable=True))
        batch_op.add_column(sa.Column('external_id', sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column('branch_id', sa.Uuid(), nullable=True))
        batch_op.create_index(batch_op.f('ix_call_records_device_id'),
                              ['device_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_call_records_branch_id'),
                              ['branch_id'], unique=False)
        batch_op.create_unique_constraint('uq_call_records_device_external',
                                          ['device_id', 'external_id'])
        batch_op.create_foreign_key('fk_call_records_device_id_call_devices',
                                    'call_devices', ['device_id'], ['id'], ondelete='SET NULL')
        batch_op.create_foreign_key('fk_call_records_branch_id_branches',
                                    'branches', ['branch_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table('call_records', schema=None) as batch_op:
        batch_op.drop_constraint('fk_call_records_branch_id_branches', type_='foreignkey')
        batch_op.drop_constraint('fk_call_records_device_id_call_devices', type_='foreignkey')
        batch_op.drop_constraint('uq_call_records_device_external', type_='unique')
        batch_op.drop_index(batch_op.f('ix_call_records_branch_id'))
        batch_op.drop_index(batch_op.f('ix_call_records_device_id'))
        batch_op.drop_column('branch_id')
        batch_op.drop_column('external_id')
        batch_op.drop_column('device_id')
        batch_op.drop_column('wait_seconds')
        batch_op.drop_column('ended_at')
        batch_op.drop_column('status')

    with op.batch_alter_table('call_devices', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_call_devices_branch_id'))
        batch_op.drop_index(batch_op.f('ix_call_devices_api_key_hash'))
    op.drop_table('call_devices')
