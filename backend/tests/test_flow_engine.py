"""Smart Workflow Engine: Visit.flow_status advances ITSELF from real events
(payment, queue call/done, doctor prescriptions, close/cancel) — there is
deliberately no endpoint to write it.

Runs in a dedicated branch (queue counters and stock are per-branch) so the
shared session DB stays clean for the other files; its name sorts after the
seeded «Главный филиал», keeping everyone's `branches[0]` stable.
"""
from __future__ import annotations

from tests.conftest import API

ROOM = "Каб. Ф"


def _flow_branch(client, auth) -> str:
    """Get-or-create the dedicated flow-test branch."""
    for b in client.get(f"{API}/branches", headers=auth).json():
        if b["code"] == "FLW":
            return b["id"]
    created = client.post(f"{API}/branches", headers=auth,
                          json={"name": "Филиал Поток-Тест", "code": "FLW"})
    assert created.status_code == 201, created.text
    return created.json()["id"]


def _register_visit(client, auth, branch_id, last_name) -> dict:
    """Register patient + open a visit with one billed service."""
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Поток", "last_name": last_name, "branch_id": branch_id},
    ).json()
    service = client.get(f"{API}/services", headers=auth).json()["items"][0]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": service["id"], "quantity": 1}]},
    ).json()
    return visit


def _pay_in_full(client, auth, visit) -> str:
    result = client.post(f"{API}/payments", headers=auth,
                         json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert result.status_code == 201, result.text
    return result.json()["queue_ticket_number"]


def _flow(client, auth, visit_id) -> str:
    resp = client.get(f"{API}/visits/{visit_id}", headers=auth)
    assert resp.status_code == 200, resp.text
    return resp.json()["flow_status"]


def _visit_tickets(client, auth, branch_id, visit_id, *, active_only=False):
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "active_only": active_only}).json()
    return [t for t in rows if t["visit_id"] == visit_id]


def _park_other_waiting(client, auth, branch_id, track, keep_id=None):
    """Skip foreign waiting tickets of a track so call-next claims ours."""
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "track": track}).json()
    for t in rows:
        if t["status"] == "waiting" and t["id"] != keep_id:
            assert client.post(f"{API}/queue/{t['id']}/skip", headers=auth).status_code == 200


def _call_next(client, auth, branch_id, track):
    return client.post(f"{API}/queue/call-next", headers=auth,
                       json={"branch_id": branch_id, "room": ROOM, "track": track})


def _operation_type(client, auth, code: str) -> dict:
    types = client.get(f"{API}/operation-types", headers=auth).json()
    return next(t for t in types if t["code"] == code)


def _product_by_sku(client, auth, sku: str) -> dict:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)


def _receipt(client, auth, branch_id: str, items: list[tuple[str, str]]) -> None:
    resp = client.post(
        f"{API}/inventory/receipts", headers=auth,
        json={"branch_id": branch_id,
              "items": [{"product_id": _product_by_sku(client, auth, sku)["id"], "quantity": qty}
                        for sku, qty in items]},
    )
    assert resp.status_code == 201, resp.text


def test_flow_full_journey_treatment_to_follow_up(client, auth):
    """registered → waiting_diagnostic → in_diagnostic → waiting_doctor →
    in_doctor → treatment_assigned → follow_up → completed, all hands-free."""
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "Путь")
    assert visit["flow_status"] == "registered"          # VisitOut carries the field
    assert _flow(client, auth, visit["id"]) == "registered"

    # Pay in full -> D ticket issued, flow advances by the payment event.
    d_number = _pay_in_full(client, auth, visit)
    assert d_number and d_number.startswith("D-")
    assert _flow(client, auth, visit["id"]) == "waiting_diagnostic"

    # Diagnost calls the patient in.
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"])
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    called = _call_next(client, auth, branch_id, "diagnostic")
    assert called.status_code == 200, called.text
    assert called.json()["id"] == d_ticket["id"]
    assert _flow(client, auth, visit["id"]) == "in_diagnostic"

    # Diagnostics done -> auto V ticket + flow says "waiting for the doctor".
    assert client.post(f"{API}/queue/{d_ticket['id']}/done", headers=auth).status_code == 200
    assert _flow(client, auth, visit["id"]) == "waiting_doctor"
    [v_ticket] = [t for t in _visit_tickets(client, auth, branch_id, visit["id"])
                  if t["track"] == "doctor"]
    assert v_ticket["status"] == "waiting"

    # Doctor calls the patient in.
    _park_other_waiting(client, auth, branch_id, "doctor", keep_id=v_ticket["id"])
    called_v = _call_next(client, auth, branch_id, "doctor")
    assert called_v.status_code == 200, called_v.text
    assert called_v.json()["id"] == v_ticket["id"]
    assert _flow(client, auth, visit["id"]) == "in_doctor"

    # Doctor prescribes a treatment.
    prescribed = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                             json={"kind": "procedure", "name": "Гимнастика для глаз"})
    assert prescribed.status_code == 201, prescribed.text
    assert _flow(client, auth, visit["id"]) == "treatment_assigned"

    # Appointment over (doctor ticket done) with an assignment -> follow-up care.
    assert client.post(f"{API}/queue/{v_ticket['id']}/done", headers=auth).status_code == 200
    assert _flow(client, auth, visit["id"]) == "follow_up"

    # Reception closes the visit -> terminal.
    closed = client.post(f"{API}/visits/{visit['id']}/close", headers=auth)
    assert closed.status_code == 200, closed.text
    assert closed.json()["flow_status"] == "completed"


