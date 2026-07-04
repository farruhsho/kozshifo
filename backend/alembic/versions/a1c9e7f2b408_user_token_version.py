"""user token_version (session revocation)

Adds users.token_version — a counter baked into every access/refresh token as
the `ver` claim. An admin password reset increments it, revoking all previously
issued tokens (incl. stolen refresh tokens) via the version check.

Revision ID: a1c9e7f2b408
Revises: fc73b7daceb4
Create Date: 2026-07-04 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1c9e7f2b408'
down_revision: Union[str, Sequence[str], None] = 'fc73b7daceb4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column(
            'token_version', sa.Integer(), nullable=False, server_default='0'))


def downgrade() -> None:
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('token_version')
