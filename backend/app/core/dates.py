"""Single source of the business calendar date.

Stock-expiry decisions (FEFO usability, dashboard deficit/expiring KPIs,
StockBatch.expired) must all agree on what "today" is — mixing UTC and
server-local dates made the dashboard disagree with the engine for ~5 hours
around midnight on UTC+5 hosts. Server-local date is the business convention.
"""
from __future__ import annotations

from datetime import date


def business_today() -> date:
    return date.today()
