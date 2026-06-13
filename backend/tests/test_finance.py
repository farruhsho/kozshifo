"""Finance module (TZ Modul 8): expenses, percent payroll, cash reports, CSV.

Money is asserted as decimal STRINGS — the platform wire convention.
Date/month keys are derived from the payment's own created_at (UTC) so the
tests stay correct across timezones and month boundaries.
"""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API

_EXPENSES = f"{API}/finance/expenses"
_PAYROLL = f"{API}/finance/payroll"
_REPORTS = f"{API}/finance/reports"


def _login(client, email: str, password: str) -> dict[str, str]:
    resp = client.post(f"{API}/auth/login", data={"username": email, "password": password})
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['access_token']}"}


def _make_doctor(client, auth, email: str, salary_percent: str | None = None) -> dict:
    user = client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": f"Доктор {email.split('@')[0]}",
              "password": "Doctor!2026", "role_names": ["Doctor"]},
    )
    assert user.status_code == 201, user.text
    user = user.json()
    if salary_percent is not None:
        resp = client.patch(f"{API}/users/{user['id']}", headers=auth,
                            json={"salary_percent": salary_percent})
        assert resp.status_code == 200, resp.text
        user = resp.json()
    return user


def _paid_visit(client, auth, *, doctor_id: str | None = None, method: str = "cash") -> tuple[dict, dict]:
    """Open a fully-paid visit (one CONS service, 150000) without queue side effects."""
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Тест", "last_name": "Финанс", "branch_id": branch_id},
    ).json()
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    consult = next(s for s in services if s["code"] == "CONS")
    body = {"patient_id": patient["id"], "branch_id": branch_id,
            "items": [{"service_id": consult["id"], "quantity": 1}]}
    if doctor_id is not None:
        body["doctor_id"] = doctor_id
    visit = client.post(f"{API}/visits", headers=auth, json=body).json()
    pay = client.post(
        f"{API}/payments", headers=auth,
        json={"visit_id": visit["id"], "amount": visit["balance"],
              "method": method, "issue_queue_ticket": False},
    )
    assert pay.status_code == 201, pay.text
    return visit, pay.json()["payment"]


# ════════════════════════════════════════════════════════════════════════════
# Branch isolation (payments + cash reports)
# ════════════════════════════════════════════════════════════════════════════


def test_payments_and_reports_are_branch_isolated(client, auth):
    import datetime

    # A paid visit on MAIN (the seeded kassa's branch).
    main_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    _, payment = _paid_visit(client, auth)
    assert payment["branch_id"] == main_id

    # A second branch with its own cashier.
    branch_b = client.post(f"{API}/branches", headers=auth,
                           json={"name": "Филиал B", "code": "BR-ISO-B"})
    assert branch_b.status_code == 201, branch_b.text
    branch_b = branch_b.json()
    made = client.post(f"{API}/users", headers=auth, json={
        "email": "kassa.iso.b@kozshifo.uz", "full_name": "Кассир B",
        "password": "KassaB!2026", "branch_id": branch_b["id"],
        "role_names": ["Cashier"],
    })
    assert made.status_code == 201, made.text
    cashier_b = _login(client, "kassa.iso.b@kozshifo.uz", "KassaB!2026")

    # The branch-B cashier must NOT see MAIN receipts — not in the default list…
    seen = client.get(f"{API}/payments", headers=cashier_b).json()["items"]
    assert all(p["branch_id"] == branch_b["id"] for p in seen)
    assert payment["id"] not in [p["id"] for p in seen]
    # …and not by passing the other branch's id explicitly (client-trusted scope).
    escaped = client.get(f"{API}/payments", headers=cashier_b,
                         params={"branch_id": main_id}).json()["items"]
    assert escaped == []

    # The seeded MAIN cashier DOES see the MAIN receipt (isolation isn't a blanket deny).
    kassa = _login(client, "kassa@kozshifo.uz", "Kassa!2026")
    mine = client.get(f"{API}/payments", headers=kassa).json()["items"]
    assert payment["id"] in [p["id"] for p in mine]

    # The director (superuser) can still filter to any branch.
    dir_view = client.get(f"{API}/payments", headers=auth,
                          params={"branch_id": main_id}).json()["items"]
    assert payment["id"] in [p["id"] for p in dir_view]

    # Cash reports are scoped too: branch B has no income today, MAIN does.
    today = datetime.date.today().isoformat()
    rep_b = client.get(f"{_REPORTS}/daily", headers=cashier_b, params={"d": today}).json()
    assert rep_b["income_total"] == "0.00"
    rep_main = client.get(f"{_REPORTS}/daily", headers=kassa, params={"d": today}).json()
    assert Decimal(rep_main["income_total"]) >= Decimal(payment["amount"])


