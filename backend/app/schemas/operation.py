"""Operations & treatments DTOs."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# ── Operation types (catalog) ─────────────────────────────────────────────────
class OperationTypeConsumableIn(BaseModel):
    product_id: UUID
    quantity: Decimal = Field(gt=0)


class OperationTypeCreate(BaseModel):
    code: str
    name: str
    service_id: UUID
    duration_minutes: int | None = None
    description: str | None = None
    consumables: list[OperationTypeConsumableIn] = []


class ConsumableOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    product_id: UUID
    product_name: str  # populated from the ORM relationship property
    quantity: Decimal


class OperationTypeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    service_id: UUID
    price: Decimal  # the linked service's price (model property)
    duration_minutes: int | None
    is_active: bool
    description: str | None
    consumables: list[ConsumableOut]


# ── Consumable availability (advisory pre-check for the doctor) ───────────────
class AvailabilityItem(BaseModel):
    """One template line vs. usable (non-expired) stock in the branch."""

    product_id: UUID
    product_name: str
    required: Decimal
    available: Decimal
    ok: bool


class AvailabilityOut(BaseModel):
    """Advisory only — the hard guarantee stays at perform time."""

    ok: bool
    items: list[AvailabilityItem]


# ── Operations (instances on a visit) ─────────────────────────────────────────
class OperationCreate(BaseModel):
    """Doctor's referral to surgery (TZ Modul 6): type + recommendation only.

    No price/date/surgeon here — reception fills those in at schedule time.
    """

    operation_type_id: UUID
    eye: Literal["od", "os", "ou"] = "ou"
    priority: Literal["normal", "urgent"] = "normal"
    notes: str | None = None  # doctor's recommendation


class OperationSchedule(BaseModel):
    """Reception fixes the organisational details and bills the visit."""

    scheduled_at: datetime
    surgeon_id: UUID | None = None
    # Optional price override; absent -> the linked service's catalog price.
    price: Decimal | None = Field(default=None, ge=0)
    notes: str | None = None


class AdHocConsumable(BaseModel):
    """One extra (non-template) product actually used during a perform — picked
    from the warehouse by the operating team; written off via the same FEFO."""

    product_id: UUID
    quantity: Decimal = Field(gt=0)


class PerformOperationRequest(BaseModel):
    """Perform payload: consumables ACTUALLY used beyond the type's template.
    Empty list = template only (backwards compatible)."""

    ad_hoc_consumables: list[AdHocConsumable] = []


class OperationComplete(BaseModel):
    """Outcome recorded on the patient card when the operation is wrapped up."""

    result: str | None = None


class OperationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    visit_id: UUID
    patient_id: UUID
    patient_name: str  # model property
    referring_doctor_id: UUID | None
    referring_doctor_name: str | None  # model property
    surgeon_id: UUID | None
    surgeon_name: str | None  # model property
    operation_type_id: UUID
    type_name: str  # model property -> operation_type.name
    eye: str
    priority: str
    status: str
    price: Decimal | None
    scheduled_at: datetime | None
    performed_at: datetime | None
    completed_at: datetime | None
    notes: str | None
    result: str | None
    created_at: datetime


# ── Operations report (TZ Modul 6: period totals, by surgeon) ─────────────────
class SurgeonOperationStat(BaseModel):
    surgeon_id: UUID | None
    surgeon_name: str | None
    count: int
    total_amount: Decimal


class OperationReport(BaseModel):
    date_from: datetime
    date_to: datetime
    count: int
    total_amount: Decimal
    by_surgeon: list[SurgeonOperationStat]


# ── Treatments ────────────────────────────────────────────────────────────────
class TreatmentCreate(BaseModel):
    kind: Literal["procedure", "medication"]
    name: str
    product_id: UUID | None = None
    quantity: Decimal | None = Field(default=None, gt=0)
    instructions: str | None = None
    doctor_id: UUID | None = None


class TreatmentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    visit_id: UUID
    patient_id: UUID
    doctor_id: UUID | None
    kind: str
    name: str
    product_id: UUID | None
    quantity: Decimal | None
    instructions: str | None
    status: str
    performed_at: datetime | None
    created_at: datetime
