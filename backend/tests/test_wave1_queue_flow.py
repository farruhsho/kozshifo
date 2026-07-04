"""Wave 1 queue/flow fixes: Л-ticket auto-binds to the patient's open visit and
inherits ЭКСТРЕННО; call-next serves personally routed patients before the open
pool; dispense/complete from the patient card drive the flow engine; late
diagnostic events never regress an advanced visit."""
from __future__ import annotations

from tests.conftest import API

PWD = "Wave1!2026"


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _patient(client, auth, last_name) -> dict:
    return client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Волна", "last_name": last_name, "branch_id": _branch(client, auth)},
    ).json()


def _visit(client, auth, patient_id, branch, items=None) -> dict:
    return client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient_id, "branch_id": branch, "items": items or []},
    ).json()


def _flow(client, auth, visit_id) -> str:
    return client.get(f"{API}/visits/{visit_id}", headers=auth).json()["flow_status"]


def _park_waiting(client, auth, branch, track, keep_ids=()) -> None:
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch, "track": track}).json()
    for t in rows:
        if t["status"] == "waiting" and t["id"] not in keep_ids:
            client.post(f"{API}/queue/{t['id']}/skip", headers=auth)


def _make_user(client, auth, branch, slug, cabinet=None) -> str:
    resp = client.post(
        f"{API}/users", headers=auth,
        json={
            "email": f"wave1.{slug}@kozshifo.uz",
            "full_name": f"Волна {slug}",
            "password": PWD,
            "role_names": ["Doctor"],
            "branch_id": branch,
            "cabinet": cabinet,
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


# ── 1+2: Л-ticket without visit_id binds to a TREATMENT-leg visit + inherits ЭКСТРЕННО ──

def test_treatment_ticket_autobinds_treatment_leg_visit_and_inherits_emergency(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Автопривязка")
    visit = _visit(client, auth, patient["id"], branch)
    assert client.post(f"{API}/visits/{visit['id']}/priority", headers=auth,
                       json={"emergency": True, "reason": "острая боль"}).status_code == 200
    # A prescribed treatment puts the visit into a real treatment leg — only then
    # may a visit-less Л-ticket auto-bind to it.
    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Массаж век"})
    assert tx.status_code == 201, tx.text
    assert _flow(client, auth, visit["id"]) == "treatment_assigned"

    # UI does not send visit_id — the server finds the treatment-leg visit itself.
    resp = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                       json={"patient_id": patient["id"], "branch_id": branch})
    assert resp.status_code == 201, resp.text
    t = resp.json()
    assert t["visit_id"] == visit["id"]
    assert t["priority"] > 0
    assert t["priority_reason"] == "острая боль"

    client.post(f"{API}/queue/{t['id']}/skip", headers=auth)  # cleanup


def test_treatment_ticket_without_any_open_visit_stays_unbound(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "БезВизита")
    resp = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                       json={"patient_id": patient["id"], "branch_id": branch})
    assert resp.status_code == 201, resp.text
    t = resp.json()
    assert t["visit_id"] is None
    assert t["priority"] == 0
    client.post(f"{API}/queue/{t['id']}/skip", headers=auth)  # cleanup


def test_treatment_ticket_does_not_bind_pre_doctor_visit(client, auth):
    # A held-for-assignment visit (paid, «Ожидает назначения», no treatment yet)
    # must NOT be captured by a visit-less Л-ticket — otherwise completing that
    # ticket would silently finish a journey that never reached the doctor.
    branch = _branch(client, auth)
    svc = _service(client, auth, "WV1-HOLD")
    patient = _patient(client, auth, "ОжидаетНазначения")
    visit = _visit(client, auth, patient["id"], branch,
                   items=[{"service_id": svc, "quantity": 1}])
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"],
                             "referral_intent": "hold"})
    assert paid.status_code == 201, paid.text
    assert _flow(client, auth, visit["id"]) == "awaiting_assignment"

    resp = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                       json={"patient_id": patient["id"], "branch_id": branch})
    assert resp.status_code == 201, resp.text
    assert resp.json()["visit_id"] is None  # stayed unbound
    # The pre-doctor visit was left untouched.
    assert _flow(client, auth, visit["id"]) == "awaiting_assignment"

    client.post(f"{API}/queue/{resp.json()['id']}/skip", headers=auth)  # cleanup


# ── 3: call-next serves the specialist's own routed ticket before the open pool ──

def test_call_next_prefers_assigned_over_earlier_open_pool(client, auth):
    branch = _branch(client, auth)
    doc = _make_user(client, auth, branch, "routed", "Каб. W1")
    p_open = _patient(client, auth, "Пул")
    p_mine = _patient(client, auth, "Свой")

    # The open-pool ticket is created FIRST (earlier in FIFO)…
    t_open = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                         json={"patient_id": p_open["id"], "branch_id": branch}).json()
    # …the personally routed one later.
    t_mine = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                         json={"patient_id": p_mine["id"], "branch_id": branch,
                               "assigned_user_id": doc}).json()
    _park_waiting(client, auth, branch, "treatment", keep_ids=(t_open["id"], t_mine["id"]))

    got = client.post(f"{API}/queue/call-next", headers=auth,
                      json={"branch_id": branch, "track": "treatment",
                            "room": "Каб. W1", "for_user_id": doc})
    assert got.status_code == 200, got.text
    assert got.json()["id"] == t_mine["id"]

    for tid in (t_mine["id"], t_open["id"]):  # cleanup
        client.post(f"{API}/queue/{tid}/skip", headers=auth)


