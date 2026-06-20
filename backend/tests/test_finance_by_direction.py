"""Phase-5b finance panel: revenue is bucketed by clinic direction
(приём / диагностика / лечение / операции) over a period."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def test_finance_by_direction_buckets_revenue(client, auth):
    branch = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    cons = next(s for s in services if s["code"] == "CONS")   # → приём
    arm = next(s for s in services if s["code"] == "ARM")     # is_diagnostic → диагностика
    patient = client.post(f"{API}/patients", headers=auth, json={
        "first_name": "Фин", "last_name": "Направленский", "branch_id": branch,
    }).json()
    visit = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": patient["id"], "branch_id": branch,
        "items": [{"service_id": cons["id"], "quantity": 1},
                  {"service_id": arm["id"], "quantity": 1}],
    }).json()
    total = Decimal(visit["total_amount"])
    paid = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": str(total), "method": "cash",
        "referral_intent": "hold",
    })
    assert paid.status_code == 201, paid.text

    rep = client.get(f"{API}/dashboard/finance-by-direction", headers=auth,
                     params={"period": "month"}).json()
    rows = {r["direction"]: r for r in rep["rows"]}
    assert set(rows) == {"priem", "diagnostika", "lechenie", "operatsii"}
    assert Decimal(rows["priem"]["revenue"]) >= Decimal(cons["price"])
    assert Decimal(rows["diagnostika"]["revenue"]) >= Decimal(arm["price"])
    # profit = revenue − expense per row.
    for r in rep["rows"]:
        assert Decimal(r["profit"]) == Decimal(r["revenue"]) - Decimal(r["expense"])
    assert Decimal(rep["total_revenue"]) >= total


def test_finance_by_direction_period_validation(client, auth):
    bad = client.get(f"{API}/dashboard/finance-by-direction", headers=auth,
                     params={"period": "decade"})
    assert bad.status_code == 422
