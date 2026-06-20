"""Phase-5 smart notifications: insights are clickable (carry a director-route)
and the new detectors fire (here: a held «Ожидает назначения» visit raises
missing_primary_doctor)."""
from __future__ import annotations

from tests.conftest import API


def test_held_visit_raises_missing_doctor_insight_with_route(client, auth):
    branch = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    consult = next(s for s in services if s["code"] == "CONS")
    patient = client.post(f"{API}/patients", headers=auth, json={
        "first_name": "Холд", "last_name": "Тестов", "branch_id": branch,
    }).json()
    visit = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": patient["id"], "branch_id": branch,
        "items": [{"service_id": consult["id"], "quantity": 1}],
    }).json()
    client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": str(consult["price"]),
        "method": "cash", "referral_intent": "hold",
    })

    insights = client.get(f"{API}/dashboard/insights", headers=auth).json()
    codes = {i["code"] for i in insights}
    assert "missing_primary_doctor" in codes
    # Every fired insight is clickable — carries a deep-link route.
    assert all(i.get("route") for i in insights), insights
    mp = next(i for i in insights if i["code"] == "missing_primary_doctor")
    assert mp["route"] == "/patients"