def test_flow_appointment_with_no_assignment_completes(client, auth):
    """Doctor ticket done with NOTHING prescribed -> completed, not follow_up."""
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "Безназначений")
    _pay_in_full(client, auth, visit)
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"])
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    assert _call_next(client, auth, branch_id, "diagnostic").json()["id"] == d_ticket["id"]
    assert client.post(f"{API}/queue/{d_ticket['id']}/done", headers=auth).status_code == 200
    [v_ticket] = [t for t in _visit_tickets(client, auth, branch_id, visit["id"])
                  if t["track"] == "doctor"]
    _park_other_waiting(client, auth, branch_id, "doctor", keep_id=v_ticket["id"])
    assert _call_next(client, auth, branch_id, "doctor").json()["id"] == v_ticket["id"]

    assert client.post(f"{API}/queue/{v_ticket['id']}/done", headers=auth).status_code == 200
    assert _flow(client, auth, visit["id"]) == "completed"


def test_flow_surgery_path_and_precedence(client, auth):
    """surgery_assigned → (perform) surgery_completed; a treatment prescribed
    alongside never downgrades surgery_*."""
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "Хирургия")
    ivi = _operation_type(client, auth, "IVI")

    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"], "eye": "od"})
    assert op.status_code == 201, op.text
    assert _flow(client, auth, visit["id"]) == "surgery_assigned"

    # Precedence: eye drops next to a planned surgery must not downgrade.
    drops = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                        json={"kind": "procedure", "name": "Капли до операции"})
    assert drops.status_code == 201, drops.text
    assert _flow(client, auth, visit["id"]) == "surgery_assigned"

    # Stock the IVI template (per-branch), schedule + perform -> surgery_completed.
    _receipt(client, auth, branch_id, [("SYR-1", "5"), ("GLOVES-ST", "5")])
    sched = client.post(f"{API}/operations/{op.json()['id']}/schedule", headers=auth,
                        json={"scheduled_at": "2026-07-01T09:00:00Z"})
    assert sched.status_code == 200, sched.text
    performed = client.post(f"{API}/operations/{op.json()['id']}/perform", headers=auth)
    assert performed.status_code == 200, performed.text
    assert _flow(client, auth, visit["id"]) == "surgery_completed"


def test_flow_scheduled_surgery(client, auth):
    """Reception scheduling a referral moves the flow to surgery_scheduled."""
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "Плановая")
    ivi = _operation_type(client, auth, "IVI")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"], "eye": "os"})
    assert op.status_code == 201, op.text
    assert _flow(client, auth, visit["id"]) == "surgery_assigned"
    sched = client.post(f"{API}/operations/{op.json()['id']}/schedule", headers=auth,
                        json={"scheduled_at": "2026-06-20T09:00:00Z"})
    assert sched.status_code == 200, sched.text
    assert _flow(client, auth, visit["id"]) == "surgery_scheduled"


def test_flow_cancel_is_terminal(client, auth):
    """Cancel -> cancelled; later prescriptions are 409 and the flow stays put."""
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "Отказ")
    cancelled = client.post(f"{API}/visits/{visit['id']}/cancel", headers=auth)
    assert cancelled.status_code == 200, cancelled.text
    assert cancelled.json()["flow_status"] == "cancelled"

    denied = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                         json={"kind": "procedure", "name": "Поздно"})
    assert denied.status_code == 409
    assert _flow(client, auth, visit["id"]) == "cancelled"


def test_flow_status_has_no_write_path(client, auth):
    """The whole point: nobody can set flow_status by hand."""
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "Только-чтение")
    assert "flow_status" in visit  # exposed read-only on VisitOut

    # There is no PATCH/PUT on /visits/{id} at all.
    assert client.patch(f"{API}/visits/{visit['id']}", headers=auth,
                        json={"flow_status": "completed"}).status_code == 405
    assert client.put(f"{API}/visits/{visit['id']}", headers=auth,
                      json={"flow_status": "completed"}).status_code == 405

    # Sneaking it into the create payload is ignored by the input DTO.
    sneaky = client.post(f"{API}/visits", headers=auth,
                         json={"patient_id": visit["patient_id"], "branch_id": branch_id,
                               "flow_status": "completed", "items": []})
    assert sneaky.status_code == 201, sneaky.text
    assert sneaky.json()["flow_status"] == "registered"


