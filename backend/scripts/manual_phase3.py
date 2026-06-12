"""Manual live exercise of Phase 3: warehouse -> operation -> auto write-off.

receipt stock -> patient+visit -> prescribe PHACO (bills 5,000,000) -> pay ->
perform (FEFO write-off) -> stock decremented -> treatment dispense.
Run:  ./.venv/Scripts/python.exe scripts/manual_phase3.py
"""
from __future__ import annotations

import sys
from decimal import Decimal

import httpx

API = "http://127.0.0.1:8000/api/v1"


def main() -> int:
    c = httpx.Client(base_url=API, timeout=20)
    token = c.post("/auth/login", data={
        "username": "director@kozshifo.uz", "password": "Director!2026",
    }).json()["access_token"]
    c.headers["Authorization"] = f"Bearer {token}"
    branch_id = c.get("/branches").json()[0]["id"]
    print("[1] login OK")

    products = {p["sku"]: p for p in c.get("/inventory/products",
                                           params={"limit": 200}).json()["items"]}
    receipt = c.post("/inventory/receipts", json={
        "branch_id": branch_id,
        "items": [
            {"product_id": products["IOL-001"]["id"], "quantity": "10", "unit_cost": "1200000",
             "batch_no": "IOL-B1", "expiry_date": "2028-01-01"},
            {"product_id": products["VISC-001"]["id"], "quantity": "20", "unit_cost": "350000",
             "batch_no": "V-B1", "expiry_date": "2027-06-01"},
            {"product_id": products["KNIFE-275"]["id"], "quantity": "15", "unit_cost": "90000"},
            {"product_id": products["SYR-1"]["id"], "quantity": "100", "unit_cost": "2000"},
            {"product_id": products["GLOVES-ST"]["id"], "quantity": "200", "unit_cost": "8000"},
        ],
    })
    assert receipt.status_code == 201, receipt.text
    print("[2] receipt: 5 positions on stock")

    patient = c.post("/patients", json={
        "first_name": "Фаза", "last_name": "Третья", "branch_id": branch_id}).json()
    visit = c.post("/visits", json={
        "patient_id": patient["id"], "branch_id": branch_id}).json()
    phaco = next(t for t in c.get("/operation-types").json() if t["code"] == "PHACO")
    assert len(phaco["consumables"]) == 5
    op = c.post(f"/visits/{visit['id']}/operations",
                json={"operation_type_id": phaco["id"], "eye": "od",
                      "notes": "OD, катаракта"})
    assert op.status_code == 201, op.text
    visit2 = c.get(f"/visits/{visit['id']}").json()
    assert Decimal(visit2["total_amount"]) == Decimal("5000000.00"), visit2["total_amount"]
    print(f"[3] PHACO назначена, визит выставлен на {visit2['total_amount']}")

    pay = c.post("/payments", json={"visit_id": visit["id"],
                                    "amount": visit2["balance"], "room": "Опер. блок"})
    assert pay.status_code == 201, pay.text
    print(f"[4] оплачено, чек {pay.json()['payment']['receipt_no']}")

    done = c.post(f"/operations/{op.json()['id']}/perform")
    assert done.status_code == 200, done.text
    assert done.json()["status"] == "done"
    stock = {r["product"]["sku"]: r for r in
             c.get("/inventory/stock", params={"branch_id": branch_id}).json()}
    assert stock["IOL-001"]["on_hand"] == "9.000", stock["IOL-001"]["on_hand"]
    assert stock["SYR-1"]["on_hand"] == "98.000"   # 2 на операцию
    assert stock["GLOVES-ST"]["on_hand"] == "197.000"  # 3 пары
    print("[5] операция выполнена, FEFO-списание: IOL 10->9, SYR 100->98, GLOVES 200->197")

    tr = c.post(f"/visits/{visit['id']}/treatments", json={
        "kind": "medication", "name": "Шприц для инъекции",
        "product_id": products["SYR-1"]["id"], "quantity": "3"})
    assert tr.status_code == 201, tr.text
    disp = c.post(f"/treatments/{tr.json()['id']}/dispense")
    assert disp.status_code == 200, disp.text
    stock2 = {r["product"]["sku"]: r for r in
              c.get("/inventory/stock", params={"branch_id": branch_id}).json()}
    assert stock2["SYR-1"]["on_hand"] == "95.000"
    print("[6] назначение выдано: SYR 98->95 — Phase-3 happy path complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
