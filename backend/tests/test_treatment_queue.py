"""Treatment queue track (Л-…): reception issues a treatment ticket independent
of payment; it shows on the TV board's «Лечение» section; the call/serve/done
lifecycle works and never auto-advances to the doctor track or touches the flow."""
from __future__ import annotations

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _patient(client, auth, last_name) -> dict:
    return client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Лечение", "last_name": last_name, "branch_id": _branch(client, auth)},
    ).json()


def _park_waiting_treatment(client, auth, branch, keep_id) -> None:
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch, "track": "treatment"}).json()
    for t in rows:
        if t["status"] == "waiting" and t["id"] != keep_id:
            client.post(f"{API}/queue/{t['id']}/skip", headers=auth)


def test_issue_treatment_ticket_tv_board_and_lifecycle(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Курс")

    # No payment needed — reception just issues the ticket.
    resp = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                       json={"patient_id": patient["id"], "branch_id": branch,
                             "room": "Процедурная"})
    assert resp.status_code == 201, resp.text
    t = resp.json()
    assert t["track"] == "treatment"
    assert t["ticket_number"].startswith("Л-")
    assert t["status"] == "waiting"
    assert t["room"] == "Процедурная"

    # Appears on the public TV board's «Лечение» section.
    board = client.get(f"{API}/queue/tv-board/{branch}").json()
    assert "treatment" in board
    waiting_nums = [e["ticket_number"] for e in board["treatment"]["waiting"]]
    assert t["ticket_number"] in waiting_nums

    # Full call/serve/done lifecycle.
    assert client.post(f"{API}/queue/{t['id']}/call", headers=auth,
                       json={"room": "Процедурная"}).status_code == 200
    assert client.post(f"{API}/queue/{t['id']}/serve", headers=auth).status_code == 200
    assert client.post(f"{API}/queue/{t['id']}/done", headers=auth).status_code == 200

    # Treatment is terminal: completing it never spawns a doctor ticket.
    doctor = client.get(f"{API}/queue", headers=auth,
                        params={"branch_id": branch, "track": "doctor", "active_only": False}).json()
    assert all(d["patient_id"] != patient["id"] for d in doctor)


def test_call_next_pulls_treatment_track(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Вызов")
    t = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                    json={"patient_id": patient["id"], "branch_id": branch}).json()
    _park_waiting_treatment(client, auth, branch, keep_id=t["id"])

    got = client.post(f"{API}/queue/call-next", headers=auth,
                      json={"branch_id": branch, "track": "treatment", "room": "Каб. Л"})
    assert got.status_code == 200, got.text
    assert got.json()["id"] == t["id"]
    assert got.json()["track"] == "treatment"

    client.post(f"{API}/queue/{t['id']}/skip", headers=auth)  # cleanup


def test_treatment_ticket_rejects_foreign_visit(client, auth):
    branch = _branch(client, auth)
    a = _patient(client, auth, "ПацА")
    b = _patient(client, auth, "ПацБ")
    visit_b = client.post(f"{API}/visits", headers=auth,
                          json={"patient_id": b["id"], "branch_id": branch}).json()
    resp = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                       json={"patient_id": a["id"], "branch_id": branch,
                             "visit_id": visit_b["id"]})
    assert resp.status_code == 422
    assert "does not belong" in resp.json()["detail"]


def test_treatment_only_visit_auto_completes_when_last_ticket_done(client, auth):
    """A treatment-only visit (Л-ticket, no doctor/diagnostic) must reach
    flow_status='completed' once its last treatment ticket is done — otherwise it
    lingers in its pre-treatment flow_status forever (the orphaned-open-record bug)."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Авто")
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch}).json()
    assert visit["flow_status"] != "completed"

    t = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                    json={"patient_id": patient["id"], "branch_id": branch,
                          "visit_id": visit["id"], "room": "Процедурная"}).json()
    # While the treatment ticket is still active the visit must NOT be completed.
    mid = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert mid["flow_status"] != "completed"

    client.post(f"{API}/queue/{t['id']}/call", headers=auth, json={"room": "Процедурная"})
    client.post(f"{API}/queue/{t['id']}/serve", headers=auth)
    assert client.post(f"{API}/queue/{t['id']}/done", headers=auth).status_code == 200

    # Last treatment ticket done + nothing else pending → lifecycle completes.
    after = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert after["flow_status"] == "completed", after
