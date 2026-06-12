"""Stock engine: FEFO write-off and receipt primitives.

This is the single place quantities are mutated — other features (operations,
treatment, inventory endpoints) call these helpers so auto write-off behaves
identically everywhere.

Contract:
- FEFO (first-expired, first-out): batches are consumed ordered by
  expiry_date ASC NULLS LAST, then received_at ASC.
- Expired batches are NEVER consumed or counted by default — dispensing an
  expired IOL/medication to a patient must be impossible by construction.
  Disposal of expired stock goes through allow_expired=True (manual write-off).
- Concurrency-safe: each batch is claimed with a guarded relative UPDATE
  (`quantity = quantity - :take WHERE quantity >= :take`), so two concurrent
  write-offs can never consume the same units twice — the loser's guard
  simply doesn't match and the loop re-reads the surviving batches. This
  works on both SQLite (single writer) and Postgres (READ COMMITTED).
- Atomic per request: on shortage InsufficientStockError is raised and the
  caller's rollback (or session close without commit) discards any partial
  claims made earlier in the same request.
- No commits here — the caller owns the transaction (audit row + commit).
"""
from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import func, or_, select
from sqlalchemy import update as sa_update
from sqlalchemy.orm import Session

from app.core.dates import business_today
from app.models.inventory import StockBatch, StockMovement


class InsufficientStockError(Exception):
    """Raised when a write-off asks for more than is usably on hand."""

    def __init__(self, product_id: uuid.UUID, requested: Decimal, available: Decimal) -> None:
        self.product_id = product_id
        self.requested = requested
        self.available = available
        super().__init__(
            f"Insufficient stock for product {product_id}: "
            f"requested {requested}, available {available}"
        )


def _usable_filter(allow_expired: bool):
    """Batch predicate: positive remainder, and not expired unless allowed."""
    conditions = [StockBatch.quantity > 0]
    if not allow_expired:
        conditions.append(
            or_(StockBatch.expiry_date.is_(None), StockBatch.expiry_date >= business_today())
        )
    return conditions


def on_hand(
    db: Session,
    product_id: uuid.UUID,
    branch_id: uuid.UUID,
    *,
    allow_expired: bool = False,
) -> Decimal:
    """Usable remaining quantity of a product in a branch (expired excluded)."""
    total = db.execute(
        select(func.coalesce(func.sum(StockBatch.quantity), 0)).where(
            StockBatch.product_id == product_id,
            StockBatch.branch_id == branch_id,
            *_usable_filter(allow_expired),
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
    allow_expired: bool = False,
) -> list[StockMovement]:
    """Consume `quantity` FEFO across usable batches; one negative movement per batch.

    Raises InsufficientStockError on shortage. Each batch is claimed with a
    guarded relative UPDATE so concurrent requests cannot double-consume the
    same units; a guard miss just re-reads the surviving batches.
    Caller commits (and must roll back / discard the session on the raise).
    """
    quantity = Decimal(quantity)
    # Fast-fail pre-check (race-tolerant: the guarded UPDATEs below are the
    # actual integrity boundary; this just gives a clean early 409).
    available = on_hand(db, product_id, branch_id, allow_expired=allow_expired)
    if available < quantity:
        raise InsufficientStockError(product_id, quantity, available)

    movements: list[StockMovement] = []
    remaining = quantity
    # Outer loop: re-select after any guard miss (concurrent consumption) so
    # we always work against fresh quantities; bounded by attempts to avoid
    # spinning under pathological contention.
    for _ in range(5):
        if remaining <= 0:
            break
        batches = (
            db.execute(
                select(StockBatch)
                .where(
                    StockBatch.product_id == product_id,
                    StockBatch.branch_id == branch_id,
                    *_usable_filter(allow_expired),
                )
                .order_by(StockBatch.expiry_date.asc().nulls_last(), StockBatch.received_at.asc())
            )
            .scalars()
            .all()
        )
        if not batches:
            break
        guard_missed = False
        for batch in batches:
            if remaining <= 0:
                break
            take = min(Decimal(batch.quantity), remaining)
            claimed = db.execute(
                sa_update(StockBatch)
                .where(StockBatch.id == batch.id, StockBatch.quantity >= take)
                .values(quantity=StockBatch.quantity - take)
                .execution_options(synchronize_session=False)
            )
            if claimed.rowcount != 1:
                guard_missed = True  # a concurrent request got there first
                continue
            db.expire(batch)
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
        if remaining > 0 and not guard_missed:
            break  # genuinely ran out of usable batches

    if remaining > 0:
        raise InsufficientStockError(
            product_id, quantity, quantity - remaining + on_hand(db, product_id, branch_id,
                                                                 allow_expired=allow_expired)
        )
    db.flush()
    return movements
