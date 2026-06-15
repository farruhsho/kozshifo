"""Hikvision face-terminal ISAPI client (HTTP Digest).

A thin, synchronous wrapper over the handful of ISAPI calls the Face ID
integration needs (docs/INTEGRATIONS_HIKVISION.md §4):

  * get_device_info  — GET  /ISAPI/System/deviceInfo            (test connection)
  * enroll_user      — POST /ISAPI/AccessControl/UserInfo/Record (provision person)
  * delete_user      — PUT  /ISAPI/AccessControl/UserInfo/Delete
  * upload_face      — POST /ISAPI/Intelligent/FDLib/FaceDataRecord (bind a photo)
  * fetch_events     — POST /ISAPI/AccessControl/AcsEvent          (poll events)

Design: every method either returns parsed data or raises ``TerminalUnreachable``
(network / auth / timeout) or ``TerminalError`` (device answered with an error).
The feature layer turns ``TerminalUnreachable`` into ``online = false`` rather
than a 500 — a powered-off terminal must never break the UI.

Several payload shapes are firmware-dependent and marked [verify on device] in
the design doc; the defaults here follow the common MinMoe / AccessControl
ISAPI contract. ``httpx`` (already a dependency, see core/notify) ships
``DigestAuth``; no new package is needed.
"""
from __future__ import annotations

import json
import uuid
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import Any

import httpx


class TerminalUnreachable(Exception):
    """Network failure, timeout, or rejected credentials — the device is down."""


class TerminalError(Exception):
    """The device answered, but with an error status (bad request / not supported)."""


def _strip_ns(tag: str) -> str:
    """`{http://...}model` -> `model` (Hikvision XML is namespaced)."""
    return tag.rsplit("}", 1)[-1]


def _parse_device_info(xml_text: str) -> dict[str, str]:
    """Pull the useful identity fields out of a deviceInfo XML document."""
    wanted = {
        "deviceName", "deviceID", "model", "serialNumber",
        "firmwareVersion", "firmwareReleasedDate", "macAddress",
    }
    info: dict[str, str] = {}
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return info
    for child in root.iter():
        name = _strip_ns(child.tag)
        if name in wanted and child.text:
            info[name] = child.text.strip()
    return info


