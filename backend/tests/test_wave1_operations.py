"""Wave 1: re-scheduling an operation must not silently drop the assigned
surgeon — an omitted surgeon_id means «keep the current one», an explicit
surgeon_id re-assigns (payroll and by-surgeon reports hang off this field)."""
from __future__ import annotations

from tests.conftest import API

PWD = "Surg!2026"
_SCHED_AT = "2026-08-01T09:00:00+00:00"
_RESCHED_AT = "2026-08-02T11:30:00+00:00"


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _user(client, auth, *, email, full_name, is_external_surgeon=False) -> str:
    body = {"email": email, "full_name": full_name, "password": PWD,
            "role_names": [], "is_external_surgeon": is_external_surgeon}
    r = client.post(f"{API}/users", headers=auth, json=body)
    assert r.status_code == 201, r.text
    return r.json()["id"]


def _refer(client, auth, branch: str, *, surgeon_id: str, suffix: str) -> dict:
    op_type = client.get(f"{API}/operation-types", headers=auth).json()[0]
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Опер", "last_name": f"Хирург-{suffix}",
                                "branch_id": branch}).json()
    visit = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch}).json()
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": op_type["id"], "eye": "od",
                           "surgeon_id": surgeon_id})
    assert op.status_code == 201, op.text
    return op.json()


def test_schedule_without_surgeon_keeps_current_one(client, auth):
    """A bare (re-)schedule — date/price only — keeps the assigned surgeon."""
    branch = _branch(client, auth)
    surgeon = _user(client, auth, email="w1.keep@kozshifo.uz",
                    full_name="Хирург Постоянный", is_external_surgeon=True)
    op = _refer(client, auth, branch, surgeon_id=surgeon, suffix="keep")
    assert op["surgeon_id"] == surgeon

    # First scheduling without surgeon_id: the referral's surgeon survives.
    first = client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                        json={"scheduled_at": _SCHED_AT, "price": "700000"})
    assert first.status_code == 200, first.text
    assert first.json()["surgeon_id"] == surgeon

    # Re-schedule (new date), again without surgeon_id: still the same surgeon.
    second = client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                         json={"scheduled_at": _RESCHED_AT})
    assert second.status_code == 200, second.text
    assert second.json()["surgeon_id"] == surgeon
    assert second.json()["scheduled_at"] is not None


def test_schedule_with_surgeon_reassigns(client, auth):
    """An explicit surgeon_id on schedule re-assigns the operation."""
    branch = _branch(client, auth)
    surgeon_a = _user(client, auth, email="w1.a@kozshifo.uz",
                      full_name="Хирург Первый", is_external_surgeon=True)
    surgeon_b = _user(client, auth, email="w1.b@kozshifo.uz",
                      full_name="Хирург Второй", is_external_surgeon=True)
    op = _refer(client, auth, branch, surgeon_id=surgeon_a, suffix="swap")

    scheduled = client.post(f"{API}/operations/{op['id']}/schedule", headers=auth,
                            json={"scheduled_at": _SCHED_AT, "surgeon_id": surgeon_b})
    assert scheduled.status_code == 200, scheduled.text
    assert scheduled.json()["surgeon_id"] == surgeon_b
