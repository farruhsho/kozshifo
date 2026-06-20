"""Notifications: low-stock event fires post-commit, 24h anti-spam, RBAC."""
from __future__ import annotations

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _low_stock_for(client, auth, product_id: str) -> list[dict]:
    rows = client.get(
        f"{API}/notifications", headers=auth, params={"event": "low_stock", "limit": 200}
    ).json()
    return [n for n in rows if n["ref_id"] == product_id]


def test_low_stock_notification_fires_once_per_24h(client, auth):
    branch_id = _branch_id(client, auth)
    created = client.post(
        f"{API}/inventory/products", headers=auth,
        json={"sku": "NOTIF-1", "name": "Тест-уведомление", "unit": "шт", "min_stock": "5"},
    )
    assert created.status_code == 201, created.text
    product = created.json()

    # Receive 6 (> min_stock 5): nothing to notify about yet.
    receipt = client.post(
        f"{API}/inventory/receipts", headers=auth,
        json={"branch_id": branch_id,
              "items": [{"product_id": product["id"], "quantity": "6", "unit_cost": "100"}]},
    )
    assert receipt.status_code == 201, receipt.text
    assert _low_stock_for(client, auth, product["id"]) == []

    # Write off 2 -> on_hand 4 <= 5: a low_stock notification must appear.
    off = client.post(
        f"{API}/inventory/write-off", headers=auth,
        json={"product_id": product["id"], "branch_id": branch_id,
              "quantity": "2", "reason": "тест уведомлений"},
    )
    assert off.status_code == 200, off.text

    mine = _low_stock_for(client, auth, product["id"])
    assert len(mine) == 1, mine
    note = mine[0]
    assert note["channel"] == "log"
    assert note["status"] == "sent"
    assert note["error"] is None
    assert note["event"] == "low_stock"
    assert note["ref_type"] == "product"
    assert note["branch_id"] == branch_id
    assert "Тест-уведомление" in note["title"]
    assert "4" in note["body"] and "5" in note["body"]
    # No Telegram configured in tests -> only the log row, no telegram row.
    assert all(n["channel"] == "log" for n in mine)

    # Still low after another write-off -> anti-spam: STILL exactly one row.
    off2 = client.post(
        f"{API}/inventory/write-off", headers=auth,
        json={"product_id": product["id"], "branch_id": branch_id,
              "quantity": "1", "reason": "тест анти-спама"},
    )
    assert off2.status_code == 200, off2.text
    assert len(_low_stock_for(client, auth, product["id"])) == 1


def test_event_filter_and_limit(client, auth):
    resp = client.get(f"{API}/notifications", headers=auth,
                      params={"event": "no_such_event"})
    assert resp.status_code == 200
    assert resp.json() == []

    too_big = client.get(f"{API}/notifications", headers=auth, params={"limit": 500})
    assert too_big.status_code == 422  # limit le 200


def test_notifications_rbac(client, auth):
    def login(email: str, password: str, role: str) -> dict[str, str]:
        created = client.post(
            f"{API}/users", headers=auth,
            json={"email": email, "full_name": f"Тест {role}",
                  "password": password, "role_names": [role]},
        )
        assert created.status_code == 201, created.text
        token = client.post(
            f"{API}/auth/login", data={"username": email, "password": password}
        ).json()["access_token"]
        return {"Authorization": f"Bearer {token}"}

    # Doctor has no notifications.read -> 403.
    doctor = login("notif.doctor@kozshifo.uz", "Doc!2026notif", "Doctor")
    denied = client.get(f"{API}/notifications", headers=doctor)
    assert denied.status_code == 403
    assert "notifications.read" in denied.json()["detail"]

    # Warehouse role includes notifications.read -> 200.
    warehouse = login("notif.wh@kozshifo.uz", "Wh!2026notif", "Warehouse")
    allowed = client.get(f"{API}/notifications", headers=warehouse)
    assert allowed.status_code == 200, allowed.text
    assert isinstance(allowed.json(), list)


def test_active_notifications_is_live_and_matches_insights(client, auth):
    """GET /notifications/active is the LIVE, self-resolving problem set — the
    same compute_insights source of truth as the dashboard attention panel, so a
    notification exists only while its problem exists (computed on read)."""
    active = client.get(f"{API}/notifications/active", headers=auth)
    assert active.status_code == 200, active.text
    insights = client.get(f"{API}/dashboard/insights", headers=auth)
    assert insights.status_code == 200, insights.text
    # Both surfaces report the SAME set of live problem codes.
    assert {n["code"] for n in active.json()} == {i["code"] for i in insights.json()}
    for n in active.json():
        assert {"code", "severity", "title", "detail"} <= set(n)


def test_active_notifications_rbac(client, auth):
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "active.doctor@kozshifo.uz", "full_name": "Врач Актив",
              "password": "Doc!2026actv", "role_names": ["Doctor"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login",
        data={"username": "active.doctor@kozshifo.uz", "password": "Doc!2026actv"},
    ).json()["access_token"]
    doctor = {"Authorization": f"Bearer {token}"}
    denied = client.get(f"{API}/notifications/active", headers=doctor)
    assert denied.status_code == 403
    assert "notifications.read" in denied.json()["detail"]


def test_notification_title_truncated_to_column_size(client, auth):
    """255-char product names must degrade to a truncated title, not a lost row."""
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    long_name = "Т" * 250
    product = client.post(f"{API}/inventory/products", headers=auth,
                          json={"sku": "LONG-NAME-1", "name": long_name,
                                "unit": "шт", "min_stock": "5"}).json()
    client.post(f"{API}/inventory/receipts", headers=auth, json={
        "branch_id": branch_id,
        "items": [{"product_id": product["id"], "quantity": "6", "unit_cost": "1"}]})
    client.post(f"{API}/inventory/write-off", headers=auth, json={
        "product_id": product["id"], "branch_id": branch_id,
        "quantity": "2", "reason": "тест"})

    notes = client.get(f"{API}/notifications", headers=auth,
                       params={"event": "low_stock", "limit": 200}).json()
    row = next(n for n in notes if n["ref_id"] == product["id"])
    assert len(row["title"]) <= 255
    assert row["title"].startswith("Дефицит: ")
