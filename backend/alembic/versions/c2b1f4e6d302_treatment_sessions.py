"""treatment sessions (multi-day course): sessions_total, sessions_done

Revision ID: c2b1f4e6d302
Revises: c1a0f3e5d201
Create Date: 2026-07-04 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c2b1f4e6d302'
down_revision: Union[str, Sequence[str], None] = 'c1a0f3e5d201'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    with op.batch_alter_table('treatments', schema=None) as batch_op:
        batch_op.add_column(sa.Column(
            'sessions_total', sa.Integer(), nullable=False, server_default='1'))
        batch_op.add_column(sa.Column(
            'sessions_done', sa.Integer(), nullable=False, server_default='0'))


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table('treatments', schema=None) as batch_op:
        batch_op.drop_column('sessions_done')
        batch_op.drop_column('sessions_total')
