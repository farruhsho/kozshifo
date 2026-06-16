"""Operations & treatments (TZ Modul 6): seeded catalog, doctor referral,
reception scheduling (bills the visit, price override), FEFO write-off on
perform (atomic on shortage), completion, worklist, report, RBAC."""
from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal

from tests.conftest import API

_SCHED_AT = "2026-07-01T09:00:00+00:00"


def _schedule(client, auth, op_id: str, **body):
    """Reception schedules a referred operation (date required)."""
    body.setdefault("scheduled_at", _SCHED_AT)
    return client.post(f"{API}/operations/{op_id}/schedule", headers=auth, json=body)

# PHACO template (seed): sku -> qty written off per operation
_PHACO_CONSUMPTION = {
    "IOL-001": Decimal("1"),
    "VISC-001": Decimal("1"),
    "KNIFE-275": Decimal("1"),
    "SYR-1": Decimal("2"),
    "GLOVES-ST": Decimal("3"),
}


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _product_by_sku(client, auth, sku: str) -> dict:
    items = client.get(f"{API}/inventory/products", headers=auth, params={"q": sku}).json()["items"]
    return next(p for p in items if p["sku"] == sku)


def _on_hand(client, auth, branch_id: str, sku: str) -> Decimal:
    rows = client.get(f"{API}/inventory/stock", headers=auth, params={"branch_id": branch_id}).json()
    return Decimal(next(r for r in rows if r["product"]["sku"] == sku)["on_hand"])


def _receipt(client, auth, branch_id: str, items: list[tuple[str, str]]) -> None:
    """items: [(sku, quantity), ...] — goods-in so write-offs have stock to draw on."""
    resp = client.post(
        f"{API}/inventory/receipts", headers=auth,
        json={
            "branch_id": branch_id,
            "items": [
                {"product_id": _product_by_sku(client, auth, sku)["id"], "quantity": qty}
                for sku, qty in items
            ],
        },
    )
    assert resp.status_code == 201, resp.text


def _new_visit(client, auth, branch_id: str, suffix: str) -> dict:
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Опер", "last_name": f"Тестов-{suffix}",
              "phone": "+998900000000", "branch_id": branch_id},
    ).json()
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "items": []},
    ).json()
    return visit


def _operation_type(client, auth, code: str) -> dict:
    types = client.get(f"{API}/operation-types", headers=auth).json()
    return next(t for t in types if t["code"] == code)


def test_operation_types_seeded(client, auth):
    phaco = _operation_type(client, auth, "PHACO")
    assert phaco["price"] == "5000000.00"
    assert len(phaco["consumables"]) == 5
    by_name = {c["product_name"]: Decimal(c["quantity"]) for c in phaco["consumables"]}
    assert by_name["Шприц 1 мл"] == Decimal("2")
    assert by_name["Перчатки стерильные (пара)"] == Decimal("3")

    ivi = _operation_type(client, auth, "IVI")
    assert ivi["price"] == "1500000.00"
    assert len(ivi["consumables"]) == 2


def test_refer_does_not_bill_then_schedule_bills_the_visit(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "bill")
    assert Decimal(visit["total_amount"]) == Decimal("0.00")
    phaco = _operation_type(client, auth, "PHACO")

    # 1) Doctor refers — recorded, NOT billed.
    created = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": phaco["id"], "eye": "od", "notes": "катаракта OD"},
    )
    assert created.status_code == 201, created.text
    operation = created.json()
    assert operation["status"] == "referred"
    assert operation["price"] is None
    assert operation["referring_doctor_id"] is not None
    assert operation["type_name"] == "Факоэмульсификация катаракты с ИОЛ"
    assert Decimal(client.get(f"{API}/visits/{visit['id']}", headers=auth)
                   .json()["total_amount"]) == Decimal("0.00")

    # 2) Reception schedules — now the linked service lands on the visit.
    scheduled = _schedule(client, auth, operation["id"])
    assert scheduled.status_code == 200, scheduled.text
    sched = scheduled.json()
    assert sched["status"] == "scheduled"
    assert Decimal(sched["price"]) == Decimal("5000000.00")
    assert sched["scheduled_at"] is not None

    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert Decimal(refreshed["total_amount"]) == Decimal("5000000.00")
    billed = [i for i in refreshed["items"] if i["service_name"] == "Факоэмульсификация катаракты с ИОЛ"]
    assert len(billed) == 1
    assert Decimal(billed[0]["total"]) == Decimal("5000000.00")

    listed = client.get(f"{API}/visits/{visit['id']}/operations", headers=auth).json()
    assert [o["id"] for o in listed] == [operation["id"]]