# ════════════════════════════════════════════════════════════════════════════
# Expenses
# ════════════════════════════════════════════════════════════════════════════


def test_expense_create_list_delete(client, auth):
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    created = client.post(
        _EXPENSES, headers=auth,
        json={"category": "Аренда", "amount": "500000", "expense_date": "2026-06-01",
              "note": "Офис, июнь"},
    )
    assert created.status_code == 201, created.text
    exp = created.json()
    assert exp["kind"] == "regular"
    assert exp["amount"] == "500000.00"  # decimal string, 2dp from Numeric(12,2)
    assert exp["branch_id"] == branch_id  # defaulted to the actor's branch
    assert exp["created_by_name"] == "Директор клиники"

    listed = client.get(_EXPENSES, headers=auth,
                        params={"category": "Аренда", "date_from": "2026-06-01",
                                "date_to": "2026-06-01"}).json()
    assert listed["total"] >= 1
    row = next(e for e in listed["items"] if e["id"] == exp["id"])
    assert row["created_by_name"] == "Директор клиники"

    deleted = client.delete(f"{_EXPENSES}/{exp['id']}", headers=auth)
    assert deleted.status_code == 200, deleted.text
    listed = client.get(_EXPENSES, headers=auth, params={"category": "Аренда"}).json()
    assert all(e["id"] != exp["id"] for e in listed["items"])


def test_expense_validation(client, auth):
    # Blank category and non-positive amounts never reach the database.
    assert client.post(_EXPENSES, headers=auth,
                       json={"category": "  ", "amount": "10", "expense_date": "2026-06-01"},
                       ).status_code == 422
    assert client.post(_EXPENSES, headers=auth,
                       json={"category": "Прочее", "amount": "0", "expense_date": "2026-06-01"},
                       ).status_code == 422


def test_expense_requires_permission(client, auth):
    # The Doctor role carries no expenses.* permissions.
    doctor = _make_doctor(client, auth, "fin.rbac@kozshifo.uz")
    doc_auth = _login(client, "fin.rbac@kozshifo.uz", "Doctor!2026")
    assert client.get(_EXPENSES, headers=doc_auth).status_code == 403
    denied = client.post(_EXPENSES, headers=doc_auth,
                         json={"category": "Прочее", "amount": "10", "expense_date": "2026-06-01"})
    assert denied.status_code == 403
    assert doctor["id"]  # silence unused warning


# ════════════════════════════════════════════════════════════════════════════
# Payroll
# ════════════════════════════════════════════════════════════════════════════


def test_payroll_math_through_the_api(client, auth):
    doctor = _make_doctor(client, auth, "fin.payroll@kozshifo.uz", salary_percent="30")
    assert doctor["salary_percent"] == "30.00"

    _, payment = _paid_visit(client, auth, doctor_id=doctor["id"], method="card")
    month = payment["created_at"][:7]

    resp = client.get(_PAYROLL, headers=auth, params={"month": month})
    assert resp.status_code == 200, resp.text
    row = next(r for r in resp.json() if r["user_id"] == doctor["id"])
    assert row["full_name"] == doctor["full_name"]
    assert row["salary_percent"] == "30.00"
    assert row["revenue"] == "150000.00"  # CONS price, decimal string
    assert row["salary"] == "45000.00"   # 30% of 150000
    assert row["paid"] is False
    assert row["paid_at"] is None

    # A refund is a status flip on the payment row -> it drops OUT of the
    # doctor's revenue (completed-only sum). Mirrors payments.py semantics.
    _, refunded_payment = _paid_visit(client, auth, doctor_id=doctor["id"])
    assert client.post(f"{API}/payments/{refunded_payment['id']}/refund",
                       headers=auth).status_code == 200
    row = next(r for r in client.get(_PAYROLL, headers=auth, params={"month": month}).json()
               if r["user_id"] == doctor["id"])
    assert row["revenue"] == "150000.00"  # unchanged by the refunded visit

    # Month format is validated.
    assert client.get(_PAYROLL, headers=auth, params={"month": "2026-13"}).status_code == 422
    assert client.get(_PAYROLL, headers=auth, params={"month": "junk"}).status_code == 422


