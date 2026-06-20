"""Self-improvement insights: the owner's morning attention list.

Covers: baseline rules fire over the seeded data (the five zero-stock seeded
SKUs make low_stock critical), the stale-open-visit rule (visit backdated >24h
by direct DB tweak), the auto-notification for critical insights with its 24h
debounce, and RBAC (dashboard.view required).
"""
from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone

from tests.conftest import API

_SEVERITY_RANK = {"critical": 0, "warning": 1, "info": 2}


def _insights(client, auth) -> list[dict]:
    resp = client.get(f"{API}/dashboard/insights", headers=auth)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert isinstance(body, list)
    return body


def _by_code(insights: list[dict], code: str) -> dict | None:
    return next((i for i in insights if i["code"] == code), None)


def _notification_rows(client, auth, event: str) -> list[dict]:
    return client.get(
        f"{API}/notifications", headers=auth, params={"event": event, "limit": 200}
    ).json()


def test_baseline_low_stock_insight_fires(client, auth):
    insights = _insights(client, auth)

    # The five seeded warehouse SKUs start at zero stock -> low_stock critical.
    low = _by_code(insights, "low_stock")
    assert low is not None, insights
    assert low["severity"] == "critical"
    assert int(low["value"]) >= 5
    # Detail lists product names (up to 5) — must not be an empty placeholder.
    assert low["detail"]
    assert "," in low["detail"] or "ещё" in low["detail"]

    # Every insight is well-formed and the list is ordered critical -> info.
    for item in insights:
        assert item["severity"] in _SEVERITY_RANK
        assert item["code"] and item["title"] and item["detail"]
    ranks = [_SEVERITY_RANK[i["severity"]] for i in insights]
    assert ranks == sorted(ranks), insights


def test_critical_insight_notifies_once_per_24h(client, auth):
    _insights(client, auth)  # ensures the critical low_stock insight computed

    rows = _notification_rows(client, auth, "insight_low_stock")
    assert len(rows) == 1, rows
    note = rows[0]
    assert note["channel"] == "log"
    assert note["status"] == "sent"
    assert note["title"]
    assert note["body"]
    assert note["branch_id"] is None

    # Debounce: a second insights GET within 24h must NOT duplicate the row.
    _insights(client, auth)
    assert len(_notification_rows(client, auth, "insight_low_stock")) == 1


def test_stale_open_visit_insight(client, auth):
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    baseline = _by_code(_insights(client, auth), "stale_open_visits")
    before = int(baseline["value"]) if baseline else 0

    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Зависший", "last_name": "Визит",
              "phone": "+998900000077", "branch_id": branch_id},
    )
    assert patient.status_code == 201, patient.text
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient.json()["id"], "branch_id": branch_id, "items": []},
    )
    assert visit.status_code == 201, visit.text

    # Fresh open visit (<24h) must not count as stale yet.
    mid = _by_code(_insights(client, auth), "stale_open_visits")
    assert (int(mid["value"]) if mid else 0) == before

    # Backdate it >24h by direct DB tweak — no API can (and should) do this.
    from app.core.database import SessionLocal
    from app.models.visit import Visit

    db = SessionLocal()
    try:
        row = db.get(Visit, uuid.UUID(visit.json()["id"]))
        row.opened_at = datetime.now(timezone.utc) - timedelta(hours=30)
        db.commit()
    finally:
        db.close()

    stale = _by_code(_insights(client, auth), "stale_open_visits")
    assert stale is not None
    assert stale["severity"] == "warning"
    assert int(stale["value"]) == before + 1
    assert "зависли" in stale["detail"]


def test_insights_rbac(client, auth):
    # Doctor role has no dashboard.view -> 403.
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "insights.wh@kozshifo.uz", "full_name": "Тест Врач",
              "password": "Wh!2026ins", "role_names": ["Doctor"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "insights.wh@kozshifo.uz", "password": "Wh!2026ins"},
    ).json()["access_token"]

    denied = client.get(f"{API}/dashboard/insights",
                        headers={"Authorization": f"Bearer {token}"})
    assert denied.status_code == 403
    assert "dashboard.view" in denied.json()["detail"]
