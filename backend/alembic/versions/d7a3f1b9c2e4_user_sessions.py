"""user_sessions: login history for Super Admin monitoring

Owner brief 2026-06-20 (Super Admin → системный мониторинг): persist one row per
successful login (who / when / ip / device). «Online now» is derived in-memory
(core/monitoring), so only login HISTORY is stored here.

Revision ID: d7a3f1b9c2e4
Revises: c5f1a2d3b4e6
Create Date: 2026-06-21 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd7a3f1b9c2e4'
down_revision: Union[str, Sequence[str], None] = 'c5f1a2d3b4e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'user_sessions',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('started_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('ip_address', sa.String(length=64), nullable=True),
        sa.Column('user_agent', sa.String(length=256), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    with op.batch_alter_table('user_sessions', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_user_sessions_user_id'), ['user_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_user_sessions_started_at'), ['started_at'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('user_sessions', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_user_sessions_started_at'))
        batch_op.drop_index(batch_op.f('ix_user_sessions_user_id'))
    op.drop_table('user_sessions')
