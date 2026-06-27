"""Treatment optional billing (C5): a treatment linked to a service bills a
VisitItem so the revenue surfaces in finance/reports; cancelling de-bills it
(refund-first when already paid); an unlinked treatment stays unbilled
(clinical-only — the previous behaviour, preserved)."""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _service(client, auth, code, price) -> dict:
    r = client.post(f"{API}/services", headers=auth,
                    json={"code": code, "name": f"Лечебная {code}", "price": price})
    assert r.status_code in (200, 201), r.text
    return r.json()


def _visit(client, auth, branch, last) -> dict:
    p = client.post(f"{API}/patients", headers=auth,
                    json={"first_name": "Леч", "last_name": last, "branch_id": branch}).json()
    return client.post(f"{API}/visits", headers=auth,
                       json={"patient_id": p["id"], "branch_id": branch, "items": []}).json()


def _balance(client, auth, vid) -> Decimal:
    return Decimal(client.get(f"{API}/visits/{vid}", headers=auth).json()["balance"])


def _prescribe(client, auth, vid, **body):
    body.setdefault("kind", "procedure")
    body.setdefault("name", "Капельница")
    return client.post(f"{API}/visits/{vid}/treatments", headers=auth, json=body)


def test_treatment_with_service_bills_the_visit(client, auth):
    branch = _branch(client, auth)
    svc = _service(client, auth, "TX-DROP", "150000")
    visit = _visit(client, auth, branch, "Билл")
    assert _balance(client, auth, visit["id"]) == Decimal("0")

    r = _prescribe(client, auth, visit["id"], service_id=svc["id"])
    assert r.status_code == 201, r.text
    tx = r.json()
    assert tx["service_id"] == svc["id"]
    assert tx["visit_item_id"] is not None
    assert _balance(client, auth, visit["id"]) == Decimal("150000")  # now billed


def test_treatment_price_override(client, auth):
    branch = _branch(client, auth)
    svc = _service(client, auth, "TX-OVR", "150000")
    visit = _visit(client, auth, branch, "Овр")
    r = _prescribe(client, auth, visit["id"], service_id=svc["id"], unit_price="90000")
    assert r.status_code == 201, r.text
    assert _balance(client, auth, visit["id"]) == Decimal("90000")  # override, not catalog


def test_unlinked_treatment_is_unbilled(client, auth):
    branch = _branch(client, auth)
    visit = _visit(client, auth, branch, "Беспл")
    r = _prescribe(client, auth, visit["id"])  # no service_id → clinical-only
    assert r.status_code == 201, r.text
    assert r.json()["visit_item_id"] is None
    assert _balance(client, auth, visit["id"]) == Decimal("0")


def test_cancel_billed_treatment_debills(client, auth):
    branch = _branch(client, auth)
    svc = _service(client, auth, "TX-CANCEL", "200000")
    visit = _visit(client, auth, branch, "Отмена")
    tx = _prescribe(client, auth, visit["id"], service_id=svc["id"]).json()
    assert _balance(client, auth, visit["id"]) == Decimal("200000")

    c = client.post(f"{API}/treatments/{tx['id']}/cancel", headers=auth)
    assert c.status_code == 200, c.text
    assert _balance(client, auth, visit["id"]) == Decimal("0")  # de-billed


def test_cancel_paid_treatment_requires_refund_first(client, auth):
    branch = _branch(client, auth)
    svc = _service(client, auth, "TX-PAID", "120000")
    visit = _visit(client, auth, branch, "Оплач")
    tx = _prescribe(client, auth, visit["id"], service_id=svc["id"]).json()
    pay = client.post(f"{API}/payments", headers=auth,
                      json={"visit_id": visit["id"], "amount": "120000",
                            "issue_queue_ticket": False})
    assert pay.status_code in (200, 201), pay.text

    c = client.post(f"{API}/treatments/{tx['id']}/cancel", headers=auth)
    assert c.status_code == 409, c.text
    assert "refund" in c.json()["detail"].lower()
