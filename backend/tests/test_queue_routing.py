"""Adressed queue routing: assign a waiting ticket to a named specialist and
have call-next honour it (mine-or-pool), while the default no-for_user_id
behaviour stays exactly as before (backward compatibility).
"""
from __future__ import annotations

from tests.conftest import API

ROOM = "Каб. Р"


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _make_doctor(client, auth, branch_id, slug) -> str:
    """Create a staff user (seeded Doctor role) -> return its id."""
    resp = client.post(
        f"{API}/users", headers=auth,
        json={
            "email": f"route.{slug}@kozshifo.uz",
            "full_name": f"Доктор {slug}",
            "password": "Route!2026",
            "role_names": ["Doctor"],
            "branch_id": branch_id,
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


def _paid_visit(client, auth, branch_id, last_name) -> dict:
    """Register patient + open visit + pay in full -> the waiting D ticket dict."""
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Маршрут", "last_name": last_name, "branch_id": branch_id},
    ).json()
    service = client.get(f"{API}/services", headers=auth).json()["items"][0]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": service["id"], "quantity": 1}]},
    ).json()
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert paid.status_code == 201, paid.text
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "track": "diagnostic"}).json()
    [mine] = [t for t in rows if t["visit_id"] == visit["id"]]
    return mine


def _park_other_waiting(client, auth, branch_id, track, keep_id):
    """Skip foreign waiting tickets so call-next deterministically claims ours."""
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "track": track}).json()
    for t in rows:
        if t["status"] == "waiting" and t["id"] != keep_id:
            assert client.post(f"{API}/queue/{t['id']}/skip", headers=auth).status_code == 200


def _call_next(client, auth, branch_id, track, for_user_id=None):
    body = {"branch_id": branch_id, "room": ROOM, "track": track}
    if for_user_id is not None:
        body["for_user_id"] = for_user_id
    return client.post(f"{API}/queue/call-next", headers=auth, json=body)


def test_assign_then_call_next_for_user_honours_routing(client, auth):
    branch_id = _branch_id(client, auth)
    doc_a = _make_doctor(client, auth, branch_id, "alfa")
    doc_b = _make_doctor(client, auth, branch_id, "beta")
    ticket = _paid_visit(client, auth, branch_id, "Адресный")
    assert ticket["assigned_user_id"] is None  # born in the open pool

    # Route it to doctor A.
    assigned = client.post(f"{API}/queue/{ticket['id']}/assign", headers=auth,
                           json={"assigned_user_id": doc_a})
    assert assigned.status_code == 200, assigned.text
    assert assigned.json()["assigned_user_id"] == doc_a

    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=ticket["id"])

    # Doctor B calls for himself: the ticket is routed to A (not B, not pool) -> 404.
    resp_b = _call_next(client, auth, branch_id, "diagnostic", for_user_id=doc_b)
    assert resp_b.status_code == 404, resp_b.text
    # The ticket was not touched.
    still = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch_id, "track": "diagnostic"}).json()
    mine = next(t for t in still if t["id"] == ticket["id"])
    assert mine["status"] == "waiting"

    # Doctor A calls for himself: claims his routed ticket.
    resp_a = _call_next(client, auth, branch_id, "diagnostic", for_user_id=doc_a)
    assert resp_a.status_code == 200, resp_a.text
    assert resp_a.json()["id"] == ticket["id"]
    assert resp_a.json()["status"] == "called"

    client.post(f"{API}/queue/{ticket['id']}/skip", headers=auth)  # cleanup


def test_for_user_call_next_falls_back_to_open_pool(client, auth):
    branch_id = _branch_id(client, auth)
    doc_b = _make_doctor(client, auth, branch_id, "gamma")
    ticket = _paid_visit(client, auth, branch_id, "Пуловый")  # unassigned

    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=ticket["id"])

    # Even calling "for me", an UNASSIGNED ticket is still claimable (pool fallback).
    resp = _call_next(client, auth, branch_id, "diagnostic", for_user_id=doc_b)
    assert resp.status_code == 200, resp.text
    assert resp.json()["id"] == ticket["id"]

    client.post(f"{API}/queue/{ticket['id']}/skip", headers=auth)  # cleanup


