"""visit follow_up_date (recall)

Adds visits.follow_up_date — the recall date set by the doctor when finishing an
appointment with a follow_up transfer. Feeds GET /visits/recall.

Revision ID: b3e7d2a4c916
Revises: a1c9e7f2b408
Create Date: 2026-07-04 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b3e7d2a4c916'
down_revision: Union[str, Sequence[str], None] = 'a1c9e7f2b408'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('visits', schema=None) as batch_op:
        batch_op.add_column(sa.Column('follow_up_date', sa.Date(), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table('visits', schema=None) as batch_op:
        batch_op.drop_column('follow_up_date')
