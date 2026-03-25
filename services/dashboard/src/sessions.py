"""Session reader — loads log + AI sidecar files from ~/.my-ez-cli."""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

logger = logging.getLogger(__name__)

# Relative to the data root (/data inside container, ~/.my-ez-cli on host)
LOGS_SUBDIR = "logs"
AI_ANALYSES_SUBDIR = "ai-analyses"


@dataclass
class SessionSummary:
    """Lightweight session entry for the list view."""

    session_id: str
    tool: str
    timestamp: str
    exit_code: int | None
    ai_status: str  # "none" | "pending" | "done"


@dataclass
class SessionDetail(SessionSummary):
    """Full session data for the detail view."""

    command: str = ""
    stdout: str = ""
    stderr: str = ""
    ai_result: str = ""
    log_file: str = ""
    ai_file: str = ""
    extra: dict[str, object] = field(default_factory=dict)


def _read_json(path: Path) -> dict[str, object]:
    """Read and parse a JSON file; return empty dict on any error."""
    try:
        content = path.read_text().strip()
        if not content:
            return {}
        return json.loads(content)  # type: ignore[no-any-return]
    except (OSError, json.JSONDecodeError) as exc:
        logger.debug("Could not read %s: %s", path, exc)
        return {}


def _ai_status(ai_path: Path) -> tuple[str, str]:
    """Return (status, result_text) from a sidecar file."""
    if not ai_path.exists() or ai_path.is_dir():
        return "none", ""
    data = _read_json(ai_path)
    analyses: dict[str, object] = data.get("analyses", {})  # type: ignore[assignment]
    if not analyses:
        return "pending", ""
    # Pick the latest entry by timestamp
    entries = sorted(
        analyses.values(),  # type: ignore[union-attr]
        key=lambda x: x.get("timestamp", ""),  # type: ignore[union-attr]
    )
    result: str = entries[-1].get("result", "") if entries else ""  # type: ignore[union-attr]
    if result:
        return "done", result
    return "pending", ""


def _log_files(data_root: Path) -> list[Path]:
    """Return all log JSON files sorted newest-first (by filename = timestamp)."""
    logs_dir = data_root / LOGS_SUBDIR
    if not logs_dir.exists():
        return []
    files = [p for p in logs_dir.rglob("*.json") if not p.name.endswith(".bak") and p.is_file()]
    return sorted(files, key=lambda p: p.name, reverse=True)


def _sidecar_path(log_path: Path, data_root: Path) -> Path:
    """Derive the ai-analyses sidecar path mirroring the logs/ tree."""
    try:
        rel = log_path.relative_to(data_root / LOGS_SUBDIR)
        return data_root / AI_ANALYSES_SUBDIR / rel
    except ValueError:
        return log_path  # fallback (should not happen)


def list_sessions(data_root: Path, limit: int = 50) -> list[SessionSummary]:
    """Return up to `limit` sessions, newest-first."""
    results: list[SessionSummary] = []
    for log_path in _log_files(data_root)[:limit]:
        data = _read_json(log_path)
        if not data:
            continue
        execution: dict[str, object] = data.get("execution", {})  # type: ignore[assignment]
        exit_code_raw = execution.get("exit_code")
        exit_code = int(exit_code_raw) if exit_code_raw is not None else None  # type: ignore[arg-type]
        ai_path = _sidecar_path(log_path, data_root)
        status, _ = _ai_status(ai_path)
        results.append(
            SessionSummary(
                session_id=str(data.get("session_id", "")),
                tool=str(data.get("tool", "")),
                timestamp=str(execution.get("start_time", data.get("timestamp", ""))),
                exit_code=exit_code,
                ai_status=status,
            )
        )
    return results


def get_session(data_root: Path, session_id: str) -> SessionDetail | None:
    """Find and return full detail for a session by ID."""
    for log_path in _log_files(data_root):
        data = _read_json(log_path)
        if str(data.get("session_id", "")) != session_id:
            continue
        execution: dict[str, object] = data.get("execution", {})  # type: ignore[assignment]
        exit_code_raw = execution.get("exit_code")
        exit_code = int(exit_code_raw) if exit_code_raw is not None else None  # type: ignore[arg-type]
        output: dict[str, object] = data.get("output", {})  # type: ignore[assignment]
        ai_path = _sidecar_path(log_path, data_root)
        status, result = _ai_status(ai_path)
        return SessionDetail(
            session_id=session_id,
            tool=str(data.get("tool", "")),
            timestamp=str(execution.get("start_time", data.get("timestamp", ""))),
            exit_code=exit_code,
            ai_status=status,
            command=str(data.get("command", "")),
            stdout=str(output.get("stdout", "")),
            stderr=str(output.get("stderr", "")),
            ai_result=result,
            log_file=str(log_path),
            ai_file=str(ai_path) if ai_path.exists() else "",
        )
    return None
