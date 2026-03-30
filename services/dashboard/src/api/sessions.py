"""REST API — session list and detail endpoints."""

from __future__ import annotations

from dataclasses import asdict
from pathlib import Path

from fastapi import APIRouter, HTTPException, Request

from src.sessions import get_session, list_sessions

router = APIRouter(prefix="/api/sessions")


def _data_root(request: Request) -> Path:
    return request.app.state.data_root  # type: ignore[no-any-return]


@router.get("")
def sessions_list(request: Request, limit: int = 50) -> dict[str, object]:
    """Return up to `limit` sessions newest-first, plus the total count."""
    result = list_sessions(_data_root(request), limit=limit)
    sessions = result["sessions"]  # type: ignore[index]
    return {"sessions": [asdict(s) for s in sessions], "total": result["total"]}  # type: ignore[arg-type]


@router.get("/{session_id}")
def session_detail(session_id: str, request: Request) -> dict[str, object]:
    """Return full detail for a single session."""
    detail = get_session(_data_root(request), session_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")
    return asdict(detail)
