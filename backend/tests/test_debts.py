"""Debt management (owner brief 2026-06-20). Debt is derived from open visit
balances; partial repayment reuses /payments and feeds the payment history.
Self-contained; pays with issue_queue_ticket=False to keep the shared DB clean."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _owing_visit(client, auth, branch: str, suffix: str, price: str) -> dict:
    """A patient + visit billed `price` via a scheduled operation (unpaid)."""
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Долг", "last_name": f"Тестов-{suffix}",
                                "phone": "+998900000004", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch,
                              "items": []}).json()
    ivi = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
               if t["code"] == "IVI")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"], "eye": "od"}).json()
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": "2026-07-01T09:00:00+00:00",
                             "price": price}).status_code == 200
    return {"patient_id": patient["id"], "visit_id": visit["id"]}


def _pay(client, auth, visit_id: str, amount: str, note: str | None = None) -> None:
    body = {"visit_id": visit_id, "amount": amount, "issue_queue_ticket": False}
    if note is not None:
        body["note"] = note
    assert client.post(f"{API}/payments", headers=auth, json=body).status_code in (200, 201)


def _debtors(client, auth, **params) -> list[dict]:
    resp = client.get(f"{API}/debts", headers=auth, params=params)
    assert resp.status_code == 200, resp.text
    return resp.json()


def test_debtor_appears_with_partial_payment_and_clears_when_paid(client, auth):
    branch = _branch_id(client, auth)
    d = _owing_visit(client, auth, branch, "partial", "1000000")
    pid, vid = d["patient_id"], d["visit_id"]

    # Partial repayment → still owes 600000, and it shows in the debtors list.
    _pay(client, auth, vid, "400000", note="первый взнос")
    row = next((r for r in _debtors(client, auth) if r["patient_id"] == pid), None)
    assert row is not None, "debtor must appear after a partial payment"
    assert Decimal(row["total_debt"]) == Decimal("600000")
    assert row["visit_count"] >= 1
    assert row["oldest_debt_at"]
    assert row["last_payment_at"] is not None

    # Detail: owing visit (remaining + services = причина) + payment history.
    detail = client.get(f"{API}/debts/patient/{pid}", headers=auth).json()
    assert Decimal(detail["total_debt"]) == Decimal("600000")
    owing = next(v for v in detail["visits"] if v["visit_id"] == vid)
    assert Decimal(owing["remaining"]) == Decimal("600000")
    assert owing["services"] and owing["services"] != "—"
    first = next(p for p in detail["payments"] if Decimal(p["amount"]) == Decimal("400000"))
    assert first["note"] == "первый взнос"
    assert first["cashier_name"]  # кассир записан
    assert first["status"] == "completed"

    # Pay the rest → the patient drops off the debtors list.
    _pay(client, auth, vid, "600000")
    assert all(r["patient_id"] != pid for r in _debtors(client, auth))


def test_debts_rbac(client, auth):
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "debts.wh@kozshifo.uz", "full_name": "Склад Долги",
              "password": "Wh!2026debt", "role_names": ["Warehouse"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "debts.wh@kozshifo.uz", "password": "Wh!2026debt"},
    ).json()["access_token"]
    denied = client.get(f"{API}/debts", headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
    assert "debts.read" in denied.json()["detail"]
