"""Device integration seam — every ingestion path normalizes to one draft shape.

The clinic's instruments are budget devices without DICOM/HL7 (DOMAIN.md §1),
so the two adapters that work *today* are manual entry and file import. The
protocol adapters (serial / HL7 / DICOM) are deliberate stubs: they fix the
interface now so a later epic can implement transport without touching the
features layer.

Normalized draft contract (what `parse()` returns):
    {"result_type": "refraction|biometry|bscan_image|file",
     "payload": dict | None,
     "file_path": str | None}

Refraction payload shape (RMK-700, per docs/prompts/02 §5.C):
    {"od": {"sph": "-1.25", "cyl": "-0.50", "axis": 170},
     "os": {"sph": "-1.00", "cyl": "-0.25", "axis": 10}}
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from decimal import Decimal, InvalidOperation
from pathlib import PurePath
from typing import Any


class AdapterError(ValueError):
    """Raised when raw device input cannot be normalized (maps to HTTP 422)."""


def validate_refraction_payload(payload: dict | None) -> dict:
    """Validate the OD/OS sph/cyl/axis shape; returns the payload unchanged."""
    if not isinstance(payload, dict):
        raise AdapterError("Refraction payload must be an object with 'od'/'os' keys")
    for eye in ("od", "os"):
        eye_data = payload.get(eye)
        if eye_data is None:
            continue  # single-eye measurement is valid
        if not isinstance(eye_data, dict):
            raise AdapterError(f"Refraction '{eye}' must be an object")
        for key in ("sph", "cyl"):
            value = eye_data.get(key)
            if value is None:
                continue
            try:
                dec = Decimal(str(value))
            except InvalidOperation:
                raise AdapterError(f"Refraction {eye}.{key} is not a decimal: {value!r}") from None
            if not Decimal("-30") <= dec <= Decimal("30"):
                raise AdapterError(f"Refraction {eye}.{key} out of range [-30, 30]: {value!r}")
        axis = eye_data.get("axis")
        if axis is not None:
            if not isinstance(axis, int) or isinstance(axis, bool) or not 0 <= axis <= 180:
                raise AdapterError(f"Refraction {eye}.axis must be an integer 0–180: {axis!r}")
    if payload.get("od") is None and payload.get("os") is None:
        raise AdapterError("Refraction payload must contain at least one of 'od'/'os'")
    return payload


class DeviceAdapter(ABC):
    """Normalizes one kind of raw device input into a DeviceResult draft."""

    @abstractmethod
    def parse(self, *, result_type: str, payload: dict | None = None,
              file_path: str | None = None, **kwargs: Any) -> dict:
        """Return the normalized draft or raise AdapterError on bad input."""


class ManualEntryAdapter(DeviceAdapter):
    """Operator types the values in (RMK-700 today: read screen, enter numbers)."""

    def parse(self, *, result_type: str, payload: dict | None = None,
              file_path: str | None = None, **kwargs: Any) -> dict:
        if result_type == "refraction":
            payload = validate_refraction_payload(payload)
        elif payload is None and file_path is None:
            raise AdapterError(f"Manual {result_type} result needs a payload")
        return {"result_type": result_type, "payload": payload, "file_path": file_path}


class FileImportAdapter(DeviceAdapter):
    """File/image import (upload or watched folder) — CAS-2000BER B-scans today.

    Stores the path and infers the result type from the extension when the
    caller passes the generic ``file`` type. Binary upload/storage is a later
    epic; this epic records the reference.
    """

    _IMAGE_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".dcm"}

    def parse(self, *, result_type: str, payload: dict | None = None,
              file_path: str | None = None, **kwargs: Any) -> dict:
        if not file_path:
            raise AdapterError("File import requires file_path")
        if result_type == "file" and PurePath(file_path).suffix.lower() in self._IMAGE_EXT:
            result_type = "bscan_image"
        if result_type == "refraction":
            payload = validate_refraction_payload(payload)
        return {"result_type": result_type, "payload": payload, "file_path": file_path}


class SerialAdapter(DeviceAdapter):
    """TODO (Phase 4): RS-232/USB-serial capture (many refractometers print via serial).

    Will open the configured port from ``Device.settings`` (baud/parity), read
    the measurement frame, and map it to the refraction payload shape.
    """

    def parse(self, **kwargs: Any) -> dict:
        raise NotImplementedError("SerialAdapter is a Phase-4 integration stub")


class Hl7Adapter(DeviceAdapter):
    """TODO (Phase 4): HL7 v2 ORU^R01 ingestion for devices that support it."""

    def parse(self, **kwargs: Any) -> dict:
        raise NotImplementedError("Hl7Adapter is a Phase-4 integration stub")


class DicomAdapter(DeviceAdapter):
    """TODO (Phase 4): DICOM C-STORE / file ingestion (don't assume devices have it)."""

    def parse(self, **kwargs: Any) -> dict:
        raise NotImplementedError("DicomAdapter is a Phase-4 integration stub")


def adapter_for_source(source: str) -> DeviceAdapter:
    """Pick the adapter for an API-submitted result."""
    return FileImportAdapter() if source == "import" else ManualEntryAdapter()
