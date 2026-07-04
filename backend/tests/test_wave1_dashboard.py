"""Wave-1 dashboard regressions: the finance-by-direction `branch_id` param used
to be an unresolved ForwardRef (`UUID` without an import under
`from __future__ import annotations`) — it broke /openapi.json entirely and
500-ed every request carrying ?branch_id=."""
from __future__ import annotations

import uuid
from decimal import Decimal

from tests.conftest import API


def test_openapi_schema_generates(client):
    resp = client.get("/openapi.json")
    assert resp.status_code == 200, resp.text
    paths = resp.json()["paths"]
    assert f"{API}/dashboard/finance-by-direction" in paths
    params = paths[f"{API}/dashboard/finance-by-direction"]["get"]["parameters"]
    assert "branch_id" in {p["name"] for p in params}


def test_finance_by_direction_accepts_branch_id(client, auth):
    branch = client.get(f"{API}/branches", headers=auth).json()[0]["id"]
    resp = client.get(f"{API}/dashboard/finance-by-direction", headers=auth,
                      params={"period": "month", "branch_id": branch})
    assert resp.status_code == 200, resp.text
    rep = resp.json()
    assert {r["direction"] for r in rep["rows"]} == {
        "priem", "diagnostika", "lechenie", "operatsii"}


def test_finance_by_direction_branch_id_filters(client, auth):
    # A branch nobody works in yields an all-zero report (the filter applies).
    ghost = str(uuid.uuid4())
    resp = client.get(f"{API}/dashboard/finance-by-direction", headers=auth,
                      params={"period": "year", "branch_id": ghost})
    assert resp.status_code == 200, resp.text
    rep = resp.json()
    assert Decimal(rep["total_revenue"]) == 0
    assert all(Decimal(r["revenue"]) == 0 for r in rep["rows"])


def test_finance_by_direction_rejects_malformed_branch_id(client, auth):
    resp = client.get(f"{API}/dashboard/finance-by-direction", headers=auth,
                      params={"branch_id": "not-a-uuid"})
    assert resp.status_code == 422
