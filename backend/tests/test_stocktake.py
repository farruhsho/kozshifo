"""Инвентаризация (stock-count): snapshot, edit counted, commit variances, idempotency."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _product_by_sku(client, auth, sku: str) -> dict:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)


def _create_product(client, auth, sku: str, name: str) -> dict:
    resp = client.post(f"{API}/inventory/products", headers=auth,
                       json={"sku": sku, "name": name, "unit": "шт", "min_stock": "1"})
    assert resp.status_code == 201, resp.text
    return resp.json()


def _stock_row(client, auth, branch_id: str, sku: str) -> dict | None:
    rows = client.get(f"{API}/inventory/stock", headers=auth, params={"branch_id": branch_id}).json()
    return next((r for r in rows if r["product"]["sku"] == sku), None)


def _receipt(client, auth, branch_id, product_id, qty, batch_no):
    resp = client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": product_id, "quantity": qty, "unit_cost": "100",
                   "batch_no": batch_no}]})
    assert resp.status_code == 201, resp.text
    return resp.json()[0]


def test_stock_count_commit_applies_surplus_and_shortage(client, auth):
    branch_id = _branch_id(client, auth)
    surplus_p = _create_product(client, auth, "ST-SURP", "Тест-излишек")
    short_p = _create_product(client, auth, "ST-SHORT", "Тест-недостача")
    surplus_batch = _receipt(client, auth, branch_id, surplus_p["id"], "10", "SURP-1")
    short_batch = _receipt(client, auth, branch_id, short_p["id"], "10", "SHORT-1")

    # Open a draft count — snapshots current on-hand into lines.
    opened = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id, "note": "тест"})
    assert opened.status_code == 201, opened.text
    count = opened.json()
    assert count["status"] == "draft"
    lines = {l["batch_id"]: l for l in count["lines"]}
    assert Decimal(lines[surplus_batch["id"]]["expected_qty"]) == Decimal("10")
    assert Decimal(lines[surplus_batch["id"]]["counted_qty"]) == Decimal("10")  # init = expected

    count_id = count["id"]
    # Surplus: counted 13 vs expected 10 → +3.
    up1 = client.patch(
        f"{API}/inventory/stock-counts/{count_id}/lines/{lines[surplus_batch['id']]['id']}",
        headers=auth, json={"counted_qty": "13"})
    assert up1.status_code == 200, up1.text
    assert Decimal(up1.json()["variance"]) == Decimal("3")
    # Shortage: counted 6 vs expected 10 → −4.
    up2 = client.patch(
        f"{API}/inventory/stock-counts/{count_id}/lines/{lines[short_batch['id']]['id']}",
        headers=auth, json={"counted_qty": "6"})
    assert up2.status_code == 200, up2.text
    assert Decimal(up2.json()["variance"]) == Decimal("-4")

    committed = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert committed.status_code == 200, committed.text
    body = committed.json()
    assert body["status"] == "committed"
    assert Decimal(body["surplus_total"]) == Decimal("3")
    assert Decimal(body["shortage_total"]) == Decimal("4")

    # Batch quantities reflect the adjustments.
    assert Decimal(_stock_row(client, auth, branch_id, "ST-SURP")["on_hand"]) == Decimal("13")
    assert Decimal(_stock_row(client, auth, branch_id, "ST-SHORT")["on_hand"]) == Decimal("6")


def test_commit_uses_absolute_counted_not_frozen_variance(client, auth):
    """Stock moved between open and commit → commit lands on the ABSOLUTE
    counted quantity, not expected_at_open + frozen variance (no double-count)."""
    branch_id = _branch_id(client, auth)
    p = _create_product(client, auth, "ST-DRIFT", "Тест-дрейф")
    batch = _receipt(client, auth, branch_id, p["id"], "10", "DRIFT-1")

    # Open the count while on-hand == 10 (expected frozen at 10). The branch
    # accumulates other products across the session-scoped DB, so pick our line
    # by batch_id rather than trusting position.
    opened = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id}).json()
    count_id = opened["id"]
    line = next(l for l in opened["lines"] if l["batch_id"] == batch["id"])
    assert Decimal(line["expected_qty"]) == Decimal("10")

    # Counter finds 12 physically on the shelf → counted 12 (variance +2 vs open).
    up = client.patch(
        f"{API}/inventory/stock-counts/{count_id}/lines/{line['id']}",
        headers=auth, json={"counted_qty": "12"})
    assert up.status_code == 200, up.text
    assert Decimal(up.json()["variance"]) == Decimal("2")

    # Meanwhile stock moves: 3 units written off (10 → 7 live).
    wo = client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": p["id"], "branch_id": branch_id,
        "quantity": "3", "reason": "движение во время пересчёта"})
    assert wo.status_code == 200, wo.text
    assert Decimal(_stock_row(client, auth, branch_id, "ST-DRIFT")["on_hand"]) == Decimal("7")

    committed = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert committed.status_code == 200, committed.text
    # ABSOLUTE: batch ends at the physical count 12 — NOT 7+2=9 (relative would
    # double-count) and NOT expected-based 12 built from a stale 10.
    assert Decimal(_stock_row(client, auth, branch_id, "ST-DRIFT")["on_hand"]) == Decimal("12")


def test_commit_shortage_and_surplus_land_on_absolute(client, auth):
    """Undisturbed count: shortage and surplus batches end exactly at counted."""
    branch_id = _branch_id(client, auth)
    surplus_p = _create_product(client, auth, "ST-ABS-S", "Абс-излишек")
    short_p = _create_product(client, auth, "ST-ABS-D", "Абс-недостача")
    surp_b = _receipt(client, auth, branch_id, surplus_p["id"], "10", "ABS-S1")
    short_b = _receipt(client, auth, branch_id, short_p["id"], "10", "ABS-D1")

    opened = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id}).json()
    count_id = opened["id"]
    lines = {l["batch_id"]: l for l in opened["lines"]}
    client.patch(f"{API}/inventory/stock-counts/{count_id}/lines/{lines[surp_b['id']]['id']}",
                 headers=auth, json={"counted_qty": "15"})
    client.patch(f"{API}/inventory/stock-counts/{count_id}/lines/{lines[short_b['id']]['id']}",
                 headers=auth, json={"counted_qty": "4"})

    committed = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert committed.status_code == 200, committed.text
    assert Decimal(_stock_row(client, auth, branch_id, "ST-ABS-S")["on_hand"]) == Decimal("15")
    assert Decimal(_stock_row(client, auth, branch_id, "ST-ABS-D")["on_hand"]) == Decimal("4")


def test_stock_count_double_commit_409(client, auth):
    branch_id = _branch_id(client, auth)
    p = _create_product(client, auth, "ST-DBL", "Тест-повтор")
    _receipt(client, auth, branch_id, p["id"], "5", "DBL-1")

    opened = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id}).json()
    count_id = opened["id"]
    first = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert first.status_code == 200, first.text
    second = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert second.status_code == 409, second.text


def test_stock_count_edit_after_commit_409(client, auth):
    branch_id = _branch_id(client, auth)
    p = _create_product(client, auth, "ST-LOCK", "Тест-блок")
    _receipt(client, auth, branch_id, p["id"], "5", "LOCK-1")
    opened = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id}).json()
    count_id = opened["id"]
    line_id = opened["lines"][0]["id"]
    client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    blocked = client.patch(
        f"{API}/inventory/stock-counts/{count_id}/lines/{line_id}",
        headers=auth, json={"counted_qty": "9"})
    assert blocked.status_code == 409, blocked.text


def test_second_open_draft_same_branch_409(client, auth):
    """Only one draft count per branch: a concurrent second open is rejected 409
    (otherwise two stale snapshots would clobber each other's corrections on
    commit — last committer wins). After the first is committed, a new one opens."""
    branch_id = _branch_id(client, auth)
    p = _create_product(client, auth, "ST-ONE", "Тест-один")
    _receipt(client, auth, branch_id, p["id"], "5", "ONE-1")

    first = client.post(f"{API}/inventory/stock-counts", headers=auth,
                        json={"branch_id": branch_id})
    assert first.status_code == 201, first.text
    count_id = first.json()["id"]

    # A second open for the SAME branch while the first is still draft → 409.
    second = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id})
    assert second.status_code == 409, second.text

    # Close the first, then a fresh open succeeds.
    committed = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert committed.status_code == 200, committed.text
    third = client.post(f"{API}/inventory/stock-counts", headers=auth,
                        json={"branch_id": branch_id})
    assert third.status_code == 201, third.text
    # Clean up so a leftover draft cannot 409 unrelated tests sharing the branch.
    client.post(f"{API}/inventory/stock-counts/{third.json()['id']}/commit", headers=auth)


def _sc_movements(count_id: str) -> list:
    """StockMovement rows written by a specific stock-count commit (direct DB)."""
    from app.core.database import SessionLocal
    from app.models.inventory import StockMovement
    from sqlalchemy import select
    from uuid import UUID

    db = SessionLocal()
    try:
        return db.execute(
            select(StockMovement).where(
                StockMovement.ref_type == "stock_count",
                StockMovement.ref_id == UUID(count_id),
            )
        ).scalars().all()
    finally:
        db.close()


def test_untouched_line_does_not_resurrect_drained_batch(client, auth):
    """Resurrect-guard: a batch that drained after the count opened but was NEVER
    recounted must stay at its live qty on commit (no phantom resurrection, no
    adjustment movement for that batch)."""
    branch_id = _branch_id(client, auth)
    p = _create_product(client, auth, "ST-RESURRECT", "Тест-воскрешение")
    batch = _receipt(client, auth, branch_id, p["id"], "10", "RESURR-1")

    # Open while on-hand == 10; the line is created with counted=expected=10 but
    # recounted=False (a display default, not a physical count).
    opened = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id}).json()
    count_id = opened["id"]
    line = next(l for l in opened["lines"] if l["batch_id"] == batch["id"])
    assert Decimal(line["expected_qty"]) == Decimal("10")

    # Stock moves: 3 written off (10 → 7 live). Operator does NOT recount this line.
    wo = client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": p["id"], "branch_id": branch_id,
        "quantity": "3", "reason": "движение во время пересчёта"})
    assert wo.status_code == 200, wo.text
    assert Decimal(_stock_row(client, auth, branch_id, "ST-RESURRECT")["on_hand"]) == Decimal("7")

    committed = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert committed.status_code == 200, committed.text
    # The untouched line did NOT force the batch back to 10 — it stays at live 7.
    assert Decimal(_stock_row(client, auth, branch_id, "ST-RESURRECT")["on_hand"]) == Decimal("7")
    # And no adjustment movement was written for this count (nothing recounted).
    assert _sc_movements(count_id) == []


def test_recounted_line_applies_absolute_and_writes_one_movement(client, auth):
    """Recounted-apply: the SAME drained batch, but the operator PATCHes counted=8
    → commit forces the batch to 8 and writes exactly one adjustment movement."""
    branch_id = _branch_id(client, auth)
    p = _create_product(client, auth, "ST-RECOUNT", "Тест-пересчёт")
    batch = _receipt(client, auth, branch_id, p["id"], "10", "RECOUNT-1")

    opened = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id}).json()
    count_id = opened["id"]
    line = next(l for l in opened["lines"] if l["batch_id"] == batch["id"])

    # Stock drains 10 → 7 live.
    client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": p["id"], "branch_id": branch_id, "quantity": "3", "reason": "движение"})
    assert Decimal(_stock_row(client, auth, branch_id, "ST-RECOUNT")["on_hand"]) == Decimal("7")

    # Operator physically recounts: finds 8 on the shelf.
    up = client.patch(f"{API}/inventory/stock-counts/{count_id}/lines/{line['id']}",
                      headers=auth, json={"counted_qty": "8"})
    assert up.status_code == 200, up.text

    committed = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert committed.status_code == 200, committed.text
    # Absolute set to the physical 8 (not 7, not 10).
    assert Decimal(_stock_row(client, auth, branch_id, "ST-RECOUNT")["on_hand"]) == Decimal("8")
    # Exactly one adjustment movement, of applied delta 8 − 7 = +1.
    movements = _sc_movements(count_id)
    assert len(movements) == 1
    assert Decimal(movements[0].quantity) == Decimal("1")


def test_concurrent_commit_guarded_update_no_double_ledger(client, auth):
    """Concurrent-commit: the guarded status UPDATE stakes the commit before any
    movement is written, so a second commit is rejected (409) and the ledger does
    not grow. We also assert the raw guarded UPDATE returns rowcount 0 the 2nd time
    (the mechanism that makes an honest race safe on both SQLite and Postgres)."""
    branch_id = _branch_id(client, auth)
    p = _create_product(client, auth, "ST-RACE", "Тест-гонка")
    batch = _receipt(client, auth, branch_id, p["id"], "10", "RACE-1")

    opened = client.post(f"{API}/inventory/stock-counts", headers=auth,
                         json={"branch_id": branch_id}).json()
    count_id = opened["id"]
    line = next(l for l in opened["lines"] if l["batch_id"] == batch["id"])
    client.patch(f"{API}/inventory/stock-counts/{count_id}/lines/{line['id']}",
                 headers=auth, json={"counted_qty": "12"})

    first = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert first.status_code == 200, first.text
    ledger_after_first = _sc_movements(count_id)
    assert len(ledger_after_first) == 1  # one adjustment (12 − 10)

    # A second commit request loses the race → 409, no extra movements.
    second = client.post(f"{API}/inventory/stock-counts/{count_id}/commit", headers=auth)
    assert second.status_code == 409, second.text
    assert len(_sc_movements(count_id)) == len(ledger_after_first)  # ledger did NOT double

    # Prove the underlying guard: a second draft→committed UPDATE matches 0 rows.
    from app.core.database import SessionLocal
    from app.models.inventory import StockCount
    from sqlalchemy import update as sa_update
    from uuid import UUID

    db = SessionLocal()
    try:
        claimed = db.execute(
            sa_update(StockCount)
            .where(StockCount.id == UUID(count_id), StockCount.status == "draft")
            .values(status="committed")
            .execution_options(synchronize_session=False)
        )
        assert claimed.rowcount == 0  # already committed — guard rejects the loser
        db.rollback()
    finally:
        db.close()


def test_receipt_rejects_past_expiry_date(client, auth):
    """Goods-in with an expiry already in the past (typo) is refused — such a lot
    is born expired and would hang as an on_hand=0 phantom. None is allowed."""
    branch_id = _branch_id(client, auth)
    p = _create_product(client, auth, "ST-PASTEXP", "Тест-просрочка-приход")
    denied = client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": p["id"], "quantity": "5", "unit_cost": "100",
                   "batch_no": "PAST-1", "expiry_date": "2020-01-01"}]})
    assert denied.status_code == 422, denied.text
    assert "Срок годности" in denied.text
    # A None expiry (бессрочный товар) is still accepted.
    ok = client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": p["id"], "quantity": "5", "unit_cost": "100",
                   "batch_no": "NOEXP-1"}]})
    assert ok.status_code == 201, ok.text


def test_stock_count_rbac_doctor_denied(client, auth):
    """Doctor lacks inventory.stocktake → cannot open a count."""
    branch_id = _branch_id(client, auth)
    created = client.post(f"{API}/users", headers=auth, json={
        "email": "st.doc@kozshifo.uz", "full_name": "Доктор Инв",
        "password": "Stk!2026xx", "role_names": ["Doctor"]})
    assert created.status_code == 201, created.text
    token = client.post(f"{API}/auth/login",
                        data={"username": "st.doc@kozshifo.uz", "password": "Stk!2026xx"}).json()["access_token"]
    doc_auth = {"Authorization": f"Bearer {token}"}
    denied = client.post(f"{API}/inventory/stock-counts", headers=doc_auth,
                        json={"branch_id": branch_id})
    assert denied.status_code == 403
    assert "inventory.stocktake" in denied.json()["detail"]
