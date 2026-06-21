"""Dashboard period filter (owner brief 2026-06-20): GET /dashboard/period-summary
recomputes headline metrics for any period (today/yesterday/week/month/quarter/
year/custom). Self-contained; pays with issue_queue_ticket=False to keep the
shared session DB clean."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _summary(client, auth, **params) -> dict:
    resp = client.get(f"{API}/dashboard/period-summary", headers=auth, params=params)
    assert resp.status_code == 200, resp.text
    return resp.json()


def test_period_summary_shape_and_today_revenue_delta(client, auth):
    branch = _branch_id(client, auth)
    before = Decimal(_summary(client, auth, period="today")["revenue"])

    # Generate revenue TODAY: refer + schedule an operation (bills the visit), pay it.
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Период", "last_name": "Тест",
                                "phone": "+998900000002", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch,
                              "items": []}).json()
    ivi = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
               if t["code"] == "IVI")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"], "eye": "od"}).json()
    assert client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                       json={"scheduled_at": "2026-07-01T09:00:00+00:00",
                             "price": "500000"}).status_code == 200
    assert client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": "500000",
                             "issue_queue_ticket": False}).status_code in (200, 201)

    today = _summary(client, auth, period="today")
    assert Decimal(today["revenue"]) - before == Decimal("500000")
    assert Decimal(today["profit"]) == Decimal(today["revenue"]) - Decimal(today["expenses"])
    assert today["visits"] >= 1
    # Full shape present and numeric.
    for key in ("new_patients", "visits", "operations", "diagnostics", "treatments"):
        assert isinstance(today[key], int)
    assert today["date_from"] == today["date_to"]  # «today» is a single day

    # Yesterday's window must NOT include today's payment.
    yest = _summary(client, auth, period="yesterday")
    assert Decimal(yest["revenue"]) <= before  # today's 500k not counted


def test_period_presets_resolve(client, auth):
    for period in ("today", "yesterday", "week", "month", "quarter", "year"):
        body = _summary(client, auth, period=period)
        assert body["period"] == period
        assert body["date_from"] <= body["date_to"]


def test_custom_period_window(client, auth):
    body = _summary(client, auth, period="custom",
                    date_from="2020-01-01", date_to="2020-12-31")
    assert body["date_from"] == "2020-01-01"
    assert body["date_to"] == "2020-12-31"
    # Long-past window: no clinic activity → zero metrics.
    assert Decimal(body["revenue"]) == Decimal("0")
    assert body["visits"] == 0


def test_period_validation(client, auth):
    # custom without dates → 422
    r1 = client.get(f"{API}/dashboard/period-summary", headers=auth,
                    params={"period": "custom"})
    assert r1.status_code == 422
    # custom with reversed range → 422
    r2 = client.get(f"{API}/dashboard/period-summary", headers=auth,
                    params={"period": "custom", "date_from": "2026-02-01",
                            "date_to": "2026-01-01"})
    assert r2.status_code == 422
    # unknown preset → 422
    r3 = client.get(f"{API}/dashboard/period-summary", headers=auth,
                    params={"period": "decade"})
    assert r3.status_code == 422


def test_period_summary_rbac(client, auth):
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "period.wh@kozshifo.uz", "full_name": "Тест Склад",
              "password": "Wh!2026per", "role_names": ["Warehouse"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "period.wh@kozshifo.uz", "password": "Wh!2026per"},
    ).json()["access_token"]
    denied = client.get(f"{API}/dashboard/period-summary",
                        headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
    assert "dashboard.view" in denied.json()["detail"]
