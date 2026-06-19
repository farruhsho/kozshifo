"""Visit DTOs."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


class VisitItemAdd(BaseModel):
    service_id: UUID
    quantity: int = Field(default=1, ge=1)


class VisitDiscountApply(BaseModel):
    """Reception discount (TZ Modul 2.2).

    Apply: exactly ONE of percent / fixed amount, plus a mandatory reason.
    Re-applying overwrites the previous discount. `{"clear": true}` removes it
    (only while the visit is open and unpaid — enforced in the endpoint).
    """

    discount_percent: Decimal | None = Field(None, gt=Decimal("0"), le=Decimal("100"))
    discount_amount: Decimal | None = Field(None, gt=Decimal("0"))
    discount_reason: str | None = Field(None, max_length=128)
    clear: bool = False
    # When a discount fully covers the bill (nothing left to pay), settle the
    # visit like a full payment would: mint a diagnostic queue ticket. Mirrors
    # PaymentCreate so a 100%-discount (free) visit still enters the journey.
    issue_queue_ticket: bool = True
    room: str | None = Field(None, max_length=32)

    @model_validator(mode="after")
    def _exactly_one_kind(self) -> "VisitDiscountApply":
        if self.clear:
            if self.discount_percent is not None or self.discount_amount is not None:
                raise ValueError("clear=true cannot be combined with a new discount")
            return self
        if (self.discount_percent is None) == (self.discount_amount is None):
            raise ValueError("Provide exactly one of discount_percent or discount_amount")
        if not (self.discount_reason or "").strip():
            raise ValueError("discount_reason is required when applying a discount")
        return self


class VisitPriorityApply(BaseModel):
    """Reception EMERGENCY toggle. emergency=true needs a reason (analytics)."""

    emergency: bool = True
    reason: str | None = Field(None, max_length=128)


class VisitCreate(BaseModel):
    patient_id: UUID
    branch_id: UUID
    visit_type: str = "consultation"
    doctor_id: UUID | None = None
    notes: str | None = None
    items: list[VisitItemAdd] = []


class VisitItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    service_id: UUID
    service_name: str
    unit_price: Decimal
    quantity: int
    total: Decimal
    status: str


class VisitOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    visit_no: str
    patient_id: UUID
    branch_id: UUID
    doctor_id: UUID | None
    # Clinical context for the visit-history view (resolved by list_visits; other
    # VisitOut producers leave these at their defaults). doctor_name / cabinet name
    # the attending doctor; diagnoses / treatments are the per-visit clinical record.
    doctor_name: str | None = None
    doctor_cabinet: str | None = None
    diagnoses: list[str] = Field(default_factory=list)
    treatments: list[str] = Field(default_factory=list)
    visit_type: str
    status: str
    # Read-only by design: produced by the Smart Workflow Engine (core/flow.py);
    # there is deliberately no input DTO / endpoint that accepts this field.
    flow_status: str
    total_amount: Decimal
    paid_amount: Decimal
    # Reception discount (TZ Modul 2.2). discount_value / payable are model
    # properties computed server-side; all Decimals serialize as strings.
    discount_percent: Decimal | None
    discount_amount: Decimal | None
    discount_reason: str | None
    discount_value: Decimal
    payable: Decimal
    balance: Decimal
    # Emergency intake: priority>0 + reason (reception «ЭКСТРЕННО»).
    priority: int
    priority_reason: str | None
    notes: str | None
    opened_at: datetime
    closed_at: datetime | None
    items: list[VisitItemOut]
