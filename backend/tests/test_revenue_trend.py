"""Phase 6: dashboard revenue-trend — daily completed-payment revenue for the
dashboard line chart."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def test_revenue_trend_shape(client, auth):
    r = client.get(f"{API}/dashboard/revenue-trend", headers=auth, params={"days": 7})
    assert r.status_code == 200, r.text
    points = r.json()["points"]
    assert len(points) == 7
    dates = [p["date"] for p in points]
    assert dates == sorted(dates)           # ascending
    assert len(set(dates)) == 7             # consecutive distinct days
    for p in points:                        # every revenue parses as a decimal
        assert Decimal(p["revenue"]) >= Decimal("0")


def test_revenue_trend_requires_dashboard_view(client, auth):
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "trend.reception@kozshifo.uz", "full_name": "Тренд Врач",
              "password": "Passw0rd!", "role_names": ["Doctor"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "trend.reception@kozshifo.uz", "password": "Passw0rd!"},
    ).json()["access_token"]
    denied = client.get(f"{API}/dashboard/revenue-trend",
                        headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
