"""Super Admin → custom roles: 4 example roles are seeded as EDITABLE starters
(is_system=False) so the owner can rename / retune / delete them (owner brief
2026-06-20)."""
from __future__ import annotations

from tests.conftest import API

_STARTERS = ("Старший ресепшен", "Главный врач", "Старшая медсестра", "Операционный менеджер")


def test_starter_custom_roles_seeded_as_editable(client, auth):
    resp = client.get(f"{API}/roles", headers=auth)
    assert resp.status_code == 200, resp.text
    by_name = {r["name"]: r for r in resp.json()}
    for name in _STARTERS:
        assert name in by_name, f"starter role {name!r} must be seeded"
        role = by_name[name]
        # is_system=False ⇒ a true custom role: the DELETE endpoint only blocks
        # system roles, so these are editable AND deletable by the owner.
        assert role["is_system"] is False
        assert role["permissions"], "starter role must come with a permission set"
