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
