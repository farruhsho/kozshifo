"""archive: archived_at on visits / operations / notifications

Owner brief 2026-06-20 (Super Admin → архив): auto-archive old records by
stamping archived_at (NULL = live). Old archived rows drop out of active views.

Revision ID: e9b4c2a7f1d8
Revises: d7a3f1b9c2e4
Create Date: 2026-06-21 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e9b4c2a7f1d8'
down_revision: Union[str, Sequence[str], None] = 'd7a3f1b9c2e4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_TABLES = ('visits', 'operations', 'notifications')


def upgrade() -> None:
    for table in _TABLES:
        with op.batch_alter_table(table, schema=None) as batch_op:
            batch_op.add_column(
                sa.Column('archived_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    for table in _TABLES:
        with op.batch_alter_table(table, schema=None) as batch_op:
            batch_op.drop_column('archived_at')
