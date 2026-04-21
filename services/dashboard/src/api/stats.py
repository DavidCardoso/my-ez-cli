"""REST API — stats and tools endpoints."""

from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, Request

from src.sessions import get_stats, get_tools

router = APIRouter(prefix="/api")


def _data_root(request: Request) -> Path:
    return request.app.state.data_root  # type: ignore[no-any-return]


@router.get("/stats")
def stats_endpoint(request: Request) -> dict[str, object]:
    """Return aggregate stats for the dashboard home page."""
    return get_stats(_data_root(request))


@router.get("/tools")
def tools_endpoint(request: Request) -> list[dict[str, str]]:
    """Return the mec tool registry."""
    return get_tools(_data_root(request))