class HikvisionClient:
    """One configured terminal. Cheap to construct; opens a client per call."""

    def __init__(
        self,
        host: str,
        port: int,
        username: str,
        password: str,
        *,
        use_https: bool = False,
        timeout: float = 5.0,
    ) -> None:
        scheme = "https" if use_https else "http"
        self._base = f"{scheme}://{host}:{port}"
        self._auth = httpx.DigestAuth(username, password)
        self._timeout = timeout

    @classmethod
    def from_terminal(cls, terminal: Any, *, timeout: float = 5.0) -> "HikvisionClient":
        """Build a client from a FaceTerminal ORM row."""
        return cls(
            terminal.host,
            terminal.port,
            terminal.username,
            terminal.password,
            use_https=terminal.use_https,
            timeout=timeout,
        )

    # ----------------------------------------------------------------- transport

    def _request(self, method: str, path: str, **kwargs: Any) -> httpx.Response:
        try:
            with httpx.Client(
                auth=self._auth, timeout=self._timeout, verify=False  # LAN, self-signed
            ) as client:
                resp = client.request(method, f"{self._base}{path}", **kwargs)
        except httpx.HTTPError as exc:
            raise TerminalUnreachable(f"{type(exc).__name__}: {exc}") from exc
        if resp.status_code == 401:
            raise TerminalUnreachable("authentication failed (check username / password)")
        return resp

    @staticmethod
    def _check_isapi_ok(resp: httpx.Response, what: str) -> dict:
        """Hikvision JSON responses carry statusCode==1 / statusString=='OK' on success."""
        if resp.status_code >= 400:
            raise TerminalError(f"{what}: HTTP {resp.status_code} {resp.text[:200]}")
        try:
            data = resp.json()
        except (json.JSONDecodeError, ValueError):
            return {}
        status_code = data.get("statusCode")
        if status_code is not None and status_code != 1:
            raise TerminalError(
                f"{what}: device status {status_code} "
                f"{data.get('statusString', '')} {data.get('subStatusCode', '')}".strip()
            )
        return data

    # ------------------------------------------------------------------- methods

    def get_device_info(self) -> dict[str, str]:
        """Identity probe — also serves as the connection test."""
        resp = self._request("GET", "/ISAPI/System/deviceInfo")
        if resp.status_code >= 400:
            raise TerminalError(f"deviceInfo: HTTP {resp.status_code}")
        return _parse_device_info(resp.text)

    def enroll_user(
        self,
        employee_no: str,
        name: str,
        *,
        door_no: int = 1,
        valid_begin: str = "2024-01-01T00:00:00",
        valid_end: str = "2037-12-31T23:59:59",
    ) -> dict:
        """Create/replace a person on the device (idempotent by employeeNo)."""
        body = {
            "UserInfo": {
                "employeeNo": str(employee_no),
                "name": name,
                "userType": "normal",
                "Valid": {
                    "enable": True,
                    "beginTime": valid_begin,
                    "endTime": valid_end,
                    "timeType": "local",
                },
                "doorRight": str(door_no),
                "RightPlan": [{"doorNo": door_no, "planTemplateNo": "1"}],
            }
        }
        resp = self._request(
            "POST", "/ISAPI/AccessControl/UserInfo/Record?format=json", json=body
        )
        return self._check_isapi_ok(resp, "enroll_user")

    def delete_user(self, employee_no: str) -> dict:
        """Remove a person from the device by employeeNo."""
        body = {"UserInfoDelCond": {"EmployeeNoList": [{"employeeNo": str(employee_no)}]}}
        resp = self._request(
            "PUT", "/ISAPI/AccessControl/UserInfo/Delete?format=json", json=body
        )
        return self._check_isapi_ok(resp, "delete_user")

    def upload_face(self, employee_no: str, jpeg: bytes, *, fdid: str = "1") -> dict:
        """Bind a face photo to an already-enrolled person.

        Multipart: a JSON ``FaceDataRecord`` part + the JPEG. The face-library
        API varies by firmware ([verify on device]); this targets FDLib.
        """
        meta = {"faceLibType": "blackFD", "FDID": fdid, "FPID": str(employee_no)}
        files = {
            "FaceDataRecord": (None, json.dumps(meta), "application/json"),
            "img": ("face.jpg", jpeg, "image/jpeg"),
        }
        resp = self._request(
            "POST", "/ISAPI/Intelligent/FDLib/FaceDataRecord?format=json", files=files
        )
        return self._check_isapi_ok(resp, "upload_face")

    def fetch_events(
        self,
        start: datetime,
        end: datetime,
        *,
        max_results: int = 30,
        position: int = 0,
    ) -> dict:
        """Pull access events in a time window (reconciliation / live view).

        Returns the raw ``AcsEvent`` block: ``InfoList`` rows, ``totalMatches``,
        and ``responseStatusStrg`` ('OK' = last page, 'MORE' = page again).
        """
        body = {
            "AcsEventCond": {
                "searchID": str(uuid.uuid4()),
                "searchResultPosition": position,
                "maxResults": max_results,
                "major": 0,
                "minor": 0,
                "startTime": start.astimezone().replace(microsecond=0).isoformat(),
                "endTime": end.astimezone().replace(microsecond=0).isoformat(),
            }
        }
        resp = self._request(
            "POST", "/ISAPI/AccessControl/AcsEvent?format=json", json=body
        )
        if resp.status_code >= 400:
            raise TerminalError(f"AcsEvent: HTTP {resp.status_code} {resp.text[:200]}")
        try:
            return resp.json().get("AcsEvent", {})
        except (json.JSONDecodeError, ValueError):
            return {}
