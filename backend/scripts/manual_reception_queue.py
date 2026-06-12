"""Manual live exercise of the Epic-3 path: reception -> queue -> public TV.

login -> register patient -> visit with services -> pay (ticket issued) ->
queue list -> call-next -> serve -> TV board WITHOUT auth -> /tv page.
Run:  ./.venv/Scripts/python.exe scripts/manual_reception_queue.py
"""
from __future__ import annotations

import sys

import httpx

BASE = "http://127.0.0.1:8000"
API = f"{BASE}/api/v1"


def main() -> int:
    c = httpx.Client(timeout=15)
    token = c.post(f"{API}/auth/login", data={
        "username": "director@kozshifo.uz", "password": "Director!2026",
    }).json()["access_token"]
    c.headers["Authorization"] = f"Bearer {token}"
    print("[1] login OK")

    branch_id = c.get(f"{API}/branches").json()[0]["id"]
    patient = c.post(f"{API}/patients", json={
        "first_name": "Ресепшен", "last_name": "Поток", "branch_id": branch_id,
    }).json()
    services = c.get(f"{API}/services").json()["items"]
    cons = next(s for s in services if s["code"] == "CONS")
    tono = next(s for s in services if s["code"] == "TONO")
    visit = c.post(f"{API}/visits", json={
        "patient_id": patient["id"], "branch_id": branch_id,
        "items": [{"service_id": cons["id"], "quantity": 1},
                  {"service_id": tono["id"], "quantity": 1}],
    }).json()
    print(f"[2] visit {visit['visit_no']} total={visit['total_amount']}")

    pay = c.post(f"{API}/payments", json={
        "visit_id": visit["id"], "amount": visit["balance"],
        "method": "cash", "room": "Каб. 2",
    }).json()
    ticket_no = pay["queue_ticket_number"]
    assert ticket_no, pay
    print(f"[3] paid, receipt {pay['payment']['receipt_no']}, ticket {ticket_no}")

    queue = c.get(f"{API}/queue", params={"branch_id": branch_id}).json()
    assert any(t["ticket_number"] == ticket_no and t["status"] == "waiting" for t in queue)
    print(f"[4] queue shows {ticket_no} waiting")

    called = c.post(f"{API}/queue/call-next",
                    json={"branch_id": branch_id, "room": "Каб. 2"}).json()
    served = c.post(f"{API}/queue/{called['id']}/serve").json()
    assert served["status"] == "serving"
    print(f"[5] called -> serving ({called['ticket_number']})")

    anon = httpx.Client(timeout=15)  # no Authorization at all
    board = anon.get(f"{API}/queue/tv-board/{branch_id}").json()
    entries = board["now_serving"] + board["waiting"]
    assert any(e["ticket_number"] == called["ticket_number"] for e in entries)
    assert "Поток" not in str(entries)  # privacy-safe
    print(f"[6] public tv-board OK, {len(board['now_serving'])} serving / "
          f"{len(board['waiting'])} waiting, no names leaked")

    page = anon.get(f"{BASE}/tv/{branch_id}")
    assert page.status_code == 200 and "KO'Z" in page.text
    print(f"[7] /tv/{{branch}} page served ({len(page.text)} chars) — happy path complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