def _backdate_payment_to_closed_month(payment_id: str) -> tuple[str, str]:
    """Move a payment into the previous (closed) month and return (month, day).

    Payroll can only be paid out for a finished month, so a test that exercises
    a payout must first put revenue in a closed month — payments are created
    "now" by the API. Returns the YYYY-MM month key and YYYY-MM-DD day.
    """
    import datetime as _dt
    import uuid as _uuid

    from app.core.database import SessionLocal
    from app.models.payment import Payment as _Payment

    today = _dt.date.today()
    first_of_month = today.replace(day=1)
    prev = first_of_month - _dt.timedelta(days=1)  # a day in the previous month
    # 15th at noon UTC stays inside the local month for any realistic offset.
    when = _dt.datetime(prev.year, prev.month, 15, 12, 0, tzinfo=_dt.timezone.utc)
    session = SessionLocal()
    try:
        payment = session.get(_Payment, _uuid.UUID(payment_id))
        payment.created_at = when
        session.commit()
    finally:
        session.close()
    return f"{prev.year:04d}-{prev.month:02d}", when.date().isoformat()


def test_payroll_payout_flow(client, auth):
    doctor = _make_doctor(client, auth, "fin.payout@kozshifo.uz", salary_percent="25")
    _, payment = _paid_visit(client, auth, doctor_id=doctor["id"])
    current_month = payment["created_at"][:7]

    # The current month is not closed yet — paying it out is rejected (409), so a
    # mid-month payout can't freeze salary at revenue-so-far.
    open_payout = client.post(f"{_PAYROLL}/payout", headers=auth,
                              json={"user_id": doctor["id"], "month": current_month})
    assert open_payout.status_code == 409, open_payout.text

    # Move the revenue into the previous (closed) month and pay THAT out.
    month, _ = _backdate_payment_to_closed_month(payment["id"])
    payout = client.post(f"{_PAYROLL}/payout", headers=auth,
                         json={"user_id": doctor["id"], "month": month})
    assert payout.status_code == 201, payout.text
    expense = payout.json()
    assert expense["kind"] == "payroll"
    assert expense["category"] == "Зарплата"
    assert expense["amount"] == "37500.00"  # 25% of 150000
    assert expense["payroll_user_id"] == doctor["id"]
    assert expense["payroll_month"] == month
    assert "25" in expense["note"] and month in expense["note"]

    # Payroll now shows the row as paid, with the frozen booked amount.
    row = next(r for r in client.get(_PAYROLL, headers=auth, params={"month": month}).json()
               if r["user_id"] == doctor["id"])
    assert row["paid"] is True
    assert row["paid_at"] is not None
    assert row["paid_amount"] == "37500.00"

    # Idempotency: the unique (user, month) constraint turns a repeat into 409.
    again = client.post(f"{_PAYROLL}/payout", headers=auth,
                        json={"user_id": doctor["id"], "month": month})
    assert again.status_code == 409

    # Payroll rows cannot be deleted through the expense API.
    assert client.delete(f"{_EXPENSES}/{expense['id']}", headers=auth).status_code == 409

    # The payout lands in the reports as an ordinary outflow.
    d = expense["expense_date"]
    daily = client.get(f"{_REPORTS}/daily", headers=auth, params={"d": d}).json()
    assert Decimal(daily["expense_total"]) >= Decimal("37500.00")
    monthly = client.get(f"{_REPORTS}/monthly", headers=auth, params={"month": d[:7]}).json()
    assert Decimal(monthly["payroll_total"]) >= Decimal("37500.00")

    # Correction path: void the payout, then it can be paid out again.
    void = client.post(f"{_PAYROLL}/void", headers=auth,
                       json={"user_id": doctor["id"], "month": month})
    assert void.status_code == 200, void.text
    assert client.get(_PAYROLL, headers=auth, params={"month": month}).json()
    repaid = client.post(f"{_PAYROLL}/payout", headers=auth,
                         json={"user_id": doctor["id"], "month": month})
    assert repaid.status_code == 201, repaid.text
    # Voiding a month with no payout is a 404.
    assert client.post(f"{_PAYROLL}/void", headers=auth,
                       json={"user_id": doctor["id"], "month": "2019-01"}).status_code == 404

    # payroll.read does not grant payouts/voids: the seeded Cashier can read…
    kassa = _login(client, "kassa@kozshifo.uz", "Kassa!2026")
    assert client.get(_PAYROLL, headers=kassa, params={"month": month}).status_code == 200
    # …but not pay out (payroll.manage missing).
    denied = client.post(f"{_PAYROLL}/payout", headers=kassa,
                         json={"user_id": doctor["id"], "month": month})
    assert denied.status_code == 403


