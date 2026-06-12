"""Operations & treatments: seeded catalog, billing on prescribe, FEFO write-off
on perform (atomic on shortage), medication dispense, RBAC."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API

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


def test_prescribe_bills_the_visit(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "bill")
    assert Decimal(visit["total_amount"]) == Decimal("0.00")
    phaco = _operation_type(client, auth, "PHACO")

    created = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": phaco["id"], "eye": "od"},
    )
    assert created.status_code == 201, created.text
    operation = created.json()
    assert operation["status"] == "planned"
    assert operation["type_name"] == "Факоэмульсификация катаракты с ИОЛ"
    assert operation["eye"] == "od"

    # The linked service landed on the visit as a billed item.
    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert Decimal(refreshed["total_amount"]) == Decimal("5000000.00")
    billed = [i for i in refreshed["items"] if i["service_name"] == "Факоэмульсификация катаракты с ИОЛ"]
    assert len(billed) == 1
    assert Decimal(billed[0]["total"]) == Decimal("5000000.00")

    # And it shows up in the visit's operation list.
    listed = client.get(f"{API}/visits/{visit['id']}/operations", headers=auth).json()
    assert [o["id"] for o in listed] == [operation["id"]]


def test_perform_writes_off_fefo_and_blocks_on_shortage(client, auth):
    branch_id = _branch_id(client, auth)
    visit = _new_visit(client, auth, branch_id, "perform")
    phaco = _operation_type(client, auth, "PHACO")
    operation = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": phaco["id"]},
    ).json()

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
    still_planned = client.get(f"{API}/visits/{visit['id']}/operations", headers=auth).json()[0]
    assert still_planned["status"] == "planned"

    # Receive the missing knife -> perform succeeds and decrements per template.
    _receipt(client, auth, branch_id, [("KNIFE-275", "1")])
    done = client.post(f"{API}/operations/{operation['id']}/perform", headers=auth)
    assert done.status_code == 200, done.text
    assert done.json()["status"] == "done"
    assert done.json()["performed_at"] is not None

    for sku, qty in _PHACO_CONSUMPTION.items():
        expected = before[sku] - qty if sku != "KNIFE-275" else Decimal("0")
        assert _on_hand(client, auth, branch_id, sku) == expected, sku


def test_perform_twice_and_cancel_after_done_409(client, auth):
    branch_id = _branch_id(client, auth)
    _receipt(client, auth, branch_id, [("SYR-1", "5"), ("GLOVES-ST", "5")])
    visit = _new_visit(client, auth, branch_id, "twice")
    ivi = _operation_type(client, auth, "IVI")
    operation = client.post(
        f"{API}/visits/{visit['id']}/operations", headers=auth,
        json={"operation_type_id": ivi["id"], "eye": "os"},
    ).json()

    assert client.post(f"{API}/operations/{operation['id']}/perform", headers=auth).status_code == 200
    again = client.post(f"{API}/operations/{operation['id']}/perform", headers=auth)
    assert again.status_code == 409

    cancelled = client.post(f"{API}/operations/{operation['id']}/cancel", headers=auth)
    assert cancelled.status_code == 409  # done operations cannot be cancelled


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


def test_cancel_planned_operation_debills_the_visit(client, auth):
    """Cancelling a planned (unpaid) operation removes its billed item."""
    visit_id = _new_visit(client, auth, _branch_id(client, auth), "debill")["id"]
    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"], "eye": "od"}).json()
    before = client.get(f"{API}/visits/{visit_id}", headers=auth).json()
    assert Decimal(before["total_amount"]) == Decimal("5000000.00")

    cancelled = client.post(f"{API}/operations/{op['id']}/cancel", headers=auth)
    assert cancelled.status_code == 200, cancelled.text
    after = client.get(f"{API}/visits/{visit_id}", headers=auth).json()
    assert Decimal(after["total_amount"]) == Decimal("0.00")
    assert after["items"] == []


def test_cancel_paid_operation_requires_refund_first(client, auth):
    visit_id = _new_visit(client, auth, _branch_id(client, auth), "paidcancel")["id"]
    phaco = _operation_type(client, auth, "PHACO")
    op = client.post(f"{API}/visits/{visit_id}/operations", headers=auth,
                     json={"operation_type_id": phaco["id"], "eye": "ou"}).json()
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
    # Reception aborts the (unpaid) visit; the planned operation must die with it.
    cancelled = client.post(f"{API}/visits/{visit_id}/cancel", headers=auth)
    assert cancelled.status_code == 200, cancelled.text

    denied = client.post(f"{API}/operations/{op['id']}/perform", headers=auth)
    assert denied.status_code == 409
    assert "cancelled visit" in denied.json()["detail"]

    # Treatments are equally guarded on dead visits.
    t_denied = client.post(f"{API}/visits/{visit_id}/treatments", headers=auth,
                           json={"kind": "procedure", "name": "Тест"})
    assert t_denied.status_code == 409
