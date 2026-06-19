"""Приём (doctor worklist, TZ Modul 5) backend contract.

The doctor's «Приём сегодня» is driven by the live V-track queue, so two things
must hold: the Doctor role can act on the queue (call next / finish → cashier,
TZ §7.1.6), and the authenticated queue payload carries the patient's name so
the worklist can render walk-in patients who have no calendar appointment.
"""
from __future__ import annotations

from app.core.permissions import ROLE_TEMPLATES
from tests.conftest import API


def test_doctor_role_can_manage_queue():
    """TZ §3.3/§7.1.6: the doctor calls the next patient and presses «Yakunlandi».

    Both require queue.manage on the Doctor role (call-next + done are guarded by
    it). Without it walk-in patients auto-queued after diagnostics could never be
    served from Приём.
    """
    doctor = ROLE_TEMPLATES["Doctor"]
    assert "queue.manage" in doctor
    assert "queue.read" in doctor
    assert "exams.write" in doctor


def test_queue_payload_exposes_patient_name(client, auth):
    """The staff-facing /queue list resolves the patient's full name + MRN — the
    worklist needs them; the public TV board keeps its own privacy-safe label.
    """
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Имя", "last_name": "Приёмов", "branch_id": branch_id},
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
                      params={"branch_id": branch_id, "active_only": True}).json()
    mine = [t for t in rows if t["visit_id"] == visit["id"]]
    assert mine, "the paid visit must have a live queue ticket"
    ticket = mine[0]
    assert ticket["patient_name"] == patient["full_name"]
    assert ticket["patient_mrn"] == patient["mrn"]

    # cleanup: park it so later tests' call-next is unaffected
    client.post(f"{API}/queue/{ticket['id']}/skip", headers=auth)


def _park_waiting(client, auth, branch_id, track, keep_id=None):
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "track": track}).json()
    for t in rows:
        if t["status"] == "waiting" and t["id"] != keep_id:
            client.post(f"{API}/queue/{t['id']}/skip", headers=auth)


def test_served_today_counts_completed_doctor_tickets(client, auth):
    """«Принято сегодня» on the worklist = today's done doctor V-tickets.

    Drive one patient through diagnostics → auto V-ticket → doctor done and
    assert the served-today count goes up by exactly one.
    """
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]

    def served() -> int:
        return client.get(f"{API}/queue/served-today", headers=auth,
                          params={"branch_id": branch_id, "track": "doctor"}).json()["count"]

    before = served()

    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Поток", "last_name": "Завершённый", "branch_id": branch_id},
    ).json()
    service = client.get(f"{API}/services", headers=auth).json()["items"][0]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": service["id"], "quantity": 1}]},
    ).json()
    client.post(f"{API}/payments", headers=auth,
                json={"visit_id": visit["id"], "amount": visit["balance"]})

    # diagnostics: claim the D ticket and finish it -> auto V ticket appears
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "active_only": False}).json()
    d_ticket = next(t for t in rows
                    if t["visit_id"] == visit["id"] and t["track"] == "diagnostic")
    _park_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    called = client.post(f"{API}/queue/call-next", headers=auth,
                         json={"branch_id": branch_id, "room": "Д1", "track": "diagnostic"}).json()
    assert called["id"] == d_ticket["id"]
    assert client.post(f"{API}/queue/{called['id']}/done", headers=auth).status_code == 200

    # doctor: claim the auto V ticket and finish the appointment
    v_ticket = next(t for t in client.get(
        f"{API}/queue", headers=auth,
        params={"branch_id": branch_id, "active_only": False}).json()
        if t["visit_id"] == visit["id"] and t["track"] == "doctor")
    _park_waiting(client, auth, branch_id, "doctor", keep_id=v_ticket["id"])
    called_v = client.post(f"{API}/queue/call-next", headers=auth,
                           json={"branch_id": branch_id, "room": "В1", "track": "doctor"}).json()
    assert called_v["id"] == v_ticket["id"]
    assert client.post(f"{API}/queue/{called_v['id']}/done", headers=auth).status_code == 200

    assert served() == before + 1


def _doctor_auth(client) -> dict[str, str]:
    """Log in as the seeded demo doctor (dev-only account)."""
    resp = client.post(f"{API}/auth/login",
                       data={"username": "vrach@kozshifo.uz", "password": "Vrach!2026"})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


def test_doctor_account_can_call_and_finish_from_worklist(client, auth):
    """End-to-end RBAC proof: the actual seeded Doctor login (not the director)
    calls the next V-ticket and finishes it — the runtime grant behind Приём.
    """
    doc = _doctor_auth(client)
    me = client.get(f"{API}/auth/me", headers=doc).json()
    assert "queue.manage" in me["permissions"]  # reconciled on startup seed

    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    # Director sets up the patient through diagnostics -> auto V-ticket.
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Врачебный", "last_name": "Приём", "branch_id": branch_id},
    ).json()
    service = client.get(f"{API}/services", headers=auth).json()["items"][0]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": service["id"], "quantity": 1}]},
    ).json()
    client.post(f"{API}/payments", headers=auth,
                json={"visit_id": visit["id"], "amount": visit["balance"]})
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "active_only": False}).json()
    d_ticket = next(t for t in rows
                    if t["visit_id"] == visit["id"] and t["track"] == "diagnostic")
    _park_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    called = client.post(f"{API}/queue/call-next", headers=auth,
                         json={"branch_id": branch_id, "room": "Д1", "track": "diagnostic"}).json()
    assert client.post(f"{API}/queue/{called['id']}/done", headers=auth).status_code == 200
    v_ticket = next(t for t in client.get(
        f"{API}/queue", headers=auth,
        params={"branch_id": branch_id, "active_only": False}).json()
        if t["visit_id"] == visit["id"] and t["track"] == "doctor")

    # The DOCTOR (not director) now drives the queue — this is the TZ behaviour.
    _park_waiting(client, doc, branch_id, "doctor", keep_id=v_ticket["id"])
    called_v = client.post(f"{API}/queue/call-next", headers=doc,
                           json={"branch_id": branch_id, "room": "В1", "track": "doctor"})
    assert called_v.status_code == 200, called_v.text
    assert called_v.json()["id"] == v_ticket["id"]
    # The queue payload the doctor's worklist consumes carries the patient name.
    assert called_v.json()["patient_name"] == patient["full_name"]
    finished = client.post(f"{API}/queue/{v_ticket['id']}/done", headers=doc)
    assert finished.status_code == 200, finished.text

    # «Yakunlandi» handed the visit on: the flow left the doctor stage.
    after = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert after["flow_status"] in ("completed", "follow_up")