def test_call_next_serves_emergency_pool_before_own_ordinary(client, auth):
    # An ЭКСТРЕННО ticket from the open pool must outrank the specialist's OWN
    # non-emergency addressed ticket — priority beats «свои первыми».
    branch = _branch(client, auth)
    doc = _make_user(client, auth, branch, "emrg", "Каб. W2")
    p_emerg = _patient(client, auth, "Экстренный")
    p_mine = _patient(client, auth, "МойОбычный")

    # Open-pool EMERGENCY ticket: bind a treatment-leg visit flagged ЭКСТРЕННО so
    # the ticket inherits priority > 0.
    v_emerg = _visit(client, auth, p_emerg["id"], branch)
    assert client.post(f"{API}/visits/{v_emerg['id']}/priority", headers=auth,
                       json={"emergency": True, "reason": "неотложно"}).status_code == 200
    assert client.post(f"{API}/visits/{v_emerg['id']}/treatments", headers=auth,
                       json={"kind": "procedure", "name": "Срочная процедура"}
                       ).status_code == 201
    t_emerg = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                          json={"patient_id": p_emerg["id"], "branch_id": branch}).json()
    assert t_emerg["visit_id"] == v_emerg["id"] and t_emerg["priority"] > 0

    # The specialist's OWN ordinary (priority 0) addressed ticket.
    t_mine = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                         json={"patient_id": p_mine["id"], "branch_id": branch,
                               "assigned_user_id": doc}).json()
    _park_waiting(client, auth, branch, "treatment", keep_ids=(t_emerg["id"], t_mine["id"]))

    got = client.post(f"{API}/queue/call-next", headers=auth,
                      json={"branch_id": branch, "track": "treatment",
                            "room": "Каб. W2", "for_user_id": doc})
    assert got.status_code == 200, got.text
    assert got.json()["id"] == t_emerg["id"]  # emergency pool wins

    for tid in (t_emerg["id"], t_mine["id"]):  # cleanup
        client.post(f"{API}/queue/{tid}/skip", headers=auth)


def test_treatment_ticket_explicit_visit_other_branch_rejected(client, auth):
    # An explicit visit_id whose visit lives in another branch must be rejected —
    # the ticket must not drive a cross-branch visit's lifecycle.
    branches = client.get(f"{API}/branches", headers=auth).json()
    if len(branches) < 2:
        import pytest
        pytest.skip("needs at least two branches")
    home, other = branches[0]["id"], branches[1]["id"]
    patient = _patient(client, auth, "ЧужойФилиал")
    visit = _visit(client, auth, patient["id"], other)  # visit in the OTHER branch

    resp = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                       json={"patient_id": patient["id"], "branch_id": home,
                             "visit_id": visit["id"]})
    assert resp.status_code == 409, resp.text


def test_complete_ticket_does_not_complete_pre_doctor_visit(client, auth):
    # A treatment ticket explicitly bound to a pre-doctor visit (awaiting_assignment)
    # is finished — flow.complete_if_treatment_done must NOT close the journey.
    branch = _branch(client, auth)
    svc = _service(client, auth, "WV1-PREDOC")
    patient = _patient(client, auth, "ПреВрач")
    visit = _visit(client, auth, patient["id"], branch,
                   items=[{"service_id": svc, "quantity": 1}])
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"],
                             "referral_intent": "hold"})
    assert paid.status_code == 201, paid.text
    assert _flow(client, auth, visit["id"]) == "awaiting_assignment"

    t = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                    json={"patient_id": patient["id"], "branch_id": branch,
                          "visit_id": visit["id"]}).json()
    assert t["visit_id"] == visit["id"]
    assert client.post(f"{API}/queue/{t['id']}/call", headers=auth,
                       json={"room": "Каб. Л"}).status_code == 200
    assert client.post(f"{API}/queue/{t['id']}/done", headers=auth).status_code == 200
    # The pre-doctor visit stays open — its journey never reached the doctor.
    assert _flow(client, auth, visit["id"]) == "awaiting_assignment"


# ── 4: dispense/complete from the patient card drive the flow engine ──

