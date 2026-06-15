"""Patient Timeline: one chronological feed assembled from existing data.

Builds a small journey through the public API (patient -> visit with a service
-> payment -> eye exam -> treatment prescription -> operation prescription),
then asserts the feed content, ordering, limit and RBAC.
"""
from __future__ import annotations

from datetime import datetime

from tests.conftest import API

_MISSING = "00000000-0000-0000-0000-000000000000"


def _build_journey(client, auth) -> dict:
    """Returns {patient_id, visit, visit_no, payment_amount, op_type_name}."""
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Хроника", "last_name": "Таймлайнов",
              "phone": "+998901112233", "branch_id": branch_id},
    ).json()

    services = client.get(f"{API}/services", headers=auth).json()["items"]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": services[0]["id"], "quantity": 1}]},
    ).json()

    # Pay the full balance (no queue ticket: this session DB is shared with the
    # queue tests — a stray waiting ticket would hijack their call-next).
    paid = client.post(
        f"{API}/payments", headers=auth,
        json={"visit_id": visit["id"], "amount": visit["balance"],
              "issue_queue_ticket": False},
    )
    assert paid.status_code == 201, paid.text

    exam = client.put(
        f"{API}/visits/{visit['id']}/exam", headers=auth,
        json={"diagnosis": "Миопия слабой степени OU", "complaints": "снижение зрения"},
    )
    assert exam.status_code == 200, exam.text

    treatment = client.post(
        f"{API}/visits/{visit['id']}/treatments", headers=auth,
        json={"kind": "procedure", "name": "Гимнастика для глаз",
              "instructions": "2 раза в день"},
    )
    assert treatment.status_code == 201, treatment.text

    # Prescribe only (perform needs warehouse stock — out of scope here).
    op_types = client.get(f"{API}/operation-types", headers=auth).json()
    phaco = next(t for t in op_types if t["code"] == "PHACO")
    operation = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": phaco["id"], "eye": "od"},
    )
    assert operation.status_code == 201, operation.text

    return {
        "patient_id": patient["id"],
        "visit": visit,
        "visit_no": visit["visit_no"],
        "payment_amount": visit["balance"],  # decimal string, e.g. "150000.00"
        "op_type_name": phaco["name"],
    }


def test_timeline_404_for_unknown_patient(client, auth):
    resp = client.get(f"{API}/patients/{_MISSING}/timeline", headers=auth)
    assert resp.status_code == 404


def test_timeline_assembles_full_journey_sorted_desc(client, auth):
    journey = _build_journey(client, auth)
    resp = client.get(f"{API}/patients/{journey['patient_id']}/timeline", headers=auth)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["patient_id"] == journey["patient_id"]

    events = body["events"]
    assert len(events) >= 5
    timestamps = [datetime.fromisoformat(e["ts"].replace("Z", "+00:00")) for e in events]
    assert timestamps == sorted(timestamps, reverse=True)  # newest first

    by_kind = {e["kind"]: e for e in events}
    assert by_kind["visit_opened"]["title"] == f"Визит {journey['visit_no']} открыт"
    assert by_kind["visit_opened"]["visit_id"] == journey["visit"]["id"]

    assert by_kind["payment"]["title"] == f"Оплата {journey['payment_amount']} (cash)"
    assert by_kind["payment"]["detail"]  # receipt_no travels in detail

    assert by_kind["exam"]["title"] == "Осмотр окулиста (025-8)"
    assert by_kind["exam"]["detail"] == "Миопия слабой степени OU"

    assert by_kind["treatment_prescribed"]["title"] == "Назначение: Гимнастика для глаз"

    assert by_kind["operation_referred"]["title"] == (
        f"Направление на операцию: {journey['op_type_name']}"
    )

    # Every event carries the visit reference back to the same visit.
    for e in events:
        assert e["visit_id"] == journey["visit"]["id"]


def test_timeline_respects_limit(client, auth):
    journey = _build_journey(client, auth)
    resp = client.get(
        f"{API}/patients/{journey['patient_id']}/timeline",
        headers=auth, params={"limit": 2},
    )
    assert resp.status_code == 200, resp.text
    assert len(resp.json()["events"]) == 2

    too_big = client.get(
        f"{API}/patients/{journey['patient_id']}/timeline",
        headers=auth, params={"limit": 501},
    )
    assert too_big.status_code == 422  # le=500


def test_timeline_rbac(client, auth):
    journey = _build_journey(client, auth)

    def _login_as(email: str, role: str) -> dict:
        created = client.post(
            f"{API}/users", headers=auth,
            json={"email": email, "full_name": f"Timeline {role}",
                  "password": "Tl!2026aa", "role_names": [role]},
        )
        assert created.status_code == 201, created.text
        token = client.post(
            f"{API}/auth/login", data={"username": email, "password": "Tl!2026aa"}
        ).json()["access_token"]
        return {"Authorization": f"Bearer {token}"}

    # Cashier (patients.read + payments.read, no EMR/clinical reads): sees the
    # feed, sees finance, but the aggregation must NOT leak diagnoses,
    # prescriptions or operations past module RBAC.
    cashier = _login_as("tl.cashier@kozshifo.uz", "Cashier")
    ok = client.get(f"{API}/patients/{journey['patient_id']}/timeline", headers=cashier)
    assert ok.status_code == 200, ok.text
    cashier_kinds = {e["kind"] for e in ok.json()["events"]}
    assert "payment" in cashier_kinds
    assert not cashier_kinds & {"exam", "device_result", "operation_referred",
                                "operation_performed", "treatment_prescribed",
                                "treatment_done"}

    # Doctor (EMR/clinical reads, NO payments.read): sees the medicine,
    # never the money.
    doctor = _login_as("tl.doctor@kozshifo.uz", "Doctor")
    ok_doc = client.get(f"{API}/patients/{journey['patient_id']}/timeline", headers=doctor)
    assert ok_doc.status_code == 200, ok_doc.text
    doctor_kinds = {e["kind"] for e in ok_doc.json()["events"]}
    assert "exam" in doctor_kinds or "treatment_prescribed" in doctor_kinds
    assert not doctor_kinds & {"payment", "refund"}

    # Warehouse has no patients.read -> 403.
    warehouse = _login_as("tl.sklad@kozshifo.uz", "Warehouse")
    denied = client.get(f"{API}/patients/{journey['patient_id']}/timeline", headers=warehouse)
    assert denied.status_code == 403
    assert "patients.read" in denied.json()["detail"]
