"""CRITICAL regression: a PARTIAL refund must NOT de-bill still-paid lines.

Before the fix, refund_payment reverted EVERY 'paid' VisitItem to 'ordered'
whenever the refund re-opened a balance — even when only part of the visit was
refunded and other lines stayed fully paid. A visit with a paid operation
(900000) + paid consultation (100000), where only the consultation payment is
refunded, would demote the OPERATION line back to 'ordered'. That let the
operation be unscheduled/cancelled/detached while its 900000 stayed collected →
the money orphaned (day-summary revenue dropped to 0 while COGS lingered).

The fix reverts lines to 'ordered' ONLY on a FULL refund (paid_amount hits 0).
A partial refund keeps paid lines 'paid' and merely surfaces the re-opened
balance. The C9a full-refund→detach flow still works (covered in
test_operation_pricing.test_refund_reverts_visit_item_so_operation_can_detach).
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal

from tests.conftest import API


def _today() -> str:
    return datetime.now().date().isoformat()


def _future() -> str:
    return (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()


def _product_id(client, auth, sku: str) -> str:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)["id"]


def _receipt(client, auth, branch, items) -> None:
    resp = client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch,
        "items": [{"product_id": _product_id(client, auth, sku), "quantity": q, "unit_cost": c}
                  for sku, q, c in items],
    })
    assert resp.status_code == 201, resp.text


def _consultation_service(client, auth) -> dict:
    """A cheap non-diagnostic service for the second billed line."""
    return client.get(f"{API}/services", headers=auth).json()["items"][0]


def test_partial_refund_keeps_still_paid_operation_paid(client, auth):
    """Operation + consultation both fully paid; refund ONLY the consultation.
    The operation must stay 'paid': its unschedule 409s, the operation payment is
    not orphaned, and day-summary still counts its revenue."""
    branch = client.post(f"{API}/branches", headers=auth,
                         json={"name": "Частичный возврат", "code": "PART-REF"}).json()["id"]
    # IVI consumes SYR-1 ×1 + GLOVES-ST ×2 → COGS 5000.
    _receipt(client, auth, branch, [("SYR-1", "10", "1000"), ("GLOVES-ST", "10", "2000")])

    svc = _consultation_service(client, auth)
    ivi = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
               if t["code"] == "IVI")
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Часть", "last_name": "Возвратов",
                                "branch_id": branch}).json()
    # Visit already carries the consultation line (100000 after we reprice it via
    # the service's own price — we just pay exactly the operation + consultation).
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch,
                              "items": [{"service_id": svc["id"], "quantity": 1}]}).json()
    consult_amount = Decimal(visit["balance"])  # the consultation line total
    assert consult_amount > 0, "need a priced consultation service"

    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"]}).json()
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": _future(), "price": "900000"}).status_code == 200

    # TWO separate payments so we can refund exactly the consultation one. Pay the
    # consultation first, then the operation → both lines flip to 'paid' once the
    # visit is fully settled.
    consult_pay = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": str(consult_amount),
        "issue_queue_ticket": False})
    assert consult_pay.status_code in (200, 201), consult_pay.text
    consult_payment_id = consult_pay.json()["payment"]["id"]

    op_pay = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": "900000", "issue_queue_ticket": False})
    assert op_pay.status_code in (200, 201), op_pay.text

    # Perform the operation → it lands in today's day-summary window (settled).
    assert client.post(f"{API}/operations/{op['id']}/perform", headers=auth).status_code == 200

    before = client.get(f"{API}/operations/day-summary", headers=auth,
                        params={"date": _today(), "branch_id": branch}).json()
    assert Decimal(before["revenue"]) == Decimal("900000")
    assert Decimal(before["cogs"]) == Decimal("5000")

    # Refund ONLY the consultation → balance re-opens by consult_amount, but the
    # operation line MUST stay 'paid'.
    refunded = client.post(f"{API}/payments/{consult_payment_id}/refund", headers=auth)
    assert refunded.status_code == 200, refunded.text

    v = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert Decimal(v["balance"]) == consult_amount  # only the consultation re-owes

    # The still-paid operation cannot be silently de-billed: unschedule 409s
    # «refund first» — the 900000 is NOT orphaned.
    blocked = client.post(f"{API}/operations/{op['id']}/unschedule", headers=auth)
    assert blocked.status_code == 409, blocked.text

    # Day-summary still counts the operation's revenue: the partial refund of the
    # consultation did not touch the operation's settlement.
    after = client.get(f"{API}/operations/day-summary", headers=auth,
                       params={"date": _today(), "branch_id": branch}).json()
    assert Decimal(after["revenue"]) == Decimal("900000")
    assert Decimal(after["cogs"]) == Decimal("5000")


def test_full_refund_across_lines_reverts_all_to_ordered(client, auth):
    """Regression guard for C9a semantics under multi-payment: when EVERY payment
    is refunded (paid_amount hits 0), all lines revert to 'ordered' and the
    operation can be detached — the full-refund unwind still works."""
    branch = client.post(f"{API}/branches", headers=auth,
                         json={"name": "Полный возврат", "code": "FULL-REF"}).json()["id"]
    svc = _consultation_service(client, auth)
    ivi = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
               if t["code"] == "IVI")
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Полный", "last_name": "Возвратов",
                                "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch,
                              "items": [{"service_id": svc["id"], "quantity": 1}]}).json()
    consult_amount = Decimal(visit["balance"])
    assert consult_amount > 0

    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"]}).json()
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": _future(), "price": "900000"}).status_code == 200

    consult_pay = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": str(consult_amount),
        "issue_queue_ticket": False})
    assert consult_pay.status_code in (200, 201), consult_pay.text
    op_pay = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": "900000", "issue_queue_ticket": False})
    assert op_pay.status_code in (200, 201), op_pay.text

    # Refund BOTH payments → paid_amount hits 0 → full unwind.
    assert client.post(f"{API}/payments/{consult_pay.json()['payment']['id']}/refund",
                       headers=auth).status_code == 200
    # After the consultation refund, balance>0 but paid_amount still 900000 → op stays paid.
    mid = client.post(f"{API}/operations/{op['id']}/unschedule", headers=auth)
    assert mid.status_code == 409, mid.text  # still paid → refund first
    assert client.post(f"{API}/payments/{op_pay.json()['payment']['id']}/refund",
                       headers=auth).status_code == 200

    # Now everything is refunded → the operation line reverted to 'ordered' → detach works.
    detached = client.post(f"{API}/operations/{op['id']}/unschedule", headers=auth)
    assert detached.status_code == 200, detached.text
    assert detached.json()["status"] == "referred"
