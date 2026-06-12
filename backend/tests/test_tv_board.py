"""Standalone TV board: public privacy-safe endpoint + served HTML page."""
from __future__ import annotations

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def test_tv_board_endpoint_is_public(client, auth):
    branch_id = _branch_id(client, auth)
    resp = client.get(f"{API}/queue/tv-board/{branch_id}")  # no Authorization header
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["branch_id"] == branch_id
    assert "now_serving" in body and "waiting" in body


def test_tv_board_is_privacy_safe(client, auth):
    """Board entries never leak full patient names — only initials + MRN tail."""
    branch_id = _branch_id(client, auth)
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Конфиденциал", "last_name": "Пациентов", "branch_id": branch_id},
    ).json()
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": services[0]["id"], "quantity": 1}]},
    ).json()
    client.post(f"{API}/payments", headers=auth,
                json={"visit_id": visit["id"], "amount": visit["total_amount"]})

    board = client.get(f"{API}/queue/tv-board/{branch_id}").json()
    entries = board["now_serving"] + board["waiting"]
    assert entries, "expected the new ticket on the board"
    text = str(entries)
    assert "Пациентов" not in text and "Конфиденциал" not in text
    assert any(e["patient_label"].startswith("ПК") for e in entries)


def test_tv_page_served(client, auth):
    branch_id = _branch_id(client, auth)
    resp = client.get(f"/tv/{branch_id}")  # no auth
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("text/html")
    assert "tv-board" in resp.text  # polls the public endpoint
    assert "KO'Z" in resp.text

    assert client.get("/tv/not-a-uuid").status_code == 422
