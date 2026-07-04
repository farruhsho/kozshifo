"""stocktake and transfers

Adds the инвентаризация (stock-count) tables — stock_counts (session header) and
stock_count_lines (per-batch expected/counted/variance snapshot). Inter-branch
transfers and supplier returns reuse the existing stock_movements ledger with
new movement_type values (transfer_out / transfer_in / supplier_return), so no
schema change is needed for those.

Revision ID: c1a0f3e5d201
Revises: b3e7d2a4c916
Create Date: 2026-07-04 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c1a0f3e5d201'
down_revision: Union[str, Sequence[str], None] = 'b3e7d2a4c916'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'stock_counts',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('branch_id', sa.Uuid(), nullable=False),
        sa.Column('created_by_id', sa.Uuid(), nullable=True),
        sa.Column('status', sa.String(length=16), nullable=False),
        sa.Column('note', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(
            ['branch_id'], ['branches.id'], name='fk_stock_counts_branch_id', ondelete='RESTRICT'
        ),
        sa.ForeignKeyConstraint(
            ['created_by_id'], ['users.id'], name='fk_stock_counts_created_by_id', ondelete='SET NULL'
        ),
        sa.PrimaryKeyConstraint('id', name='pk_stock_counts'),
    )
    with op.batch_alter_table('stock_counts', schema=None) as batch_op:
        batch_op.create_index('ix_stock_counts_branch_id', ['branch_id'], unique=False)

    op.create_table(
        'stock_count_lines',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('stock_count_id', sa.Uuid(), nullable=False),
        sa.Column('product_id', sa.Uuid(), nullable=False),
        sa.Column('batch_id', sa.Uuid(), nullable=True),
        sa.Column('expected_qty', sa.Numeric(precision=12, scale=3), nullable=False),
        sa.Column('counted_qty', sa.Numeric(precision=12, scale=3), nullable=False),
        sa.Column('variance', sa.Numeric(precision=12, scale=3), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True),
                  server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(
            ['stock_count_id'], ['stock_counts.id'],
            name='fk_stock_count_lines_stock_count_id', ondelete='CASCADE',
        ),
        sa.ForeignKeyConstraint(
            ['product_id'], ['products.id'], name='fk_stock_count_lines_product_id', ondelete='RESTRICT'
        ),
        sa.ForeignKeyConstraint(
            ['batch_id'], ['stock_batches.id'], name='fk_stock_count_lines_batch_id', ondelete='SET NULL'
        ),
        sa.PrimaryKeyConstraint('id', name='pk_stock_count_lines'),
    )
    with op.batch_alter_table('stock_count_lines', schema=None) as batch_op:
        batch_op.create_index('ix_stock_count_lines_stock_count_id', ['stock_count_id'], unique=False)


def downgrade() -> None:
    with op.batch_alter_table('stock_count_lines', schema=None) as batch_op:
        batch_op.drop_index('ix_stock_count_lines_stock_count_id')
    op.drop_table('stock_count_lines')
    with op.batch_alter_table('stock_counts', schema=None) as batch_op:
        batch_op.drop_index('ix_stock_counts_branch_id')
    op.drop_table('stock_counts')