def test_settling_a_later_bill_never_regresses_the_flow(client, auth):
    """Blocker fix: paying a prescribed surgery must not re-queue diagnostics."""
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "ПовторнаяОплата")
    _pay_in_full(client, auth, visit)

    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"], active_only=True)
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    d = _call_next(client, auth, branch_id, "diagnostic").json()
    client.post(f"{API}/queue/{d['id']}/done", headers=auth)
    v_ticket = next(t for t in _visit_tickets(client, auth, branch_id, visit["id"], active_only=True)
                    if t["track"] == "doctor")
    _park_other_waiting(client, auth, branch_id, "doctor", keep_id=v_ticket["id"])
    _call_next(client, auth, branch_id, "doctor")

    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"], "eye": "od"}).json()
    # Reception schedules it — this is what bills the visit (TZ Modul 6).
    client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                json={"scheduled_at": "2026-07-01T09:00:00Z"})
    assert _flow(client, auth, visit["id"]) == "surgery_scheduled"

    # Reception settles the surgery bill: flow must NOT regress, and no new
    # diagnostic ticket may be minted (the reported number is at most the
    # already-active V ticket, never a fresh D).
    fresh = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    pay = client.post(f"{API}/payments", headers=auth,
                      json={"visit_id": visit["id"], "amount": fresh["balance"]}).json()
    assert pay["queue_ticket_number"] is None or pay["queue_ticket_number"].startswith("V-")
    tickets = _visit_tickets(client, auth, branch_id, visit["id"])
    assert len([t for t in tickets if t["track"] == "diagnostic"]) == 1  # старый, done
    assert _flow(client, auth, visit["id"]) == "surgery_scheduled"


def test_cancelling_the_plan_recomputes_the_flow(client, auth):
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "ОтменаПлана")
    _pay_in_full(client, auth, visit)
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"], active_only=True)
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    d = _call_next(client, auth, branch_id, "diagnostic").json()
    client.post(f"{API}/queue/{d['id']}/done", headers=auth)
    v_ticket = next(t for t in _visit_tickets(client, auth, branch_id, visit["id"], active_only=True)
                    if t["track"] == "doctor")
    _park_other_waiting(client, auth, branch_id, "doctor", keep_id=v_ticket["id"])
    _call_next(client, auth, branch_id, "doctor")

    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"], "eye": "os"}).json()
    assert _flow(client, auth, visit["id"]) == "surgery_assigned"
    client.post(f"{API}/operations/{op['id']}/cancel", headers=auth)
    # Plan gone, doctor ticket still active (called) -> back to in_doctor.
    assert _flow(client, auth, visit["id"]) == "in_doctor"

    tr = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Капли"}).json()
    assert _flow(client, auth, visit["id"]) == "treatment_assigned"
    client.post(f"{API}/treatments/{tr['id']}/cancel", headers=auth)
    assert _flow(client, auth, visit["id"]) == "in_doctor"


def test_skip_reverts_flow_and_requeue_restores_the_ticket(client, auth):
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "Неявка")
    _pay_in_full(client, auth, visit)
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"], active_only=True)
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    d = _call_next(client, auth, branch_id, "diagnostic").json()
    assert _flow(client, auth, visit["id"]) == "in_diagnostic"

    # No-show: skip reverts the "in the room" claim instead of freezing it.
    client.post(f"{API}/queue/{d['id']}/skip", headers=auth)
    assert _flow(client, auth, visit["id"]) == "waiting_diagnostic"

    # ...and the patient can be returned to the line without money movement.
    requeued = client.post(f"{API}/queue/{d['id']}/requeue", headers=auth)
    assert requeued.status_code == 200, requeued.text
    assert requeued.json()["status"] == "waiting"
    d2 = _call_next(client, auth, branch_id, "diagnostic").json()
    assert d2["id"] == d["id"]
    assert _flow(client, auth, visit["id"]) == "in_diagnostic"


def test_late_prescription_unsticks_early_completed_flow(client, auth):
    """Doctor marks the ticket done first, prescribes after: the open visit
    must keep flowing instead of swallowing events in terminal 'completed'."""
    branch_id = _flow_branch(client, auth)
    visit = _register_visit(client, auth, branch_id, "ПозднийПлан")
    _pay_in_full(client, auth, visit)
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"], active_only=True)
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    d = _call_next(client, auth, branch_id, "diagnostic").json()
    client.post(f"{API}/queue/{d['id']}/done", headers=auth)
    v_ticket = next(t for t in _visit_tickets(client, auth, branch_id, visit["id"], active_only=True)
                    if t["track"] == "doctor")
    _park_other_waiting(client, auth, branch_id, "doctor", keep_id=v_ticket["id"])
    v = _call_next(client, auth, branch_id, "doctor").json()
    client.post(f"{API}/queue/{v['id']}/done", headers=auth)
    assert _flow(client, auth, visit["id"]) == "completed"  # nothing assigned yet

    tr = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Поздние капли"})
    assert tr.status_code == 201, tr.text
    assert _flow(client, auth, visit["id"]) == "treatment_assigned"

    # A billing-closed visit, however, IS locked for good.
    client.post(f"{API}/visits/{visit['id']}/close", headers=auth)
    assert _flow(client, auth, visit["id"]) == "completed"