def test_schedule_price_override(client, auth):
    """Reception may override the catalog price; the visit bills the override."""
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "override")
    ivi = _operation_type(client, auth, "IVI")  # catalog 1 500 000
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"]}).json()

    scheduled = _schedule(client, auth, op["id"], price="1200000")
    assert scheduled.status_code == 200, scheduled.text
    assert Decimal(scheduled.json()["price"]) == Decimal("1200000.00")
    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert Decimal(refreshed["total_amount"]) == Decimal("1200000.00")

    # Re-schedule (still unpaid) adjusts the same billed line, not a second one.
    again = _schedule(client, auth, op["id"], price="1000000")
    assert again.status_code == 200, again.text
    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert len(refreshed["items"]) == 1
    assert Decimal(refreshed["total_amount"]) == Decimal("1000000.00")


def test_perform_writes_off_fefo_and_blocks_on_shortage(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "perform")
    phaco = _operation_type(client, auth, "PHACO")
    operation = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": phaco["id"]},
    ).json()
    # A bare referral cannot be performed — it must be scheduled first.
    too_early = client.post(f"{API}/operations/{operation['id']}/perform", headers=auth)
    assert too_early.status_code == 409, too_early.text
    assert _schedule(client, auth, operation["id"]).status_code == 200

    # Stock everything generously EXCEPT the knife — exactly 1 IOL, no KNIFE-275.
    _receipt(client, auth, branch_id, [
        ("IOL-001", "1"), ("VISC-001", "5"), ("SYR-1", "20"), ("GLOVES-ST", "20"),
    ])
    before = {sku: _on_hand(client, auth, branch_id, sku) for sku in _PHACO_CONSUMPTION}
    assert before["KNIFE-275"] == Decimal("0")

    # Shortage of one consumable blocks the whole perform…
    denied = client.post(f"{API}/operations/{operation['id']}/perform", headers=auth)
    assert denied.status_code == 409, denied.text
    assert "Нож офтальмологический" in denied.json()["detail"]
    assert "available 0" in denied.json()["detail"]

    # …and is atomic: nothing was consumed from the products that WERE available.
    after_denied = {sku: _on_hand(client, auth, branch_id, sku) for sku in _PHACO_CONSUMPTION}
    assert after_denied == before
    still_scheduled = client.get(f"{API}/visits/{visit['id']}/operations", headers=auth).json()[0]
    assert still_scheduled["status"] == "scheduled"

    # Receive the missing knife -> perform succeeds and decrements per template.
    _receipt(client, auth, branch_id, [("KNIFE-275", "1")])
    done = client.post(f"{API}/operations/{operation['id']}/perform", headers=auth)
    assert done.status_code == 200, done.text
    assert done.json()["status"] == "performed"
    assert done.json()["performed_at"] is not None

    for sku, qty in _PHACO_CONSUMPTION.items():
        expected = before[sku] - qty if sku != "KNIFE-275" else Decimal("0")
        assert _on_hand(client, auth, branch_id, sku) == expected, sku


def test_perform_with_adhoc_consumables(client, auth):
    """Ф4a: reception logs EXTRA (ad-hoc) products used during a perform — they
    are written off alongside the template via the same FEFO, atomically."""
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "adhoc")
    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"]}).json()
    assert _schedule(client, auth, op["id"]).status_code == 200

    # An ad-hoc product that is NOT in the PHACO template (an extra suture).
    extra = client.post(f"{API}/inventory/products", headers=auth, json={
        "sku": "ADHOC-SUTURE", "name": "Шов доп.", "unit": "шт",
    })
    assert extra.status_code == 201, extra.text
    extra = extra.json()

    # Stock the full template + 1 suture (the perform will ask for 2 → short).
    _receipt(client, auth, branch_id, [
        ("IOL-001", "1"), ("VISC-001", "5"), ("SYR-1", "20"),
        ("GLOVES-ST", "20"), ("KNIFE-275", "1"), ("ADHOC-SUTURE", "1"),
    ])
    body = {"ad_hoc_consumables": [{"product_id": extra["id"], "quantity": "2"}]}

    # Ad-hoc shortage blocks the WHOLE perform atomically (template untouched).
    before = {sku: _on_hand(client, auth, branch_id, sku) for sku in _PHACO_CONSUMPTION}
    denied = client.post(f"{API}/operations/{op['id']}/perform", headers=auth, json=body)
    assert denied.status_code == 409, denied.text
    assert "Шов доп." in denied.json()["detail"]
    assert {sku: _on_hand(client, auth, branch_id, sku)
            for sku in _PHACO_CONSUMPTION} == before

    # Receive the missing suture → perform writes off template AND ad-hoc.
    _receipt(client, auth, branch_id, [("ADHOC-SUTURE", "1")])
    done = client.post(f"{API}/operations/{op['id']}/perform", headers=auth, json=body)
    assert done.status_code == 200, done.text
    assert done.json()["status"] == "performed"
    for sku, qty in _PHACO_CONSUMPTION.items():
        assert _on_hand(client, auth, branch_id, sku) == before[sku] - qty, sku
    assert _on_hand(client, auth, branch_id, "ADHOC-SUTURE") == Decimal("0")  # 2 used


