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
