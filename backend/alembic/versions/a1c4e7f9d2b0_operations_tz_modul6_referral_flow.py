"""operations TZ Modul 6 referral flow

Doctor refers (no bill) -> reception schedules (date/surgeon/price, bills) ->
in_progress -> performed -> completed. Splits the single doctor into a
referring doctor and a performing surgeon, adds a per-operation price override,
a completion timestamp and a clinical result.

Revision ID: a1c4e7f9d2b0
Revises: e4fe653ef60e
Create Date: 2026-06-15 16:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1c4e7f9d2b0'
down_revision: Union[str, Sequence[str], None] = 'e4fe653ef60e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    with op.batch_alter_table('operations', schema=None) as batch_op:
        batch_op.alter_column('doctor_id', new_column_name='referring_doctor_id')
        batch_op.add_column(sa.Column('surgeon_id', sa.Uuid(), nullable=True))
        batch_op.add_column(sa.Column('price', sa.Numeric(precision=12, scale=2), nullable=True))
        batch_op.add_column(sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(sa.Column('result', sa.Text(), nullable=True))
        batch_op.create_foreign_key(
            'fk_operations_surgeon_id_users', 'users', ['surgeon_id'], ['id'], ondelete='SET NULL'
        )

    # Carry pre-existing rows onto the new lifecycle vocabulary (pre-TZ data):
    # old "planned" operations were already billed -> "scheduled";
    # old "done" -> "performed".
    op.execute("UPDATE operations SET status='scheduled' WHERE status='planned'")
    op.execute("UPDATE operations SET status='performed' WHERE status='done'")


def downgrade() -> None:
    """Downgrade schema."""
    op.execute("UPDATE operations SET status='done' WHERE status IN ('performed','completed')")
    op.execute(
        "UPDATE operations SET status='planned' "
        "WHERE status IN ('referred','scheduled','in_progress')"
    )
    with op.batch_alter_table('operations', schema=None) as batch_op:
        batch_op.drop_constraint('fk_operations_surgeon_id_users', type_='foreignkey')
        batch_op.drop_column('result')
        batch_op.drop_column('completed_at')
        batch_op.drop_column('price')
        batch_op.drop_column('surgeon_id')
        batch_op.alter_column('referring_doctor_id', new_column_name='doctor_id')
