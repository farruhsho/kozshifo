"""Finance module additions (TZ Modul 8): flexible pay (consult/operation,
percent/fixed), salary detalizatsiya + PDF, admin expense types, recurring
(monthly) expenses.

Money is asserted as decimal STRINGS — the platform wire convention.
"""
from __future__ import annotations

import datetime as _dt
import uuid as _uuid
from decimal import Decimal

from sqlalchemy import select

from tests.conftest import API
from tests.test_finance import _login, _make_doctor, _paid_visit

_FIN = f"{API}/finance"
_PAYROLL = f"{_FIN}/payroll"


def _set_pay(client, auth, user_id: str, **fields) -> dict:
    resp = client.patch(f"{API}/users/{user_id}", headers=auth, json=fields)
    assert resp.status_code == 200, resp.text
    return resp.json()


def _add_performed_operation(visit_id: str, patient_id: str, surgeon_id: str,
                             price: str, when: _dt.datetime) -> str:
    """Insert a performed operation straight into the DB (bypasses the
    refer→schedule→perform API dance — we only need the payroll inputs)."""
    from app.core.database import SessionLocal
    from app.models.operation import Operation, OperationType

    session = SessionLocal()
    try:
        op_type = session.execute(select(OperationType)).scalars().first()
        assert op_type is not None, "an operation type must be seeded"
        op = Operation(
            visit_id=_uuid.UUID(visit_id),
            patient_id=_uuid.UUID(patient_id),
            operation_type_id=op_type.id,
            surgeon_id=_uuid.UUID(surgeon_id),
            status="performed",
            price=Decimal(price),
            performed_at=when,
        )
        session.add(op)
        session.commit()
        return str(op.id)
    finally:
        session.close()


# ── Flexible pay: consult fixed + operation percent/fixed ──────────────────


def test_consult_fixed_and_operation_percent_pay(client, auth):
    doctor = _make_doctor(client, auth, "fin.flex@kozshifo.uz")
    # Consult = flat 1 000 000/mo; operations = 10% of operation revenue.
    _set_pay(client, auth, doctor["id"],
             consult_salary_type="fixed", consult_salary_value="1000000",
             operation_salary_type="percent", operation_salary_value="10")

    visit, payment = _paid_visit(client, auth, doctor_id=doctor["id"])
    month = payment["created_at"][:7]
    when = _dt.datetime.fromisoformat(payment["created_at"].replace("Z", "+00:00"))
    _add_performed_operation(visit["id"], visit["patient_id"], doctor["id"],
                             "2000000", when)

    row = next(r for r in client.get(_PAYROLL, headers=auth, params={"month": month}).json()
               if r["user_id"] == doctor["id"])
    assert row["consult_salary_type"] == "fixed"
    assert row["consult_pay"] == "1000000.00"  # flat, independent of revenue
    assert row["operation_salary_type"] == "percent"
    assert row["operation_revenue"] == "2000000.00"
    assert row["operation_count"] == 1
    assert row["operation_pay"] == "200000.00"  # 10% of 2 000 000
    assert row["salary"] == "1200000.00"  # 1 000 000 + 200 000


def test_operation_fixed_per_op_pay(client, auth):
    doctor = _make_doctor(client, auth, "fin.opfixed@kozshifo.uz")
    # 50 000 сум per performed operation, no consult pay.
    _set_pay(client, auth, doctor["id"],
             operation_salary_type="fixed", operation_salary_value="50000")
    visit, payment = _paid_visit(client, auth, doctor_id=doctor["id"])
    month = payment["created_at"][:7]
    when = _dt.datetime.fromisoformat(payment["created_at"].replace("Z", "+00:00"))
    for _ in range(3):
        _add_performed_operation(visit["id"], visit["patient_id"], doctor["id"], "100000", when)

    row = next(r for r in client.get(_PAYROLL, headers=auth, params={"month": month}).json()
               if r["user_id"] == doctor["id"])
    assert row["operation_count"] == 3
    assert row["operation_pay"] == "150000.00"  # 50 000 × 3
    assert row["consult_pay"] == "0.00"
    assert row["salary"] == "150000.00"


def test_percent_value_capped_at_100(client, auth):
    doctor = _make_doctor(client, auth, "fin.cap@kozshifo.uz")
    bad = client.patch(f"{API}/users/{doctor['id']}", headers=auth,
                       json={"consult_salary_type": "percent", "consult_salary_value": "150"})
    assert bad.status_code == 422, bad.text
    # A fixed value may exceed 100.
    ok = client.patch(f"{API}/users/{doctor['id']}", headers=auth,
                      json={"consult_salary_type": "fixed", "consult_salary_value": "5000000"})
    assert ok.status_code == 200, ok.text


# ── Salary detalizatsiya (per-day, per-patient) + PDF ──────────────────────


