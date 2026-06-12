"""Two-track queue (Queue V2): payment -> diagnostic D-ticket -> diagnostics
done -> AUTO doctor V-ticket -> doctor done. Plus per-track numbering, track
separation in call-next, dedupe across tracks and the 2x2 TV board contract.
"""
from __future__ import annotations

from decimal import Decimal

from tests.conftest import API

ROOM = "Каб. Т"


def _branch_id(client, auth) -> str:
    return client.get(f"{API}/branches", headers=auth).json()[0]["id"]


def _paid_visit(client, auth, branch_id, last_name):
    """Register patient + open visit + pay in full -> (visit, ticket_number)."""
    patient = client.post(
        f"{API}/patients", headers=auth,
        json={"first_name": "Очередь", "last_name": last_name, "branch_id": branch_id},
    ).json()
    service = client.get(f"{API}/services", headers=auth).json()["items"][0]
    visit = client.post(
        f"{API}/visits", headers=auth,
        json={"patient_id": patient["id"], "branch_id": branch_id,
              "items": [{"service_id": service["id"], "quantity": 1}]},
    ).json()
    result = client.post(f"{API}/payments", headers=auth,
                         json={"visit_id": visit["id"], "amount": visit["balance"]})
    assert result.status_code == 201, result.text
    return visit, result.json()["queue_ticket_number"]


def _visit_tickets(client, auth, branch_id, visit_id, *, active_only=False):
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "active_only": active_only}).json()
    return [t for t in rows if t["visit_id"] == visit_id]


def _park_other_waiting(client, auth, branch_id, track, keep_id=None):
    """Skip foreign waiting tickets of a track (tests share one session DB) so
    call-next deterministically claims ours. Skip never auto-advances."""
    rows = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "track": track}).json()
    for t in rows:
        if t["status"] == "waiting" and t["id"] != keep_id:
            assert client.post(f"{API}/queue/{t['id']}/skip", headers=auth).status_code == 200


def _call_next(client, auth, branch_id, track):
    return client.post(f"{API}/queue/call-next", headers=auth,
                       json={"branch_id": branch_id, "room": ROOM, "track": track})


def test_payment_issues_diagnostic_ticket(client, auth):
    branch_id = _branch_id(client, auth)
    visit, number = _paid_visit(client, auth, branch_id, "Диагностика")

    assert number and number.startswith("D-")

    diag = client.get(f"{API}/queue", headers=auth,
                      params={"branch_id": branch_id, "track": "diagnostic"}).json()
    mine = [t for t in diag if t["visit_id"] == visit["id"]]
    assert len(mine) == 1
    assert mine[0]["ticket_number"] == number
    assert mine[0]["track"] == "diagnostic"
    assert mine[0]["status"] == "waiting"
    assert mine[0]["called_by_id"] is None

    # The doctor-track filter must not show it.
    doctor = client.get(f"{API}/queue", headers=auth,
                        params={"branch_id": branch_id, "track": "doctor"}).json()
    assert all(t["visit_id"] != visit["id"] for t in doctor)

    # cleanup: park it so later tests' call-next is unaffected
    client.post(f"{API}/queue/{mine[0]['id']}/skip", headers=auth)


def test_diagnostic_done_auto_advances_to_doctor_queue(client, auth):
    branch_id = _branch_id(client, auth)
    visit, d_number = _paid_visit(client, auth, branch_id, "Автопоток")
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"])

    # Claim the D ticket on the diagnostic track; the caller is recorded.
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    called = _call_next(client, auth, branch_id, "diagnostic")
    assert called.status_code == 200, called.text
    called = called.json()
    assert called["id"] == d_ticket["id"]
    assert called["track"] == "diagnostic"
    assert called["called_by_id"] is not None

    assert client.post(f"{API}/queue/{called['id']}/serve", headers=auth).status_code == 200
    assert client.post(f"{API}/queue/{called['id']}/done", headers=auth).status_code == 200

    # AUTO-ADVANCE: a fresh waiting doctor-track V ticket exists for the visit.
    tickets = _visit_tickets(client, auth, branch_id, visit["id"])
    doctor_tickets = [t for t in tickets if t["track"] == "doctor"]
    assert len(doctor_tickets) == 1
    v_ticket = doctor_tickets[0]
    assert v_ticket["ticket_number"].startswith("V-")
    assert v_ticket["status"] == "waiting"
    assert v_ticket["room"] is None

    # State machine intact: re-completing the finished D ticket is 409 ...
    assert client.post(f"{API}/queue/{called['id']}/done", headers=auth).status_code == 409
    # ... and the failed transition spawned nothing.
    tickets = _visit_tickets(client, auth, branch_id, visit["id"])
    assert len([t for t in tickets if t["track"] == "doctor"]) == 1

    # Completing the V (doctor) ticket does NOT spawn anything further.
    _park_other_waiting(client, auth, branch_id, "doctor", keep_id=v_ticket["id"])
    called_v = _call_next(client, auth, branch_id, "doctor").json()
    assert called_v["id"] == v_ticket["id"]
    assert client.post(f"{API}/queue/{called_v['id']}/done", headers=auth).status_code == 200
    after = _visit_tickets(client, auth, branch_id, visit["id"])
    assert len(after) == 2  # exactly the original D + the auto V
    assert all(t["status"] == "done" for t in after)