def test_payroll_payout_rejects_zero_salary_and_no_percent(client, auth):
    with_pct = _make_doctor(client, auth, "fin.zero@kozshifo.uz", salary_percent="40")
    # No revenue in a long-gone month -> nothing to pay.
    resp = client.post(f"{_PAYROLL}/payout", headers=auth,
                       json={"user_id": with_pct["id"], "month": "2020-01"})
    assert resp.status_code == 400

    no_pct = _make_doctor(client, auth, "fin.nopct@kozshifo.uz")
    resp = client.post(f"{_PAYROLL}/payout", headers=auth,
                       json={"user_id": no_pct["id"], "month": "2020-01"})
    assert resp.status_code == 400


def test_salary_percent_validation_on_user_update(client, auth):
    doctor = _make_doctor(client, auth, "fin.pct@kozshifo.uz")
    bad = client.patch(f"{API}/users/{doctor['id']}", headers=auth,
                       json={"salary_percent": "101"})
    assert bad.status_code == 422
    bad = client.patch(f"{API}/users/{doctor['id']}", headers=auth,
                       json={"salary_percent": "-1"})
    assert bad.status_code == 422
    ok = client.patch(f"{API}/users/{doctor['id']}", headers=auth,
                      json={"salary_percent": "12.5"})
    assert ok.status_code == 200
    assert ok.json()["salary_percent"] == "12.50"
    # Explicit null clears percent-based pay.
    cleared = client.patch(f"{API}/users/{doctor['id']}", headers=auth,
                           json={"salary_percent": None})
    assert cleared.status_code == 200
    assert cleared.json()["salary_percent"] is None


# ════════════════════════════════════════════════════════════════════════════
# Cash reports
# ════════════════════════════════════════════════════════════════════════════


def test_daily_report_methods_expenses_and_refunds(client, auth):
    _, payment = _paid_visit(client, auth, method="qr")
    d = payment["created_at"][:10]  # the payment's own UTC business day
    amount = Decimal(payment["amount"])

    created = client.post(_EXPENSES, headers=auth,
                          json={"category": "Коммуналка", "amount": "10000", "expense_date": d})
    assert created.status_code == 201, created.text

    body = client.get(f"{_REPORTS}/daily", headers=auth, params={"d": d}).json()
    assert body["date"] == d
    assert set(body["income_by_method"]) >= {"cash", "card", "qr", "transfer"}
    assert Decimal(body["income_by_method"]["qr"]) >= amount
    assert Decimal(body["expense_total"]) >= Decimal("10000.00")
    # Internal consistency (shared DB may hold other rows from this session).
    assert Decimal(body["income_total"]) == sum(
        Decimal(v) for v in body["income_by_method"].values())
    assert Decimal(body["net"]) == (Decimal(body["income_total"])
                                    - Decimal(body["refund_total"])
                                    - Decimal(body["expense_total"]))

    # Refund = status flip: the till keeps the day's inflow AND books the
    # outflow, so a same-day pay+refund nets to zero instead of double-dipping.
    before = client.get(f"{_REPORTS}/daily", headers=auth, params={"d": d}).json()
    _, refunded = _paid_visit(client, auth, method="cash")
    assert client.post(f"{API}/payments/{refunded['id']}/refund",
                       headers=auth).status_code == 200
    after = client.get(f"{_REPORTS}/daily", headers=auth, params={"d": d}).json()
    refund_amount = Decimal(refunded["amount"])
    assert Decimal(after["income_total"]) == Decimal(before["income_total"]) + refund_amount
    assert Decimal(after["refund_total"]) == Decimal(before["refund_total"]) + refund_amount
    assert Decimal(after["net"]) == Decimal(before["net"])  # zero net effect


def test_monthly_report_shape(client, auth):
    _, payment = _paid_visit(client, auth, method="transfer")
    month = payment["created_at"][:7]
    body = client.get(f"{_REPORTS}/monthly", headers=auth, params={"month": month}).json()
    assert body["month"] == month
    assert Decimal(body["income_by_method"]["transfer"]) >= Decimal(payment["amount"])
    assert Decimal(body["net"]) == (Decimal(body["income_total"])
                                    - Decimal(body["refund_total"])
                                    - Decimal(body["expense_total"]))
    assert "payroll_total" in body
    assert client.get(f"{_REPORTS}/monthly", headers=auth,
                      params={"month": "2026-1"}).status_code == 422


