"""Многодневный курс лечения: назначение на N сеансов, помечаемых по одному
(/mark-session). Курс «активен» (визит-лечение не закрывается), пока не выполнены
все сеансы; на последнем сеансе назначение переходит в «done». Одноразовое
назначение (total 1) закрывается первым же сеансом. Биллинг курса не задваивается.
"""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API


def _branch(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _patient(client, auth, last_name) -> dict:
    return client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Курс", "last_name": last_name, "branch_id": _branch(client, auth)},
    ).json()


def _visit(client, auth, patient, branch) -> dict:
    return client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch},
    ).json()


def test_multi_session_course_marks_and_completes(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Три")
    visit = _visit(client, auth, patient, branch)

    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Магнитотерапия", "sessions_total": 3})
    assert tx.status_code == 201, tx.text
    body = tx.json()
    assert body["sessions_total"] == 3
    assert body["sessions_done"] == 0
    assert body["status"] == "prescribed"
    tid = body["id"]

    # Два сеанса — курс всё ещё активен (prescribed).
    r1 = client.post(f"{API}/treatments/{tid}/mark-session", headers=auth)
    assert r1.status_code == 200, r1.text
    assert r1.json()["sessions_done"] == 1
    assert r1.json()["status"] == "prescribed"

    r2 = client.post(f"{API}/treatments/{tid}/mark-session", headers=auth)
    assert r2.status_code == 200
    assert r2.json()["sessions_done"] == 2
    assert r2.json()["status"] == "prescribed"

    # Третий (последний) сеанс — курс завершён.
    r3 = client.post(f"{API}/treatments/{tid}/mark-session", headers=auth)
    assert r3.status_code == 200
    assert r3.json()["sessions_done"] == 3
    assert r3.json()["status"] == "done"
    assert r3.json()["performed_at"] is not None


def test_fourth_session_over_total_is_409(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Перебор")
    visit = _visit(client, auth, patient, branch)
    tid = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                      json={"kind": "procedure", "name": "УВЧ", "sessions_total": 3}).json()["id"]
    for _ in range(3):
        assert client.post(f"{API}/treatments/{tid}/mark-session", headers=auth).status_code == 200
    over = client.post(f"{API}/treatments/{tid}/mark-session", headers=auth)
    assert over.status_code == 409, over.text


def test_single_session_marks_done_at_once(client, auth):
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Раз")
    visit = _visit(client, auth, patient, branch)
    # Дефолт sessions_total=1 (поле не передаём — backward-compat).
    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Осмотр"}).json()
    assert tx["sessions_total"] == 1
    assert tx["sessions_done"] == 0
    r = client.post(f"{API}/treatments/{tx['id']}/mark-session", headers=auth)
    assert r.status_code == 200
    assert r.json()["sessions_done"] == 1
    assert r.json()["status"] == "done"


def test_visit_stays_open_until_course_finished(client, auth):
    """Визит-лечение не закрывается, пока курс не добит: пока назначение
    остаётся 'prescribed' (сеансы не выполнены), complete_if_treatment_done видит
    pending и держит визит открытым. Последний сеанс закрывает лечение."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Открыт")
    visit = _visit(client, auth, patient, branch)
    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Курс", "sessions_total": 2}).json()
    tid = tx["id"]

    # Л-талон в реальную ветку лечения; его завершение не должно закрыть визит,
    # пока в курсе остались сеансы.
    ticket = client.post(f"{API}/queue/treatment-ticket", headers=auth,
                         json={"patient_id": patient["id"], "branch_id": branch,
                               "visit_id": visit["id"], "room": "Процедурная"}).json()

    # Один сеанс — курс ещё активен.
    assert client.post(f"{API}/treatments/{tid}/mark-session", headers=auth).status_code == 200

    client.post(f"{API}/queue/{ticket['id']}/call", headers=auth, json={"room": "Процедурная"})
    client.post(f"{API}/queue/{ticket['id']}/serve", headers=auth)
    assert client.post(f"{API}/queue/{ticket['id']}/done", headers=auth).status_code == 200

    # Талон закрыт, но курс не добит (1/2) → визит остаётся открытым.
    mid = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert mid["flow_status"] != "completed", mid

    # Последний сеанс закрывает курс; ничего не осталось → лечение завершено.
    assert client.post(f"{API}/treatments/{tid}/mark-session", headers=auth).status_code == 200
    after = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert after["flow_status"] == "completed", after


def _product(client, auth, branch, sku="MED-CRS") -> dict:
    return client.post(
        f"{API}/inventory/products", headers=auth,
        json={"sku": sku, "name": "Капли", "unit": "шт", "min_stock": "0"},
    ).json()


def test_medication_multi_session_rejected(client, auth):
    """Медикамент нельзя назначить многосеансным курсом (списание идёт через
    /dispense с FEFO; sessions_total>1 обошёл бы склад)."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "МедКурс")
    visit = _visit(client, auth, patient, branch)
    product = _product(client, auth, branch)
    r = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                    json={"kind": "medication", "name": "Капли",
                          "product_id": product["id"], "quantity": "1",
                          "sessions_total": 2})
    assert r.status_code == 422, r.text


