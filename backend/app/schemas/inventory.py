"""Inventory / warehouse DTOs."""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.dates import business_today


# ── Categories ────────────────────────────────────────────────────────────────
class CategoryCreate(BaseModel):
    name: str
    parent_id: UUID | None = None
    description: str | None = None


class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    parent_id: UUID | None
    description: str | None


# ── Suppliers ─────────────────────────────────────────────────────────────────
class SupplierCreate(BaseModel):
    name: str
    phone: str | None = None
    email: str | None = None
    address: str | None = None


class SupplierUpdate(BaseModel):
    name: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    is_active: bool | None = None


class SupplierOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    phone: str | None
    email: str | None
    address: str | None
    is_active: bool


# ── Products ──────────────────────────────────────────────────────────────────
class ProductCreate(BaseModel):
    sku: str
    name: str
    category_id: UUID | None = None
    unit: str = "шт"
    product_type: str = "consumable"  # medicine | consumable | material | instrument
    barcode: str | None = None
    min_stock: Decimal = Field(default=Decimal("0"), ge=0)
    description: str | None = None


class ProductUpdate(BaseModel):
    name: str | None = None
    category_id: UUID | None = None
    unit: str | None = None
    product_type: str | None = None
    barcode: str | None = None
    min_stock: Decimal | None = Field(default=None, ge=0)
    is_active: bool | None = None
    description: str | None = None


class ProductOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    sku: str
    name: str
    category_id: UUID | None
    unit: str
    product_type: str
    barcode: str | None
    min_stock: Decimal
    is_active: bool
    description: str | None


# ── Receipts (goods-in) ───────────────────────────────────────────────────────
class ReceiptItemIn(BaseModel):
    product_id: UUID
    quantity: Decimal = Field(gt=0)
    unit_cost: Decimal = Field(default=Decimal("0.00"), ge=0)
    batch_no: str | None = None
    expiry_date: date | None = None

    @field_validator("expiry_date")
    @classmethod
    def _expiry_not_in_past(cls, v: date | None) -> date | None:
        """Reject a receipt whose expiry is already past (typo like 2024-01-01):
        such a lot is born expired, FEFO never touches it and it hangs as an
        on_hand=0 phantom. None = бессрочный товар (allowed)."""
        if v is not None and v < business_today():
            raise ValueError("Срок годности в прошлом")
        return v


class ReceiptIn(BaseModel):
    branch_id: UUID
    supplier_id: UUID | None = None
    items: list[ReceiptItemIn] = Field(min_length=1)


class BatchOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    batch_no: str | None
    expiry_date: date | None
    quantity: Decimal
    unit_cost: Decimal
    received_at: datetime
    expired: bool  # expired batches are never auto-consumed; dispose explicitly
    supplier_id: UUID | None = None  # feeds supplier-return ref_id from the picked lot


# ── Stock view ────────────────────────────────────────────────────────────────
class StockRowOut(BaseModel):
    product: ProductOut
    on_hand: Decimal
    low_stock: bool
    batches: list[BatchOut]


class ReorderSuggestionOut(BaseModel):
    """A product at/below min_stock with a suggested reorder qty (up to 2× min)."""

    product: ProductOut
    on_hand: Decimal
    min_stock: Decimal
    suggested_qty: Decimal


# ── Write-off ─────────────────────────────────────────────────────────────────
class WriteOffIn(BaseModel):
    product_id: UUID
    branch_id: UUID
    quantity: Decimal = Field(gt=0)
    reason: str
    # Disposal path for expired lots: lets the FEFO engine consume expired
    # batches too (clinical write-offs never set this).
    include_expired: bool = False


class MovementOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    product_id: UUID
    batch_id: UUID | None
    branch_id: UUID
    movement_type: str
    quantity: Decimal
    reason: str | None
    ref_type: str | None
    ref_id: UUID | None
    created_at: datetime
    # Joined, human-readable labels for the movement-history list. Optional so
    # the inline action responses (write-off / transfer / supplier-return) that
    # build MovementOut straight from the ORM row keep working unchanged — those
    # rows simply leave the labels None.
    product_name: str | None = None
    product_sku: str | None = None
    actor_name: str | None = None


# ── Stock-count / инвентаризация ──────────────────────────────────────────────
class StockCountCreate(BaseModel):
    branch_id: UUID
    note: str | None = None


class StockCountLineUpdate(BaseModel):
    counted_qty: Decimal = Field(ge=0)


class StockCountLineOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    product_id: UUID
    batch_id: UUID | None
    product_name: str
    product_sku: str
    unit: str
    batch_no: str | None
    expiry_date: date | None
    expected_qty: Decimal
    counted_qty: Decimal
    variance: Decimal


class StockCountOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    branch_id: UUID
    status: str
    note: str | None
    created_at: datetime
    # totals across lines — surplus (variance > 0) and shortage (variance < 0)
    surplus_total: Decimal
    shortage_total: Decimal
    lines_count: int


class StockCountDetailOut(StockCountOut):
    lines: list[StockCountLineOut]


# ── Inter-branch transfer ─────────────────────────────────────────────────────
class TransferIn(BaseModel):
    product_id: UUID
    from_branch_id: UUID
    to_branch_id: UUID
    quantity: Decimal = Field(gt=0)


# ── Supplier return ───────────────────────────────────────────────────────────
class SupplierReturnIn(BaseModel):
    product_id: UUID
    batch_id: UUID
    quantity: Decimal = Field(gt=0)
    supplier_id: UUID | None = None
    reason: str
