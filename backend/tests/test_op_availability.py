"""Operation priority + consumables-availability pre-check.

The availability endpoint is advisory (the doctor sees shortages at prescribe
time); the hard guarantee stays in perform_operation. These tests share the
session DB with the rest of the suite, so every receipt made here is written
back off before the file ends — test_operations.py (alphabetically next)
expects KNIFE-275 == 0 and measures the other SKUs as before/after deltas.
"""
from __future__ import annotations

import uuid
from decimal import Decimal

from tests.conftest import API

# PHACO template (seed): sku -> qty required per operation.
_PHACO_TEMPLATE = {
    "IOL-001": Decimal("1"),
    "VISC-001": Decimal("1"),
    "KNIFE-275": Decimal("1"),
    "SYR-1": Decimal("2"),
    "GLOVES-ST": Decimal("3"),
}


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _product_by_sku(client, auth, sku: str) -> dict:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)


def _on_hand(client, auth, branch_id: str, sku: str) -> Decimal:
    rows = client.get(f"{API}/inventory/stock", headers=auth, params={"branch_id": branch_id}).json()
    return Decimal(next(r for r in rows if r["product"]["sku"] == sku)["on_hand"])


def _receipt(client, auth, branch_id: str, items: list[tuple[str, str]]) -> None:
    resp = client.post(
        f"{API}/inventory/receipts", headers=auth,
        json={
            "branch_id": branch_id,
            "items": [
                {"product_id": _product_by_sku(client, auth, sku)["id"], "quantity": qty}
                for sku, qty in items
            ],
        },
    )
    assert resp.status_code == 201, resp.text


def _write_off(client, auth, branch_id: str, sku: str, qty: Decimal, reason: str) -> None:
    resp = client.post(
        f"{API}/inventory/write-off", headers=auth,
        json={"product_id": _product_by_sku(client, auth, sku)["id"],
              "branch_id": branch_id, "quantity": str(qty), "reason": reason},
    )
    assert resp.status_code == 200, resp.text


def _drain_to_zero(client, auth, branch_id: str, reason: str) -> None:
    """Write the PHACO SKUs down to zero (earlier files leave leftovers)."""
    for sku in _PHACO_TEMPLATE:
        leftover = _on_hand(client, auth, branch_id, sku)
        if leftover > 0:
            _write_off(client, auth, branch_id, sku, leftover, reason)
        assert _on_hand(client, auth, branch_id, sku) == Decimal("0"), sku


def _operation_type(client, auth, code: str) -> dict:
    types = client.get(f"{API}/operation-types", headers=auth).json()
    return next(t for t in types if t["code"] == code)


def _availability(client, headers, op_type_id: str, branch_id: str):
    return client.get(
        f"{API}/operation-types/{op_type_id}/availability",
        headers=headers, params={"branch_id": branch_id},
    )


def _new_visit(client, auth, branch_id: str, suffix: str) -> dict:
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Доступ", "last_name": f"Тестов-{suffix}",
              "phone": "+998900000001", "branch_id": branch_id},
    ).json()
    return client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "items": []},
    ).json()


def test_availability_zero_stock_blocks_every_item(client, auth):
    branch_id = _branch_id(client, auth)
    # Earlier test files leave stock in seeded SKUs (e.g. test_inventory leaves
    # SYR-1/GLOVES-ST/VISC-001) — establish a true zero baseline first.
    _drain_to_zero(client, auth, branch_id, "Тест: обнуление остатков перед проверкой доступности")
    phaco = _operation_type(client, auth, "PHACO")

    resp = _availability(client, auth, phaco["id"], branch_id)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["ok"] is False
    assert len(body["items"]) == len(_PHACO_TEMPLATE)

    by_name = {i["product_name"]: i for i in body["items"]}
    assert Decimal(by_name["Шприц 1 мл"]["required"]) == Decimal("2")
    assert Decimal(by_name["Перчатки стерильные (пара)"]["required"]) == Decimal("3")
    for item in body["items"]:
        assert item["ok"] is False
        assert Decimal(item["available"]) == Decimal("0")
        assert Decimal(item["required"]) > 0
        assert item["product_id"]


def test_availability_ok_after_exact_template_receipt(client, auth):
    branch_id = _branch_id(client, auth)
    phaco = _operation_type(client, auth, "PHACO")

    # Receive EXACTLY one PHACO template worth of stock.
    _receipt(client, auth, branch_id, [(sku, str(qty)) for sku, qty in _PHACO_TEMPLATE.items()])

    body = _availability(client, auth, phaco["id"], branch_id).json()
    assert body["ok"] is True
    assert len(body["items"]) == len(_PHACO_TEMPLATE)
    for item in body["items"]:
        assert item["ok"] is True, item
        assert Decimal(item["available"]) == Decimal(item["required"])

    # Boundary: available == required is exactly enough (>=, not >) — and one
    # syringe short flips both the item and the top-level verdict.
    _write_off(client, auth, branch_id, "SYR-1", Decimal("1"), "Тест: граница доступности")
    short = _availability(client, auth, phaco["id"], branch_id).json()
    assert short["ok"] is False
    flags = {i["product_name"]: i["ok"] for i in short["items"]}
    assert flags["Шприц 1 мл"] is False
    assert sum(1 for ok in flags.values() if not ok) == 1

    # Cleanup discipline: write the rest of the receipt back off so the next
    # files keep their baselines (test_operations hard-asserts KNIFE-275 == 0).
    _drain_to_zero(client, auth, branch_id, "Тест: возврат остатков к нулю после проверки доступности")
    assert _on_hand(client, auth, branch_id, "KNIFE-275") == Decimal("0")


