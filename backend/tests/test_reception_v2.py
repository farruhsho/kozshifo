"""Reception Workspace V2.0 — backend foundation.

Covers: 8-digit patient_no generation, duplicate pre-check, patient summary,
EMERGENCY intake (visit priority + reason inherited by the minted ticket and
reflected on the TV board), and search by patient_no / birth date.
`auth` is the director (superuser).
"""
from __future__ import annotations

from tests.conftest import API


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _service(client, auth) -> dict:
    return client.get(f"{API}/services", headers=auth).json()["items"][0]


def _patient(client, auth, **extra) -> dict:
    body = {"first_name": "Тест", "last_name": "Пациент"}
    body.update(extra)
    resp = client.post(f"{API}/patients", headers=auth, json=body)
    assert resp.status_code == 201, resp.text
    return resp.json()


# ── patient_no ────────────────────────────────────────────────────────────────

def test_patient_no_is_8_digits_and_unique(client, auth):
    a = _patient(client, auth, first_name="Анвар", last_name="Алиев")
    b = _patient(client, auth, first_name="Бекзод", last_name="Бобоев")
    assert a["patient_no"] is not None
    assert len(a["patient_no"]) == 8 and a["patient_no"].isdigit()
    assert a["patient_no"] != b["patient_no"]
    # mrn (internal) is untouched and still prefixed.
    assert a["mrn"].startswith("P-")


# ── duplicate pre-check ───────────────────────────────────────────────────────

def test_duplicates_by_phone_and_name_dob(client, auth):
    # Stored normalized (platform convention); the receptionist may type loosely.
    p = _patient(client, auth, first_name="Дилноза", last_name="Каримова",
                 phone="+998907776655", birth_date="1990-05-12")

    # by phone typed with separators → strongest match, reason «телефон»
    by_phone = client.get(f"{API}/patients/duplicates", headers=auth,
                          params={"phone": "+998 90 777-66-55"})
    assert by_phone.status_code == 200, by_phone.text
    ids = [c["id"] for c in by_phone.json()]
    assert p["id"] in ids
    assert by_phone.json()[0]["reason"] == "телефон"

    # by name + birth date
    by_name = client.get(f"{API}/patients/duplicates", headers=auth,
                         params={"last_name": "Каримова", "first_name": "Дилноза",
                                 "birth_date": "1990-05-12"})
    assert by_name.status_code == 200
    assert p["id"] in [c["id"] for c in by_name.json()]

    # empty query → empty list (nothing to warn about)
    assert client.get(f"{API}/patients/duplicates", headers=auth).json() == []


# ── patient summary ───────────────────────────────────────────────────────────

def test_patient_summary_after_visit_and_payment(client, auth):
    branch_id = _branch_id(client, auth)
    svc = _service(client, auth)
    p = _patient(client, auth, first_name="Сводка", last_name="Пациентов")

    visit = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": p["id"], "branch_id": branch_id,
        "items": [{"service_id": svc["id"], "quantity": 1}],
    }).json()
    payable = visit["payable"]
    client.post(f"{API}/payments", headers=auth,
                json={"visit_id": visit["id"], "amount": payable, "method": "cash"})

    s = client.get(f"{API}/patients/{p['id']}/summary", headers=auth)
    assert s.status_code == 200, s.text
    body = s.json()
    assert body["visit_count"] == 1
    assert body["is_repeat"] is False
    assert body["last_payment_amount"] is not None
    assert body["total_debt"] == "0.00"  # paid in full


# ── EMERGENCY intake ──────────────────────────────────────────────────────────

