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
from app.core.stock import (
    InsufficientStockError,
    draw_down_batch,
    receive_stock,
    set_batch_absolute,
    transfer_fefo,
    write_off_fefo,
)
from app.models.branch import Branch
from app.models.inventory import (
    InventoryCategory,
    Product,
    StockBatch,
    StockCount,
    StockCountLine,
    Supplier,
)
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
    StockCountCreate,
    StockCountDetailOut,
    StockCountLineOut,
    StockCountLineUpdate,
    StockCountOut,
    StockRowOut,
    SupplierCreate,
    SupplierOut,
    SupplierReturnIn,
    SupplierUpdate,
    TransferIn,
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


# ── Stock-count / инвентаризация ──────────────────────────────────────────────
def _count_totals(lines: list[StockCountLine]) -> tuple[Decimal, Decimal]:
    """(surplus_total, shortage_total) — sum of positive and (abs) negative variances."""
    surplus = sum((Decimal(l.variance) for l in lines if Decimal(l.variance) > 0), Decimal("0"))
    shortage = sum((-Decimal(l.variance) for l in lines if Decimal(l.variance) < 0), Decimal("0"))
    return surplus, shortage


def _serialize_line(line: StockCountLine, batch: StockBatch | None) -> StockCountLineOut:
    product = line.product
    return StockCountLineOut(
        id=line.id,
        product_id=line.product_id,
        batch_id=line.batch_id,
        product_name=product.name,
        product_sku=product.sku,
        unit=product.unit,
        batch_no=batch.batch_no if batch else None,
        expiry_date=batch.expiry_date if batch else None,
        expected_qty=Decimal(line.expected_qty),
        counted_qty=Decimal(line.counted_qty),
        variance=Decimal(line.variance),
    )


def _serialize_count(db: Session, count: StockCount, *, detail: bool) -> StockCountOut:
    lines = list(count.lines)
    surplus, shortage = _count_totals(lines)
    base = dict(
        id=count.id,
        branch_id=count.branch_id,
        status=count.status,
        note=count.note,
        created_at=count.created_at,
        surplus_total=surplus,
        shortage_total=shortage,
        lines_count=len(lines),
    )
    if not detail:
        return StockCountOut(**base)
    batch_ids = {l.batch_id for l in lines if l.batch_id is not None}
    batches = {}
    if batch_ids:
        batches = {
            b.id: b
            for b in db.execute(select(StockBatch).where(StockBatch.id.in_(batch_ids))).scalars().all()
        }
    return StockCountDetailOut(
        **base,
        lines=[_serialize_line(l, batches.get(l.batch_id)) for l in lines],
    )


@router.get("/stock-counts", response_model=list[StockCountOut],
            dependencies=[Depends(require_permission("inventory.stocktake"))])
def list_stock_counts(
    db: Annotated[Session, Depends(get_db)],
    branch_id: UUID | None = None,
) -> list[StockCountOut]:
    stmt = select(StockCount).order_by(StockCount.created_at.desc())
    if branch_id:
        stmt = stmt.where(StockCount.branch_id == branch_id)
    counts = db.execute(stmt).scalars().all()
    return [_serialize_count(db, c, detail=False) for c in counts]