def test_perform_adhoc_aggregates_duplicate_product(client, auth):
    """Two ad-hoc lines of the SAME product sum to one demand — the pre-check
    409 reports the cumulative total, not a single line's quantity."""
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "dup")
    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"]}).json()
    assert _schedule(client, auth, op["id"]).status_code == 200
    _receipt(client, auth, branch_id, [
        ("IOL-001", "1"), ("VISC-001", "5"), ("SYR-1", "20"),
        ("GLOVES-ST", "20"), ("KNIFE-275", "1"),
    ])
    # A fresh ad-hoc product with only 3 on hand, requested twice (2 + 2 = 4).
    dup = client.post(f"{API}/inventory/products", headers=auth, json={
        "sku": "ADHOC-DUP", "name": "Дубль-расходник", "unit": "шт",
    }).json()
    _receipt(client, auth, branch_id, [("ADHOC-DUP", "3")])

    body = {"ad_hoc_consumables": [
        {"product_id": dup["id"], "quantity": "2"},
        {"product_id": dup["id"], "quantity": "2"},
    ]}
    denied = client.post(f"{API}/operations/{op['id']}/perform", headers=auth, json=body)
    assert denied.status_code == 409, denied.text
    assert "Дубль-расходник" in denied.json()["detail"]
    # Cumulative 2+2=4 is reported (not a single line's 2).
    assert "requested 4" in denied.json()["detail"]


def test_start_perform_complete_lifecycle(client, auth):
    """scheduled -> in_progress -> performed -> completed, with the outcome
    recorded on the operation (TZ Modul 6)."""
    branch_id = _branch_id(client, auth)
    _receipt(client, auth, branch_id, [("SYR-1", "5"), ("GLOVES-ST", "5")])
    visit = _new_visit(client, auth, branch_id, "lifecycle")
    ivi = _operation_type(client, auth, "IVI")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"], "eye": "os"}).json()
    assert _schedule(client, auth, op["id"]).status_code == 200

    started = client.post(f"{API}/operations/{op['id']}/start", headers=auth)
    assert started.status_code == 200, started.text
    assert started.json()["status"] == "in_progress"

    performed = client.post(f"{API}/operations/{op['id']}/perform", headers=auth)
    assert performed.status_code == 200, performed.text
    assert performed.json()["status"] == "performed"

    completed = client.post(f"{API}/operations/{op['id']}/complete", headers=auth,
                            json={"result": "Без осложнений"})
    assert completed.status_code == 200, completed.text
    assert completed.json()["status"] == "completed"
    assert completed.json()["result"] == "Без осложнений"
    assert completed.json()["completed_at"] is not None


def test_perform_twice_and_cancel_after_performed_409(client, auth):
    branch_id = _branch_id(client, auth)
    _receipt(client, auth, branch_id, [("SYR-1", "5"), ("GLOVES-ST", "5")])
    visit = _new_visit(client, auth, branch_id, "twice")
    ivi = _operation_type(client, auth, "IVI")
    operation = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": ivi["id"], "eye": "os"},
    ).json()
    assert _schedule(client, auth, operation["id"]).status_code == 200

    assert client.post(f"{API}/operations/{operation['id']}/perform", headers=auth).status_code == 200
    again = client.post(f"{API}/operations/{operation['id']}/perform", headers=auth)
    assert again.status_code == 409

    cancelled = client.post(f"{API}/operations/{operation['id']}/cancel", headers=auth)
    assert cancelled.status_code == 409  # performed operations cannot be cancelled


