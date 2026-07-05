"""stock_count_line recounted flag

Adds ``recounted`` to stock_count_lines. A stock-count line is created for every
batch of the branch at open time with counted = expected (a display default, NOT
a physical count). Only lines the operator actually recounts (PATCH) get
recounted=True; commit applies the absolute set to those alone, so a batch that
drained after the count opened but was never physically recounted is left
untouched instead of being resurrected to its stale open-time value.

Backfill: existing rows default to recounted=0 (server_default). Any historical
draft counts thus commit as no-ops until their lines are re-entered — the safe
direction (never resurrects phantoms).

Revision ID: d1e5c9a2f7b3
Revises: c2b1f4e6d302
Create Date: 2026-07-04 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd1e5c9a2f7b3'
down_revision: Union[str, Sequence[str], None] = 'c2b1f4e6d302'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('stock_count_lines', schema=None) as batch_op:
        batch_op.add_column(
            sa.Column('recounted', sa.Boolean(), nullable=False, server_default='0')
        )


def downgrade() -> None:
    with op.batch_alter_table('stock_count_lines', schema=None) as batch_op:
        batch_op.drop_column('recounted')
