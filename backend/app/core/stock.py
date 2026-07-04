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


def set_batch_absolute(
    db: Session,
    *,
    batch: StockBatch,
    counted: Decimal,
    reason: str,
    ref_type: str | None = None,
    ref_id: uuid.UUID | None = None,
    actor_id: uuid.UUID | None = None,
) -> StockMovement:
    """Force a batch to an ABSOLUTE physical count (инвентаризация result).

    A stock-count must bring the system to the *physical* reality on the shelf,
    so the batch is set to `counted` outright — NOT nudged by a frozen
    counted−expected delta. Doing it relative would double-count any movement
    that happened between opening and committing the count (e.g. a write-off of
    3 units drops 10→7, and applying a +2 variance would land on 9 instead of
    the counted 12).

    IMPORTANT: stock must NOT move while a count is being reconciled — this
    performs an absolute set. The audit `adjustment` movement records the
    *actually applied* change: quantity = counted − current_live_quantity. The
    per-line "variance vs expected-at-open" is preserved separately on the count
    line/report for auditing. Written with a guarded absolute UPDATE
    (`SET quantity = :counted WHERE id = :id`) so it obeys stock.py's mutation
    contract; `synchronize_session=False` + `db.expire(batch)` re-reads the row.
    After this returns, `batch.quantity == counted`. Caller commits.
    """
    counted = Decimal(counted)
    live = Decimal(batch.quantity)  # what the ledger actually held pre-set
    applied = counted - live
    db.execute(
        sa_update(StockBatch)
        .where(StockBatch.id == batch.id)
        .values(quantity=counted)
        .execution_options(synchronize_session=False)
    )
    db.expire(batch)
    movement = StockMovement(
        product_id=batch.product_id,
        batch_id=batch.id,
        branch_id=batch.branch_id,
        movement_type="adjustment",
        quantity=applied,
        reason=reason,
        ref_type=ref_type,
        ref_id=ref_id,
        actor_id=actor_id,
    )
    db.add(movement)
    db.flush()
    return movement


def draw_down_batch(
    db: Session,
    *,
    batch: StockBatch,
    quantity: Decimal,
    movement_type: str,
    reason: str,
    ref_type: str | None = None,
    ref_id: uuid.UUID | None = None,
    actor_id: uuid.UUID | None = None,
) -> StockMovement:
    """Subtract `quantity` from ONE specific batch, atomically (supplier return).

    Unlike FEFO write-off this targets a caller-chosen batch (a return goes back
    to the supplier the lot came from). Uses a guarded relative UPDATE
    (`SET quantity = quantity - :qty WHERE id = :id AND quantity >= :qty`) so it
    can never drive the batch negative or clobber a concurrent movement — a
    TOCTOU-free replacement for check-then-act. Raises InsufficientStockError
    (→ 409) when the batch no longer holds `quantity`. One negative movement of
    `movement_type` is written. Caller commits.
    """
    quantity = Decimal(quantity)
    claimed = db.execute(
        sa_update(StockBatch)
        .where(StockBatch.id == batch.id, StockBatch.quantity >= quantity)
        .values(quantity=StockBatch.quantity - quantity)
        .execution_options(synchronize_session=False)
    )
    if claimed.rowcount != 1:
        raise InsufficientStockError(batch.product_id, quantity, Decimal(batch.quantity))
    db.expire(batch)
    movement = StockMovement(
        product_id=batch.product_id,
        batch_id=batch.id,
        branch_id=batch.branch_id,
        movement_type=movement_type,
        quantity=-quantity,
        reason=reason,
        ref_type=ref_type,
        ref_id=ref_id,
        actor_id=actor_id,
    )
    db.add(movement)
    db.flush()
    return movement


def transfer_fefo(
    db: Session,
    *,
    product_id: uuid.UUID,
    from_branch_id: uuid.UUID,
    to_branch_id: uuid.UUID,
    quantity: Decimal,
    reason: str,
    actor_id: uuid.UUID | None = None,
    ref_id: uuid.UUID | None = None,
) -> tuple[list[StockMovement], list[StockBatch]]:
    """Move `quantity` FEFO from one branch to another, batch-for-batch.

    Consumes usable (non-expired) batches in the source branch first-expired-first
    and, for each consumed slice, creates a matching batch in the destination
    branch that preserves the source lot's expiry_date / batch_no / unit_cost /
    supplier. Ledger: one negative 'transfer_out' per source slice and one
    positive 'transfer_in' per destination batch. Raises InsufficientStockError
    on shortage (source untouched by the caller's rollback). Caller commits.
    """
    quantity = Decimal(quantity)
    available = on_hand(db, product_id, from_branch_id)
    if available < quantity:
        raise InsufficientStockError(product_id, quantity, available)

    out_movements: list[StockMovement] = []
    in_batches: list[StockBatch] = []
    remaining = quantity
    for _ in range(5):
        if remaining <= 0:
            break
        batches = (
            db.execute(
                select(StockBatch)
                .where(
                    StockBatch.product_id == product_id,
                    StockBatch.branch_id == from_branch_id,
                    *_usable_filter(False),
                )
                .order_by(StockBatch.expiry_date.asc().nulls_last(), StockBatch.received_at.asc())
            )
            .scalars()
            .all()
        )
        if not batches:
            break
        guard_missed = False
        for src in batches:
            if remaining <= 0:
                break
            take = min(Decimal(src.quantity), remaining)
            claimed = db.execute(
                sa_update(StockBatch)
                .where(StockBatch.id == src.id, StockBatch.quantity >= take)
                .values(quantity=StockBatch.quantity - take)
                .execution_options(synchronize_session=False)
            )
            if claimed.rowcount != 1:
                guard_missed = True
                continue
            db.expire(src)
            out_movements.append(
                StockMovement(
                    product_id=product_id,
                    batch_id=src.id,
                    branch_id=from_branch_id,
                    movement_type="transfer_out",
                    quantity=-take,
                    reason=reason,
                    ref_type="transfer",
                    ref_id=ref_id,
                    actor_id=actor_id,
                )
            )
            dst = StockBatch(
                product_id=product_id,
                branch_id=to_branch_id,
                batch_no=src.batch_no,
                expiry_date=src.expiry_date,
                quantity=take,
                unit_cost=src.unit_cost,
                supplier_id=src.supplier_id,
            )
            db.add(dst)
            db.flush()
            db.add(
                StockMovement(
                    product_id=product_id,
                    batch_id=dst.id,
                    branch_id=to_branch_id,
                    movement_type="transfer_in",
                    quantity=take,
                    reason=reason,
                    ref_type="transfer",
                    ref_id=ref_id,
                    actor_id=actor_id,
                )
            )
            in_batches.append(dst)
            remaining -= take
        if remaining > 0 and not guard_missed:
            break

    if remaining > 0:
        raise InsufficientStockError(
            product_id, quantity, quantity - remaining + on_hand(db, product_id, from_branch_id)
        )
    for m in out_movements:
        db.add(m)
    db.flush()
    return out_movements, in_batches


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