def test_treatment_medication_dispense(client, auth):
    branch_id = _branch_id(client, auth)
    _receipt(client, auth, branch_id, [("SYR-1", "10")])
    visit = _new_visit(client, auth, branch_id, "med")
    syr = _product_by_sku(client, auth, "SYR-1")

    # medication without product/quantity is rejected
    invalid = client.post(
        f"{API}/visits/{visit['id']}/treatments", headers=auth,
        json={"kind": "medication", "name": "Шприцы без товара"},
    )
    assert invalid.status_code == 422

    treatment = client.post(
        f"{API}/visits/{visit['id']}/treatments", headers=auth,
        json={"kind": "medication", "name": "Шприцы для инъекций",
              "product_id": syr["id"], "quantity": "5", "instructions": "1 раз в день"},
    )
    assert treatment.status_code == 201, treatment.text
    treatment = treatment.json()
    assert treatment["status"] == "prescribed"

    before = _on_hand(client, auth, branch_id, "SYR-1")
    dispensed = client.post(f"{API}/treatments/{treatment['id']}/dispense", headers=auth)
    assert dispensed.status_code == 200, dispensed.text
    assert dispensed.json()["status"] == "done"
    assert _on_hand(client, auth, branch_id, "SYR-1") == before - Decimal("5")

    # Already dispensed -> 409, stock untouched.
    again = client.post(f"{API}/treatments/{treatment['id']}/dispense", headers=auth)
    assert again.status_code == 409
    assert _on_hand(client, auth, branch_id, "SYR-1") == before - Decimal("5")

    # History is visible per visit and per patient.
    by_visit = client.get(f"{API}/visits/{visit['id']}/treatments", headers=auth).json()
    assert [t["id"] for t in by_visit] == [treatment["id"]]
    by_patient = client.get(f"{API}/patients/{visit['patient_id']}/treatments", headers=auth).json()
    assert treatment["id"] in [t["id"] for t in by_patient]


def test_clinical_rbac(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "rbac")
    phaco = _operation_type(client, auth, "PHACO")

    created = client.post(
        f"{API}/users", headers=auth,
        json={"email": "op.cashier@kozshifo.uz", "full_name": "Кассир Операций",
              "password": "Kassa!2026", "role_names": ["Cashier"]},
    )
    assert created.status_code == 201, created.text
    token = client.post(
        f"{API}/auth/login", data={"username": "op.cashier@kozshifo.uz", "password": "Kassa!2026"}
    ).json()["access_token"]
    cashier_auth = {"Authorization": f"Bearer {token}"}

    denied = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=cashier_auth,
        json={"operation_type_id": phaco["id"]},
    )
    assert denied.status_code == 403
    assert "operations.prescribe" in denied.json()["detail"]


def test_cancel_scheduled_operation_debills_the_visit(client, auth):
    """Cancelling a scheduled (unpaid) operation removes its billed item."""
    visit_id = _new_visit(client, auth, _branch_id(client, auth), "debill")["id"]
    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"], "eye": "od"}).json()
    assert _schedule(client, auth, op["id"]).status_code == 200
    before = client.get(f"{API}/visits/{visit_id}", headers=auth).json()
    assert Decimal(before["total_amount"]) == Decimal("5000000.00")

    cancelled = client.post(f"{API}/operations/{op['id']}/cancel", headers=auth)
    assert cancelled.status_code == 200, cancelled.text
    after = client.get(f"{API}/visits/{visit_id}", headers=auth).json()
    assert Decimal(after["total_amount"]) == Decimal("0.00")
    assert after["items"] == []


def test_cancel_bare_referral_has_no_bill(client, auth):
    """A referral that was never scheduled has nothing to de-bill."""
    visit_id = _new_visit(client, auth, _branch_id(client, auth), "refcancel")["id"]
    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"]}).json()
    cancelled = client.post(f"{API}/operations/{op['id']}/cancel", headers=auth)
    assert cancelled.status_code == 200, cancelled.text
    assert cancelled.json()["status"] == "cancelled"
    after = client.get(f"{API}/visits/{visit_id}", headers=auth).json()
    assert Decimal(after["total_amount"]) == Decimal("0.00")


