"""merge finance module + owner-reqs heads

Revision ID: 3f7348baf0c4
Revises: d9a1f4b2c7e3, d9f3b1c5e7a2
Create Date: 2026-06-20 21:06:33.016137

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3f7348baf0c4'
down_revision: Union[str, Sequence[str], None] = ('d9a1f4b2c7e3', 'd9f3b1c5e7a2')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
