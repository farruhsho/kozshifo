"""patient region + district (marketing geography)

Adds patients.region (one of UZ's 14 oblasts) and patients.district (Fergana
raion/city) for the director's «пациенты по регионам» marketing dashboard.

Revision ID: d5b1f3a86c47
Revises: a7e3c9b15d28
Create Date: 2026-06-18 02:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd5b1f3a86c47'
down_revision: Union[str, Sequence[str], None] = 'a7e3c9b15d28'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('patients', schema=None) as batch_op:
        batch_op.add_column(sa.Column('region', sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column('district', sa.String(length=64), nullable=True))
        batch_op.create_index(batch_op.f('ix_patients_region'), ['region'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('patients', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_patients_region'))
        batch_op.drop_column('district')
        batch_op.drop_column('region')
