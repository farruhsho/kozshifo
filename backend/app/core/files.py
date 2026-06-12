"""Binary file storage for device-result files (B-scans, biometry printouts).

Uploads live flat inside ``settings.upload_dir`` under random UUID names; the
client-supplied original name is kept only as metadata (``DeviceResult.payload``)
and never becomes a path component, so user input cannot influence where bytes
land. ``DeviceResult.file_path`` stores the bare generated filename, and
``resolve_stored`` refuses anything that is not a bare filename — a DB row
tampered with path separators or ``..`` can never escape the upload directory.
"""
from __future__ import annotations

from pathlib import Path, PureWindowsPath
from uuid import uuid4

from app.core.config import settings

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".dcm", ".pdf"}
MAX_FILE_BYTES = 20 * 1024 * 1024  # 20 MB

_MEDIA_TYPES = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".bmp": "image/bmp",
    ".tif": "image/tiff",
    ".tiff": "image/tiff",
    ".dcm": "application/dicom",
    ".pdf": "application/pdf",
}


def save_upload(content: bytes, original_name: str) -> str:
    """Validate and persist an uploaded file; return the stored bare filename.

    Raises ``ValueError`` on a disallowed extension or oversized content.
    """
    ext = Path(original_name or "").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(
            f"File type '{ext or '(none)'}' is not allowed; "
            f"allowed: {', '.join(sorted(ALLOWED_EXTENSIONS))}"
        )
    if len(content) > MAX_FILE_BYTES:
        raise ValueError(f"File exceeds the {MAX_FILE_BYTES // (1024 * 1024)} MB limit")

    upload_dir = Path(settings.upload_dir)
    upload_dir.mkdir(parents=True, exist_ok=True)
    stored_name = f"{uuid4().hex}{ext}"
    (upload_dir / stored_name).write_bytes(content)
    return stored_name


def resolve_stored(stored_name: str) -> Path:
    """Map a stored bare filename back to its path inside the upload dir.

    Raises ``ValueError`` for anything that is not a plain filename (path
    separators, ``..``, drive prefixes) — callers map that to 404, never
    leaking filesystem details.
    """
    if (
        not stored_name
        or "/" in stored_name
        or "\\" in stored_name
        or ".." in stored_name
        # Catches drive-relative names like "C:evil" even when running on POSIX.
        or PureWindowsPath(stored_name).name != stored_name
    ):
        raise ValueError(f"Invalid stored file name: {stored_name!r}")
    return Path(settings.upload_dir) / stored_name


def media_type_for(stored_name: str) -> str:
    """Best-effort Content-Type for a stored file, by extension."""
    return _MEDIA_TYPES.get(Path(stored_name).suffix.lower(), "application/octet-stream")
