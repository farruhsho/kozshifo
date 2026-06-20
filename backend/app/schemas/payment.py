"""Payment DTOs."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

# Closed vocabulary (TZ Modul 2.2): anything else is a 422 before touching the DB.
PaymentMethod = Literal["cash", "card", "qr", "transfer"]

# Reception's registration-time routing choice on full payment:
#   diagnostic — issue a D-… diagnostics ticket (default; eye-clinic norm)
#   doctor     — «Направлен к врачу»: issue the doctor ticket directly (Вариант 2)
#   hold       — «Ожидает назначения»: no ticket, await a routing decision (Вариант 1)
ReferralIntent = Literal["diagnostic", "doctor", "hold"]


class PaymentCreate(BaseModel):
    visit_id: UUID
    amount: Decimal = Field(gt=0)
    method: PaymentMethod = "cash"
    note: str | None = None
    # Issue a queue ticket when the visit becomes fully paid (default behaviour).
    issue_queue_ticket: bool = True
    room: str | None = None
    # Where the patient goes when this payment settles the visit (see above).
    referral_intent: ReferralIntent = "diagnostic"


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
    # Emergency intake: >0 means the visit/ticket is priority — the receipt shows
    # «ЭКСТРЕННЫЙ ПРИЕМ» and the TV board flags it.
    priority: int = 0
    priority_reason: str | None = None
