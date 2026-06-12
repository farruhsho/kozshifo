"""Manual live exercise of Phase 4: file upload -> download; low-stock alert; KPI.

Run:  ./.venv/Scripts/python.exe scripts/manual_phase4.py
"""
from __future__ import annotations

import sys

import httpx

API = "http://127.0.0.1:8000/api/v1"
PNG = b"\x89PNG\r\n\x1a\n" + b"fakepngdata" * 100


def main() -> int:
    c = httpx.Client(base_url=API, timeout=20)
    token = c.post("/auth/login", data={
        "username": "director@kozshifo.uz", "password": "Director!2026",
    }).json()["access_token"]
    c.headers["Authorization"] = f"Bearer {token}"
    branch_id = c.get("/branches").json()[0]["id"]
    print("[1] login OK")

    patient = c.post("/patients", json={
        "first_name": "Файл", "last_name": "Тестов", "branch_id": branch_id}).json()
    visit = c.post("/visits", json={
        "patient_id": patient["id"], "branch_id": branch_id}).json()
    cas = next(d for d in c.get("/devices").json()["items"]
               if d["model"] == "CAS-2000BER")
    up = c.post(f"/devices/{cas['id']}/results/file",
                files={"file": ("bscan-od.png", PNG, "image/png")},
                data={"visit_id": visit["id"]})
    assert up.status_code == 201, up.text
    result = up.json()
    assert result["result_type"] == "bscan_image"
    assert result["payload"]["original_name"] == "bscan-od.png"
    print(f"[2] uploaded {len(PNG)} bytes -> result {result['id'][:8]}…")

    down = c.get(f"/device-results/{result['id']}/file")
    assert down.status_code == 200 and down.content == PNG
    assert down.headers["content-type"].startswith("image/png")
    print("[3] downloaded byte-identical, image/png")

    products = {p["sku"]: p for p in c.get("/inventory/products",
                                           params={"limit": 500}).json()["items"]}
    syr = products["SYR-1"]  # min_stock 50
    c.post("/inventory/receipts", json={
        "branch_id": branch_id,
        "items": [{"product_id": syr["id"], "quantity": "51", "unit_cost": "2000"}]})
    c.post("/inventory/write-off", json={
        "product_id": syr["id"], "branch_id": branch_id,
        "quantity": "2", "reason": "тест"})  # 49 <= 50 -> alert
    notes = c.get("/notifications").json()
    low = [n for n in notes if n["event"] == "low_stock" and n["ref_id"] == syr["id"]]
    assert low and low[0]["status"] == "sent" and low[0]["channel"] == "log"
    print(f"[4] low-stock alert fired: «{low[0]['title']}» (telegram skipped, no token)")

    kpi = c.get("/dashboard/summary").json()
    assert {"operations_today", "operations_month",
            "low_stock_count", "expiring_soon_count"} <= kpi.keys()
    assert kpi["low_stock_count"] >= 5
    print(f"[5] KPI: low_stock={kpi['low_stock_count']}, expiring_soon={kpi['expiring_soon_count']}, "
          f"ops_today={kpi['operations_today']} — Phase-4 happy path complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
