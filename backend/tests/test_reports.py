"""Director reports hub — date-range financial / clinical / CRM reports + CSV.

Runs alphabetically AFTER test_inventory/test_operations on the shared session DB,
so creating a paid visit + expense here doesn't disturb their zero-stock asserts.
"""
from __future__ import annotations

from datetime import date

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _cons_service(client, auth) -> dict:
    page = client.get(f"{API}/services", headers=auth, params={"limit": 200}).json()
    return next(s for s in page["items"] if s["code"] == "CONS")


def _paid_visit(client, auth, branch_id, doctor_id) -> tuple[str, str, str]:
    """Register a patient, open a CONS visit for `doctor_id`, pay it in full."""
    service = _cons_service(client, auth)
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Отчёт", "last_name": "Пациент", "branch_id": branch_id,
              "region": "Ферганская"},
    ).json()
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id, "doctor_id": doctor_id,
              "items": [{"service_id": service["id"], "quantity": 1}]},
    ).json()
    pay = client.post(f"{API}/payments", headers=auth,
                      json={"visit_id": visit["id"], "amount": visit["payable"], "method": "cash"})
    assert pay.status_code in (200, 201), pay.text
    return patient["id"], visit["id"], visit["payable"]


def _doctor(client, auth, email="report.doc@kozshifo.uz") -> dict:
    resp = client.post(
        f"{API}/users", headers=auth,
        json={"email": email, "full_name": "Доктор Отчётов",
              "password": "Passw0rd!", "role_names": ["Doctor"], "cabinet": "Каб. 3"},
    )
    assert resp.status_code == 201, resp.text
    return resp.json()


def test_financial_report_reflects_payment_and_expense(client, auth):
    branch_id = _branch(client, auth)
    doc = _doctor(client, auth, "report.doc.fin@kozshifo.uz")
    _, visit_id, payable = _paid_visit(client, auth, branch_id, doc["id"])
    exp = client.post(f"{API}/finance/expenses", headers=auth,
                      json={"branch_id": branch_id, "category": "Аренда отчёт",
                            "amount": "100000.00", "expense_date": date.today().isoformat()})
    assert exp.status_code == 201, exp.text

    fin = client.get(f"{API}/reports/financial", headers=auth)
    assert fin.status_code == 200, fin.text
    body = fin.json()
    assert float(body["income"]) >= float(payable)
    assert float(body["expenses"]) >= 100000
    # profit = income - expenses (exact decimal maths).
    assert float(body["profit"]) == float(body["income"]) - float(body["expenses"])
    methods = {m["label"] for m in body["by_method"]}
    assert "Наличные" in methods
    assert "Аренда отчёт" in {c["label"] for c in body["by_category"]}


def test_by_doctor_and_by_patient_reflect_revenue(client, auth):
    branch_id = _branch(client, auth)
    doc = _doctor(client, auth, "report.doc.rev@kozshifo.uz")
    patient_id, visit_id, _ = _paid_visit(client, auth, branch_id, doc["id"])
    # Record a conclusion so the diagnostician report has data.
    client.post(f"{API}/visits/{visit_id}/diagnoses", headers=auth,
                json={"diagnosis": "Катаракта OD"})

    by_doctor = client.get(f"{API}/reports/by-doctor", headers=auth).json()
    mine = next((r for r in by_doctor if r["doctor_id"] == doc["id"]), None)
    assert mine is not None and float(mine["revenue"]) > 0 and mine["visits"] >= 1

    by_patient = client.get(f"{API}/reports/by-patient", headers=auth).json()
    assert any(r["patient_id"] == patient_id and float(r["total_paid"]) > 0 for r in by_patient)

    by_dx = client.get(f"{API}/reports/by-diagnostician", headers=auth).json()
    assert any(r["conclusions"] >= 1 for r in by_dx)


def test_region_and_operation_reports_shape(client, auth):
    region = client.get(f"{API}/reports/by-region", headers=auth)
    assert region.status_code == 200
    assert isinstance(region.json(), list)

    ops = client.get(f"{API}/reports/by-operation", headers=auth)
    assert ops.status_code == 200
    for key in ("count", "revenue", "by_surgeon", "date_from", "date_to"):
        assert key in ops.json()


def test_csv_export_is_excel_friendly(client, auth):
    resp = client.get(f"{API}/reports/financial.csv", headers=auth)
    assert resp.status_code == 200, resp.text
    assert resp.headers["content-type"].startswith("text/csv")
    # UTF-8 BOM so Excel renders Cyrillic columns.
    assert resp.content[:3] == b"\xef\xbb\xbf"

    doc_csv = client.get(f"{API}/reports/by-doctor.csv", headers=auth)
    assert doc_csv.status_code == 200
    assert "Врач" in doc_csv.content.decode("utf-8-sig")


def test_by_doctor_enriched_and_profit_by_region(client, auth):
    branch_id = _branch(client, auth)
    doc = _doctor(client, auth, "report.doc.enriched@kozshifo.uz")
    _paid_visit(client, auth, branch_id, doc["id"])  # patient region = Ферганская

    by_doctor = client.get(f"{API}/reports/by-doctor", headers=auth).json()
    mine = next(r for r in by_doctor if r["doctor_id"] == doc["id"])
    assert mine["distinct_patients"] >= 1
    assert float(mine["avg_check"]) > 0
    assert "repeat_patients" in mine and "avg_consult_minutes" in mine

    # profit-by-region: the paid visit's region (Ферганская) shows positive revenue.
    region = client.get(f"{API}/reports/profit-by-region", headers=auth).json()
    fergana = next((r for r in region if r["region"] == "Ферганская"), None)
    assert fergana is not None and float(fergana["revenue"]) > 0

    # by-operation now carries clinic-wide cogs/profit + per-surgeon profit fields.
    ops = client.get(f"{API}/reports/by-operation", headers=auth).json()
    assert "cogs" in ops and "profit" in ops
    for s in ops["by_surgeon"]:
        assert {"cogs", "profit"} <= set(s)

    # CSV for the new region report is Excel-friendly.
    csv = client.get(f"{API}/reports/profit-by-region.csv", headers=auth)
    assert csv.status_code == 200
    assert "Регион" in csv.content.decode("utf-8-sig")


