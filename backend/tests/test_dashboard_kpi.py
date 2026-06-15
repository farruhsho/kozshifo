"""Director dashboard KPI extensions: operation counters + warehouse alerts.

Ordering note: this file runs alphabetically BEFORE test_inventory.py and
test_operations.py on the shared session DB, and test_inventory asserts the
five seeded SKUs sit at exactly zero stock with no open batches. So the
operation test below receipts EXACTLY the PHACO template quantities (fully
consumed by one perform), and the expiry test uses its own dedicated product.
"""
from __future__ import annotations

from datetime import date, timedelta

from tests.conftest import API

# PHACO template (seed): sku -> qty written off per performed operation.
_PHACO_CONSUMPTION = {
    "IOL-001": "1",
    "VISC-001": "1",
    "KNIFE-275": "1",
    "SYR-1": "2",
    "GLOVES-ST": "3",
}

_NEW_FIELDS = ("operations_today", "operations_month", "low_stock_count", "expiring_soon_count")


def _summary(client, auth) -> dict:
    resp = client.get(f"{API}/dashboard/summary", headers=auth)
    assert resp.status_code == 200, resp.text
    return resp.json()


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _product_by_sku(client, auth, sku: str) -> dict:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)


def test_summary_has_new_kpi_fields(client, auth):
    body = _summary(client, auth)
    for field in _NEW_FIELDS:
        assert field in body, f"missing field {field}"
        assert isinstance(body[field], int), f"{field} must be an int"


def test_low_stock_counts_seeded_zero_stock_products(client, auth):
    # The five seeded warehouse SKUs start with zero stock -> all at/below min_stock.
    assert _summary(client, auth)["low_stock_count"] >= 5


def test_expiring_soon_counts_near_expiry_batches(client, auth):
    branch_id = _branch_id(client, auth)
    before = _summary(client, auth)["expiring_soon_count"]

    # Dedicated product: the seeded SKUs must stay at zero for later test files.
    product = client.post(
        f"{API}/inventory/products", headers=auth,
        json={"sku": "KPI-EXP-1", "name": "КПИ тест срока годности", "min_stock": "0"},
    )
    assert product.status_code == 201, product.text

    soon = (date.today() + timedelta(days=10)).isoformat()
    receipt = client.post(
        f"{API}/inventory/receipts", headers=auth,
        json={"branch_id": branch_id,
              "items": [{"product_id": product.json()["id"], "quantity": "5",
                         "unit_cost": "100.00", "batch_no": "KPI-SOON", "expiry_date": soon}]},
    )
    assert receipt.status_code == 201, receipt.text

    assert _summary(client, auth)["expiring_soon_count"] == before + 1


def test_operations_counters_after_perform(client, auth):
    branch_id = _branch_id(client, auth)
    before = _summary(client, auth)

    # Goods-in EXACTLY what one PHACO consumes — perform drains it back to zero.
    receipt = client.post(
        f"{API}/inventory/receipts", headers=auth,
        json={"branch_id": branch_id,
              "items": [{"product_id": _product_by_sku(client, auth, sku)["id"], "quantity": qty}
                        for sku, qty in _PHACO_CONSUMPTION.items()]},
    )
    assert receipt.status_code == 201, receipt.text

    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "КПИ", "last_name": "Операционный",
              "phone": "+998900000001", "branch_id": branch_id},
    ).json()
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "items": []},
    ).json()
    phaco = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
                 if t["code"] == "PHACO")
    created = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": phaco["id"], "eye": "od"},
    )
    assert created.status_code == 201, created.text

    # Referred/scheduled operations must NOT count — only performed ones do.
    assert _summary(client, auth)["operations_today"] == before["operations_today"]

    sched = client.post(f"{API}/operations/{created.json()['id']}/schedule", headers=auth,
                        json={"scheduled_at": "2026-07-01T09:00:00Z"})
    assert sched.status_code == 200, sched.text
    assert _summary(client, auth)["operations_today"] == before["operations_today"]

    done = client.post(f"{API}/operations/{created.json()['id']}/perform", headers=auth)
    assert done.status_code == 200, done.text

    after = _summary(client, auth)
    assert after["operations_today"] == before["operations_today"] + 1
    assert after["operations_today"] >= 1
    assert after["operations_month"] >= after["operations_today"]


def test_low_stock_is_per_branch_not_cross_branch_sum(client, auth):
    """A branch deficit must count even when another branch is well stocked."""
    second = client.post(f"{API}/branches", headers=auth,
                         json={"name": "Филиал КПИ", "code": "KPI-B"}).json()
    product = client.post(f"{API}/inventory/products", headers=auth,
                          json={"sku": "KPI-BR-1", "name": "Межфилиальный тест",
                                "unit": "шт", "min_stock": "5"}).json()

    # Healthy in the second branch only -> not low (it has a stocked branch
    # above the minimum, and no branch holds it below while stocked).
    client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": second["id"],
        "items": [{"product_id": product["id"], "quantity": "10", "unit_cost": "1"}]})
    before = client.get(f"{API}/dashboard/summary", headers=auth).json()["low_stock_count"]

    # Drop the SAME branch to 4 <= 5: per-branch deficit must raise the KPI,
    # even though a cross-branch sum would once have hidden a multi-branch case.
    client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": product["id"], "branch_id": second["id"],
        "quantity": "6", "reason": "кпи-тест"})
    after = client.get(f"{API}/dashboard/summary", headers=auth).json()["low_stock_count"]
    assert after == before + 1