def test_repeat_payment_reuses_active_ticket_on_either_track(client, auth):
    branch_id = _branch_id(client, auth)
    visit, d_number = _paid_visit(client, auth, branch_id, "Дубликат")
    service = client.get(f"{API}/services", headers=auth).json()["items"][0]

    # Bill an extra service -> balance reopens -> pay again while D is active:
    # the existing D ticket is reused, no second ticket appears.
    client.post(f"{API}/visits/{visit['id']}/items", headers=auth,
                json={"service_id": service["id"], "quantity": 1})
    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    assert Decimal(refreshed["balance"]) > Decimal("0.00")
    second = client.post(f"{API}/payments", headers=auth,
                         json={"visit_id": visit["id"], "amount": refreshed["balance"]})
    assert second.status_code == 201, second.text
    assert second.json()["queue_ticket_number"] == d_number
    assert len(_visit_tickets(client, auth, branch_id, visit["id"])) == 1

    # Now finish diagnostics -> auto V ticket becomes the visit's active ticket.
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"])
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    called = _call_next(client, auth, branch_id, "diagnostic").json()
    assert called["id"] == d_ticket["id"]
    assert client.post(f"{API}/queue/{called['id']}/done", headers=auth).status_code == 200
    [v_ticket] = [t for t in _visit_tickets(client, auth, branch_id, visit["id"])
                  if t["track"] == "doctor"]

    # Paying once more must NOT issue a second D ticket: the dedupe sees the
    # active doctor-track ticket (cross-track check).
    client.post(f"{API}/visits/{visit['id']}/items", headers=auth,
                json={"service_id": service["id"], "quantity": 1})
    refreshed = client.get(f"{API}/visits/{visit['id']}", headers=auth).json()
    third = client.post(f"{API}/payments", headers=auth,
                        json={"visit_id": visit["id"], "amount": refreshed["balance"]})
    assert third.status_code == 201, third.text
    assert third.json()["queue_ticket_number"] == v_ticket["ticket_number"]
    tickets = _visit_tickets(client, auth, branch_id, visit["id"])
    assert len(tickets) == 2  # still just the done D + the active V

    # cleanup
    client.post(f"{API}/queue/{v_ticket['id']}/skip", headers=auth)


def test_call_next_respects_track_separation(client, auth):
    branch_id = _branch_id(client, auth)
    visit, _ = _paid_visit(client, auth, branch_id, "Разделение")
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"])

    # With no waiting doctor tickets, a doctor-track call must 404 even though
    # a diagnostic ticket is waiting right there.
    _park_other_waiting(client, auth, branch_id, "doctor")
    resp = _call_next(client, auth, branch_id, "doctor")
    assert resp.status_code == 404

    # track defaults to "doctor" when omitted -> same result.
    resp = client.post(f"{API}/queue/call-next", headers=auth,
                       json={"branch_id": branch_id, "room": ROOM})
    assert resp.status_code == 404

    # The waiting D ticket was never touched by the doctor-track calls.
    [still] = _visit_tickets(client, auth, branch_id, visit["id"])
    assert still["status"] == "waiting" and still["track"] == "diagnostic"

    # cleanup
    client.post(f"{API}/queue/{d_ticket['id']}/skip", headers=auth)


def test_tv_board_two_tracks_and_specialist(client, auth):
    branch_id = _branch_id(client, auth)
    visit, d_number = _paid_visit(client, auth, branch_id, "Табло")
    [d_ticket] = _visit_tickets(client, auth, branch_id, visit["id"])

    board = client.get(f"{API}/queue/tv-board/{branch_id}").json()  # public, no auth
    for track in ("doctor", "diagnostic"):
        assert "now" in board[track] and "waiting" in board[track]
    waiting_entry = next(e for e in board["diagnostic"]["waiting"]
                         if e["ticket_number"] == d_number)
    assert waiting_entry["specialist"] is None
    assert waiting_entry["called_at"] is None

    # Call it -> appears under diagnostic "now" with the caller's full name.
    _park_other_waiting(client, auth, branch_id, "diagnostic", keep_id=d_ticket["id"])
    called = _call_next(client, auth, branch_id, "diagnostic").json()
    assert called["id"] == d_ticket["id"]

    me = client.get(f"{API}/auth/me", headers=auth).json()
    board = client.get(f"{API}/queue/tv-board/{branch_id}").json()
    entry = next(e for e in board["diagnostic"]["now"] if e["ticket_number"] == d_number)
    assert entry["specialist"] == me["full_name"]
    assert entry["called_at"] is not None
    assert entry["room"] == ROOM
    assert entry["status"] == "called"
    assert d_number not in [e["ticket_number"] for e in board["diagnostic"]["waiting"]]

    # cleanup
    client.post(f"{API}/queue/{d_ticket['id']}/skip", headers=auth)


