"""Payment DTOs."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class PaymentCreate(BaseModel):
    visit_id: UUID
    amount: Decimal = Field(gt=0)
    method: str = "cash"  # cash | card | transfer
    note: str | None = None
    # Issue a queue ticket when the visit becomes fully paid (default behaviour).
    issue_queue_ticket: bool = True
    room: str | None = None


class PaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    receipt_no: str
    visit_id: UUID
    patient_id: UUID
    branch_id: UUID
    cashier_id: UUID | None
    amount: Decimal
    method: str
    status: str
    note: str | None
    created_at: datetime


class PaymentResult(BaseModel):
    """Receipt + the resulting visit state + any queue ticket created."""

    payment: PaymentOut
    visit_status: str
    visit_balance: Decimal
    queue_ticket_number: str | None = None
