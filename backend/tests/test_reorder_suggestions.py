"""Phase 6: warehouse reorder suggestions — products at/below min_stock with a
suggested restock qty (up to 2× min). Runs in a fresh branch (on_hand starts 0)."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _product_id(client, auth, sku: str) -> str:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)["id"]


def test_reorder_suggestions(client, auth):
    branch = client.post(f"{API}/branches", headers=auth,
                         json={"name": "Склад-реордер", "code": "REORD"}).json()["id"]

    # A fresh branch has no stock → every active product with min_stock>0 is below.
    sugg = client.get(f"{API}/inventory/reorder-suggestions", headers=auth,
                      params={"branch_id": branch})
    assert sugg.status_code == 200, sugg.text
    by_sku = {s["product"]["sku"]: s for s in sugg.json()}
    assert "SYR-1" in by_sku  # seeded with min_stock 50
    s = by_sku["SYR-1"]
    assert Decimal(s["on_hand"]) == Decimal("0")
    assert Decimal(s["min_stock"]) == Decimal("50")
    assert Decimal(s["suggested_qty"]) == Decimal("100")  # 2×50 − 0

    # Receive plenty → SYR-1 is no longer below min_stock, drops off the list.
    client.post(f"{API}/inventory/receipts", headers=auth,
                json={"branch_id": branch,
                      "items": [{"product_id": _product_id(client, auth, "SYR-1"),
                                 "quantity": "200"}]})
    sugg2 = client.get(f"{API}/inventory/reorder-suggestions", headers=auth,
                       params={"branch_id": branch}).json()
    assert "SYR-1" not in {s["product"]["sku"] for s in sugg2}