def test_monthly_report_expense_window_is_calendar_month(client, auth):
    """Boundary expenses bucket by LOCAL calendar month — not by the .date() of a
    UTC instant, which shifts a day on non-UTC hosts (the regression this guards).
    Uses an isolated far-past month (2024-02, leap) no other test touches."""
    def expense(category: str, d: str) -> None:
        r = client.post(_EXPENSES, headers=auth,
                        json={"category": category, "amount": "1000.00", "expense_date": d})
        assert r.status_code == 201, r.text

    expense("BoundIn", "2024-02-29")    # last day of Feb -> February
    expense("BoundPrev", "2024-01-31")  # last day of Jan -> NOT February
    expense("BoundNext", "2024-03-01")  # first day of Mar -> NOT February

    feb = client.get(f"{_REPORTS}/monthly", headers=auth, params={"month": "2024-02"}).json()
    jan = client.get(f"{_REPORTS}/monthly", headers=auth, params={"month": "2024-01"}).json()
    mar = client.get(f"{_REPORTS}/monthly", headers=auth, params={"month": "2024-03"}).json()
    assert Decimal(feb["expense_total"]) == Decimal("1000.00")   # only Feb-29
    assert Decimal(jan["expense_total"]) == Decimal("1000.00")   # only Jan-31
    assert Decimal(mar["expense_total"]) == Decimal("1000.00")   # only Mar-01


def test_visits_branch_scoped_for_non_superuser(client, auth):
    """A branch-scoped cashier sees only their branch's visits; the director
    (superuser) sees all branches."""
    main = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    other = client.post(f"{API}/branches", headers=auth,
                        json={"name": "Филиал-2", "code": "BR2", "address": "x"}).json()["id"]
    services = client.get(f"{API}/services", headers=auth).json()["items"]
    svc = services[0]["id"]
    def visit_in(branch_id: str) -> str:
        p = client.post(f"{API}/patients", headers=auth,
                        json={"first_name": "Б", "last_name": "Скоуп", "branch_id": branch_id}).json()
        return client.post(f"{API}/visits", headers=auth,
                           json={"patient_id": p["id"], "branch_id": branch_id,
                                 "items": [{"service_id": svc, "quantity": 1}]}).json()["id"]
    v_main, v_other = visit_in(main), visit_in(other)

    kassa = _login(client, "kassa@kozshifo.uz", "Kassa!2026")  # seeded at MAIN
    seen = {v["id"] for v in client.get(f"{API}/visits", headers=kassa,
                                        params={"limit": 200}).json()["items"]}
    assert v_other not in seen   # other branch hidden from the cashier
    # Director sees both branches.
    all_seen = {v["id"] for v in client.get(f"{API}/visits", headers=auth,
                                            params={"limit": 200}).json()["items"]}
    assert {v_main, v_other} <= all_seen


def test_visits_owing_filter(client, auth):
    """owing=true returns only visits whose payable still exceeds paid."""
    _, paid = _paid_visit(client, auth)         # fully paid -> not owing
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    patient = client.post(f"{API}/patients", headers=auth,
                          json={"first_name": "Д", "last_name": "Долг", "branch_id": branch_id}).json()
    svc = client.get(f"{API}/services", headers=auth).json()["items"][0]["id"]
    owing = client.post(f"{API}/visits", headers=auth,
                        json={"patient_id": patient["id"], "branch_id": branch_id,
                              "items": [{"service_id": svc, "quantity": 1}]}).json()

    rows = client.get(f"{API}/visits", headers=auth,
                      params={"status": "open", "owing": True, "limit": 200}).json()["items"]
    ids = {v["id"] for v in rows}
    assert owing["id"] in ids
    assert paid["id"] not in ids


# ════════════════════════════════════════════════════════════════════════════
# CSV exports
# ════════════════════════════════════════════════════════════════════════════


def test_csv_exports(client, auth):
    # Expenses CSV: BOM + attachment + header row.
    resp = client.get(f"{_EXPENSES}.csv", headers=auth)
    assert resp.status_code == 200, resp.text
    assert resp.content.startswith(b"\xef\xbb\xbf")
    assert "attachment" in resp.headers["content-disposition"]
    header = resp.text.lstrip("\ufeff").splitlines()[0]
    assert header.startswith("expense_date,category,amount")

    resp = client.get(f"{_PAYROLL}.csv", headers=auth, params={"month": "2026-06"})
    assert resp.status_code == 200, resp.text
    assert resp.content.startswith(b"\xef\xbb\xbf")

    resp = client.get(f"{_REPORTS}/daily.csv", headers=auth, params={"d": "2026-06-01"})
    assert resp.status_code == 200, resp.text
    assert resp.content.startswith(b"\xef\xbb\xbf")

    # CSV twins share the JSON endpoint's permission gate.
    doc_auth = _login(client, "vrach@kozshifo.uz", "Vrach!2026")
    assert client.get(f"{_EXPENSES}.csv", headers=doc_auth).status_code == 403
