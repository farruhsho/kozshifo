"""audit log device tracking: user_agent

Owner brief 2026-06-20 (Super Admin → audit): record «с какого устройства» on
every change — adds audit_logs.user_agent (raw User-Agent of the request). The
IP was already captured (ip_address); both are now filled uniformly from a
request-scoped context (core.audit + the audit middleware).

Revision ID: c5f1a2d3b4e6
Revises: b6d2f8a1c3e5
Create Date: 2026-06-21 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c5f1a2d3b4e6'
down_revision: Union[str, Sequence[str], None] = 'b6d2f8a1c3e5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('audit_logs', schema=None) as batch_op:
        batch_op.add_column(sa.Column('user_agent', sa.String(length=256), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table('audit_logs', schema=None) as batch_op:
        batch_op.drop_column('user_agent')
