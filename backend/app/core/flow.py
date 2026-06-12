"""Smart Workflow Engine — the visit's lifecycle drives ITSELF.

Owner automation: `Visit.flow_status` is never set by a human or an endpoint.
Real events that already happen in the system (a payment lands, a queue ticket
is called, the doctor prescribes, reception closes/cancels) call
`advance_flow()` at their existing success points, inside the same DB
transaction — so the lifecycle can never disagree with what actually happened.

Event table (event -> resulting flow_status):

    paid_in_full          -> waiting_diagnostic   ONLY from "registered": the
                             first full payment starts the journey; settling a
                             later bill (e.g. a prescribed surgery) must never
                             throw the patient back into the diagnostics queue
    diagnostic_called     -> in_diagnostic        D-ticket claimed by call-next
    diagnostic_skipped    -> waiting_diagnostic   called D no-show skipped
    diagnostic_done       -> waiting_doctor       D-ticket done (auto V-ticket point)
    doctor_called         -> in_doctor            V-ticket claimed by call-next
    doctor_skipped        -> waiting_doctor       called V no-show skipped
    treatment_prescribed  -> treatment_assigned   doctor prescribed a treatment
    surgery_prescribed    -> surgery_assigned     operation prescribed, no date yet
    surgery_scheduled     -> surgery_scheduled    operation prescribed WITH a date
    surgery_performed     -> surgery_completed    operation performed (stock written off)
    appointment_finished  -> follow_up | completed   doctor V-ticket marked done:
                             follow_up when something was assigned (treatment_/
                             surgery_*), completed when nothing was
    visit_closed          -> completed            reception closed the visit
    visit_cancelled       -> cancelled            reception cancelled the visit

Plan changes (operation/treatment cancelled) go through `recompute_plan()`,
which re-derives the assignment state from what actually remains planned.
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.visit import Visit

FLOW_EVENTS: dict[str, str] = {
    "paid_in_full": "waiting_diagnostic",
    "diagnostic_called": "in_diagnostic",
    "diagnostic_skipped": "waiting_diagnostic",
    "diagnostic_done": "waiting_doctor",
    "doctor_called": "in_doctor",
    "doctor_skipped": "waiting_doctor",
    "treatment_prescribed": "treatment_assigned",
    "surgery_prescribed": "surgery_assigned",
    "surgery_scheduled": "surgery_scheduled",
    "surgery_performed": "surgery_completed",
    "appointment_finished": "follow_up",  # contextual: "completed" when nothing assigned
    "visit_closed": "completed",
    "visit_cancelled": "cancelled",
}

# "Something was assigned": a doctor ticket finishing on these states means the
# patient leaves with a plan -> follow_up, not completed.
_ASSIGNED = ("treatment_assigned", "surgery_assigned", "surgery_scheduled", "surgery_completed")


def _is_locked(visit: Visit) -> bool:
    """The flow is frozen only when the VISIT itself is closed/cancelled.

    flow_status == "completed" alone (appointment finished early) must NOT
    swallow later real events — the doctor may legitimately prescribe after
    marking the ticket done, and a live (open) visit keeps flowing.
    """
    if visit.flow_status == "cancelled":
        return True
    return visit.flow_status == "completed" and visit.status in ("completed", "cancelled")


def advance_flow(db: Session, visit: Visit, event: str) -> None:
    """Apply one lifecycle event to the visit. No commit — caller's transaction."""
    if event not in FLOW_EVENTS:  # fixed vocabulary — a typo in a hook must explode in dev
        raise ValueError(f"Unknown flow event: {event!r}")
    current = visit.flow_status

    # close/cancel always win — they are the only events allowed to rewrite a
    # locked state.
    if event in ("visit_closed", "visit_cancelled"):
        visit.flow_status = FLOW_EVENTS[event]
        return
    if _is_locked(visit):
        return
    # The journey starts exactly once: later full payments (surgery billed and
    # settled mid-flow) must not regress the patient to the diagnostics queue.
    if event == "paid_in_full" and current != "registered":
        return
    # No-show skips revert the "in the room" claim without inventing progress.
    if event == "diagnostic_skipped" and current != "in_diagnostic":
        return
    if event == "doctor_skipped" and current != "in_doctor":
        return
    # Doctor finished the appointment: with assignments the patient is in
    # follow-up care; with none, the journey is simply over.
    if event == "appointment_finished":
        visit.flow_status = "follow_up" if current in _ASSIGNED else "completed"
        return
    # Surgery outranks treatment: prescribing eye drops alongside a planned
    # operation must not downgrade surgery_* back to treatment_assigned.
    if event == "treatment_prescribed" and current.startswith("surgery"):
        return
    visit.flow_status = FLOW_EVENTS[event]


def recompute_plan(db: Session, visit: Visit) -> None:
    """Re-derive the assignment state after a plan change (cancel of an
    operation/treatment). Only acts when the flow currently claims a plan —
    the lifecycle must not keep advertising a surgery that was cancelled.
    """
    if visit.flow_status not in _ASSIGNED:
        return
    # Local imports: operations/treatments import flow (avoid module cycles).
    from app.models.operation import Operation, Treatment
    from app.models.queue import QueueTicket

    ops = db.execute(
        select(Operation.status, Operation.scheduled_at)
        .where(Operation.visit_id == visit.id, Operation.status.in_(("planned", "done")))
    ).all()
    planned = [o for o in ops if o.status == "planned"]
    if planned:
        visit.flow_status = ("surgery_scheduled"
                             if any(o.scheduled_at is not None for o in planned)
                             else "surgery_assigned")
        return
    if any(o.status == "done" for o in ops):
        visit.flow_status = "surgery_completed"
        return
    has_treatment = db.execute(
        select(Treatment.id)
        .where(Treatment.visit_id == visit.id, Treatment.status == "prescribed")
        .limit(1)
    ).first()
    if has_treatment is not None:
        visit.flow_status = "treatment_assigned"
        return
    # Nothing planned anymore: fall back to where the patient physically is.
    active_doctor = db.execute(
        select(QueueTicket.status)
        .where(
            QueueTicket.visit_id == visit.id,
            QueueTicket.track == "doctor",
            QueueTicket.status.in_(("waiting", "called", "serving")),
        )
        .limit(1)
    ).scalar_one_or_none()
    if active_doctor in ("called", "serving"):
        visit.flow_status = "in_doctor"
    elif active_doctor == "waiting":
        visit.flow_status = "waiting_doctor"
    else:
        visit.flow_status = "completed"
