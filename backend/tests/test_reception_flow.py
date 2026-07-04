"""Reception abort path, queue state-machine guarantees and visit discounts
(Epic-3 review fixes + TZ Modul 2.2)."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _make_visit(client, auth, *, last_name, pay=False):
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": last_name, "branch_id": branch_id},
    ).json()
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": services[0]["id"], "quantity": 1}]},
    ).json()
    if pay:
        client.post(f"{API}/payments", headers=auth,
                    json={"visit_id": visit["id"], "amount": visit["balance"]})
    return branch_id, visit


def _park_other_waiting(client, auth, branch_id, track, keep_id=None):
    """Skip foreign waiting tickets of a track (tests share one session DB) so
    call-next deterministically claims ours. Skip never auto-advances.
    Mirrors the helper in tests/test_queue_tracks.py."""
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "track": track}).json()
    for t in rows:
        if t["status"] == "waiting" and t["id"] != keep_id:
            assert client.post(f"{API}/queue/{t['id']}/skip", headers=auth).status_code == 200


def _park_visit_tickets(client, auth, branch_id, visit_id):
    """Cleanup: skip this visit's still-waiting tickets so later tests'
    call-next is never fed our leftovers (order-independence)."""
    rows = client.get(f"{API}/queue", headers=auth, params={"branch_id": branch_id}).json()
    for t in rows:
        if t["visit_id"] == visit_id and t["status"] == "waiting":
            client.post(f"{API}/queue/{t['id']}/skip", headers=auth)


def test_cancel_unpaid_visit(client, auth):
    _, visit = _make_visit(client, auth, last_name="Отмена")
    resp = client.post(f"{API}/visits/{visit['id']}/cancel", headers=auth)
    assert resp.status_code == 200, resp.text
    assert resp.json()["status"] == "cancelled"
    # Idempotence guard: a cancelled visit cannot be cancelled again, paid,
    # or resurrected via close.
    assert client.post(f"{API}/visits/{visit['id']}/cancel", headers=auth).status_code == 409
    pay = client.post(f"{API}/payments", headers=auth,
                      json={"visit_id": visit["id"], "amount": "1.00"})
    assert pay.status_code == 409
    assert client.post(f"{API}/visits/{visit['id']}/close", headers=auth).status_code == 409


def test_cancel_paid_visit_rejected(client, auth):
    branch_id, visit = _make_visit(client, auth, last_name="Оплачен", pay=True)
    resp = client.post(f"{API}/visits/{visit['id']}/cancel", headers=auth)
    assert resp.status_code == 409
    assert "refund" in resp.json()["detail"].lower()
    # cleanup: the payment minted a waiting D ticket — park it.
    _park_visit_tickets(client, auth, branch_id, visit["id"])


def test_queue_state_machine_enforced(client, auth):
    branch_id, visit = _make_visit(client, auth, last_name="Машина", pay=True)
    queue = client.get(f"{API}/queue", headers=auth, params={"branch_id": branch_id}).json()
    ticket = next(t for t in queue if t["visit_id"] == visit["id"])

    # waiting -> serving is forbidden (must be called first).
    assert client.post(f"{API}/queue/{ticket['id']}/serve", headers=auth).status_code == 409

    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=ticket["id"])
    called = client.post(f"{API}/queue/call-next", headers=auth,
                         json={"branch_id": branch_id, "room": "Каб. 9",
                               "track": "diagnostic"}).json()
    assert called["id"] == ticket["id"]  # provably ours, not a stray leftover
    done = client.post(f"{API}/queue/{called['id']}/done", headers=auth)
    assert done.status_code == 200  # called -> done is the allowed shortcut

    # A finished ticket cannot be resurrected or re-completed.
    assert client.post(f"{API}/queue/{called['id']}/serve", headers=auth).status_code == 409
    assert client.post(f"{API}/queue/{called['id']}/done", headers=auth).status_code == 409
    assert client.post(f"{API}/queue/{called['id']}/skip", headers=auth).status_code == 409

    # cleanup: diagnostics done auto-spawned a waiting doctor V ticket — park it.
    _park_visit_tickets(client, auth, branch_id, visit["id"])


# ── Visit discounts (TZ Modul 2.2) ──────────────────────────────────────────

def test_discount_percent_then_amount_overwrites(client, auth):
    _, visit = _make_visit(client, auth, last_name="Скидка")
    url = f"{API}/visits/{visit['id']}/discount"
    total = Decimal(visit["total_amount"])

    resp = client.post(url, headers=auth,
                       json={"discount_percent": "10", "discount_reason": "Пенсионер"})
    assert resp.status_code == 200, resp.text
    body = resp.json()
    expected = (total * Decimal("10") / 100).quantize(Decimal("0.01"))
    # Decimals cross the wire as strings (platform-wide rule).
    assert isinstance(body["discount_value"], str)
    assert isinstance(body["payable"], str)
    assert Decimal(body["discount_percent"]) == Decimal("10")
    assert body["discount_amount"] is None
    assert body["discount_reason"] == "Пенсионер"
    assert Decimal(body["discount_value"]) == expected
    assert Decimal(body["payable"]) == total - expected
    assert Decimal(body["balance"]) == total - expected
    assert Decimal(body["total_amount"]) == total  # gross total untouched

    # Re-applying overwrites: fixed amount replaces the percent entirely.
    resp2 = client.post(url, headers=auth,
                        json={"discount_amount": "5000.00", "discount_reason": "Акция"})
    assert resp2.status_code == 200, resp2.text
    body2 = resp2.json()
    assert body2["discount_percent"] is None
    assert Decimal(body2["discount_amount"]) == Decimal("5000.00")
    assert body2["discount_reason"] == "Акция"
    assert Decimal(body2["discount_value"]) == Decimal("5000.00")
    assert Decimal(body2["payable"]) == total - Decimal("5000.00")


def test_discount_validation_422(client, auth):
    _, visit = _make_visit(client, auth, last_name="СкидкаВалид")
    url = f"{API}/visits/{visit['id']}/discount"
    for bad in (
        # both percent and amount
        {"discount_percent": "10", "discount_amount": "5", "discount_reason": "x"},
        # neither
        {"discount_reason": "x"},
        # reason missing / blank
        {"discount_percent": "10"},
        {"discount_percent": "10", "discount_reason": "   "},
        # out-of-range values
        {"discount_percent": "0", "discount_reason": "x"},
        {"discount_percent": "150", "discount_reason": "x"},
        {"discount_amount": "-5", "discount_reason": "x"},
        # clear combined with a new discount is ambiguous
        {"clear": True, "discount_percent": "10"},
    ):
        resp = client.post(url, headers=auth, json=bad)
        assert resp.status_code == 422, f"{bad} -> {resp.status_code}: {resp.text}"
    # No discount must have stuck.
    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert refreshed["discount_percent"] is None
    assert refreshed["discount_amount"] is None


def test_discount_amount_cannot_exceed_total(client, auth):
    """A fixed amount larger than the bill is rejected — otherwise the excess
    lies dormant and silently makes services added later free."""
    _, visit = _make_visit(client, auth, last_name="СкидкаПревышение")
    total = Decimal(visit["total_amount"])
    resp = client.post(f"{API}/visits/{visit['id']}/discount", headers=auth,
                       json={"discount_amount": str(total + Decimal("1")),
                             "discount_reason": "Опечатка"})
    assert resp.status_code == 422, resp.text
    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert refreshed["discount_amount"] is None  # nothing stored


def test_full_discount_settles_visit_and_enters_journey(client, auth):
    """A 100% discount leaves nothing to pay; the visit must still enter the
    journey (items paid, flow advanced, ticket minted) instead of stranding."""
    branch_id, visit = _make_visit(client, auth, last_name="СкидкаБесплатно")
    resp = client.post(f"{API}/visits/{visit['id']}/discount", headers=auth,
                       json={"discount_percent": "100", "discount_reason": "Сотрудник"})
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert Decimal(body["payable"]) == Decimal("0.00")
    assert Decimal(body["balance"]) <= Decimal("0.00")
    assert body["flow_status"] == "waiting_diagnostic"
    assert all(it["status"] == "paid" for it in body["items"])
    # A diagnostic ticket was minted for the free visit — with the D-… prefix
    # (regression: the free-settlement path used to pass the track name
    # "diagnostic" as the prefix, minting "diagnostic-001" instead of "D-001").
    tickets = client.get(f"{API}/queue", headers=auth,
                         params={"branch_id": branch_id, "track": "diagnostic"}).json()
    ours = [t for t in tickets if t["visit_id"] == visit["id"]]
    assert ours, "free visit did not enter the diagnostic queue"
    assert ours[0]["ticket_number"].startswith("D-"), ours[0]["ticket_number"]
    _park_visit_tickets(client, auth, branch_id, visit["id"])  # order-independence


def test_full_discount_referral_intent_doctor_mints_doctor_ticket(client, auth):
    """A free (100%-discount) visit with referral_intent='doctor' must route to a
    doctor exactly like a paid «Направлен к врачу» — a doctor-track ticket (NOT a
    D-… diagnostic one), flow at waiting_doctor. Regression: the free-settlement
    path used to ignore referral_intent and always mint a diagnostic ticket."""
    branch_id, visit = _make_visit(client, auth, last_name="СкидкаКВрачу")
    resp = client.post(f"{API}/visits/{visit['id']}/discount", headers=auth,
                       json={"discount_percent": "100", "discount_reason": "Сотрудник",
                             "referral_intent": "doctor"})
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert Decimal(body["balance"]) <= Decimal("0.00")
    assert body["flow_status"] == "waiting_doctor"
    # A doctor-track ticket was minted (not diagnostic).
    doctor_q = client.get(f"{API}/queue", headers=auth,
                          params={"branch_id": branch_id, "track": "doctor"}).json()
    ours = [t for t in doctor_q if t["visit_id"] == visit["id"]]
    assert ours, "free doctor-intent visit did not enter the doctor queue"
    assert not ours[0]["ticket_number"].startswith("D-"), ours[0]["ticket_number"]
    # And no diagnostic ticket leaked out.
    diag_q = client.get(f"{API}/queue", headers=auth,
                        params={"branch_id": branch_id, "track": "diagnostic"}).json()
    assert not any(t["visit_id"] == visit["id"] for t in diag_q)
    _park_visit_tickets(client, auth, branch_id, visit["id"])


def test_full_discount_referral_intent_hold_mints_nothing(client, auth):
    """referral_intent='hold' on a free visit: no ticket, flow parks at
    awaiting_assignment (mirrors the paid «Ожидает назначения» path)."""
    branch_id, visit = _make_visit(client, auth, last_name="СкидкаОжидает")
    resp = client.post(f"{API}/visits/{visit['id']}/discount", headers=auth,
                       json={"discount_percent": "100", "discount_reason": "Сотрудник",
                             "referral_intent": "hold"})
    assert resp.status_code == 200, resp.text
    assert resp.json()["flow_status"] == "awaiting_assignment"
    q = client.get(f"{API}/queue", headers=auth, params={"branch_id": branch_id}).json()
    assert not any(t["visit_id"] == visit["id"] for t in q), "hold must mint no ticket"


def test_finish_appointment_gate_rejects_queue_only_role(client, auth):
    """POST /visits/{id}/finish-appointment is gated on exams.write OR
    visits.update. A queue-only clinical role (Diagnost: has queue.manage +
    visits.read but NOT visits.update / exams.write) must be denied (403) — it
    must not be able to finish a doctor's appointment. Regression: the gate used
    to accept queue.manage, which Diagnost / TreatmentRoom hold."""
    _, visit = _make_visit(client, auth, last_name="ГейтДиагност")
    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "finish.diag@kozshifo.uz", "full_name": "Диагност Гейт",
              "password": "Diag!2026fin", "role_names": ["Diagnost"]},
    )
    assert created.status_code == 201, created.text
    diag_token = client.post(
        f"{API}/auth/login",
        data={"username": "finish.diag@kozshifo.uz", "password": "Diag!2026fin"},
    ).json()["access_token"]
    diag_auth = {"Authorization": f"Bearer {diag_token}"}

    # queue.manage-only role → 403 (not a 404 or 200): the gate refuses it despite
    # the visit existing and the role having visits.read.
    denied = client.post(f"{API}/visits/{visit['id']}/finish-appointment", headers=diag_auth)
    assert denied.status_code == 403, denied.text

    # The privileged setup account (superuser) still finishes fine.
    ok = client.post(f"{API}/visits/{visit['id']}/finish-appointment", headers=auth)
    assert ok.status_code == 200, ok.text


def test_discount_on_closed_or_cancelled_visit_409(client, auth):
    # Pay in full first: close now guards against an outstanding balance (409).
    _, closed = _make_visit(client, auth, last_name="СкидкаЗакрыт", pay=True)
    assert client.post(f"{API}/visits/{closed['id']}/close", headers=auth).status_code == 200
    resp = client.post(f"{API}/visits/{closed['id']}/discount", headers=auth,
                       json={"discount_percent": "10", "discount_reason": "Поздно"})
    assert resp.status_code == 409

    _, cancelled = _make_visit(client, auth, last_name="СкидкаОтмена")
    assert client.post(f"{API}/visits/{cancelled['id']}/cancel", headers=auth).status_code == 200
    resp = client.post(f"{API}/visits/{cancelled['id']}/discount", headers=auth,
                       json={"discount_amount": "5", "discount_reason": "Поздно"})
    assert resp.status_code == 409


def test_discount_clear_rules(client, auth):
    _, visit = _make_visit(client, auth, last_name="СкидкаСброс")
    url = f"{API}/visits/{visit['id']}/discount"
    total = Decimal(visit["total_amount"])

    assert client.post(url, headers=auth,
                       json={"discount_percent": "20", "discount_reason": "Сотрудник"}
                       ).status_code == 200
    cleared = client.post(url, headers=auth, json={"clear": True})
    assert cleared.status_code == 200, cleared.text
    body = cleared.json()
    assert body["discount_percent"] is None
    assert body["discount_amount"] is None
    assert body["discount_reason"] is None
    assert Decimal(body["discount_value"]) == Decimal("0.00")
    assert Decimal(body["payable"]) == total

    # After ANY payment: clearing is forbidden, and a discount that would push
    # payable below the already-paid amount is rejected.
    pay = client.post(f"{API}/payments", headers=auth,
                      json={"visit_id": visit["id"], "amount": "1000.00"})
    assert pay.status_code == 201, pay.text
    assert client.post(url, headers=auth, json={"clear": True}).status_code == 409
    assert client.post(url, headers=auth,
                       json={"discount_percent": "100", "discount_reason": "Бесплатно"}
                       ).status_code == 409


def test_discounted_visit_full_payment_flow(client, auth):
    """Paying exactly `payable` on a discounted visit IS full payment: the flow
    leaves `registered`, items flip to paid and a D ticket is minted. Paying a
    tiyin beyond payable is rejected even though it is under the gross total."""
    branch_id, visit = _make_visit(client, auth, last_name="СкидкаПоток")
    total = Decimal(visit["total_amount"])
    resp = client.post(f"{API}/visits/{visit['id']}/discount", headers=auth,
                       json={"discount_percent": "50", "discount_reason": "Ветеран"})
    assert resp.status_code == 200, resp.text
    payable = Decimal(resp.json()["payable"])
    assert payable < total

    over = client.post(f"{API}/payments", headers=auth,
                       json={"visit_id": visit["id"], "amount": str(payable + Decimal("0.01"))})
    assert over.status_code == 422

    result = client.post(f"{API}/payments", headers=auth,
                         json={"visit_id": visit["id"], "amount": str(payable), "method": "qr"})
    assert result.status_code == 201, result.text
    body = result.json()
    assert Decimal(body["visit_balance"]) == Decimal("0.00")
    assert body["payment"]["method"] == "qr"
    assert body["queue_ticket_number"] and body["queue_ticket_number"].startswith("D-")

    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert refreshed["flow_status"] == "waiting_diagnostic"  # left "registered"
    assert refreshed["items"][0]["status"] == "paid"
    assert Decimal(refreshed["paid_amount"]) == payable

    # cleanup: park the minted ticket
    _park_visit_tickets(client, auth, branch_id, visit["id"])


def test_payment_method_vocabulary(client, auth):
    _, visit = _make_visit(client, auth, last_name="Метод")
    bad = client.post(f"{API}/payments", headers=auth,
                      json={"visit_id": visit["id"], "amount": "1000.00", "method": "bitcoin"})
    assert bad.status_code == 422

    ok = client.post(f"{API}/payments", headers=auth,
                     json={"visit_id": visit["id"], "amount": "1000.00", "method": "qr"})
    assert ok.status_code == 201, ok.text
    assert ok.json()["payment"]["method"] == "qr"
    # The method survives storage and listing.
    listed = client.get(f"{API}/payments", headers=auth,
                        params={"visit_id": visit["id"]}).json()["items"]
    assert listed[0]["method"] == "qr"
