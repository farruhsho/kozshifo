"""Call-log DTOs — PBX webhook + Android reception-phone agent (TZ Modul 9)."""
from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

CallStatus = Literal["answered", "missed", "rejected", "outgoing"]


# ── PBX webhook (legacy single-call seam) ────────────────────────────────────
class CallIngest(BaseModel):
    """Webhook body the PBX (Asterisk dialplan / AMI bridge) POSTs per call."""

    direction: Literal["in", "out"] = "in"
    phone: str = Field(min_length=1, max_length=32)
    started_at: datetime
    duration_seconds: int = Field(0, ge=0)
    recording_url: str | None = Field(None, max_length=512)
    note: str | None = Field(None, max_length=512)


# ── Android agent (reception phones) ─────────────────────────────────────────
class AgentCallIngest(BaseModel):
    """One finished call as the reception-phone agent reports it.

    ``external_id`` is the phone's own call-log id; together with the device it
    makes re-uploads idempotent. ``wait_seconds`` is the ring time before pickup
    (answered) or before the call dropped (missed/rejected).
    """

    external_id: str = Field(min_length=1, max_length=64)
    direction: Literal["in", "out"] = "in"
    status: CallStatus = "answered"
    phone: str = Field(min_length=1, max_length=32)
    started_at: datetime
    ended_at: datetime | None = None
    wait_seconds: int = Field(0, ge=0)
    duration_seconds: int = Field(0, ge=0)
    note: str | None = Field(None, max_length=512)


class AgentBatchResult(BaseModel):
    """Outcome of an agent batch upload — the agent drops what's acknowledged."""

    received: int
    ingested: int
    duplicates: int


class HeartbeatIn(BaseModel):
    app_version: str | None = Field(None, max_length=32)


class HeartbeatOut(BaseModel):
    ok: bool = True
    server_time: datetime


# ── Device management (director) ─────────────────────────────────────────────
class CallDeviceCreate(BaseModel):
    label: str = Field(min_length=1, max_length=120)
    phone_number: str | None = Field(None, max_length=32)
    branch_id: UUID | None = None


class CallDeviceUpdate(BaseModel):
    label: str | None = Field(None, min_length=1, max_length=120)
    phone_number: str | None = Field(None, max_length=32)
    branch_id: UUID | None = None
    is_active: bool | None = None


class CallDeviceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    label: str
    phone_number: str | None
    branch_id: UUID | None
    is_active: bool
    last_seen_at: datetime | None
    app_version: str | None
    online: bool  # computed against the offline threshold


class CallDeviceCreated(CallDeviceOut):
    """Returned ONCE on create / key rotation — carries the plaintext key.

    The key is never retrievable again (only its hash is stored); the director
    copies it into the phone's agent app now.
    """

    api_key: str


# ── Journal rows ─────────────────────────────────────────────────────────────
class CallPatientBrief(BaseModel):
    """Just enough to render 'who called' in the journal row."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    last_name: str
    first_name: str


class CallDeviceBrief(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    label: str


class CallOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    direction: str
    status: str
    phone: str
    started_at: datetime
    ended_at: datetime | None
    wait_seconds: int
    duration_seconds: int
    recording_url: str | None
    note: str | None
    branch_id: UUID | None
    patient: CallPatientBrief | None
    device: CallDeviceBrief | None


# ── KPI summary (director monitoring) ────────────────────────────────────────
class CallDeviceStat(BaseModel):
    device_id: UUID | None
    label: str
    total: int
    answered: int
    missed: int
    avg_wait_seconds: int


class CallHourBucket(BaseModel):
    hour: int  # 0–23, clinic-local
    total: int
    missed: int


class CallsSummary(BaseModel):
    total: int
    incoming: int
    answered: int
    missed: int
    rejected: int
    outgoing: int
    missed_rate: float  # missed / incoming, 0–1
    avg_wait_seconds: int  # over answered incoming calls
    max_wait_seconds: int
    by_device: list[CallDeviceStat]
    by_hour: list[CallHourBucket]
    offline_devices: list[CallDeviceOut]
