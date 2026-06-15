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

    @classmethod
    def from_camera(cls, camera: Any, *, timeout: float = 5.0) -> "HikvisionClient":
        """Build a client from a Camera ORM row (same connection shape as a terminal)."""
        return cls(
            camera.host,
            camera.port,
            camera.username,
            camera.password,
            use_https=camera.use_https,
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
        except (NotImplementedError, KeyError) as exc:
            # httpx.DigestAuth raises these (not HTTPError) when a device offers an
            # unsupported challenge — qop="auth-int" -> NotImplementedError, an
            # unknown algorithm -> KeyError. Map them to the graceful "device down"
            # path so an odd-firmware camera/terminal yields 502, never a 500.
            raise TerminalUnreachable(
                f"unsupported digest auth challenge from device ({type(exc).__name__})"
            ) from exc
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

    def get_snapshot(self, *, channel: int = 1, path: str | None = None) -> bytes:
        """Pull one still JPEG frame — the unit of the snapshot-polling live view.

        Hikvision ISAPI: GET /ISAPI/Streaming/channels/{channel}01/picture
        (channel 1 main stream = 101). A non-Hikvision camera can pass an explicit
        snapshot ``path``. Returns the raw image bytes; raises ``TerminalError`` on
        an error status and ``TerminalUnreachable`` when the camera is down/auth
        fails (the feature layer maps these to a 502, never a 500).
        """
        snapshot_path = path or f"/ISAPI/Streaming/channels/{channel}01/picture"
        resp = self._request("GET", snapshot_path)
        if resp.status_code >= 400:
            raise TerminalError(f"snapshot: HTTP {resp.status_code}")
        content = resp.content
        if not content:
            raise TerminalError("snapshot: empty response from camera")
        return content

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

    def enable_event_push(
        self,
        server_ip: str,
        server_port: int,
        token: str,
        *,
        host_id: int = 1,
    ) -> dict:
        """Point the terminal at our webhook so it pushes events automatically.

        Sets HTTP host #1 (PUT /ISAPI/Event/notification/httpHosts/{id}) — the
        device then POSTs every access event to
        ``http://server_ip:server_port/api/v1/access-control/event/<token>``.
        Saves the operator a trip into the device web UI. [verify on device] —
        a few firmwares additionally require enabling "Notify Surveillance
        Center" linkage on the access events.
        """
        url_path = f"/api/v1/access-control/event/{token}"
        body = (
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<HttpHostNotification version="2.0" '
            'xmlns="http://www.isapi.org/ver20/XMLSchema">'
            f"<id>{host_id}</id>"
            f"<url>{url_path}</url>"
            "<protocolType>HTTP</protocolType>"
            "<parameterFormatType>JSON</parameterFormatType>"
            "<addressingFormatType>ipaddress</addressingFormatType>"
            f"<ipAddress>{server_ip}</ipAddress>"
            f"<portNo>{server_port}</portNo>"
            "<httpAuthenticationMethod>none</httpAuthenticationMethod>"
            "</HttpHostNotification>"
        )
        resp = self._request(
            "PUT",
            f"/ISAPI/Event/notification/httpHosts/{host_id}",
            content=body.encode("utf-8"),
            headers={"Content-Type": "application/xml"},
        )
        if resp.status_code >= 400:
            raise TerminalError(f"enable_event_push: HTTP {resp.status_code} {resp.text[:200]}")
        # Success is a ResponseStatus XML with <statusCode>1</statusCode> / "OK".
        text = resp.text or ""
        if "<statusCode>" in text and "<statusCode>1<" not in text and "OK" not in text:
            raise TerminalError(f"enable_event_push: device rejected config — {text[:200]}")
        return {"url_path": url_path}

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
