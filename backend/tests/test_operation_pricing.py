"""Operation cost flexibility (owner brief 2026-06-20): the price is NOT fixed at
planning — `set-price` changes it any time until the operation is financially
closed (manually via /financial-close, or automatically when the visit closes).
Repricing a PAID operation no longer forces a refund-first; the recomputed visit
balance / refund-due reconciles instead.

Self-contained: uses IVI (no perform → no stock touched), and pays with
issue_queue_ticket=False so no stray queue ticket leaks into the shared session
DB that the patient-journey spec relies on."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API

_SCHED_AT = "2026-07-01T09:00:00+00:00"


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _new_visit(client, auth, branch_id: str, suffix: str) -> dict:
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Цена", "last_name": f"Тестов-{suffix}",
              "phone": "+998900000000", "branch_id": branch_id},
    ).json()
    return client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "items": []},
    ).json()


def _ivi(client, auth) -> dict:
    types = client.get(f"{API}/operation-types", headers=auth).json()
    return next(t for t in types if t["code"] == "IVI")


def _refer(client, auth, visit_id: str, op_type_id: str) -> dict:
    return client.post(
        f"{API}/visits/{visit_id}/operations", headers=auth,
        json={"operation_type_id": op_type_id, "eye": "od"},
    ).json()


def _schedule(client, auth, op_id: str, **body):
    body.setdefault("scheduled_at", _SCHED_AT)
    return client.post(f"{API}/operations/{op_id}/schedule", headers=auth, json=body)


def _pay(client, auth, visit_id: str, amount: str) -> None:
    resp = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit_id, "amount": amount,
                             "issue_queue_ticket": False})
    assert resp.status_code in (200, 201), resp.text


def _set_price(client, auth, op_id: str, price: str, reason: str | None = None):
    body: dict = {"price": price}
    if reason is not None:
        body["reason"] = reason
    return client.post(f"{API}/operations/{op_id}/set-price", headers=auth, json=body)


def test_set_price_on_paid_operation_reconciles_without_refund_first(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "reprice")
    ivi = _ivi(client, auth)
    op = _refer(client, auth, visit["id"], ivi["id"])
    assert _schedule(client, auth, op["id"], price="1000000").status_code == 200
    _pay(client, auth, visit["id"], "1000000")  # item flips to 'paid'

    # Raise the price on a PAID op — previously 409 "refund first", now allowed.
    up = _set_price(client, auth, op["id"], "1200000", reason="доп. этап")
    assert up.status_code == 200, up.text
    body = up.json()
    assert Decimal(body["operation"]["price"]) == Decimal("1200000")
    assert Decimal(body["visit_balance"]) == Decimal("200000")  # owes the diff
    assert Decimal(body["refund_due"]) == Decimal("0")

    # Lower below what was paid → overpaid → refund_due surfaces (no auto-refund).
    down = _set_price(client, auth, op["id"], "700000")
    assert down.status_code == 200, down.text
    b2 = down.json()
    assert Decimal(b2["visit_balance"]) == Decimal("-300000")  # 700000 − 1000000 paid
    assert Decimal(b2["refund_due"]) == Decimal("300000")


def test_financial_close_freezes_price(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "freeze")
    ivi = _ivi(client, auth)
    op = _refer(client, auth, visit["id"], ivi["id"])
    assert _schedule(client, auth, op["id"], price="1000000").status_code == 200

    closed = client.post(f"{API}/operations/{op['id']}/financial-close", headers=auth)
    assert closed.status_code == 200, closed.text
    assert closed.json()["financially_closed_at"] is not None

    assert _set_price(client, auth, op["id"], "900000").status_code == 409
    assert _schedule(client, auth, op["id"], price="800000").status_code == 409  # reprice/resched
    # Idempotency: a second close is rejected.
    assert client.post(f"{API}/operations/{op['id']}/financial-close",
                       headers=auth).status_code == 409


def test_closing_visit_financially_closes_operations(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "visitclose")
    ivi = _ivi(client, auth)
    op = _refer(client, auth, visit["id"], ivi["id"])
    assert _schedule(client, auth, op["id"], price="1000000").status_code == 200
    _pay(client, auth, visit["id"], "1000000")

    assert client.post(f"{API}/visits/{visit['id']}/close", headers=auth).status_code == 200

    listed = client.get(f"{API}/visits/{visit['id']}/operations", headers=auth).json()
    assert listed[0]["financially_closed_at"] is not None
    # Frozen: the price can no longer change after the visit closed it.
    assert _set_price(client, auth, op["id"], "900000").status_code == 409


def test_set_price_on_referred_op_is_applied_at_schedule(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "quote")
    ivi = _ivi(client, auth)
    op = _refer(client, auth, visit["id"], ivi["id"])  # referred, not billed yet

    # Quote a price before scheduling — stored on the op, nothing billed yet.
    q = _set_price(client, auth, op["id"], "1234000")
    assert q.status_code == 200, q.text
    assert Decimal(q.json()["operation"]["price"]) == Decimal("1234000")
    assert Decimal(q.json()["visit_balance"]) == Decimal("0")

    # Schedule WITHOUT an explicit price → honours the quote (not catalog 1.5M).
    sched = _schedule(client, auth, op["id"])
    assert sched.status_code == 200, sched.text
    assert Decimal(sched.json()["price"]) == Decimal("1234000")