def test_payroll_detail_and_pdf(client, auth):
    doctor = _make_doctor(client, auth, "fin.detail@kozshifo.uz")
    _set_pay(client, auth, doctor["id"],
             consult_salary_type="percent", consult_salary_value="20")
    _, payment = _paid_visit(client, auth, doctor_id=doctor["id"])
    month = payment["created_at"][:7]

    detail = client.get(f"{_PAYROLL}/{doctor['id']}/detail", headers=auth,
                        params={"month": month})
    assert detail.status_code == 200, detail.text
    data = detail.json()
    assert data["consult_revenue"] == "150000.00"
    assert data["consult_pay"] == "30000.00"  # 20% of 150000
    assert len(data["days"]) == 1
    day = data["days"][0]
    assert len(day["patients"]) == 1
    assert day["patients"][0]["amount"] == "150000.00"
    assert day["patients"][0]["share"] == "30000.00"
    assert day["revenue"] == "150000.00"

    pdf = client.get(f"{_PAYROLL}/{doctor['id']}/detail.pdf", headers=auth,
                     params={"month": month})
    assert pdf.status_code == 200, pdf.text
    assert pdf.content[:4] == b"%PDF"
    assert "application/pdf" in pdf.headers["content-type"]

    # Detail is behind payroll.read: a doctor cannot pull it.
    doc_auth = _login(client, "vrach@kozshifo.uz", "Vrach!2026")
    assert client.get(f"{_PAYROLL}/{doctor['id']}/detail", headers=doc_auth,
                      params={"month": month}).status_code == 403


# ── Admin-managed expense types ────────────────────────────────────────────


def test_expense_category_crud(client, auth):
    # Defaults are seeded; «Зарплата» is a system type.
    cats = client.get(f"{_FIN}/expense-categories", headers=auth)
    assert cats.status_code == 200, cats.text
    names = {c["name"]: c for c in cats.json()}
    assert "Зарплата" in names and names["Зарплата"]["is_system"] is True

    created = client.post(f"{_FIN}/expense-categories", headers=auth,
                          json={"name": "Транспорт"})
    assert created.status_code == 201, created.text
    cat_id = created.json()["id"]

    # Duplicate name → 409.
    assert client.post(f"{_FIN}/expense-categories", headers=auth,
                       json={"name": "Транспорт"}).status_code == 409

    # Rename / deactivate.
    upd = client.patch(f"{_FIN}/expense-categories/{cat_id}", headers=auth,
                       json={"name": "Топливо", "is_active": False})
    assert upd.status_code == 200 and upd.json()["name"] == "Топливо"

    # System type cannot be deleted.
    sys_id = names["Зарплата"]["id"]
    assert client.delete(f"{_FIN}/expense-categories/{sys_id}", headers=auth).status_code == 409

    # Regular type deletes fine.
    assert client.delete(f"{_FIN}/expense-categories/{cat_id}", headers=auth).status_code == 200

    # A doctor (no expenses.manage) cannot create types.
    doc_auth = _login(client, "vrach@kozshifo.uz", "Vrach!2026")
    assert client.post(f"{_FIN}/expense-categories", headers=doc_auth,
                       json={"name": "X"}).status_code == 403


# ── Recurring (monthly) expenses ───────────────────────────────────────────


def test_recurring_expense_fixed_and_variable(client, auth):
    month = _dt.date.today().isoformat()[:7]

    # Fixed template needs an amount.
    assert client.post(f"{_FIN}/recurring-expenses", headers=auth,
                       json={"category": "Аренда", "name": "Офис",
                             "is_fixed": True}).status_code == 422

    fixed = client.post(f"{_FIN}/recurring-expenses", headers=auth,
                        json={"category": "Аренда", "name": "Офис",
                              "amount": "3000000", "is_fixed": True})
    assert fixed.status_code == 201, fixed.text
    fixed_id = fixed.json()["id"]

    variable = client.post(f"{_FIN}/recurring-expenses", headers=auth,
                           json={"category": "Коммунальные", "name": "Свет",
                                 "is_fixed": False})
    assert variable.status_code == 201, variable.text
    var_id = variable.json()["id"]

    # Post the fixed one for the month → Expense at template amount.
    posted = client.post(f"{_FIN}/recurring-expenses/{fixed_id}/post", headers=auth,
                         json={"month": month})
    assert posted.status_code == 201, posted.text
    assert posted.json()["amount"] == "3000000.00"
    assert posted.json()["name"] == "Офис"

    # Idempotent: second post for the same month → 409.
    assert client.post(f"{_FIN}/recurring-expenses/{fixed_id}/post", headers=auth,
                       json={"month": month}).status_code == 409

    # Variable one needs an explicit amount at post time.
    assert client.post(f"{_FIN}/recurring-expenses/{var_id}/post", headers=auth,
                       json={"month": month}).status_code == 422
    var_posted = client.post(f"{_FIN}/recurring-expenses/{var_id}/post", headers=auth,
                             json={"month": month, "amount": "450000"})
    assert var_posted.status_code == 201, var_posted.text
    assert var_posted.json()["amount"] == "450000.00"

    # Status list flags both as posted for the month.
    status_list = client.get(f"{_FIN}/recurring-expenses", headers=auth,
                             params={"month": month}).json()
    posted_map = {r["id"]: r for r in status_list}
    assert posted_map[fixed_id]["posted"] is True
    assert posted_map[fixed_id]["posted_amount"] == "3000000.00"
    assert posted_map[var_id]["posted"] is True


def test_expense_name_persisted(client, auth):
    branch_id = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    created = client.post(f"{API}/finance/expenses", headers=auth, json={
        "category": "Расходники", "name": "Перчатки", "amount": "120000",
        "expense_date": _dt.date.today().isoformat(), "branch_id": branch_id,
    })
    assert created.status_code == 201, created.text
    assert created.json()["name"] == "Перчатки"
