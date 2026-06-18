"""Phase 3: the patient timeline records who called the patient in and when
(«принят: ФИО, время») — a `seen` event sourced from called queue tickets."""
from __future__ import annotations

from tests.conftest import API


def test_timeline_records_who_called_the_patient(client, auth):
    branch = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Хроно", "last_name": "Принят", "branch_id": branch},
    ).json()
    service = client.get(f"{API}/services", headers=auth).json()["items"][0]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch,
              "items": [{"service_id": service["id"], "quantity": 1}]},
    ).json()
    paid = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert paid.status_code == 201, paid.text

    drows = client.get(f"{API}/queue", headers=auth,
                       params={"branch_id": branch, "track": "diagnostic"}).json()
    [d] = [t for t in drows if t["visit_id"] == visit["id"]]
    # The director calls the ticket → called_by is recorded.
    assert client.post(f"{API}/queue/{d['id']}/call", headers=auth,
                       json={"room": "Каб. 5"}).status_code == 200

    tl = client.get(f"{API}/patients/{patient['id']}/timeline", headers=auth).json()
    seen = [e for e in tl["events"] if e["kind"] == "seen"]
    assert seen, tl["events"]
    assert seen[0]["title"].startswith("Принят:")
    assert "Каб. 5" in (seen[0]["detail"] or "")

    client.post(f"{API}/queue/{d['id']}/skip", headers=auth)  # cleanup