def test_complete_procedure_from_card_completes_treatment_only_visit(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Процедура")
    visit = _visit(client, auth, patient["id"], branch)

    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Массаж век"})
    assert tx.status_code == 201, tx.text
    assert _flow(client, auth, visit["id"]) == "treatment_assigned"

    # The nurse works from the patient card — no Л-ticket ever exists.
    done = client.post(f"{API}/treatments/{tx.json()['id']}/complete", headers=auth)
    assert done.status_code == 200, done.text
    assert _flow(client, auth, visit["id"]) == "completed"


def test_dispense_medication_from_card_completes_treatment_only_visit(client, auth):
    branch = _branch(client, auth)
    products = client.get(f"{API}/inventory/products", headers=auth,
                          params={"q": "SYR-1"}).json()["items"]
    syr = next(p for p in products if p["sku"] == "SYR-1")
    assert client.post(f"{API}/inventory/receipts", headers=auth,
                       json={"branch_id": branch,
                             "items": [{"product_id": syr["id"], "quantity": "5"}]},
                       ).status_code == 201
    patient = _patient(client, auth, "Выдача")
    visit = _visit(client, auth, patient["id"], branch)

    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "medication", "name": "Шприцы",
                           "product_id": syr["id"], "quantity": "2"})
    assert tx.status_code == 201, tx.text
    assert _flow(client, auth, visit["id"]) == "treatment_assigned"

    disp = client.post(f"{API}/treatments/{tx.json()['id']}/dispense", headers=auth)
    assert disp.status_code == 200, disp.text
    assert _flow(client, auth, visit["id"]) == "completed"


def test_complete_from_card_waits_for_remaining_prescriptions(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Курсовой")
    visit = _visit(client, auth, patient["id"], branch)

    first = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                        json={"kind": "procedure", "name": "Процедура 1"}).json()
    second = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                         json={"kind": "procedure", "name": "Процедура 2"}).json()

    assert client.post(f"{API}/treatments/{first['id']}/complete",
                       headers=auth).status_code == 200
    # One prescription still pending — the visit must stay open.
    assert _flow(client, auth, visit["id"]) == "treatment_assigned"

    assert client.post(f"{API}/treatments/{second['id']}/complete",
                       headers=auth).status_code == 200
    assert _flow(client, auth, visit["id"]) == "completed"


# ── 5: late diagnostic events never regress an advanced visit ──

def _service(client, auth, code) -> str:
    resp = client.post(f"{API}/services", headers=auth,
                       json={"code": code, "name": f"Услуга {code}", "price": "100000"})
    assert resp.status_code in (200, 201), resp.text
    return resp.json()["id"]


def test_late_diagnostic_call_does_not_regress_surgery_assigned(client, auth):
    branch = _branch(client, auth)
    svc = _service(client, auth, "WV1-CONS")
    patient = _patient(client, auth, "Хирургия")
    visit = _visit(client, auth, patient["id"], branch,
                   items=[{"service_id": svc, "quantity": 1}])
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert paid.status_code == 201, paid.text
    drows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch, "track": "diagnostic"}).json()
    [d] = [t for t in drows if t["visit_id"] == visit["id"]]

    # The patient goes straight to the doctor, skipping the D-ticket for now.
    v = client.post(f"{API}/queue/refer-to-doctor", headers=auth,
                    json={"visit_id": visit["id"]}).json()
    assert client.post(f"{API}/queue/{v['id']}/call", headers=auth,
                       json={"room": "Каб. В"}).status_code == 200
    assert _flow(client, auth, visit["id"]) == "in_doctor"

    phaco = next(t for t in client.get(f"{API}/operation-types", headers=auth).json()
                 if t["code"] == "PHACO")
    assert client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                       json={"operation_type_id": phaco["id"], "eye": "od"},
                       ).status_code == 201
    assert _flow(client, auth, visit["id"]) == "surgery_assigned"

    # The forgotten D-ticket is called late — the visit must NOT fall back into
    # diagnostics; finishing it must not fake diagnostics progress either.
    assert client.post(f"{API}/queue/{d['id']}/call", headers=auth,
                       json={"room": "Каб. Д"}).status_code == 200
    assert _flow(client, auth, visit["id"]) == "surgery_assigned"
    assert client.post(f"{API}/queue/{d['id']}/done", headers=auth).status_code == 200
    assert _flow(client, auth, visit["id"]) == "surgery_assigned"

    client.post(f"{API}/queue/{v['id']}/skip", headers=auth)  # cleanup


def test_diagnostic_called_still_advances_the_normal_journey(client, auth):
    branch = _branch(client, auth)
    svc = _service(client, auth, "WV1-DIAG")
    patient = _patient(client, auth, "Обычный")
    visit = _visit(client, auth, patient["id"], branch,
                   items=[{"service_id": svc, "quantity": 1}])
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert paid.status_code == 201, paid.text
    assert _flow(client, auth, visit["id"]) == "waiting_diagnostic"
    drows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch, "track": "diagnostic"}).json()
    [d] = [t for t in drows if t["visit_id"] == visit["id"]]

    assert client.post(f"{API}/queue/{d['id']}/call", headers=auth,
                       json={"room": "Каб. Д"}).status_code == 200
    assert _flow(client, auth, visit["id"]) == "in_diagnostic"
    assert client.post(f"{API}/queue/{d['id']}/done", headers=auth).status_code == 200
    assert _flow(client, auth, visit["id"]) == "waiting_doctor"

    vrows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch, "track": "doctor"}).json()
    for t in vrows:  # cleanup the auto-issued V-ticket
        if t["visit_id"] == visit["id"] and t["status"] == "waiting":
            client.post(f"{API}/queue/{t['id']}/skip", headers=auth)
