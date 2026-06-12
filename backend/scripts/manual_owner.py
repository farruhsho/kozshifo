"""Manual live exercise of Owner Automation: auto flow statuses, timeline, insights.

Run:  ./.venv/Scripts/python.exe scripts/manual_owner.py  (server on :8000, fresh DB)
"""
from __future__ import annotations

import sys

import httpx

API = "http://127.0.0.1:8000/api/v1"


def flow(c, visit_id):
    return c.get(f"/visits/{visit_id}").json()["flow_status"]


def main() -> int:
    c = httpx.Client(base_url=API, timeout=20)
    token = c.post("/auth/login", data={"username": "director@kozshifo.uz",
                                        "password": "Director!2026"}).json()["access_token"]
    c.headers["Authorization"] = f"Bearer {token}"
    branch_id = c.get("/branches").json()[0]["id"]
    svc = c.get("/services").json()["items"][0]

    patient = c.post("/patients", json={"first_name": "Авто", "last_name": "Поточный",
                                        "branch_id": branch_id}).json()
    visit = c.post("/visits", json={"patient_id": patient["id"], "branch_id": branch_id,
                                    "items": [{"service_id": svc["id"], "quantity": 1}]}).json()
    assert flow(c, visit["id"]) == "registered"
    print("[1] visit registered")

    c.post("/payments", json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert flow(c, visit["id"]) == "waiting_diagnostic"
    print("[2] paid -> waiting_diagnostic (авто)")

    called = c.post("/queue/call-next", json={"branch_id": branch_id, "room": "Каб. 2",
                                              "track": "diagnostic"}).json()
    assert flow(c, visit["id"]) == "in_diagnostic"
    c.post(f"/queue/{called['id']}/done")
    assert flow(c, visit["id"]) == "waiting_doctor"
    print("[3] diagnostics done -> waiting_doctor (авто, V-талон создан)")

    v_called = c.post("/queue/call-next", json={"branch_id": branch_id, "room": "Каб. 5",
                                                "track": "doctor"}).json()
    assert flow(c, visit["id"]) == "in_doctor"
    tr = c.post(f"/visits/{visit['id']}/treatments",
                json={"kind": "procedure", "name": "Промывание"})
    assert flow(c, visit["id"]) == "treatment_assigned"
    c.post(f"/queue/{v_called['id']}/done")
    assert flow(c, visit["id"]) == "follow_up"
    print("[4] приём завершён -> follow_up (никто не менял статусы руками)")

    tl = c.get(f"/patients/{patient['id']}/timeline").json()["events"]
    kinds = [e["kind"] for e in tl]
    assert {"visit_opened", "payment", "treatment_prescribed"} <= set(kinds)
    print(f"[5] timeline: {len(tl)} событий ({', '.join(sorted(set(kinds)))})")

    insights = c.get("/dashboard/insights").json()
    codes = {i["code"] for i in insights}
    assert "low_stock" in codes  # склад пуст после свежего сида
    notes = c.get("/notifications", params={"event": "insight_low_stock"}).json()
    assert notes, "critical insight must auto-notify"
    print(f"[6] insights: {sorted(codes)}; авто-уведомление в журнале — owner happy path complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