def test_emergency_inherits_to_ticket_and_tv(client, auth):
    branch_id = _branch_id(client, auth)
    svc = _service(client, auth)
    p = _patient(client, auth, first_name="Экстренный", last_name="Случай")
    visit = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": p["id"], "branch_id": branch_id,
        "items": [{"service_id": svc["id"], "quantity": 1}],
    }).json()

    # emergency without a reason → 422
    bad = client.post(f"{API}/visits/{visit['id']}/priority", headers=auth,
                      json={"emergency": True})
    assert bad.status_code == 422, bad.text

    # mark emergency with a reason
    pr = client.post(f"{API}/visits/{visit['id']}/priority", headers=auth,
                     json={"emergency": True, "reason": "ДТП, травма глаза"})
    assert pr.status_code == 200, pr.text
    assert pr.json()["priority"] > 0
    assert pr.json()["priority_reason"] == "ДТП, травма глаза"

    # pay in full → the minted diagnostic ticket inherits priority + reason
    result = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": visit["payable"], "method": "cash",
    })
    assert result.status_code == 201, result.text
    rb = result.json()
    assert rb["priority"] > 0
    assert rb["priority_reason"] == "ДТП, травма глаза"
    ticket_no = rb["queue_ticket_number"]
    assert ticket_no and ticket_no.startswith("D-")

    # the ticket itself carries the priority + reason
    queue = client.get(f"{API}/queue", headers=auth, params={"branch_id": branch_id}).json()
    ticket = next(t for t in queue if t["ticket_number"] == ticket_no)
    assert ticket["priority"] > 0
    assert ticket["priority_reason"] == "ДТП, травма глаза"

    # TV board flags it as emergency
    tv = client.get(f"{API}/queue/tv-board/{branch_id}", headers=auth).json()
    flagged = [e for e in tv["diagnostic"]["waiting"] if e["ticket_number"] == ticket_no]
    assert flagged and flagged[0]["emergency"] is True


# ── receipt PDF ───────────────────────────────────────────────────────────────

def test_receipt_pdf_renders(client, auth):
    branch_id = _branch_id(client, auth)
    svc = _service(client, auth)
    p = _patient(client, auth, first_name="Чек", last_name="Чеков")
    visit = client.post(f"{API}/visits", headers=auth, json={
        "patient_id": p["id"], "branch_id": branch_id,
        "items": [{"service_id": svc["id"], "quantity": 1}],
    }).json()
    # emergency so the receipt path exercises the «ЭКСТРЕННЫЙ ПРИЕМ» branch
    client.post(f"{API}/visits/{visit['id']}/priority", headers=auth,
                json={"emergency": True, "reason": "тест"})
    result = client.post(f"{API}/payments", headers=auth, json={
        "visit_id": visit["id"], "amount": visit["payable"], "method": "card",
    }).json()
    pid = result["payment"]["id"]

    pdf = client.get(f"{API}/payments/{pid}/receipt.pdf", headers=auth)
    assert pdf.status_code == 200, pdf.text
    assert pdf.headers["content-type"] == "application/pdf"
    assert pdf.content[:5] == b"%PDF-"
    assert len(pdf.content) > 1000  # real document, not a stub


# ── TV board branch picker ────────────────────────────────────────────────────

def test_tv_branches_public_and_bare_tv_page(client):
    # Public list (no auth) for the board's branch picker.
    r = client.get(f"{API}/queue/tv-branches")
    assert r.status_code == 200, r.text
    rows = r.json()
    assert isinstance(rows, list) and rows
    assert all("id" in b and "name" in b for b in rows)
    assert r.headers.get("access-control-allow-origin") == "*"

    # Bare /tv (no branch) still serves the board HTML — it shows the picker.
    page = client.get("/tv")
    assert page.status_code == 200
    assert "text/html" in page.headers["content-type"]


# ── search by patient_no / birth date ─────────────────────────────────────────

def test_search_by_patient_no_and_birth_date(client, auth):
    p = _patient(client, auth, first_name="Поиск", last_name="Поисков",
                 birth_date="1985-03-14")

    by_no = client.get(f"{API}/search", headers=auth, params={"q": p["patient_no"]})
    assert by_no.status_code == 200, by_no.text
    assert any(x["id"] == p["id"] for x in by_no.json()["patients"])
    # result carries patient_no
    assert any(x.get("patient_no") == p["patient_no"] for x in by_no.json()["patients"])

    by_dob = client.get(f"{API}/search", headers=auth, params={"q": "14.03.1985"})
    assert by_dob.status_code == 200
    assert any(x["id"] == p["id"] for x in by_dob.json()["patients"])
