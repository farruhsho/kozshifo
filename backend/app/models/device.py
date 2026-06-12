"""Medical devices and their measurement results.

The clinic's two real instruments (docs/DOMAIN.md §1) are seeded on startup:
Supore RMK-700 auto-refractometer and CAS-2000BER ophthalmic A/B ultrasound.
Results arrive through pluggable adapters (core/devices/adapters.py) — manual
entry and file import now; serial/HL7/DICOM are documented stubs for later.
"""
from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import JSON, Date, DateTime, ForeignKey, Integer, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDPKMixin


class Device(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "devices"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # ab_ultrasound | refractometer | other
    device_type: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    model: Mapped[str | None] = mapped_column(String(128), nullable=True)
    manufacturer: Mapped[str | None] = mapped_column(String(255), nullable=True)
    serial_no: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    asset_code: Mapped[str | None] = mapped_column(String(64), nullable=True)
    # manual | file | serial | usb | hl7 | dicom
    connection_type: Mapped[str] = mapped_column(String(16), default="manual", nullable=False)
    branch_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("branches.id", ondelete="SET NULL"), nullable=True
    )
    # active | inactive | maintenance
    status: Mapped[str] = mapped_column(String(16), default="active", index=True, nullable=False)
    manufacture_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    settings: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    eu_rep: Mapped[str | None] = mapped_column(String(255), nullable=True)
    address: Mapped[str | None] = mapped_column(String(512), nullable=True)
    useful_life_years: Mapped[int | None] = mapped_column(Integer, nullable=True)

    results: Mapped[list["DeviceResult"]] = relationship(back_populates="device")


class DeviceResult(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "device_results"

    device_id: Mapped[uuid.UUID] = mapped_column(
        Uuid, ForeignKey("devices.id", ondelete="CASCADE"), index=True, nullable=False
    )
    patient_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("patients.id", ondelete="SET NULL"), index=True, nullable=True
    )
    visit_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid, ForeignKey("visits.id", ondelete="SET NULL"), index=True, nullable=True
    )
    # refraction | biometry | bscan_image | file
    result_type: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    payload: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    file_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    measured_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    # manual | import
    source: Mapped[str] = mapped_column(String(16), default="manual", nullable=False)

    device: Mapped[Device] = relationship(back_populates="results")
