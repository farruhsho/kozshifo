"""Cloud object storage for staff face photos (Firebase Storage / GCS).

Optional integration. If ``FIREBASE_STORAGE_BUCKET`` is unset every call is a
no-op returning ``None`` — the clinic runs fine without cloud storage and face
photos still reach the device + local ``upload_dir``. When a bucket is
configured, Face ID enrollment mirrors the photo to it under
``staff_faces/<employeeNo>.jpg`` as a durable backup (local uploads on
Cloud Run / Railway are ephemeral; see docs/FIREBASE.md).

The client is built lazily and once: importing ``google.cloud.storage`` and
opening credentials is relatively expensive, and the dependency is optional, so
a missing package or bad key degrades to a logged warning + no-op rather than a
500 on enrollment.
"""
from __future__ import annotations

import logging
import threading

from app.core.config import settings

logger = logging.getLogger(__name__)

_bucket = None
_lock = threading.Lock()
_init_done = False  # we attempted init (success or permanent failure)


def _get_bucket():
    """Return the configured GCS bucket, or None if storage is disabled/unavailable."""
    global _bucket, _init_done
    if not settings.firebase_storage_bucket:
        return None
    if _init_done:
        return _bucket
    with _lock:
        if _init_done:
            return _bucket
        try:
            from google.cloud import storage  # lazy: optional dependency

            if settings.google_application_credentials:
                client = storage.Client.from_service_account_json(
                    settings.google_application_credentials
                )
            else:
                client = storage.Client()  # Application Default Credentials
            _bucket = client.bucket(settings.firebase_storage_bucket)
        except Exception as exc:  # missing dep, bad key, no creds — disable, don't crash
            logger.warning("Cloud storage unavailable, disabling: %s", exc)
            _bucket = None
        _init_done = True
        return _bucket


def upload_face_photo(
    employee_no: str, content: bytes, *, content_type: str = "image/jpeg"
) -> str | None:
    """Best-effort mirror of a staff face photo to cloud storage.

    Returns the ``gs://`` URI on success, or ``None`` when storage is disabled
    or the upload failed (never raises — enrollment must not break on a storage
    hiccup).
    """
    bucket = _get_bucket()
    if bucket is None:
        return None
    blob_name = f"staff_faces/{employee_no}.jpg"
    try:
        blob = bucket.blob(blob_name)
        blob.upload_from_string(content, content_type=content_type)
        uri = f"gs://{bucket.name}/{blob_name}"
        logger.info("Face photo mirrored to %s", uri)
        return uri
    except Exception as exc:
        logger.warning("Face photo upload failed (employeeNo=%s): %s", employee_no, exc)
        return None
