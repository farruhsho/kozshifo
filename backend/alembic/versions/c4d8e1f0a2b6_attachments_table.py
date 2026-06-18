"""attachments table — patient file documents (УЗИ, анализ на ВИЧ, прочие)

Revision ID: c4d8e1f0a2b6
Revises: b2f7c0a91d34
Create Date: 2026-06-18 00:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c4d8e1f0a2b6'
down_revision: Union[str, Sequence[str], None] = 'b2f7c0a91d34'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create the attachments table."""
    op.create_table(
        'attachments',
        sa.Column('patient_id', sa.Uuid(), nullable=False),
        sa.Column('visit_id', sa.Uuid(), nullable=True),
        sa.Column('operation_id', sa.Uuid(), nullable=True),
        sa.Column('kind', sa.String(length=16), nullable=False),
        sa.Column('file_path', sa.String(length=512), nullable=False),
        sa.Column('original_name', sa.String(length=512), nullable=True),
        sa.Column('content_type', sa.String(length=128), nullable=True),
        sa.Column('size', sa.Integer(), nullable=True),
        sa.Column('note', sa.String(length=512), nullable=True),
        sa.Column('uploaded_by_id', sa.Uuid(), nullable=True),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
        sa.ForeignKeyConstraint(['patient_id'], ['patients.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['visit_id'], ['visits.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['operation_id'], ['operations.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['uploaded_by_id'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    with op.batch_alter_table('attachments', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_attachments_patient_id'), ['patient_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_attachments_visit_id'), ['visit_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_attachments_operation_id'), ['operation_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_attachments_kind'), ['kind'], unique=False)


def downgrade() -> None:
    """Drop the attachments table."""
    with op.batch_alter_table('attachments', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_attachments_kind'))
        batch_op.drop_index(batch_op.f('ix_attachments_operation_id'))
        batch_op.drop_index(batch_op.f('ix_attachments_visit_id'))
        batch_op.drop_index(batch_op.f('ix_attachments_patient_id'))
    op.drop_table('attachments')
