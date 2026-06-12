"""Notification seam: fire-and-forget event delivery.

Contract:
- Called AFTER the caller's business commit — never inside it. notify() owns
  its own (tiny) transaction for the notification rows.
- Notifications must NEVER break a business request: every code path here is
  wrapped so a Telegram outage, a DB hiccup or a programming error degrades to
  "no notification", not to a 500 on the write-off/operation that fired it.
- Always writes a channel="log" row (the in-system journal). If a Telegram bot
  token + chat id are configured, additionally records a channel="telegram" row
  (status "queued") and delivers it from a daemon thread — the HTTP request that
  fired the event never waits on Telegram. The thread updates the row to
  sent/failed in its own session.
- The bot token must never appear in stored errors or logs (httpx exception
  text includes the request URL, which embeds the token) — see _sanitize.
"""
from __future__ import annotations

import logging
import threading
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Iterable

import httpx
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.stock import on_hand
from app.models.inventory import Product
from app.models.notification import Notification

logger = logging.getLogger(__name__)

_TELEGRAM_TIMEOUT_S = 3.0
_LOW_STOCK_DEBOUNCE = timedelta(hours=24)


def _sanitize(text: str) -> str:
    """Strip the bot token from any error/log text (httpx errors embed the URL)."""
    token = settings.telegram_bot_token
    if token:
        text = text.replace(token, "***")
    return text[:512]


def _deliver_telegram(notification_id: uuid.UUID, text: str) -> None:
    """Daemon-thread worker: push to Telegram, update the queued row's status."""
    from app.core.database import SessionLocal  # local import: no cycles at module load

    status, error = "sent", None
    try:
        url = f"https://api.telegram.org/bot{settings.telegram_bot_token}/sendMessage"
        response = httpx.post(
            url,
            json={"chat_id": settings.telegram_chat_id, "text": text},
            timeout=_TELEGRAM_TIMEOUT_S,
        )
        response.raise_for_status()
    except Exception as exc:
        status, error = "failed", _sanitize(str(exc))
        logger.warning("Telegram notification failed: %s", error)

    try:
        db = SessionLocal()
        try:
            row = db.get(Notification, notification_id)
            if row is not None:
                row.status = status
                row.error = error
                db.commit()
        finally:
            db.close()
    except Exception:
        logger.exception("Could not record Telegram delivery status")


def notify(
    db: Session,
    *,
    event: str,
    title: str,
    body: str | None = None,
    ref_type: str | None = None,
    ref_id: uuid.UUID | None = None,
    branch_id: uuid.UUID | None = None,
) -> list[Notification]:
    """Record an event (and push it to Telegram when configured). COMMITS itself.

    Returns the created Notification rows; returns [] and swallows the error if
    anything at all goes wrong — a notification failure must never surface as a
    failure of the business request that triggered it.
    """
    try:
        # Column-capped: a 255-char product name must degrade to a truncated
        # title, never to a silently lost row (Postgres enforces VARCHAR sizes).
        title = title[:255]
        body = body[:1000] if body else body

        rows: list[Notification] = [
            Notification(
                event=event, channel="log", title=title, body=body,
                status="sent", ref_type=ref_type, ref_id=ref_id, branch_id=branch_id,
            )
        ]

        telegram_row: Notification | None = None
        if settings.telegram_bot_token and settings.telegram_chat_id:
            telegram_row = Notification(
                event=event, channel="telegram", title=title, body=body,
                status="queued", ref_type=ref_type, ref_id=ref_id, branch_id=branch_id,
            )
            rows.append(telegram_row)

        # Persist FIRST (debounce queries these rows), deliver asynchronously —
        # a slow Telegram must never stall the clinical request thread.
        db.add_all(rows)
        db.commit()

        if telegram_row is not None:
            threading.Thread(
                target=_deliver_telegram,
                args=(telegram_row.id, f"{title}\n{body or ''}"),
                daemon=True,
            ).start()
        return rows
    except Exception:  # last resort: notifications never break the request
        logger.exception("notify() failed for event %s", event)
        try:
            db.rollback()
        except Exception:
            pass
        return []


def check_low_stock(
    db: Session,
    product_ids: Iterable[uuid.UUID],
    branch_id: uuid.UUID,
) -> None:
    """Fire a low_stock notification for each active product at/below min_stock.

    Anti-spam: at most one low_stock notification per (product, branch) per
    24 hours. Called after the business commit; swallows every error.
    """
    try:
        since = datetime.now(timezone.utc) - _LOW_STOCK_DEBOUNCE
        for product_id in dict.fromkeys(product_ids):  # de-dup, keep order
            product = db.get(Product, product_id)
            if product is None or not product.is_active:
                continue
            remaining = on_hand(db, product_id, branch_id)
            if remaining > Decimal(product.min_stock):
                continue
            already = db.execute(
                select(Notification.id)
                .where(
                    Notification.event == "low_stock",
                    Notification.ref_id == product_id,
                    Notification.branch_id == branch_id,
                    Notification.created_at >= since,
                )
                .limit(1)
            ).scalar_one_or_none()
            if already is not None:
                continue
            notify(
                db,
                event="low_stock",
                title=f"Дефицит: {product.name}",
                body=f"Остаток {remaining} {product.unit} (минимум {product.min_stock})",
                ref_type="product",
                ref_id=product_id,
                branch_id=branch_id,
            )
    except Exception:  # never break the business request
        logger.exception("check_low_stock() failed")
        try:
            db.rollback()
        except Exception:
            pass