def test_mark_session_on_medication_is_409(client, auth):
    """mark-session отклоняется для медикамента — сеансы только у процедур."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "МедСеанс")
    visit = _visit(client, auth, patient, branch)
    product = _product(client, auth, branch, sku="MED-CRS2")
    tid = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                      json={"kind": "medication", "name": "Капли",
                            "product_id": product["id"], "quantity": "1"}).json()["id"]
    r = client.post(f"{API}/treatments/{tid}/mark-session", headers=auth)
    assert r.status_code == 409, r.text


def test_mark_session_on_completed_visit_is_409(client, auth):
    """mark-session нельзя выполнять на завершённом визите (зеркало prescribe)."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Завершён")
    visit = _visit(client, auth, patient, branch)
    tid = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                      json={"kind": "procedure", "name": "Курс", "sessions_total": 3}).json()["id"]
    # Закрываем визит (баланс 0 — назначение без оплаты).
    done = client.post(f"{API}/visits/{visit['id']}/close", headers=auth)
    assert done.status_code == 200, done.text
    assert done.json()["status"] == "completed", done.text
    r = client.post(f"{API}/treatments/{tid}/mark-session", headers=auth)
    assert r.status_code == 409, r.text


def test_sessions_total_over_cap_is_422(client, auth):
    """sessions_total ограничен потолком (365) — защита от абсурдных курсов."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Потолок")
    visit = _visit(client, auth, patient, branch)
    r = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                    json={"kind": "procedure", "name": "Много", "sessions_total": 366})
    assert r.status_code == 422, r.text


def test_course_billing_not_doubled(client, auth):
    """Платный курс биллит РОВНО одну строку услуги за весь курс (цена за курс,
    не за сеанс); отметка сеансов не создаёт дополнительных начислений."""
    from decimal import Decimal

    branch = _branch(client, auth)
    patient = _patient(client, auth, "Оплата")
    visit = _visit(client, auth, patient, branch)
    service = client.post(f"{API}/services", headers=auth,
                          json={"code": "TX-COURSE", "name": "Платный курс",
                                "price": "150000"}).json()

    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Платный курс",
                           "service_id": service["id"], "sessions_total": 3}).json()
    tid = tx["id"]
    assert tx["visit_item_id"] is not None

    before = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    billed = [i for i in before["items"] if i["service_id"] == service["id"]]
    # Цена за курс: одна строка на цену услуги, а не 3× (не умножается на сеансы).
    assert len(billed) == 1, before
    assert Decimal(before["balance"]) == Decimal("150000")

    # Отметка сеансов не создаёт новых начислений.
    for _ in range(3):
        assert client.post(f"{API}/treatments/{tid}/mark-session", headers=auth).status_code == 200

    after = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    billed_after = [i for i in after["items"] if i["service_id"] == service["id"]]
    assert len(billed_after) == 1, after
    assert Decimal(after["balance"]) == Decimal("150000")


def _pay_full(client, auth, visit_id, *, issue_ticket=False) -> dict:
    """Полная оплата остатка визита (не выпуская талон по умолчанию — курс уже
    назначен, диагностический талон не нужен)."""
    balance = client.get(f"{API}/visits/{visit_id}", headers=auth).json()["balance"]
    r = client.post(f"{API}/payments", headers=auth,
                    json={"visit_id": visit_id, "amount": balance,
                          "issue_queue_ticket": issue_ticket})
    assert r.status_code == 201, r.text
    return r.json()


def test_prepaid_course_keeps_visit_open(client, auth):
    """БАГ 1 (регрессия): полная предоплата платного многосеансного курса ДО
    первого сеанса НЕ должна авто-закрыть визит. После назначения курса и
    завершения приёма (flow=follow_up) полная оплата раньше звала
    close_visit_if_done → visit.status='completed' ещё до дня 1, и
    mark_treatment_session упирался в 409. Теперь незавершённый (prescribed) курс
    держит визит открытым, а день-1 сеанс проходит."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "Предоплата")
    visit = _visit(client, auth, patient, branch)
    service = client.post(f"{API}/services", headers=auth,
                          json={"code": "TX-PREPAID", "name": "Курс вперёд",
                                "price": "90000"}).json()

    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Курс вперёд",
                           "service_id": service["id"], "sessions_total": 3}).json()
    tid = tx["id"]

    # Врач завершает приём: есть назначение (treatment_assigned) → flow=follow_up.
    fin = client.post(f"{API}/visits/{visit['id']}/finish-appointment", headers=auth)
    assert fin.status_code == 200, fin.text
    assert fin.json()["flow_status"] == "follow_up", fin.text
    assert fin.json()["status"] == "open"

    # Регистратура принимает ПОЛНУЮ предоплату курса до выдачи первого Л-талона.
    paid = _pay_full(client, auth, visit["id"])
    # КЛЮЧЕВОЕ утверждение бага 1: визит НЕ закрылся — курс ещё не выполнен.
    assert paid["visit_status"] == "open", paid
    v = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert v["status"] == "open", v
    assert Decimal(v["balance"]) == Decimal("0")

    # День 1: сеанс проходит (не 409, визит открыт).
    r = client.post(f"{API}/treatments/{tid}/mark-session", headers=auth)
    assert r.status_code == 200, r.text
    assert r.json()["sessions_done"] == 1
    assert r.json()["status"] == "prescribed"