def test_availability_unknown_type_404_and_branch_required(client, auth):
    branch_id = _branch_id(client, auth)
    missing = _availability(client, auth, str(uuid.uuid4()), branch_id)
    assert missing.status_code == 404

    phaco = _operation_type(client, auth, "PHACO")
    no_branch = client.get(f"{API}/operation-types/{phaco['id']}/availability", headers=auth)
    assert no_branch.status_code == 422  # branch_id query param is required


def test_availability_empty_template_is_trivially_ok(client, auth):
    branch_id = _branch_id(client, auth)
    phaco = _operation_type(client, auth, "PHACO")
    created = client.post(
        f"{API}/operation-types", headers=auth,
        json={"code": "AVAIL-EMPTY", "name": "Тест без расходников",
              "service_id": phaco["service_id"], "consumables": []},
    )
    assert created.status_code == 201, created.text

    body = _availability(client, auth, created.json()["id"], branch_id).json()
    # No consumables required → nothing can constrain the operation.
    assert body == {
        "ok": True,
        "items": [],
        "min_feasibility": 0,
        "status": "green",
        "bottleneck": None,
    }


def test_availability_feasibility_traffic_light(client, auth):
    """Feasibility = how many whole operations current stock supports, per line
    (feasibility_count) and overall (min_feasibility), with a 🟢/🟡/🔴 status and
    the limiting product surfaced as the bottleneck. Mirrors the FEFO guarantee
    that perform enforces — this is the advisory pre-check the planner sees."""
    branch_id = _branch_id(client, auth)
    _drain_to_zero(client, auth, branch_id, "Тест: обнуление перед проверкой запаса операций")
    phaco = _operation_type(client, auth, "PHACO")

    # Not-enough: stock everything generously EXCEPT the knife (0 in stock).
    _receipt(client, auth, branch_id, [
        ("IOL-001", "10"), ("VISC-001", "10"), ("SYR-1", "100"), ("GLOVES-ST", "100"),
    ])
    short = _availability(client, auth, phaco["id"], branch_id).json()
    by_name = {i["product_name"]: i for i in short["items"]}
    assert by_name["Нож офтальмологический 2.75 мм"]["feasibility_count"] == 0
    assert by_name["Шприц 1 мл"]["feasibility_count"] == 50  # 100 // 2
    assert short["min_feasibility"] == 0
    assert short["status"] == "red"
    assert short["bottleneck"] == "Нож офтальмологический 2.75 мм"
    assert short["ok"] is False

    # Low: exactly 3 knives → floor(3/1)=3 ops, still the limiting line.
    _receipt(client, auth, branch_id, [("KNIFE-275", "3")])
    low = _availability(client, auth, phaco["id"], branch_id).json()
    knife = next(i for i in low["items"]
                 if i["product_name"] == "Нож офтальмологический 2.75 мм")
    assert knife["feasibility_count"] == 3
    assert low["min_feasibility"] == 3  # < LOW_FEASIBILITY_THRESHOLD (5)
    assert low["status"] == "yellow"
    assert low["bottleneck"] == "Нож офтальмологический 2.75 мм"
    assert low["ok"] is True

    # Plenty: top knives up so the limiting line supports >= threshold ops.
    _receipt(client, auth, branch_id, [("KNIFE-275", "20")])  # 23 total
    plenty = _availability(client, auth, phaco["id"], branch_id).json()
    assert plenty["min_feasibility"] >= 5
    assert plenty["status"] == "green"
    assert plenty["bottleneck"] is None
    assert plenty["ok"] is True

    # Cleanup discipline: drain back to zero so later files keep KNIFE-275 == 0.
    _drain_to_zero(client, auth, branch_id, "Тест: возврат остатков к нулю после проверки запаса")
    assert _on_hand(client, auth, branch_id, "KNIFE-275") == Decimal("0")


def test_prescribe_priority_urgent_and_default_normal(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "prio")
    ivi = _operation_type(client, auth, "IVI")

    urgent = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": ivi["id"], "eye": "od", "priority": "urgent"},
    )
    assert urgent.status_code == 201, urgent.text
    assert urgent.json()["priority"] == "urgent"

    default = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": ivi["id"], "eye": "os"},
    )
    assert default.status_code == 201, default.text
    assert default.json()["priority"] == "normal"

    # Persisted, not just echoed: the visit's operation list carries it back.
    listed = client.get(f"{API}/visits/{visit['id']}/operations", headers=auth).json()
    by_id = {o["id"]: o["priority"] for o in listed}
    assert by_id[urgent.json()["id"]] == "urgent"
    assert by_id[default.json()["id"]] == "normal"

    # Anything outside normal|urgent is rejected by the schema.
    bad = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": ivi["id"], "priority": "asap"},
    )
    assert bad.status_code == 422


def test_availability_rbac_requires_operations_read(client, auth):
    branch_id = _branch_id(client, auth)
    phaco = _operation_type(client, auth, "PHACO")

    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "avail.cashier@kozshifo.uz", "full_name": "Кассир Доступности",
              "password": "Kassa!2026av", "role_names": ["Diagnost"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "avail.cashier@kozshifo.uz", "password": "Kassa!2026av"},
    ).json()["access_token"]
    cashier_auth = {"Authorization": f"Bearer {token}"}

    denied = _availability(client, cashier_auth, phaco["id"], branch_id)
    assert denied.status_code == 403
    assert "operations.read" in denied.json()["detail"]
