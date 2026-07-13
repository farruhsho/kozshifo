"""Movement-history ledger view: GET /inventory/movements.

A receipt + write-off + inter-branch transfer produce ledger rows; the endpoint
returns them newest-first, joined to human-readable product/actor labels, and
filters by branch, product, movement_type and a half-open created_at window.
"""
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


def _movements(client, auth, **params) -> dict:
    resp = client.get(f"{API}/inventory/movements", headers=auth, params=params)
    assert resp.status_code == 200, resp.text
    return resp.json()


def test_movements_records_receipt_writeoff_transfer(client, auth):
    branch_id = _branch_id(client, auth)
    other = _create_branch(client, auth, "MH-B2", "MH-Филиал-2")
    product = _create_product(client, auth, "MH-1", "Тест-леджер")

    # Receipt (+), write-off (−), transfer_out (−) to a second branch.
    recv = client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": product["id"], "quantity": "20", "unit_cost": "100",
                   "batch_no": "MH-B1", "expiry_date": "2030-01-01"}],
    })
    assert recv.status_code == 201, recv.text

    wo = client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": product["id"], "branch_id": branch_id,
        "quantity": "3", "reason": "тест списание"})
    assert wo.status_code == 200, wo.text

    tr = client.post(f"{API}/inventory/transfers", headers=auth, json={
        "product_id": product["id"], "from_branch_id": branch_id,
        "to_branch_id": other, "quantity": "4"})
    assert tr.status_code == 200, tr.text

    # All movements for this product across branches: receipt + write_off +
    # transfer_out (source branch) + transfer_in (destination branch) = 4 rows.
    all_mv = _movements(client, auth, product_id=product["id"])
    assert all_mv["total"] == 4
    types = {m["movement_type"] for m in all_mv["items"]}
    assert types == {"receipt", "write_off", "transfer_out", "transfer_in"}

    # Ordering is newest-first by created_at (non-increasing). Strict chronological
    # order WITHIN one second is not asserted: created_at (server func.now()) has
    # only second granularity and ties for same-transaction rows, so the endpoint's
    # id.desc() tiebreak makes the order deterministic but not sub-second-chrono.
    stamps = [m["created_at"] for m in all_mv["items"]]
    assert stamps == sorted(stamps, reverse=True)

    # Human-readable join: product name/sku + actor name are populated.
    top = all_mv["items"][0]
    assert top["product_name"] == "Тест-леджер"
    assert top["product_sku"] == "MH-1"
    assert top["actor_name"]  # superadmin performed the action

    # Signs: receipt positive, write-off/transfer_out negative.
    by_type = {}
    for m in all_mv["items"]:
        by_type.setdefault(m["movement_type"], Decimal(m["quantity"]))
    assert by_type["receipt"] > 0
    assert by_type["write_off"] < 0
    assert by_type["transfer_out"] < 0
    assert by_type["transfer_in"] > 0


def test_movements_filter_by_type_and_branch(client, auth):
    branch_id = _branch_id(client, auth)
    product = _create_product(client, auth, "MH-2", "Тест-фильтр")
    client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": product["id"], "quantity": "10", "unit_cost": "1"}]})
    client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": product["id"], "branch_id": branch_id,
        "quantity": "2", "reason": "фильтр-тест"})

    only_receipts = _movements(client, auth, product_id=product["id"],
                               movement_type="receipt")
    assert only_receipts["total"] == 1
    assert only_receipts["items"][0]["movement_type"] == "receipt"

    only_writeoffs = _movements(client, auth, product_id=product["id"],
                                movement_type="write_off")
    assert only_writeoffs["total"] == 1
    assert only_writeoffs["items"][0]["movement_type"] == "write_off"

    # Branch filter narrows to the branch that actually holds the movements.
    branch_scoped = _movements(client, auth, branch_id=branch_id,
                               product_id=product["id"])
    assert branch_scoped["total"] == 2


def test_movements_pagination(client, auth):
    branch_id = _branch_id(client, auth)
    product = _create_product(client, auth, "MH-3", "Тест-пагинация")
    # Five separate receipts → five receipt rows.
    for _ in range(5):
        client.post(f"{API}/inventory/receipts", headers=auth, json={
            "branch_id": branch_id,
            "items": [{"product_id": product["id"], "quantity": "1", "unit_cost": "1"}]})

    page1 = _movements(client, auth, product_id=product["id"], limit=2, offset=0)
    assert page1["total"] == 5
    assert len(page1["items"]) == 2
    assert page1["limit"] == 2 and page1["offset"] == 0

    page2 = _movements(client, auth, product_id=product["id"], limit=2, offset=2)
    assert len(page2["items"]) == 2
    # Distinct rows across pages (no overlap).
    assert {m["id"] for m in page1["items"]}.isdisjoint({m["id"] for m in page2["items"]})


def test_movements_date_window(client, auth):
    branch_id = _branch_id(client, auth)
    product = _create_product(client, auth, "MH-4", "Тест-окно")
    client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": product["id"], "quantity": "1", "unit_cost": "1"}]})

    # A window entirely in the past excludes today's movement…
    empty = _movements(client, auth, product_id=product["id"],
                       date_from="2000-01-01T00:00:00Z", date_to="2000-01-02T00:00:00Z")
    assert empty["total"] == 0

    # …a window that reaches into the future includes it.
    present = _movements(client, auth, product_id=product["id"],
                         date_from="2000-01-01T00:00:00Z", date_to="2100-01-01T00:00:00Z")
    assert present["total"] == 1


def test_movements_requires_inventory_read(client, auth):
    # A brand-new user with no roles has no inventory.read → 403.
    created = client.post(f"{API}/users", headers=auth, json={
        "email": "mh.noperm@kozshifo.uz", "full_name": "Без прав",
        "password": "NoPerm!2026", "role_names": []})
    assert created.status_code == 201, created.text
    token = client.post(f"{API}/auth/login",
                        data={"username": "mh.noperm@kozshifo.uz", "password": "NoPerm!2026"}
                        ).json()["access_token"]
    denied = client.get(f"{API}/inventory/movements",
                        headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
    assert "inventory.read" in denied.json()["detail"]
