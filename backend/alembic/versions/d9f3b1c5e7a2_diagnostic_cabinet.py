"""cabinet on diagnostic records (attachments + visit_diagnoses)

Revision ID: d9f3b1c5e7a2
Revises: c8e4a1b9f2d3
Create Date: 2026-06-20

A diagnostic result must record the room it was done in. Snapshot of the
recorder's cabinet at the time, so a later cabinet change doesn't rewrite history.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d9f3b1c5e7a2"
down_revision: Union[str, Sequence[str], None] = "c8e4a1b9f2d3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("attachments", schema=None) as batch_op:
        batch_op.add_column(sa.Column("cabinet", sa.String(length=64), nullable=True))
    with op.batch_alter_table("visit_diagnoses", schema=None) as batch_op:
        batch_op.add_column(sa.Column("cabinet", sa.String(length=64), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table("visit_diagnoses", schema=None) as batch_op:
        batch_op.drop_column("cabinet")
    with op.batch_alter_table("attachments", schema=None) as batch_op:
        batch_op.drop_column("cabinet")
