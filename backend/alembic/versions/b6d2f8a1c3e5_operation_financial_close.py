"""operation financial close (price editable until financially closed)

Owner brief 2026-06-20: an operation's cost is NOT fixed at planning — it stays
editable (before/during/after the operation) until the operation is financially
closed. Adds:
- operations.financially_closed_at      (UTC timestamp; NULL = still editable)
- operations.financially_closed_by_id   (FK users — who closed it)

Revision ID: b6d2f8a1c3e5
Revises: 32eb64bbf044
Create Date: 2026-06-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b6d2f8a1c3e5'
down_revision: Union[str, Sequence[str], None] = '32eb64bbf044'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('operations', schema=None) as batch_op:
        batch_op.add_column(
            sa.Column('financially_closed_at', sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(
            sa.Column('financially_closed_by_id', sa.Uuid(), nullable=True))
        batch_op.create_foreign_key(
            'fk_operations_financially_closed_by_id_users', 'users',
            ['financially_closed_by_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    with op.batch_alter_table('operations', schema=None) as batch_op:
        batch_op.drop_constraint(
            'fk_operations_financially_closed_by_id_users', type_='foreignkey')
        batch_op.drop_column('financially_closed_by_id')
        batch_op.drop_column('financially_closed_at')