@router.post("/stock-counts", response_model=StockCountDetailOut, status_code=status.HTTP_201_CREATED)
def create_stock_count(
    payload: StockCountCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.stocktake"))],
) -> StockCountDetailOut:
    """Open a draft stock-count: snapshot every (product, batch) of the branch
    into a line with expected = on-hand and counted initialized to expected
    (so untouched lines commit to a zero variance).

    Zero-quantity batches of *active* products are included too: a batch that is
    empty at open but physically found on the shelf must have somewhere to record
    the surplus (committing counted>0 then creates a corrective movement). Batches
    with stock are always snapshotted regardless of product state."""
    if db.get(Branch, payload.branch_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Branch not found")
    count = StockCount(branch_id=payload.branch_id, created_by_id=actor.id,
                       status="draft", note=payload.note)
    db.add(count)
    db.flush()

    active_ids = {
        pid for (pid,) in db.execute(
            select(Product.id).where(Product.is_active.is_(True))
        ).all()
    }
    batches = db.execute(
        select(StockBatch)
        .where(
            StockBatch.branch_id == payload.branch_id,
            or_(StockBatch.quantity > 0, StockBatch.product_id.in_(active_ids)),
        )
        .order_by(StockBatch.expiry_date.asc().nulls_last(), StockBatch.received_at.asc())
    ).scalars().all()
    for batch in batches:
        expected = Decimal(batch.quantity)
        db.add(StockCountLine(
            stock_count_id=count.id,
            product_id=batch.product_id,
            batch_id=batch.id,
            expected_qty=expected,
            counted_qty=expected,
            variance=Decimal("0"),
        ))
    db.flush()
    record_audit(db, action="create", entity_type="stock_count", entity_id=count.id, actor_id=actor.id,
                 branch_id=payload.branch_id, summary=f"Открыта инвентаризация: {len(batches)} позиций")
    db.commit()
    db.refresh(count)
    return _serialize_count(db, count, detail=True)


@router.get("/stock-counts/{count_id}", response_model=StockCountDetailOut,
            dependencies=[Depends(require_permission("inventory.stocktake"))])
def get_stock_count(
    count_id: UUID,
    db: Annotated[Session, Depends(get_db)],
) -> StockCountDetailOut:
    count = db.get(StockCount, count_id)
    if count is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stock count not found")
    return _serialize_count(db, count, detail=True)


@router.patch("/stock-counts/{count_id}/lines/{line_id}", response_model=StockCountLineOut)
def update_stock_count_line(
    count_id: UUID,
    line_id: UUID,
    payload: StockCountLineUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.stocktake"))],
) -> StockCountLineOut:
    """Enter the physically counted quantity on a line; variance is recomputed."""
    count = db.get(StockCount, count_id)
    if count is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stock count not found")
    if count.status != "draft":
        raise HTTPException(status.HTTP_409_CONFLICT, "Инвентаризация уже проведена")
    line = db.get(StockCountLine, line_id)
    if line is None or line.stock_count_id != count_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Line not found")
    line.counted_qty = payload.counted_qty
    line.variance = Decimal(payload.counted_qty) - Decimal(line.expected_qty)
    db.flush()
    db.commit()
    batch = db.get(StockBatch, line.batch_id) if line.batch_id else None
    return _serialize_line(line, batch)


@router.post("/stock-counts/{count_id}/commit", response_model=StockCountDetailOut)
def commit_stock_count(
    count_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.stocktake"))],
) -> StockCountDetailOut:
    """Force every counted batch to its ABSOLUTE physical count (an `adjustment`
    movement records the actually-applied change: counted − live), then mark the
    count committed. The count reconciles the ledger to the shelf, so stock must
    NOT move while the count is open; committing sets counted outright rather than
    applying the frozen counted−expected-at-open variance (which would double-count
    any interim movement). Idempotency: committing an already-committed count
    returns 409 (movements are applied once)."""
    count = db.get(StockCount, count_id)
    if count is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stock count not found")
    if count.status != "draft":
        raise HTTPException(status.HTTP_409_CONFLICT, "Инвентаризация уже проведена")

    touched: set[UUID] = set()
    for line in count.lines:
        if line.batch_id is None:
            continue
        batch = db.get(StockBatch, line.batch_id)
        if batch is None:
            continue  # batch vanished (SET NULL / deleted) — nothing to adjust
        counted = Decimal(line.counted_qty)
        if counted == Decimal(batch.quantity):
            continue  # ledger already matches the shelf — no movement to write
        set_batch_absolute(
            db, batch=batch, counted=counted,
            reason=f"Инвентаризация {count.id}",
            ref_type="stock_count", ref_id=count.id, actor_id=actor.id,
        )
        touched.add(line.product_id)
    count.status = "committed"
    db.flush()
    record_audit(db, action="update", entity_type="stock_count", entity_id=count.id, actor_id=actor.id,
                 branch_id=count.branch_id, summary=f"Инвентаризация проведена: {len(touched)} товаров скорректировано")
    db.commit()
    if touched:
        check_low_stock(db, list(touched), count.branch_id)  # post-commit, never raises
    db.refresh(count)
    return _serialize_count(db, count, detail=True)


# ── Inter-branch transfer ─────────────────────────────────────────────────────
@router.post("/transfers", response_model=list[MovementOut])
def create_transfer(
    payload: TransferIn,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.manage"))],
) -> list[MovementOut]:
    """Move stock FEFO between branches, preserving each source lot's expiry/партия."""
    if payload.from_branch_id == payload.to_branch_id:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Филиалы должны отличаться")
    product = db.get(Product, payload.product_id)
    if product is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    if db.get(Branch, payload.from_branch_id) is None or db.get(Branch, payload.to_branch_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Branch not found")
    try:
        out_movements, _ = transfer_fefo(
            db,
            product_id=payload.product_id,
            from_branch_id=payload.from_branch_id,
            to_branch_id=payload.to_branch_id,
            quantity=payload.quantity,
            reason=f"Перемещение {product.name}",
            actor_id=actor.id,
        )
    except InsufficientStockError as exc:
        db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Insufficient stock for {product.name} ({product.sku}): "
            f"requested {exc.requested}, available {exc.available}",
        ) from None
    record_audit(db, action="update", entity_type="stock", entity_id=product.id, actor_id=actor.id,
                 branch_id=payload.from_branch_id,
                 summary=f"Перемещение {payload.quantity} {product.unit} {product.name} в другой филиал")
    db.commit()
    check_low_stock(db, [payload.product_id], payload.from_branch_id)  # post-commit, never raises
    return [MovementOut.model_validate(m) for m in out_movements]


# ── Supplier return ───────────────────────────────────────────────────────────
@router.post("/supplier-returns", response_model=list[MovementOut])
def create_supplier_return(
    payload: SupplierReturnIn,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("inventory.manage"))],
) -> list[MovementOut]:
    """Return a specific batch to a supplier: write it down with a dedicated
    `supplier_return` movement (distinct from порча/write-off)."""
    product = db.get(Product, payload.product_id)
    if product is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    batch = db.get(StockBatch, payload.batch_id)
    if batch is None or batch.product_id != payload.product_id:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Batch not found")
    if payload.supplier_id and db.get(Supplier, payload.supplier_id) is None:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Supplier not found")
    quantity = Decimal(payload.quantity)
    try:
        movement = draw_down_batch(
            db,
            batch=batch,
            quantity=quantity,
            movement_type="supplier_return",
            reason=payload.reason,
            ref_type="supplier_return",
            ref_id=payload.supplier_id,
            actor_id=actor.id,
        )
    except InsufficientStockError as exc:
        db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Insufficient stock in batch for {product.name} ({product.sku}): "
            f"requested {exc.requested}, available {exc.available}",
        ) from None
    record_audit(db, action="write_off", entity_type="stock", entity_id=product.id, actor_id=actor.id,
                 branch_id=batch.branch_id,
                 summary=f"Возврат поставщику {quantity} {product.unit} {product.name}: {payload.reason}")
    db.commit()
    check_low_stock(db, [payload.product_id], batch.branch_id)  # post-commit, never raises
    return [MovementOut.model_validate(movement)]
