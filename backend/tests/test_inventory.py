"""Inventory: seed, receipts, FEFO write-off, atomicity, RBAC."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API

_SEEDED_SKUS = {"VISC-001", "IOL-001", "KNIFE-275", "SYR-1", "GLOVES-ST"}


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _product_by_sku(client, auth, sku: str) -> dict:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)


def _stock_row(client, auth, branch_id: str, sku: str) -> dict | None:
    rows = client.get(f"{API}/inventory/stock", headers=auth, params={"branch_id": branch_id}).json()
    return next((r for r in rows if r["product"]["sku"] == sku), None)


def test_seeded_products_present(client, auth):
    products = client.get(f"{API}/inventory/products", headers=auth, params={"limit": 500}).json()
    skus = {p["sku"] for p in products["items"]}
    assert _SEEDED_SKUS <= skus

    gloves = _product_by_sku(client, auth, "GLOVES-ST")
    assert gloves["unit"] == "пара"
    assert Decimal(gloves["min_stock"]) == Decimal("50")

    # With zero stock everything seeded is below min_stock -> shows in low_only.
    branch_id = _branch_id(client, auth)
    low_rows = client.get(
        f"{API}/inventory/stock", headers=auth,
        params={"branch_id": branch_id, "low_only": "true"},
    ).json()
    low_skus = {r["product"]["sku"] for r in low_rows}
    assert _SEEDED_SKUS <= low_skus
    for row in low_rows:
        if row["product"]["sku"] in _SEEDED_SKUS:
            assert row["low_stock"] is True
            assert Decimal(row["on_hand"]) == 0
            assert row["batches"] == []


def test_receipt_creates_batches_and_stock(client, auth):
    branch_id = _branch_id(client, auth)
    supplier = client.get(f"{API}/inventory/suppliers", headers=auth).json()["items"][0]
    syr = _product_by_sku(client, auth, "SYR-1")
    gloves = _product_by_sku(client, auth, "GLOVES-ST")

    resp = client.post(
        f"{API}/inventory/receipts", headers=auth,
        json={
            "branch_id": branch_id,
            "supplier_id": supplier["id"],
            "items": [
                {"product_id": syr["id"], "quantity": "30", "unit_cost": "1500.00"},
                {"product_id": gloves["id"], "quantity": "40", "unit_cost": "8000.00",
                 "batch_no": "GL-2026-01", "expiry_date": "2027-01-31"},
            ],
        },
    )
    assert resp.status_code == 201, resp.text
    batches = resp.json()
    assert len(batches) == 2
    assert batches[1]["batch_no"] == "GL-2026-01"
    assert batches[1]["expiry_date"] == "2027-01-31"

    syr_row = _stock_row(client, auth, branch_id, "SYR-1")
    assert Decimal(syr_row["on_hand"]) == Decimal("30")
    assert len(syr_row["batches"]) == 1
    assert syr_row["low_stock"] is True  # 30 <= min_stock 50

    gloves_row = _stock_row(client, auth, branch_id, "GLOVES-ST")
    assert Decimal(gloves_row["on_hand"]) == Decimal("40")
    assert gloves_row["batches"][0]["expiry_date"] == "2027-01-31"


def test_write_off_fefo_order(client, auth):
    branch_id = _branch_id(client, auth)
    visc = _product_by_sku(client, auth, "VISC-001")

    # The chronologically FIRST batch expires LATER — FEFO must skip it first.
    for batch_no, expiry in (("B-LATE", "2027-06-01"), ("B-EARLY", "2026-12-01")):
        resp = client.post(
            f"{API}/inventory/receipts", headers=auth,
            json={"branch_id": branch_id,
                  "items": [{"product_id": visc["id"], "quantity": "5",
                             "unit_cost": "90000.00", "batch_no": batch_no, "expiry_date": expiry}]},
        )
        assert resp.status_code == 201, resp.text

    written = client.post(
        f"{API}/inventory/write-off", headers=auth,
        json={"product_id": visc["id"], "branch_id": branch_id,
              "quantity": "7", "reason": "Тест FEFO"},
    )
    assert written.status_code == 200, written.text
    movements = written.json()
    assert [Decimal(m["quantity"]) for m in movements] == [Decimal("-5"), Decimal("-2")]
    assert all(m["movement_type"] == "write_off" for m in movements)

    # Earliest-expiry batch fully drained; remainder came from the later one.
    row = _stock_row(client, auth, branch_id, "VISC-001")
    assert Decimal(row["on_hand"]) == Decimal("3")
    open_batches = {b["batch_no"]: Decimal(b["quantity"]) for b in row["batches"]}
    assert open_batches == {"B-LATE": Decimal("3")}


def test_write_off_insufficient_is_atomic_409(client, auth):
    branch_id = _branch_id(client, auth)
    visc = _product_by_sku(client, auth, "VISC-001")
    before = _stock_row(client, auth, branch_id, "VISC-001")

    resp = client.post(
        f"{API}/inventory/write-off", headers=auth,
        json={"product_id": visc["id"], "branch_id": branch_id,
              "quantity": "100", "reason": "Слишком много"},
    )
    assert resp.status_code == 409, resp.text
    detail = resp.json()["detail"]
    assert "Вискоэластик" in detail
    assert "3" in detail  # available qty named in the error

    # Nothing was consumed: quantities are exactly as before.
    after = _stock_row(client, auth, branch_id, "VISC-001")
    assert Decimal(after["on_hand"]) == Decimal(before["on_hand"])
    assert [b["quantity"] for b in after["batches"]] == [b["quantity"] for b in before["batches"]]


def test_inventory_rbac(client, auth):
    branch_id = _branch_id(client, auth)
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "wh.doctor@kozshifo.uz", "full_name": "Доктор Склада",
              "password": "Sklad!2026", "role_names": ["Doctor"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login", data={"username": "wh.doctor@kozshifo.uz", "password": "Sklad!2026"}
    ).json()["access_token"]
    doc_auth = {"Authorization": f"Bearer {token}"}

    # Doctor has inventory.read -> can see stock…
    seen = client.get(f"{API}/inventory/stock", headers=doc_auth, params={"branch_id": branch_id})
    assert seen.status_code == 200, seen.text

    # …but not inventory.manage -> receipts are denied.
    syr = _product_by_sku(client, auth, "SYR-1")
    denied = client.post(
        f"{API}/inventory/receipts", headers=doc_auth,
        json={"branch_id": branch_id,
              "items": [{"product_id": syr["id"], "quantity": "1"}]},
    )
    assert denied.status_code == 403
    assert "inventory.manage" in denied.json()["detail"]


def _create_product(client, auth, sku: str, name: str) -> dict:
    resp = client.post(f"{API}/inventory/products", headers=auth,
                       json={"sku": sku, "name": name, "unit": "шт", "min_stock": "1"})
    assert resp.status_code == 201, resp.text
    return resp.json()


def test_expired_batches_never_consumed_without_explicit_disposal(client, auth):
    """Patient safety: expired lots are excluded from on_hand and FEFO."""
    branch_id = _branch_id(client, auth)
    product = _create_product(client, auth, "EXP-TEST-1", "Тест-срок")

    client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [
            {"product_id": product["id"], "quantity": "5", "unit_cost": "100",
             "batch_no": "OLD", "expiry_date": "2020-01-01"},     # уже просрочен
            {"product_id": product["id"], "quantity": "3", "unit_cost": "100",
             "batch_no": "FRESH", "expiry_date": "2030-01-01"},
        ],
    })

    row = _stock_row(client, auth, branch_id, "EXP-TEST-1")
    assert Decimal(row["on_hand"]) == Decimal("3")          # only the fresh lot counts
    flags = {b["batch_no"]: b["expired"] for b in row["batches"]}
    assert flags == {"OLD": True, "FRESH": False}

    # Auto/FEFO write-off cannot reach the expired lot: 4 > 3 usable -> 409.
    denied = client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": product["id"], "branch_id": branch_id,
        "quantity": "4", "reason": "тест"})
    assert denied.status_code == 409

    # Explicit disposal path consumes the expired lot too.
    disposed = client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": product["id"], "branch_id": branch_id,
        "quantity": "5", "reason": "утилизация просрочки", "include_expired": True})
    assert disposed.status_code == 200, disposed.text
    row2 = _stock_row(client, auth, branch_id, "EXP-TEST-1")
    assert {b["batch_no"]: b["quantity"] for b in row2["batches"]} == {"FRESH": "3.000"}


def test_products_filtered_by_product_type(client, auth):
    """?product_type=… returns only that class; omitting it returns all."""
    med = client.post(f"{API}/inventory/products", headers=auth, json={
        "sku": "PT-MED-1", "name": "Тест-лекарство", "unit": "шт",
        "min_stock": "1", "product_type": "medicine"})
    assert med.status_code == 201, med.text
    inst = client.post(f"{API}/inventory/products", headers=auth, json={
        "sku": "PT-INST-1", "name": "Тест-инструмент", "unit": "шт",
        "min_stock": "1", "product_type": "instrument"})
    assert inst.status_code == 201, inst.text

    filtered = client.get(f"{API}/inventory/products", headers=auth,
                          params={"product_type": "medicine", "limit": 500}).json()["items"]
    types = {p["product_type"] for p in filtered}
    assert types == {"medicine"}
    filtered_skus = {p["sku"] for p in filtered}
    assert "PT-MED-1" in filtered_skus
    assert "PT-INST-1" not in filtered_skus

    # Omitting the param returns the full catalog (both new ones present).
    all_skus = {p["sku"] for p in
                client.get(f"{API}/inventory/products", headers=auth,
                           params={"limit": 500}).json()["items"]}
    assert {"PT-MED-1", "PT-INST-1"} <= all_skus


def test_inactive_product_stock_stays_visible_and_unreceivable(client, auth):
    branch_id = _branch_id(client, auth)
    product = _create_product(client, auth, "INACT-1", "Тест-деактивация")
    client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": product["id"], "quantity": "7", "unit_cost": "10"}]})

    off = client.patch(f"{API}/inventory/products/{product['id']}", headers=auth,
                       json={"is_active": False})
    assert off.status_code == 200

    # Remaining stock must NOT vanish from the only stock view.
    row = _stock_row(client, auth, branch_id, "INACT-1")
    assert row is not None and Decimal(row["on_hand"]) == Decimal("7")
    assert row["product"]["is_active"] is False
    assert row["low_stock"] is False  # deactivated products do not raise alerts

    # ...but new stock cannot be received into it.
    blocked = client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": product["id"], "quantity": "1", "unit_cost": "10"}]})
    assert blocked.status_code == 422
    assert "deactivated" in blocked.json()["detail"]
