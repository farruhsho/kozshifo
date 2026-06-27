"""Inventory / warehouse: catalog, suppliers, receipts (goods-in), stock view, write-off.

Quantities are only ever mutated through the FEFO engine in `app.core.stock`,
so future features (operations, treatment) reuse the exact same write-off path.
"""
from __future__ import annotations

from collections import defaultdict
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.notify import check_low_stock
from app.core.stock import InsufficientStockError, receive_stock, write_off_fefo
from app.models.branch import Branch
from app.models.inventory import InventoryCategory, Product, StockBatch, Supplier
from app.schemas.common import Page
from app.schemas.inventory import (
    BatchOut,
    CategoryCreate,
    CategoryOut,
    MovementOut,
    ProductCreate,
    ProductOut,
    ProductUpdate,
    ReceiptIn,
    ReorderSuggestionOut,
    StockRowOut,
    SupplierCreate,
    SupplierOut,
    SupplierUpdate,
    WriteOffIn,
)

router = APIRouter(prefix="/inventory", tags=["Inventory"])


# ── Categories ────────────────────────────────────────────────────────────────
@router.get("/categories", response_model=list[CategoryOut],
            dependencies=[Depends(require_permission("inventory.read"))])
def list_categories(db: Annotated[Session, Depends(get_db)]) -> list[InventoryCategory]:
    return list(db.execute(select(InventoryCategory).order_by(InventoryCategory.name)).scalars().all())


