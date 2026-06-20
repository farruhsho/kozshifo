"""cabinets table (consulting rooms managed by the Super Admin)

Revision ID: c8e4a1b9f2d3
Revises: b7d2e3f4a5c6
Create Date: 2026-06-20

A named room within a branch (Кабинет №1, Кабинет УЗИ, Операционная №1…). Staff
pick «Мой кабинет» at login; all their patient calls go to that room.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c8e4a1b9f2d3"
down_revision: Union[str, Sequence[str], None] = "b7d2e3f4a5c6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "cabinets",
        sa.Column("branch_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=64), nullable=False),
        sa.Column("kind", sa.String(length=32), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.ForeignKeyConstraint(["branch_id"], ["branches.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    with op.batch_alter_table("cabinets", schema=None) as batch_op:
        batch_op.create_index(batch_op.f("ix_cabinets_branch_id"), ["branch_id"], unique=False)


def downgrade() -> None:
    with op.batch_alter_table("cabinets", schema=None) as batch_op:
        batch_op.drop_index(batch_op.f("ix_cabinets_branch_id"))
    op.drop_table("cabinets")
