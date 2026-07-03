"""Phase 5: end-of-day operations P&L — revenue − COGS − day expenses. Runs in a
dedicated branch so the day's totals aren't polluted by other tests' operations."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal

from tests.conftest import API


def _today() -> str:
    # day-summary windows operations by the LOCAL calendar day (local_day_bounds_utc)
    # and perform stamps performed_at = utcnow, so "today" must be the LOCAL date —
    # the UTC date lags behind between local midnight and UTC midnight.
    return datetime.now().date().isoformat()


def _future() -> str:
    """A scheduled_at that stays in the future (a fixed date would rot into the past)."""
    return (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()


def _product_id(client, auth, sku: str) -> str:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)["id"]


def _receipt(client, auth, branch, items) -> None:
    """items: [(sku, quantity, unit_cost), ...] — goods-in with a cost for COGS."""
    resp = client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch,
        "items": [{"product_id": _product_id(client, auth, sku), "quantity": q, "unit_cost": c}
                  for sku, q, c in items],
    })
    assert resp.status_code == 201, resp.text


def test_operation_day_summary_pnl(client, auth):
    branch = client.post(f"{API}/branches", headers=auth,
                         json={"name": "Дневной P&L", "code": "PNL-DAY"}).json()["id"]
    # IVI consumes SYR-1 ×1 + GLOVES-ST ×2 → COGS = 1×1000 + 2×2000 = 5000.
    _receipt(client, auth, branch, [("SYR-1", "10", "1000"), ("GLOVES-ST", "10", "2000")])

    ivi = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
               if t["code"] == "IVI")
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "ПЛ", "last_name": "Дневной", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch}).json()
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"]}).json()
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": _future(),
                             "price": "900000"}).status_code == 200
    # Cash-clinic flow: the operation is paid before it is performed, so it counts
    # as SETTLED revenue in the day's P&L.
    assert client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": "900000",
        "issue_queue_ticket": False}).status_code in (200, 201)
    # Perform now → performed_at lands in today's window.
    assert client.post(f"{API}/operations/{op['id']}/perform", headers=auth).status_code == 200

    # An operation expense for today (finance category «Операции»).
    exp = client.post(f"{API}/finance/expenses", headers=auth,
                      json={"branch_id": branch, "category": "Операции",
                            "amount": "50000", "expense_date": _today()})
    assert exp.status_code == 201, exp.text

    summary = client.get(f"{API}/operations/day-summary", headers=auth,
                         params={"date": _today(), "branch_id": branch})
    assert summary.status_code == 200, summary.text
    s = summary.json()
    assert s["operations_count"] == 1
    assert Decimal(s["revenue"]) == Decimal("900000")
    assert Decimal(s["cogs"]) == Decimal("5000")
    assert Decimal(s["expenses"]) == Decimal("50000")
    assert Decimal(s["profit"]) == Decimal("845000")  # 900000 − 5000 − 50000


def test_day_summary_refunded_operation_drops_revenue_keeps_cogs(client, auth):
    """A refunded performed operation drops out of revenue while its COGS stays
    (materials were consumed) — the P&L shows the real loss, not inflated profit."""
    branch = client.post(f"{API}/branches", headers=auth,
                         json={"name": "P&L Возврат", "code": "PNL-REF"}).json()["id"]
    _receipt(client, auth, branch, [("SYR-1", "10", "1000"), ("GLOVES-ST", "10", "2000")])
    ivi = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
               if t["code"] == "IVI")
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "ПЛ", "last_name": "Возврат", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch}).json()
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"]}).json()
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": _future(),
                             "price": "900000"}).status_code == 200
    pay = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": "900000", "issue_queue_ticket": False})
    assert pay.status_code in (200, 201), pay.text
    payment_id = pay.json()["payment"]["id"]
    assert client.post(f"{API}/operations/{op['id']}/perform", headers=auth).status_code == 200

    before = client.get(f"{API}/operations/day-summary", headers=auth,
                        params={"date": _today(), "branch_id": branch}).json()
    assert Decimal(before["revenue"]) == Decimal("900000")
    assert Decimal(before["cogs"]) == Decimal("5000")
    assert Decimal(before["profit"]) == Decimal("895000")  # 900000 − 5000

    # Refund → revenue drops, COGS (consumed materials) stays → the day shows a loss.
    assert client.post(f"{API}/payments/{payment_id}/refund", headers=auth).status_code == 200
    after = client.get(f"{API}/operations/day-summary", headers=auth,
                       params={"date": _today(), "branch_id": branch}).json()
    assert Decimal(after["revenue"]) == Decimal("0")
    assert Decimal(after["cogs"]) == Decimal("5000")     # materials still consumed
    assert after["operations_count"] == 1                # still counted as performed
    assert Decimal(after["profit"]) == Decimal("-5000")  # the real loss


def test_day_summary_excludes_non_operation_expenses(client, auth):
    """A generic expense (not «Операции») does NOT reduce the operations P&L."""
    branch = client.post(f"{API}/branches", headers=auth,
                         json={"name": "P&L Фильтр", "code": "PNL-FILT"}).json()["id"]
    client.post(f"{API}/finance/expenses", headers=auth,
                json={"branch_id": branch, "category": "Аренда",
                      "amount": "999999", "expense_date": _today()})
    s = client.get(f"{API}/operations/day-summary", headers=auth,
                   params={"date": _today(), "branch_id": branch}).json()
    assert Decimal(s["expenses"]) == Decimal("0")
    assert s["operations_count"] == 0