@router.post("/categories", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: CategoryCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.manage"))],
) -> InventoryCategory:
    if db.execute(select(InventoryCategory).where(InventoryCategory.name == payload.name)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Category already exists")
    if payload.parent_id and db.get(InventoryCategory, payload.parent_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Parent category not found")
    category = InventoryCategory(**payload.model_dump())
    db.add(category)
    db.flush()
    record_audit(db, action="create", entity_type="inventory_category", entity_id=category.id,
                 actor_id=actor.id, summary=f"Created inventory category {category.name}")
    db.commit()
    db.refresh(category)
    return category


# ── Suppliers ─────────────────────────────────────────────────────────────────
@router.get("/suppliers", response_model=Page[SupplierOut],
            dependencies=[Depends(require_permission("inventory.read"))])
def list_suppliers(
    db: Annotated[Session, Depends(get_db)],
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
) -> Page[SupplierOut]:
    stmt = select(Supplier)
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(stmt.order_by(Supplier.name).offset(offset).limit(limit)).scalars().all()
    return Page(items=[SupplierOut.model_validate(s) for s in rows], total=total, offset=offset, limit=limit)


@router.post("/suppliers", response_model=SupplierOut, status_code=status.HTTP_201_CREATED)
def create_supplier(
    payload: SupplierCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.manage"))],
) -> Supplier:
    supplier = Supplier(**payload.model_dump())
    db.add(supplier)
    db.flush()
    record_audit(db, action="create", entity_type="supplier", entity_id=supplier.id, actor_id=actor.id,
                 summary=f"Created supplier {supplier.name}")
    db.commit()
    db.refresh(supplier)
    return supplier


@router.patch("/suppliers/{supplier_id}", response_model=SupplierOut)
def update_supplier(
    supplier_id: UUID,
    payload: SupplierUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.manage"))],
) -> Supplier:
    supplier = db.get(Supplier, supplier_id)
    if supplier is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Supplier not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(supplier, field, value)
    record_audit(db, action="update", entity_type="supplier", entity_id=supplier.id, actor_id=actor.id,
                 summary=f"Updated supplier {supplier.name}")
    db.commit()
    db.refresh(supplier)
    return supplier


# ── Products ──────────────────────────────────────────────────────────────────
@router.get("/products", response_model=Page[ProductOut],
            dependencies=[Depends(require_permission("inventory.read"))])
def list_products(
    db: Annotated[Session, Depends(get_db)],
    q: str | None = Query(None, description="Search by name, SKU or barcode"),
    category_id: UUID | None = None,
    product_type: str | None = Query(
        None, description="Filter by class: medicine | consumable | material | instrument"
    ),
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
) -> Page[ProductOut]:
    stmt = select(Product)
    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(or_(Product.name.ilike(like), Product.sku.ilike(like), Product.barcode.ilike(like)))
    if category_id:
        stmt = stmt.where(Product.category_id == category_id)
    if product_type:
        stmt = stmt.where(Product.product_type == product_type)
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(stmt.order_by(Product.name).offset(offset).limit(limit)).scalars().all()
    return Page(items=[ProductOut.model_validate(p) for p in rows], total=total, offset=offset, limit=limit)


@router.post("/products", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
def create_product(
    payload: ProductCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.manage"))],
) -> Product:
    if db.execute(select(Product).where(Product.sku == payload.sku)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, f"SKU {payload.sku} already exists")
    product = Product(**payload.model_dump())
    db.add(product)
    db.flush()
    record_audit(db, action="create", entity_type="product", entity_id=product.id, actor_id=actor.id,
                 summary=f"Created product {product.sku} — {product.name}")
    db.commit()
    db.refresh(product)
    return product


@router.patch("/products/{product_id}", response_model=ProductOut)
def update_product(
    product_id: UUID,
    payload: ProductUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.manage"))],
) -> Product:
    product = db.get(Product, product_id)
    if product is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    record_audit(db, action="update", entity_type="product", entity_id=product.id, actor_id=actor.id,
                 summary=f"Updated product {product.sku}")
    db.commit()
    db.refresh(product)
    return product


# ── Receipts (goods-in) ───────────────────────────────────────────────────────
@router.post("/receipts", response_model=list[BatchOut], status_code=status.HTTP_201_CREATED)
def create_receipt(
    payload: ReceiptIn,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.manage"))],
) -> list[StockBatch]:
    if db.get(Branch, payload.branch_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Branch not found")
    if payload.supplier_id and db.get(Supplier, payload.supplier_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Supplier not found")
    for item in payload.items:
        product = db.get(Product, item.product_id)
        if product is None:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, f"Product {item.product_id} not found")
        if not product.is_active:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                                f"Product {product.name} ({product.sku}) is deactivated — "
                                "reactivate it before receiving stock")

    batches = [
        receive_stock(
            db,
            product_id=item.product_id,
            branch_id=payload.branch_id,
            quantity=item.quantity,
            unit_cost=item.unit_cost,
            batch_no=item.batch_no,
            expiry_date=item.expiry_date,
            supplier_id=payload.supplier_id,
            actor_id=actor.id,
        )
        for item in payload.items
    ]
    record_audit(db, action="create", entity_type="stock_receipt", actor_id=actor.id,
                 branch_id=payload.branch_id, summary=f"Receipt: {len(batches)} positions")
    db.commit()
    return batches


# ── Stock view ────────────────────────────────────────────────────────────────
@router.get("/stock", response_model=list[StockRowOut],
            dependencies=[Depends(require_permission("inventory.read"))])
def stock_overview(
    db: Annotated[Session, Depends(get_db)],
    branch_id: UUID,
    low_only: bool = Query(False, description="Only rows at or below min_stock"),
) -> list[StockRowOut]:
    # All products, not only active ones: a deactivated product with remaining
    # batches must stay visible here (this is the only stock view) — otherwise
    # inventory value silently disappears from reporting.
    products = db.execute(select(Product).order_by(Product.name)).scalars().all()
    batches = db.execute(
        select(StockBatch)
        .where(StockBatch.branch_id == branch_id, StockBatch.quantity > 0)
        .order_by(StockBatch.expiry_date.asc().nulls_last(), StockBatch.received_at.asc())
    ).scalars().all()
    by_product: dict[UUID, list[StockBatch]] = defaultdict(list)
    for batch in batches:
        by_product[batch.product_id].append(batch)

    rows: list[StockRowOut] = []
    for product in products:
        product_batches = by_product.get(product.id, [])
        if not product.is_active and not product_batches:
            continue  # deactivated and empty — nothing to report
        # on_hand counts only usable (non-expired) units, matching what the
        # FEFO engine will actually consume; expired lots stay listed below
        # with their flag so they can be disposed of.
        total = sum(
            (Decimal(b.quantity) for b in product_batches if not b.expired), Decimal("0")
        )
        low = product.is_active and total <= Decimal(product.min_stock)
        if low_only and not low:
            continue
        rows.append(
            StockRowOut(
                product=ProductOut.model_validate(product),
                on_hand=total,
                low_stock=low,
                batches=[BatchOut.model_validate(b) for b in product_batches],
            )
        )
    return rows


@router.get("/reorder-suggestions", response_model=list[ReorderSuggestionOut],
            dependencies=[Depends(require_permission("inventory.read"))])
def reorder_suggestions(
    db: Annotated[Session, Depends(get_db)],
    branch_id: UUID,
) -> list[ReorderSuggestionOut]:
    """Active products at or below min_stock in the branch, with a suggested
    reorder quantity (bring stock up to 2× min_stock). Powers a one-click restock
    list — most-deficient first. on_hand counts only usable (non-expired) units,
    matching what FEFO will actually consume."""
    products = db.execute(
        select(Product).where(Product.is_active.is_(True), Product.min_stock > 0)
    ).scalars().all()
    batches = db.execute(
        select(StockBatch).where(StockBatch.branch_id == branch_id, StockBatch.quantity > 0)
    ).scalars().all()
    by_product: dict[UUID, list[StockBatch]] = defaultdict(list)
    for batch in batches:
        by_product[batch.product_id].append(batch)

    out: list[ReorderSuggestionOut] = []
    for product in products:
        on_hand = sum(
            (Decimal(b.quantity) for b in by_product.get(product.id, []) if not b.expired),
            Decimal("0"),
        )
        min_stock = Decimal(product.min_stock)
        if on_hand > min_stock:
            continue
        out.append(ReorderSuggestionOut(
            product=ProductOut.model_validate(product),
            on_hand=on_hand,
            min_stock=min_stock,
            suggested_qty=min_stock * 2 - on_hand,  # restock up to 2× min
        ))
    out.sort(key=lambda r: r.on_hand - r.min_stock)  # most-deficient first
    return out


# ── Write-off ─────────────────────────────────────────────────────────────────
@router.post("/write-off", response_model=list[MovementOut])
def write_off(
    payload: WriteOffIn,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.write_off"))],
) -> list[MovementOut]:
    product = db.get(Product, payload.product_id)
    if product is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    try:
        movements = write_off_fefo(
            db,
            product_id=payload.product_id,
            branch_id=payload.branch_id,
            quantity=payload.quantity,
            reason=payload.reason,
            ref_type="manual",
            actor_id=actor.id,
            allow_expired=payload.include_expired,
        )
    except InsufficientStockError as exc:
        db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Insufficient stock for {product.name} ({product.sku}): "
            f"requested {exc.requested}, available {exc.available}",
        ) from None
    record_audit(db, action="write_off", entity_type="stock", entity_id=product.id, actor_id=actor.id,
                 branch_id=payload.branch_id,
                 summary=f"Write-off {payload.quantity} {product.unit} of {product.name}: {payload.reason}")
    db.commit()
    check_low_stock(db, [payload.product_id], payload.branch_id)  # post-commit, never raises
    return [MovementOut.model_validate(m) for m in movements]
