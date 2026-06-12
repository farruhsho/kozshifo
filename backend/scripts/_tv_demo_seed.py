"""Temp helper: seed a few queue tickets for the TV-board visual check."""
import httpx

API = "http://127.0.0.1:8000/api/v1"
c = httpx.Client(timeout=15)
token = c.post(f"{API}/auth/login", data={
    "username": "director@kozshifo.uz", "password": "Director!2026",
}).json()["access_token"]
c.headers["Authorization"] = f"Bearer {token}"
branch_id = c.get(f"{API}/branches").json()[0]["id"]
svc = c.get(f"{API}/services").json()["items"][0]

for i, (last, first) in enumerate([("Алимов", "Бек"), ("Каримова", "Дилноза"), ("Юсупов", "Тимур")]):
    p = c.post(f"{API}/patients", json={
        "first_name": first, "last_name": last, "branch_id": branch_id}).json()
    v = c.post(f"{API}/visits", json={
        "patient_id": p["id"], "branch_id": branch_id,
        "items": [{"service_id": svc["id"], "quantity": 1}]}).json()
    c.post(f"{API}/payments", json={"visit_id": v["id"], "amount": v["balance"]})

called = c.post(f"{API}/queue/call-next",
                json={"branch_id": branch_id, "room": "Каб. 2"}).json()
print(branch_id)
print(called["ticket_number"])
