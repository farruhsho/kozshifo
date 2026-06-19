"""Per-doctor queue-ticket numbering (Phase 3): the doctor-track ticket takes the
assigned doctor's queue_prefix (Сарвар → С-001), resolved from the visit's chosen
doctor → the patient's primary doctor → the service's single eligible doctor."""
from __future__ import annotations

from tests.conftest import API

PWD = "Num!2026"


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _doctor(client, auth, branch, slug, *, full_name, prefix=None, cabinet=None) -> str:
    body = {"email": f"num.{slug}@kozshifo.uz", "full_name": full_name,
            "password": PWD, "role_names": ["Doctor"], "branch_id": branch}
    if prefix is not None:
        body["queue_prefix"] = prefix
    if cabinet is not None:
        body["cabinet"] = cabinet
    r = client.post(f"{API}/users", headers=auth, json=body)
    assert r.status_code == 201, r.text
    return r.json()["id"]


def _service(client, auth, code, doctor_ids) -> str:
    r = client.post(f"{API}/services", headers=auth,
                    json={"code": code, "name": f"Услуга {code}", "price": "100000",
                          "doctor_ids": doctor_ids})
    assert r.status_code in (200, 201), r.text
    return r.json()["id"]


def _doctor_ticket(client, auth, branch, *, last_name, service_id,
                   doctor_id=None, primary_doctor_id=None) -> dict:
    """Register + visit (on `service_id`, optional doctor) + pay + finish
    diagnostics → return the auto-issued waiting doctor ticket for the visit."""
    pbody = {"first_name": "Номер", "last_name": last_name, "branch_id": branch}
    if primary_doctor_id is not None:
        pbody["primary_doctor_id"] = primary_doctor_id
    patient = client.post(f"{API}/patients", headers=auth, json=pbody).json()
    vbody = {"patient_id": patient["id"], "branch_id": branch,
             "items": [{"service_id": service_id, "quantity": 1}]}
    if doctor_id is not None:
        vbody["doctor_id"] = doctor_id
    visit = client.post(f"{API}/visits", headers=auth, json=vbody).json()
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert paid.status_code == 201, paid.text
    drows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch, "track": "diagnostic"}).json()
    [d] = [t for t in drows if t["visit_id"] == visit["id"]]
    assert client.post(f"{API}/queue/{d['id']}/call", headers=auth,
                       json={"room": "Д"}).status_code == 200
    assert client.post(f"{API}/queue/{d['id']}/done", headers=auth).status_code == 200
    vrows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch, "track": "doctor"}).json()
    [v] = [t for t in vrows if t["visit_id"] == visit["id"]]
    return v


def test_doctor_prefix_and_per_doctor_counter(client, auth):
    branch = _branch(client, auth)
    # Unique prefix «Ц» isolates this counter from other tests' doctors.
    doc = _doctor(client, auth, branch, "tsoy", full_name="Цой Виктор", prefix="Ц", cabinet="Каб. 3")
    svc = _service(client, auth, "NUM-C", [doc])

    v1 = _doctor_ticket(client, auth, branch, last_name="Первый", service_id=svc)
    assert v1["ticket_number"] == "Ц-001"
    assert v1["assigned_user_id"] == doc
    assert v1["room"] == "Каб. 3"  # the doctor's cabinet pre-fills the ticket

    v2 = _doctor_ticket(client, auth, branch, last_name="Второй", service_id=svc)
    assert v2["ticket_number"] == "Ц-002"  # per-doctor daily counter increments


def test_reception_chosen_doctor_overrides_service_routing(client, auth):
    branch = _branch(client, auth)
    doc_svc = _doctor(client, auth, branch, "svc-doc", full_name="Алишер Сервис", prefix="А")
    doc_pick = _doctor(client, auth, branch, "picked", full_name="Бобур Выбран", prefix="Б", cabinet="Каб. 9")
    svc = _service(client, auth, "NUM-AB", [doc_svc])  # service routes to doc_svc...

    # ...but reception chose doc_pick on the visit → that wins.
    v = _doctor_ticket(client, auth, branch, last_name="Выбор", service_id=svc, doctor_id=doc_pick)
    assert v["ticket_number"].startswith("Б-")
    assert v["assigned_user_id"] == doc_pick
    assert v["room"] == "Каб. 9"


def test_primary_doctor_fallback_when_service_has_no_doctor(client, auth):
    branch = _branch(client, auth)
    doc = _doctor(client, auth, branch, "primary", full_name="Гулнора Лечащая", prefix="Г")
    svc = _service(client, auth, "NUM-NONE", [])  # no eligible doctor on the service

    # Returning patient: their primary doctor fills in when the service can't.
    v = _doctor_ticket(client, auth, branch, last_name="Повторный",
                       service_id=svc, primary_doctor_id=doc)
    assert v["ticket_number"].startswith("Г-")
    assert v["assigned_user_id"] == doc
