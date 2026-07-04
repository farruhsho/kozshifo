"""Operations & treatments DTOs."""
from __future__ import annotations

from datetime import date, datetime
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
    # How many whole operations THIS line's stock supports = floor(available /
    # required). Lines that require nothing (<=0) don't constrain the operation.
    feasibility_count: int


class AvailabilityOut(BaseModel):
    """Advisory only — the hard guarantee stays at perform time."""

    ok: bool
    items: list[AvailabilityItem]
    # Whole operations the current stock supports = min feasibility_count across
    # the template (0 if any constraining line can't cover even one operation).
    min_feasibility: int
    # Traffic-light verdict: red (0), yellow (low, <threshold), green (enough).
    status: Literal["red", "yellow", "green"]
    # Product name of the limiting line — null when green or template is empty.
    bottleneck: str | None = None


# ── Operations (instances on a visit) ─────────────────────────────────────────
class OperationCreate(BaseModel):
    """Doctor's referral to surgery (TZ Modul 6): type, recommendation and,
    optionally, the chosen surgeon (incl. a visiting/external one). Reception
    still fixes price/date at schedule time and may change the surgeon then.
    """

    operation_type_id: UUID
    eye: Literal["od", "os", "ou"] = "ou"
    priority: Literal["normal", "urgent"] = "normal"
    notes: str | None = None  # doctor's recommendation
    surgeon_id: UUID | None = None  # chosen surgeon (optional)


class OperationSchedule(BaseModel):
    """Reception fixes the organisational details and bills the visit."""

    scheduled_at: datetime
    # Omitted/None = keep the operation's current surgeon (a bare re-schedule
    # must not drop the assignment); there is no «clear surgeon» use case.
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
    # Financial freeze: when set, the price/bill is locked (editable until then).
    financially_closed_at: datetime | None
    notes: str | None
    result: str | None
    created_at: datetime


class OperationPriceUpdate(BaseModel):
    """Change an operation's cost any time before it is financially closed
    (owner brief 2026-06-20: cost is NOT fixed at planning)."""

    price: Decimal = Field(ge=0)
    reason: str | None = None


class OperationPriceResult(BaseModel):
    """Result of a price change — carries the recomputed visit balance so
    reception sees what to collect, plus any refund owed if the new price is
    below what the patient already paid (overpayment)."""

    operation: OperationOut
    visit_balance: Decimal   # payable − paid (negative = overpaid)
    refund_due: Decimal      # max(0, paid − payable): money to return on a cut


class SurgeonOut(BaseModel):
    """Staff eligible to operate, for the referral/schedule surgeon picker —
    a surgeon (operations.perform) or a visiting/external one (из Ташкента)."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    full_name: str
    is_external_surgeon: bool = False
    cabinet: str | None = None


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


class OperationDaySummary(BaseModel):
    """End-of-day operations P&L:
    profit = revenue − COGS − surgeon fees − day expenses."""

    date: date
    operations_count: int
    revenue: Decimal   # Σ price of operations performed that day
    cogs: Decimal      # Σ consumables cost (qty × batch unit_cost)
    expenses: Decimal  # Σ day operation-expenses (Expense category «Операции»)
    # Σ per-op surgeon fee (obligation for ALL performed work, mirrors payroll):
    # 'percent' → % of the op's price, 'fixed' → flat sum per op. Salary data:
    # 0 for a caller without payroll.read (profit then omits the fee).
    surgeon_fees_total: Decimal = Decimal("0")
    profit: Decimal


# ── Treatments ────────────────────────────────────────────────────────────────
class TreatmentCreate(BaseModel):
    kind: Literal["procedure", "medication"]
    name: str
    product_id: UUID | None = None
    quantity: Decimal | None = Field(default=None, gt=0)
    instructions: str | None = None
    doctor_id: UUID | None = None
    # Optional billing: when set, the treatment is billed as a paid service.
    # unit_price overrides the catalog price; omit both → unbilled (clinical-only).
    service_id: UUID | None = None
    unit_price: Decimal | None = Field(default=None, ge=0)


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
    service_id: UUID | None = None
    unit_price: Decimal | None = None
    visit_item_id: UUID | None = None
