"""Inventory / warehouse DTOs."""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


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


# ── Stock view ────────────────────────────────────────────────────────────────
class StockRowOut(BaseModel):
    product: ProductOut
    on_hand: Decimal
    low_stock: bool
    batches: list[BatchOut]


# ── Write-off ─────────────────────────────────────────────────────────────────
class WriteOffIn(BaseModel):
    product_id: UUID
    branch_id: UUID
    quantity: Decimal = Field(gt=0)
    reason: str


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