def test_cancel_paid_operation_requires_refund_first(client, auth):
    visit_id = _new_visit(client, auth, _branch_id(client, auth), "paidcancel")["id"]
    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"], "eye": "ou"}).json()
    assert _schedule(client, auth, op["id"]).status_code == 200
    visit = client.get(f"{API}/visits/{visit_id}", headers=auth).json()
    # issue_queue_ticket=False: a stray waiting ticket would hijack call-next
    # in the patient-journey test that shares this session DB.
    client.post(f"{API}/payments", headers=auth,
                json={"visit_id": visit_id, "amount": visit["balance"],
                      "issue_queue_ticket": False})

    denied = client.post(f"{API}/operations/{op['id']}/cancel", headers=auth)
    assert denied.status_code == 409
    assert "refund" in denied.json()["detail"].lower()


def test_perform_blocked_on_cancelled_visit(client, auth):
    """A visit cancelled at reception must not let its operation consume stock."""
    visit_id = _new_visit(client, auth, _branch_id(client, auth), "deadvisit")["id"]
    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"], "eye": "os"}).json()
    assert _schedule(client, auth, op["id"]).status_code == 200
    # Reception aborts the (unpaid) visit; the scheduled operation must die with it.
    cancelled = client.post(f"{API}/visits/{visit_id}/cancel", headers=auth)
    assert cancelled.status_code == 200, cancelled.text

    denied = client.post(f"{API}/operations/{op['id']}/perform", headers=auth)
    assert denied.status_code == 409
    assert "cancelled visit" in denied.json()["detail"]

    # Treatments are equally guarded on dead visits.
    t_denied = client.post(f"{API}/visits/{visit_id}/treatments", headers=auth,
                           json={"kind": "procedure", "name": "Тест"})
    assert t_denied.status_code == 409


def test_operations_worklist(client, auth):
    """The department worklist surfaces referred/scheduled operations and
    filters by status."""
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "worklist")
    ivi = _operation_type(client, auth, "IVI")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"], "priority": "urgent",
                           "notes": "срочно"}).json()

    referred = client.get(f"{API}/operations", headers=auth, params={"status": "referred"})
    assert referred.status_code == 200, referred.text
    ids = [o["id"] for o in referred.json()]
    assert op["id"] in ids
    row = next(o for o in referred.json() if o["id"] == op["id"])
    assert row["patient_name"]  # enriched for the worklist
    assert row["priority"] == "urgent"

    # After scheduling it leaves the "referred" filter and enters "scheduled".
    assert _schedule(client, auth, op["id"]).status_code == 200
    assert op["id"] not in [o["id"] for o in
                            client.get(f"{API}/operations", headers=auth,
                                       params={"status": "referred"}).json()]
    assert op["id"] in [o["id"] for o in
                        client.get(f"{API}/operations", headers=auth,
                                   params={"status": "scheduled"}).json()]


def test_operations_report_by_surgeon(client, auth):
    """Period report counts performed operations and breaks revenue down by surgeon."""
    branch_id = _branch_id(client, auth)
    _receipt(client, auth, branch_id, [("SYR-1", "10"), ("GLOVES-ST", "10")])
    # A surgeon to attribute the operation to.
    surgeon = client.post(f"{API}/users", headers=auth,
                          json={"email": "surgeon.rep@kozshifo.uz", "full_name": "Жаррох Тестов",
                                "password": "Vrach!2026", "role_names": ["Doctor"]}).json()
    visit = _new_visit(client, auth, branch_id, "report")
    ivi = _operation_type(client, auth, "IVI")
    op = client.post(f"{API}/visits/{visit['id']}/operations", headers=auth,
                     json={"operation_type_id": ivi["id"]}).json()
    assert _schedule(client, auth, op["id"], surgeon_id=surgeon["id"], price="900000").status_code == 200
    assert client.post(f"{API}/operations/{op['id']}/perform", headers=auth).status_code == 200

    report = client.get(f"{API}/operations/report", headers=auth,
                        params={"date_from": "2020-01-01T00:00:00+00:00",
                                "date_to": "2100-01-01T00:00:00+00:00"})
    assert report.status_code == 200, report.text
    data = report.json()
    assert data["count"] >= 1
    surgeons = {s["surgeon_id"]: s for s in data["by_surgeon"]}
    assert surgeon["id"] in surgeons
    assert Decimal(surgeons[surgeon["id"]]["total_amount"]) >= Decimal("900000.00")