def test_default_call_next_ignores_assignment_backward_compatible(client, auth):
    """An old client that sends no for_user_id must keep pulling ANY waiting
    ticket — assignment must never silently hide work from the legacy flow."""
    branch_id = _branch_id(client, auth)
    doc_a = _make_doctor(client, auth, branch_id, "delta")
    ticket = _paid_visit(client, auth, branch_id, "Совместимый")

    client.post(f"{API}/queue/{ticket['id']}/assign", headers=auth,
                json={"assigned_user_id": doc_a})
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=ticket["id"])

    # No for_user_id -> legacy behaviour: claims the ticket regardless of routing.
    resp = _call_next(client, auth, branch_id, "diagnostic")
    assert resp.status_code == 200, resp.text
    assert resp.json()["id"] == ticket["id"]

    client.post(f"{API}/queue/{ticket['id']}/skip", headers=auth)  # cleanup


def test_assign_null_clears_routing(client, auth):
    branch_id = _branch_id(client, auth)
    doc_a = _make_doctor(client, auth, branch_id, "epsilon")
    ticket = _paid_visit(client, auth, branch_id, "Сброс")

    client.post(f"{API}/queue/{ticket['id']}/assign", headers=auth,
                json={"assigned_user_id": doc_a})
    cleared = client.post(f"{API}/queue/{ticket['id']}/assign", headers=auth,
                          json={"assigned_user_id": None})
    assert cleared.status_code == 200, cleared.text
    assert cleared.json()["assigned_user_id"] is None

    client.post(f"{API}/queue/{ticket['id']}/skip", headers=auth)  # cleanup


def test_specialists_endpoint_lists_branch_staff(client, auth):
    branch_id = _branch_id(client, auth)
    doc_id = _make_doctor(client, auth, branch_id, "eta")

    resp = client.get(f"{API}/queue/specialists", headers=auth,
                      params={"branch_id": branch_id})
    assert resp.status_code == 200, resp.text
    rows = resp.json()
    mine = next(r for r in rows if r["id"] == doc_id)
    assert mine["full_name"] == "Доктор eta"
    assert "Doctor" in mine["roles"]


def test_tv_board_exposes_assigned_specialist(client, auth):
    branch_id = _branch_id(client, auth)
    doc_id = _make_doctor(client, auth, branch_id, "theta")
    ticket = _paid_visit(client, auth, branch_id, "Таблонаправ")

    client.post(f"{API}/queue/{ticket['id']}/assign", headers=auth,
                json={"assigned_user_id": doc_id})

    board = client.get(f"{API}/queue/tv-board/{branch_id}").json()  # public
    entry = next(e for e in board["diagnostic"]["waiting"]
                 if e["ticket_number"] == ticket["ticket_number"])
    assert entry["assigned"] == "Доктор theta"

    client.post(f"{API}/queue/{ticket['id']}/skip", headers=auth)  # cleanup


def test_assign_guards(client, auth):
    import uuid

    branch_id = _branch_id(client, auth)
    ticket = _paid_visit(client, auth, branch_id, "Гарды")

    # Unknown ticket -> 404.
    assert client.post(f"{API}/queue/{uuid.uuid4()}/assign", headers=auth,
                       json={"assigned_user_id": None}).status_code == 404
    # Unknown assignee -> 404.
    assert client.post(f"{API}/queue/{ticket['id']}/assign", headers=auth,
                       json={"assigned_user_id": str(uuid.uuid4())}).status_code == 404

    # A called (non-waiting) ticket cannot be routed -> 409.
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=ticket["id"])
    called = _call_next(client, auth, branch_id, "diagnostic")
    assert called.status_code == 200, called.text
    doc = _make_doctor(client, auth, branch_id, "zeta")
    conflict = client.post(f"{API}/queue/{ticket['id']}/assign", headers=auth,
                           json={"assigned_user_id": doc})
    assert conflict.status_code == 409, conflict.text

    client.post(f"{API}/queue/{ticket['id']}/skip", headers=auth)  # cleanup
