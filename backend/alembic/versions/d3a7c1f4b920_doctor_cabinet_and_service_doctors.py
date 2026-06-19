"""doctor cabinet and service-doctors M2M

Revision ID: d3a7c1f4b920
Revises: a1c4e7f9d2b0
Create Date: 2026-06-16 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd3a7c1f4b920'
down_revision: Union[str, Sequence[str], None] = 'a1c4e7f9d2b0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # The doctor's cabinet — the queue routes a called ticket to the doctor's own
    # room, so reception never sets a cabinet at payment time. Nullable: existing
    # and non-clinical staff stay NULL.
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('cabinet', sa.String(length=64), nullable=True))

    # Services a doctor provides (M2M). Empty for a service = open pool (any
    # doctor); the cabinet always comes from whichever doctor calls the ticket.
    op.create_table(
        'service_doctors',
        sa.Column('service_id', sa.Uuid(), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.ForeignKeyConstraint(['service_id'], ['services.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('service_id', 'user_id'),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('service_doctors')
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('cabinet')
