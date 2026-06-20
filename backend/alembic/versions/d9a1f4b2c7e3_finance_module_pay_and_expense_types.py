"""finance_module_pay_and_expense_types

Flexible doctor pay (consult + operation, percent/fixed), admin-managed expense
types, recurring expense templates, expense name. TZ Modul 8.

Revision ID: d9a1f4b2c7e3
Revises: f1ca11d09e10
Create Date: 2026-06-20 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd9a1f4b2c7e3'
down_revision: Union[str, Sequence[str], None] = 'f1ca11d09e10'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # ── Flexible doctor pay on users ────────────────────────────────────────
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('consult_salary_type', sa.String(length=8), nullable=True))
        batch_op.add_column(sa.Column('consult_salary_value', sa.Numeric(precision=12, scale=2), nullable=True))
        batch_op.add_column(sa.Column('operation_salary_type', sa.String(length=8), nullable=True))
        batch_op.add_column(sa.Column('operation_salary_value', sa.Numeric(precision=12, scale=2), nullable=True))

    # Backfill: existing percent-based doctors → consult percent pay.
    op.execute(
        "UPDATE users SET consult_salary_type = 'percent', "
        "consult_salary_value = salary_percent WHERE salary_percent IS NOT NULL"
    )

    # ── Expense name (rasxod nomi) ──────────────────────────────────────────
    with op.batch_alter_table('expenses', schema=None) as batch_op:
        batch_op.add_column(sa.Column('name', sa.String(length=128), nullable=True))

    # ── Expense types (admin-managed) ───────────────────────────────────────
    op.create_table(
        'expense_categories',
        sa.Column('name', sa.String(length=64), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('is_system', sa.Boolean(), nullable=False),
        sa.Column('sort_order', sa.Integer(), nullable=False),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name'),
    )

    # ── Recurring expense templates (постоянные расходы) ────────────────────
    op.create_table(
        'recurring_expenses',
        sa.Column('category', sa.String(length=64), nullable=False),
        sa.Column('name', sa.String(length=128), nullable=False),
        sa.Column('amount', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('is_fixed', sa.Boolean(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('branch_id', sa.Uuid(), nullable=True),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(['branch_id'], ['branches.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )

    # Seed default expense types (idempotent: skip names that already exist).
    _seed_default_categories()


_DEFAULT_CATEGORIES = [
    ("Аренда", False),
    ("Зарплата", True),
    ("Коммунальные", False),
    ("Расходники", False),
    ("Реклама", False),
    ("Налоги", False),
    ("Прочее", False),
]


def _seed_default_categories() -> None:
    from uuid import uuid4

    table = sa.table(
        'expense_categories',
        sa.column('id', sa.Uuid()),
        sa.column('name', sa.String()),
        sa.column('is_active', sa.Boolean()),
        sa.column('is_system', sa.Boolean()),
        sa.column('sort_order', sa.Integer()),
    )
    bind = op.get_bind()
    existing = {
        row[0]
        for row in bind.execute(sa.text("SELECT name FROM expense_categories"))
    }
    rows = [
        {
            'id': uuid4(),
            'name': name,
            'is_active': True,
            'is_system': is_system,
            'sort_order': order,
        }
        for order, (name, is_system) in enumerate(_DEFAULT_CATEGORIES)
        if name not in existing
    ]
    if rows:
        op.bulk_insert(table, rows)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('recurring_expenses')
    op.drop_table('expense_categories')
    with op.batch_alter_table('expenses', schema=None) as batch_op:
        batch_op.drop_column('name')
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('operation_salary_value')
        batch_op.drop_column('operation_salary_type')
        batch_op.drop_column('consult_salary_value')
        batch_op.drop_column('consult_salary_type')
