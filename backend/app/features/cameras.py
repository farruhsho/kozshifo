"""IP cameras — connect a camera by IP and view it live in the app.

Mirrors the Face ID access-control slice (features/access_control.py): an
operator registers a camera (host/port/login/password) under ``cameras.manage``;
anyone with ``cameras.view`` lists them and streams the live view.

Browsers can't play RTSP, so the backend proxies a still JPEG snapshot
(``GET /cameras/{id}/snapshot``) and the app polls it ~1 fps for a live view.
The camera password is write-only (absent from CameraOut), exactly like the
terminal password.

Security: the camera host comes only from a stored, operator-created row (never a
raw URL in the request), so this does not widen the SSRF surface beyond the
existing terminal connector. An unreachable camera yields a 502 — never a 500 —
so an unplugged camera can't break the UI.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.core.devices.hikvision import HikvisionClient, TerminalError, TerminalUnreachable
from app.models.camera import Camera
from app.schemas.camera import CameraCreate, CameraOut, CameraTestResult, CameraUpdate

router = APIRouter(prefix="/cameras", tags=["Cameras"])


def _get_camera_or_404(db: Session, camera_id: UUID) -> Camera:
    camera = db.get(Camera, camera_id)
    if camera is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Camera not found")
    return camera


@router.get(
    "",
    response_model=list[CameraOut],
    dependencies=[Depends(require_permission("cameras.view"))],
)
def list_cameras(db: Annotated[Session, Depends(get_db)]) -> list[Camera]:
    return list(
        db.execute(select(Camera).order_by(Camera.created_at.asc())).scalars().all()
    )


@router.post("", response_model=CameraOut, status_code=status.HTTP_201_CREATED)
def create_camera(
    payload: CameraCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("cameras.manage"))],
) -> Camera:
    camera = Camera(**payload.model_dump())
    db.add(camera)
    db.flush()
    record_audit(db, action="create", entity_type="camera", entity_id=camera.id,
                 actor_id=actor.id, branch_id=camera.branch_id,
                 summary=f"Connected camera {camera.name} ({camera.host}:{camera.port})")
    db.commit()
    db.refresh(camera)
    return camera


@router.patch("/{camera_id}", response_model=CameraOut)
def update_camera(
    camera_id: UUID,
    payload: CameraUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("cameras.manage"))],
) -> Camera:
    camera = _get_camera_or_404(db, camera_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(camera, field, value)  # password only set when present
    record_audit(db, action="update", entity_type="camera", entity_id=camera.id,
                 actor_id=actor.id, branch_id=camera.branch_id,
                 summary=f"Updated camera {camera.name}")
    db.commit()
    db.refresh(camera)
    return camera


@router.delete("/{camera_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_camera(
    camera_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("cameras.manage"))],
) -> None:
    camera = _get_camera_or_404(db, camera_id)
    record_audit(db, action="delete", entity_type="camera", entity_id=camera.id,
                 actor_id=actor.id, branch_id=camera.branch_id,
                 summary=f"Removed camera {camera.name}")
    db.delete(camera)
    db.commit()


@router.post("/{camera_id}/test", response_model=CameraTestResult)
def test_camera(
    camera_id: UUID,
    db: Annotated[Session, Depends(get_db)],
    _: Annotated[CurrentUser, Depends(require_permission("cameras.manage"))],
) -> CameraTestResult:
    """Probe the camera over ISAPI and refresh its online status / device info."""
    camera = _get_camera_or_404(db, camera_id)
    client = HikvisionClient.from_camera(camera)
    try:
        info = client.get_device_info()
    except (TerminalUnreachable, TerminalError) as exc:
        camera.online = False
        db.commit()
        return CameraTestResult(online=False, error=str(exc))

    camera.online = True
    camera.last_seen = datetime.now(timezone.utc)
    camera.device_info = info
    db.commit()
    return CameraTestResult(
        online=True,
        model=info.get("model"),
        firmware=info.get("firmwareVersion"),
        serial=info.get("serialNumber"),
        device_name=info.get("deviceName"),
    )


@router.get(
    "/{camera_id}/snapshot",
    dependencies=[Depends(require_permission("cameras.view"))],
)
def camera_snapshot(camera_id: UUID, db: Annotated[Session, Depends(get_db)]) -> Response:
    """Proxy one live JPEG frame from the camera (the app polls this for live view).

    The camera host is taken from the stored row (never a request param), so this
    is no broader an SSRF surface than the terminal connector. A down camera maps
    to 502, never 500 — the UI just shows «нет сигнала» and keeps polling.
    """
    camera = _get_camera_or_404(db, camera_id)
    client = HikvisionClient.from_camera(camera)
    try:
        jpeg = client.get_snapshot(channel=camera.channel_no, path=camera.snapshot_path)
    except (TerminalUnreachable, TerminalError) as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"Camera unreachable: {exc}") from exc
    return Response(
        content=jpeg,
        media_type="image/jpeg",
        headers={"Cache-Control": "no-store"},  # live frames must never be cached
    )
