"""service is_diagnostic flag (queue-by-service routing)

Marks a service as diagnostic (УЗИ, биометрия, ОКТ…): a paid visit billed for it
mints a diagnostic-track queue ticket tagged with the service so the matching
diagnostician pulls only their own work.

Revision ID: e8c2a4f9b73d
Revises: d5b1f3a86c47
Create Date: 2026-06-18 03:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e8c2a4f9b73d'
down_revision: Union[str, Sequence[str], None] = 'd5b1f3a86c47'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('services', schema=None) as batch_op:
        batch_op.add_column(sa.Column(
            'is_diagnostic', sa.Boolean(), nullable=False, server_default=sa.false()))


def downgrade() -> None:
    with op.batch_alter_table('services', schema=None) as batch_op:
        batch_op.drop_column('is_diagnostic')
