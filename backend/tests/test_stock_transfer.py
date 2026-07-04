"""Inter-branch transfers (FEFO, expiry-preserving) and supplier returns."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _create_branch(client, auth, code: str, name: str) -> str:
    resp = client.post(f"{API}/branches", headers=auth, json={"name": name, "code": code})
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


def _create_product(client, auth, sku: str, name: str) -> dict:
    resp = client.post(f"{API}/inventory/products", headers=auth,
                       json={"sku": sku, "name": name, "unit": "шт", "min_stock": "1"})
    assert resp.status_code == 201, resp.text
    return resp.json()


def _stock_row(client, auth, branch_id: str, sku: str) -> dict | None:
    rows = client.get(f"{API}/inventory/stock", headers=auth, params={"branch_id": branch_id}).json()
    return next((r for r in rows if r["product"]["sku"] == sku), None)


def _receipt(client, auth, branch_id, product_id, qty, batch_no, expiry):
    resp = client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": product_id, "quantity": qty, "unit_cost": "100",
                   "batch_no": batch_no, "expiry_date": expiry}]})
    assert resp.status_code == 201, resp.text
    return resp.json()[0]


def test_transfer_moves_stock_preserving_expiry(client, auth):
    from_branch = _branch_id(client, auth)
    to_branch = _create_branch(client, auth, "TRF-B2", "Филиал-2")
    product = _create_product(client, auth, "TRF-1", "Тест-перемещение")
    _receipt(client, auth, from_branch, product["id"], "10", "TRF-B", "2027-05-01")

    resp = client.post(f"{API}/inventory/transfers", headers=auth, json={
        "product_id": product["id"], "from_branch_id": from_branch,
        "to_branch_id": to_branch, "quantity": "4"})
    assert resp.status_code == 200, resp.text
    movements = resp.json()
    # transfer_out movements are returned (negative).
    assert all(m["movement_type"] == "transfer_out" for m in movements)
    assert sum(Decimal(m["quantity"]) for m in movements) == Decimal("-4")

    src = _stock_row(client, auth, from_branch, "TRF-1")
    assert Decimal(src["on_hand"]) == Decimal("6")

    dst = _stock_row(client, auth, to_branch, "TRF-1")
    assert Decimal(dst["on_hand"]) == Decimal("4")
    # Destination batch preserves the source lot's expiry.
    assert dst["batches"][0]["expiry_date"] == "2027-05-01"


def test_transfer_insufficient_409(client, auth):
    from_branch = _branch_id(client, auth)
    to_branch = _create_branch(client, auth, "TRF-B3", "Филиал-3")
    product = _create_product(client, auth, "TRF-2", "Тест-нехватка")
    _receipt(client, auth, from_branch, product["id"], "3", "TRF-C", "2027-05-01")

    resp = client.post(f"{API}/inventory/transfers", headers=auth, json={
        "product_id": product["id"], "from_branch_id": from_branch,
        "to_branch_id": to_branch, "quantity": "10"})
    assert resp.status_code == 409, resp.text
    # Source untouched.
    assert Decimal(_stock_row(client, auth, from_branch, "TRF-2")["on_hand"]) == Decimal("3")


def test_transfer_same_branch_422(client, auth):
    branch = _branch_id(client, auth)
    product = _create_product(client, auth, "TRF-SAME", "Тест-один-филиал")
    _receipt(client, auth, branch, product["id"], "5", "TRF-S", "2027-05-01")
    resp = client.post(f"{API}/inventory/transfers", headers=auth, json={
        "product_id": product["id"], "from_branch_id": branch,
        "to_branch_id": branch, "quantity": "1"})
    assert resp.status_code == 422, resp.text


def test_supplier_return_writes_down_batch(client, auth):
    branch = _branch_id(client, auth)
    product = _create_product(client, auth, "SRET-1", "Тест-возврат")
    batch = _receipt(client, auth, branch, product["id"], "8", "SRET-B", "2027-05-01")

    resp = client.post(f"{API}/inventory/supplier-returns", headers=auth, json={
        "product_id": product["id"], "batch_id": batch["id"],
        "quantity": "3", "reason": "брак партии"})
    assert resp.status_code == 200, resp.text
    movement = resp.json()[0]
    assert movement["movement_type"] == "supplier_return"
    assert Decimal(movement["quantity"]) == Decimal("-3")

    assert Decimal(_stock_row(client, auth, branch, "SRET-1")["on_hand"]) == Decimal("5")


def test_supplier_return_over_batch_409(client, auth):
    branch = _branch_id(client, auth)
    product = _create_product(client, auth, "SRET-2", "Тест-возврат-много")
    batch = _receipt(client, auth, branch, product["id"], "2", "SRET-C", "2027-05-01")
    resp = client.post(f"{API}/inventory/supplier-returns", headers=auth, json={
        "product_id": product["id"], "batch_id": batch["id"],
        "quantity": "5", "reason": "слишком много"})
    assert resp.status_code == 409, resp.text
    assert Decimal(_stock_row(client, auth, branch, "SRET-2")["on_hand"]) == Decimal("2")
