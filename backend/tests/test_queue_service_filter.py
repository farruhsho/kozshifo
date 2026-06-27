"""Phase 3b: the diagnostic queue is distributed BY SERVICE — a paid visit's
diagnostic ticket is tagged with its diagnostic service (is_diagnostic), and a
diagnostician who serves only УЗИ pulls only УЗИ-tagged tickets."""
from __future__ import annotations

from tests.conftest import API

PWD = "Filt!2026"


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _diag_service(client, auth, code) -> dict:
    r = client.post(f"{API}/services", headers=auth,
                    json={"code": code, "name": f"Диаг {code}", "price": "70000",
                          "is_diagnostic": True})
    assert r.status_code in (200, 201), r.text
    body = r.json()
    assert body["is_diagnostic"] is True
    return body


def _diagnost(client, auth, branch, slug, service_ids) -> None:
    r = client.post(f"{API}/users", headers=auth,
                    json={"email": f"filt.{slug}@kozshifo.uz", "full_name": f"Диагност {slug}",
                          "password": PWD, "role_names": ["Diagnost"], "branch_id": branch,
                          "service_ids": service_ids, "cabinet": f"УЗ-{slug}"})
    assert r.status_code == 201, r.text


def _login(client, email) -> dict:
    t = client.post(f"{API}/auth/login",
                    data={"username": email, "password": PWD}).json()["access_token"]
    return {"Authorization": f"Bearer {t}"}


def _park_waiting_diagnostic(client, auth, branch, keep_id) -> None:
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch, "track": "diagnostic"}).json()
    for t in rows:
        if t["status"] == "waiting" and t["id"] != keep_id:
            client.post(f"{API}/queue/{t['id']}/skip", headers=auth)


def test_diagnostic_ticket_tagged_and_filtered_by_service(client, auth):
    branch = _branch(client, auth)
    uzi = _diag_service(client, auth, "F3-UZI")
    bio = _diag_service(client, auth, "F3-BIO")
    _diagnost(client, auth, branch, "uzi", [uzi["id"]])
    _diagnost(client, auth, branch, "bio", [bio["id"]])

    # A visit billed for УЗИ → a diagnostic ticket tagged with the УЗИ service.
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Фильтр", "last_name": "УЗИ", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch,
                              "items": [{"service_id": uzi["id"], "quantity": 1}]}).json()
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert paid.status_code == 201, paid.text
    drows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch, "track": "diagnostic"}).json()
    [d] = [t for t in drows if t["visit_id"] == visit["id"]]
    assert d["service_id"] == uzi["id"]  # ticket carries the diagnostic service

    # Isolate our ticket so call-next is deterministic in the shared session DB.
    _park_waiting_diagnostic(client, auth, branch, keep_id=d["id"])

    # The BIO diagnostician must NOT be handed the УЗИ ticket (service mismatch).
    bio_auth = _login(client, "filt.bio@kozshifo.uz")
    denied = client.post(f"{API}/queue/call-next", headers=bio_auth,
                         json={"branch_id": branch, "track": "diagnostic"})
    assert denied.status_code == 404, denied.text

    # The УЗИ diagnostician claims it.
    uzi_auth = _login(client, "filt.uzi@kozshifo.uz")
    got = client.post(f"{API}/queue/call-next", headers=uzi_auth,
                      json={"branch_id": branch, "track": "diagnostic"})
    assert got.status_code == 200, got.text
    assert got.json()["id"] == d["id"]

    client.post(f"{API}/queue/{d['id']}/skip", headers=auth)  # cleanup


def test_two_diagnostic_services_open_pool(client, auth):
    """A visit billed for TWO diagnostic services tags the ticket NULL (open pool)
    so EITHER specialist can claim it. Tagging only the first (the old .limit(1)
    behaviour) hid the ticket from the second specialist and hung the visit."""
    branch = _branch(client, auth)
    uzi = _diag_service(client, auth, "F3B-UZI")
    bio = _diag_service(client, auth, "F3B-BIO")
    _diagnost(client, auth, branch, "muzi", [uzi["id"]])
    _diagnost(client, auth, branch, "mbio", [bio["id"]])

    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Мульти", "last_name": "Диаг", "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch,
                              "items": [{"service_id": uzi["id"], "quantity": 1},
                                        {"service_id": bio["id"], "quantity": 1}]}).json()
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert paid.status_code == 201, paid.text

    drows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch, "track": "diagnostic"}).json()
    [d] = [t for t in drows if t["visit_id"] == visit["id"]]
    assert d["service_id"] is None  # open pool — NOT tagged with the first service only

    # Isolate our ticket so call-next is deterministic in the shared session DB.
    _park_waiting_diagnostic(client, auth, branch, keep_id=d["id"])

    # The BIO diagnostician must be able to claim the (untagged) ticket — under the
    # old behaviour it was tagged УЗИ and BIO's service-filtered call-next 404'd.
    bio_auth = _login(client, "filt.mbio@kozshifo.uz")
    got = client.post(f"{API}/queue/call-next", headers=bio_auth,
                      json={"branch_id": branch, "track": "diagnostic"})
    assert got.status_code == 200, got.text
    assert got.json()["id"] == d["id"]

    client.post(f"{API}/queue/{d['id']}/skip", headers=auth)  # cleanup
