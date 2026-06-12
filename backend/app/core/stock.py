"""Stock engine: FEFO write-off and receipt primitives.

This is the single place quantities are mutated — other features (operations,
treatment, inventory endpoints) call these helpers so auto write-off behaves
identically everywhere.

Contract:
- FEFO (first-expired, first-out): batches are consumed ordered by
  expiry_date ASC NULLS LAST, then received_at ASC.
- Atomic: availability is checked *before* anything is mutated, so a failed
  write-off leaves the session clean.
- No commits here — the caller owns the transaction (audit row + commit).
"""
from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.inventory import StockBatch, StockMovement


class InsufficientStockError(Exception):
    """Raised when a write-off asks for more than is on hand. Nothing was mutated."""

    def __init__(self, product_id: uuid.UUID, requested: Decimal, available: Decimal) -> None:
        self.product_id = product_id
        self.requested = requested
        self.available = available
        super().__init__(
            f"Insufficient stock for product {product_id}: "
            f"requested {requested}, available {available}"
        )


def on_hand(db: Session, product_id: uuid.UUID, branch_id: uuid.UUID) -> Decimal:
    """Total remaining quantity of a product in a branch (sum of open batches)."""
    total = db.execute(
        select(func.coalesce(func.sum(StockBatch.quantity), 0)).where(
            StockBatch.product_id == product_id,
            StockBatch.branch_id == branch_id,
            StockBatch.quantity > 0,
        )
    ).scalar_one()
    return Decimal(total)


def receive_stock(
    db: Session,
    *,
    product_id: uuid.UUID,
    branch_id: uuid.UUID,
    quantity: Decimal,
    unit_cost: Decimal = Decimal("0.00"),
    batch_no: str | None = None,
    expiry_date: date | None = None,
    supplier_id: uuid.UUID | None = None,
    actor_id: uuid.UUID | None = None,
) -> StockBatch:
    """Create a new batch plus its positive 'receipt' movement. Caller commits."""
    quantity = Decimal(quantity)
    batch = StockBatch(
        product_id=product_id,
        branch_id=branch_id,
        batch_no=batch_no,
        expiry_date=expiry_date,
        quantity=quantity,
        unit_cost=Decimal(unit_cost),
        supplier_id=supplier_id,
    )
    db.add(batch)
    db.flush()  # assign batch.id for the movement link
    db.add(
        StockMovement(
            product_id=product_id,
            batch_id=batch.id,
            branch_id=branch_id,
            movement_type="receipt",
            quantity=quantity,
            reason=f"Receipt{f' (batch {batch_no})' if batch_no else ''}",
            actor_id=actor_id,
        )
    )
    return batch


def write_off_fefo(
    db: Session,
    *,
    product_id: uuid.UUID,
    branch_id: uuid.UUID,
    quantity: Decimal,
    reason: str,
    ref_type: str | None = None,
    ref_id: uuid.UUID | None = None,
    actor_id: uuid.UUID | None = None,
) -> list[StockMovement]:
    """Consume `quantity` FEFO across batches; one negative movement per batch.

    Raises InsufficientStockError (before any mutation) if not enough on hand.
    Caller commits.
    """
    quantity = Decimal(quantity)
    available = on_hand(db, product_id, branch_id)
    if available < quantity:
        raise InsufficientStockError(product_id, quantity, available)

    batches = (
        db.execute(
            select(StockBatch)
            .where(
                StockBatch.product_id == product_id,
                StockBatch.branch_id == branch_id,
                StockBatch.quantity > 0,
            )
            .order_by(StockBatch.expiry_date.asc().nulls_last(), StockBatch.received_at.asc())
        )
        .scalars()
        .all()
    )

    movements: list[StockMovement] = []
    remaining = quantity
    for batch in batches:
        if remaining <= 0:
            break
        take = min(Decimal(batch.quantity), remaining)
        batch.quantity = Decimal(batch.quantity) - take
        movement = StockMovement(
            product_id=product_id,
            batch_id=batch.id,
            branch_id=branch_id,
            movement_type="write_off",
            quantity=-take,
            reason=reason,
            ref_type=ref_type,
            ref_id=ref_id,
            actor_id=actor_id,
        )
        db.add(movement)
        movements.append(movement)
        remaining -= take
    db.flush()
    return movements