def test_per_track_daily_counters_are_independent(client, auth):
    # A fresh branch gives fresh per-branch counters.
    branch = client.post(f"{API}/branches", headers=auth,
                         json={"name": "Филиал Очередь-Тест", "code": "QT"})
    assert branch.status_code == 201, branch.text
    branch_id = branch.json()["id"]

    visit, first = _paid_visit(client, auth, branch_id, "Счётчик")
    assert first == "D-001"

    # Finish diagnostics -> auto doctor ticket starts its own counter at V-001.
    called = _call_next(client, auth, branch_id, "diagnostic").json()
    assert client.post(f"{API}/queue/{called['id']}/done", headers=auth).status_code == 200
    [v_ticket] = [t for t in _visit_tickets(client, auth, branch_id, visit["id"])
                  if t["track"] == "doctor"]
    assert v_ticket["ticket_number"] == "V-001"  # D-001 and V-001 coexist same day

    # A second paid visit increments only the D counter.
    _, second = _paid_visit(client, auth, branch_id, "Счётчик2")
    assert second == "D-002"


def test_full_refund_skips_active_tickets(client, auth):
    """A refunded patient must leave the queue: no board entry, no auto-advance."""
    branch_id = _branch_id(client, auth)
    visit, ticket_no = _paid_visit(client, auth, branch_id, "Возвратов")
    payments = client.get(f"{API}/payments", headers=auth,
                          params={"visit_id": visit["id"]}).json()["items"]
    refunded = client.post(f"{API}/payments/{payments[0]['id']}/refund", headers=auth)
    assert refunded.status_code == 200, refunded.text

    mine = _visit_tickets(client, auth, branch_id, visit["id"])
    assert mine and all(t["status"] == "skipped" for t in mine)


def test_no_auto_advance_for_closed_visit(client, auth):
    """Diagnostics done on a ticket of an already-closed visit spawns no V ticket."""
    branch_id = _branch_id(client, auth)
    visit, ticket_no = _paid_visit(client, auth, branch_id, "Закрытый")
    closed = client.post(f"{API}/visits/{visit['id']}/close", headers=auth)
    assert closed.status_code == 200, closed.text

    _park_other_waiting(client, auth, branch_id, "diagnostic",
                        keep_id=_visit_tickets(client, auth, branch_id,
                                               visit["id"])[0]["id"])
    called = _call_next(client, auth, branch_id, "diagnostic").json()
    assert called["visit_id"] == visit["id"]
    done = client.post(f"{API}/queue/{called['id']}/done", headers=auth)
    assert done.status_code == 200, done.text

    doctor_q = client.get(f"{API}/queue", headers=auth,
                          params={"branch_id": branch_id, "track": "doctor"}).json()
    assert not any(t["visit_id"] == visit["id"] for t in doctor_q)


def test_stale_yesterday_ticket_excluded_from_active_views(client, auth):
    """A ticket forgotten yesterday must not head today's queue or board."""
    import uuid as _uuid
    from datetime import datetime, timedelta, timezone

    from app.core.database import SessionLocal
    from app.models.queue import QueueTicket

    branch_id = _branch_id(client, auth)
    visit, ticket_no = _paid_visit(client, auth, branch_id, "Вчерашний")

    db = SessionLocal()
    try:
        row = db.query(QueueTicket).filter(
            QueueTicket.visit_id == _uuid.UUID(visit["id"])).one()
        row.created_at = datetime.now(timezone.utc) - timedelta(days=1, hours=2)
        db.commit()
    finally:
        db.close()

    active = client.get(f"{API}/queue", headers=auth,
                        params={"branch_id": branch_id, "track": "diagnostic"}).json()
    assert not any(t["visit_id"] == visit["id"] for t in active)
    board = client.get(f"{API}/queue/tv-board/{branch_id}").json()
    entries = [e for col in ("now", "waiting") for e in board["diagnostic"][col]]
    assert all(e["ticket_number"] != ticket_no for e in entries)