def test_course_closes_after_last_session(client, auth):
    """Оплаченный-вперёд курс закрывает визит на ПОСЛЕДНЕМ сеансе: гард снимается,
    когда prescribed-Treatment больше не остаётся (не создали вечно-открытый
    визит). Баланс 0 → авто-close отрабатывает."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "ПоследнийСеанс")
    visit = _visit(client, auth, patient, branch)
    service = client.post(f"{API}/services", headers=auth,
                          json={"code": "TX-LAST", "name": "Курс закрытие",
                                "price": "60000"}).json()
    tx = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                     json={"kind": "procedure", "name": "Курс закрытие",
                           "service_id": service["id"], "sessions_total": 3}).json()
    tid = tx["id"]
    assert client.post(f"{API}/visits/{visit['id']}/finish-appointment",
                       headers=auth).status_code == 200
    _pay_full(client, auth, visit["id"])

    # Первые два сеанса — визит остаётся открытым (курс не добит).
    for _ in range(2):
        assert client.post(f"{API}/treatments/{tid}/mark-session",
                           headers=auth).status_code == 200
    mid = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert mid["status"] == "open", mid

    # Последний сеанс: prescribed-Treatment исчезает → визит авто-закрывается.
    last = client.post(f"{API}/treatments/{tid}/mark-session", headers=auth)
    assert last.status_code == 200, last.text
    assert last.json()["status"] == "done"
    after = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert after["status"] == "completed", after
    assert Decimal(after["balance"]) == Decimal("0")


def test_guards_reject_closed_visit(client, auth):
    """БАГ 2 (регрессия): dispense/complete на закрытом визите отвергаются тем же
    409, что и mark_treatment_session — списание стока и завершение курса не
    попадают в терминальный визит."""
    branch = _branch(client, auth)
    patient = _patient(client, auth, "ЗакрытГарды")
    visit = _visit(client, auth, patient, branch)
    product = _product(client, auth, branch, sku="MED-GUARD")
    # Кладём реальный сток на медикамент, чтобы /dispense упёрся именно в гард
    # закрытого визита, а не в нехватку остатка (иначе тест был бы вырожденным).
    rcpt = client.post(f"{API}/inventory/receipts", headers=auth,
                       json={"branch_id": branch,
                             "items": [{"product_id": product["id"], "quantity": "5"}]})
    assert rcpt.status_code == 201, rcpt.text

    # Процедура (для complete) и медикамент (для dispense) на одном визите.
    proc = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                       json={"kind": "procedure", "name": "Процедура"}).json()
    med = client.post(f"{API}/visits/{visit['id']}/treatments", headers=auth,
                      json={"kind": "medication", "name": "Капли",
                            "product_id": product["id"], "quantity": "1"}).json()

    # Легально закрываем визит (баланс 0 — назначения без оплаты).
    closed = client.post(f"{API}/visits/{visit['id']}/close", headers=auth)
    assert closed.status_code == 200, closed.text
    assert closed.json()["status"] == "completed", closed.text

    # Эталон — mark-session на completed визите даёт 409.
    ref = client.post(f"{API}/treatments/{proc['id']}/mark-session", headers=auth)
    assert ref.status_code == 409, ref.text

    # Гард приведён к тому же коду: complete на completed визите тоже 409.
    comp = client.post(f"{API}/treatments/{proc['id']}/complete", headers=auth)
    assert comp.status_code == 409, comp.text
    assert "completed" in comp.json()["detail"], comp.text

    # dispense: сток есть, поэтому 409 приходит от гарда визита, а не от нехватки
    # остатка — сообщение упоминает закрытый визит, а сток остаётся нетронутым.
    disp = client.post(f"{API}/treatments/{med['id']}/dispense", headers=auth)
    assert disp.status_code == 409, disp.text
    assert "completed" in disp.json()["detail"], disp.text
    stock = client.get(f"{API}/inventory/stock", headers=auth,
                       params={"branch_id": branch}).json()
    med_row = next(r for r in stock if r["product"]["sku"] == "MED-GUARD")
    assert Decimal(med_row["on_hand"]) == Decimal("5"), med_row  # ничего не списано