def test_by_treatment_reflects_procedure_revenue(client, auth):
    """Платная процедура-лечение появляется в отчёте «По лечениям» с корректной
    выручкой (цена услуги), и все экспорты отдают 200. Зеркалит by-operation:
    выручка — собственная биллинговая строка лечения (VisitItem), не оплата."""
    branch_id = _branch(client, auth)
    # Пациент + визит без диагностического талона (лечение назначается сразу).
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Леч", "last_name": "Отчёт", "branch_id": branch_id},
    ).json()
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id},
    ).json()
    service = client.post(
        f"{API}/services", headers=auth,
        json={"code": "TX-REPORT", "name": "Отчётная процедура", "price": "175000"},
    ).json()
    # Платное лечение биллит строку услуги (visit_item_id) на цену услуги.
    tx = client.post(
        f"{API}/visits/{visit['id']}/treatments", headers=auth,
        json={"kind": "procedure", "name": "Отчётная процедура",
              "service_id": service["id"]},
    )
    assert tx.status_code == 201, tx.text
    assert tx.json()["visit_item_id"] is not None

    # Оплачиваем визит полностью (семантика by-treatment — accrual, но платим для
    # полноты сценария директора «процедура принесла деньги»).
    balance = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()["balance"]
    pay = client.post(f"{API}/payments", headers=auth,
                      json={"visit_id": visit["id"], "amount": balance,
                            "issue_queue_ticket": False})
    assert pay.status_code in (200, 201), pay.text

    rep = client.get(f"{API}/reports/by-treatment", headers=auth)
    assert rep.status_code == 200, rep.text
    body = rep.json()
    for key in ("count", "revenue", "by_service", "date_from", "date_to"):
        assert key in body
    row = next((r for r in body["by_service"]
                if r["service_name"] == "Отчётная процедура"), None)
    assert row is not None, body
    assert row["kind"] == "procedure"
    assert row["count"] >= 1
    assert float(row["revenue"]) >= 175000
    assert float(body["revenue"]) >= 175000

    # Все четыре формата экспорта отдают 200 + верный content-type/magic.
    csv = client.get(f"{API}/reports/by-treatment.csv", headers=auth)
    assert csv.status_code == 200
    assert csv.content[:3] == b"\xef\xbb\xbf"
    assert "Услуга" in csv.content.decode("utf-8-sig")

    xlsx = client.get(f"{API}/reports/by-treatment.xlsx", headers=auth)
    assert xlsx.status_code == 200
    assert "spreadsheetml" in xlsx.headers["content-type"]
    assert xlsx.content[:4] == b"PK\x03\x04"

    pdf = client.get(f"{API}/reports/by-treatment.pdf", headers=auth)
    assert pdf.status_code == 200
    assert pdf.headers["content-type"] == "application/pdf"
    assert pdf.content[:4] == b"%PDF"


def test_by_diagnostician_has_studies_and_time(client, auth):
    dx = client.get(f"{API}/reports/by-diagnostician", headers=auth).json()
    assert isinstance(dx, list)
    for r in dx:
        assert "studies" in r and "avg_minutes" in r


def test_xlsx_and_pdf_export(client, auth):
    # XLSX — ZIP magic bytes + spreadsheet content-type.
    for path in ("financial.xlsx", "by-doctor.xlsx"):
        resp = client.get(f"{API}/reports/{path}", headers=auth)
        assert resp.status_code == 200, resp.text
        assert "spreadsheetml" in resp.headers["content-type"]
        assert resp.content[:4] == b"PK\x03\x04"

    # PDF — %PDF magic bytes + pdf content-type.
    for path in ("financial.pdf", "by-operation.pdf"):
        resp = client.get(f"{API}/reports/{path}", headers=auth)
        assert resp.status_code == 200, resp.text
        assert resp.headers["content-type"] == "application/pdf"
        assert resp.content[:4] == b"%PDF"


def test_pdf_uses_cyrillic_font():
    # Building a PDF must register the bundled DejaVu font (NOT the Helvetica
    # fallback) so Cyrillic renders without tofu — mirrors the print_forms guard.
    from app.core import print_forms, report_export

    report_export.build_pdf("Тест", ["Колонка"], [["Значение"]])
    assert print_forms.FONT == "CardFont"


def test_bad_range_rejected_and_rbac_enforced(client, auth):
    bad = client.get(f"{API}/reports/financial", headers=auth,
                     params={"date_from": "2026-06-30", "date_to": "2026-06-01"})
    assert bad.status_code == 422

    # Doctor lacks reports.view → 403 (and is not a superuser).
    client.post(f"{API}/users", headers=auth,
                json={"email": "report.recep@kozshifo.uz", "full_name": "Врач Отчёт",
                      "password": "Passw0rd!", "role_names": ["Doctor"]})
    tok = client.post(f"{API}/auth/login",
                      data={"username": "report.recep@kozshifo.uz", "password": "Passw0rd!"}
                      ).json()["access_token"]
    denied = client.get(f"{API}/reports/financial",
                        headers={"Authorization": f"Bearer {tok}"})
    assert denied.status_code == 403
    assert "reports.view" in denied.json()["detail"]
