"""
Claude Response Parser
======================

Parses Claude Code --output-format json responses and writes analysis
results to a parallel sidecar file. Pure stdlib — no external dependencies.
"""

import json
import logging
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from .exceptions import ClaudeResponseParseError


def parse_claude_response(raw_json: str, logger: logging.Logger) -> tuple[str, str]:
    """
    Parse Claude Code JSON response into (session_id, result).

    Args:
        raw_json: Raw JSON string from Claude Code --output-format json
        logger: Logger instance

    Returns:
        Tuple of (session_id, result text)

    Raises:
        ClaudeResponseParseError: If JSON is malformed or required fields are missing
    """
    if not raw_json or not raw_json.strip():
        logger.error("Claude response is empty")
        raise ClaudeResponseParseError("Empty response received from Claude Code")

    try:
        data: dict[str, Any] = json.loads(raw_json)
    except json.JSONDecodeError as e:
        logger.error("Failed to parse Claude JSON response: %s", e, exc_info=True)
        raise ClaudeResponseParseError(
            f"Invalid JSON: {e}",
            original_error=e,
        ) from e

    session_id: str = data.get("session_id", "")
    result: str = data.get("result", "")

    if not session_id and not result:
        logger.debug("Claude response has no session_id or result fields")

    logger.debug("Parsed Claude response: session_id=%s, result_len=%d", session_id, len(result))
    return session_id, result


def write_ai_analysis(
    ai_analysis_path: str,
    log_file_path: str,
    log_session_id: str,
    claude_session_id: str,
    result: str,
    logger: logging.Logger,
) -> None:
    """
    Write an AI analysis entry to the sidecar file.

    Reads the sidecar file if it exists, adds a new entry to the analyses
    dict keyed by claude_session_id, then writes back. The original log
    file is never modified.

    Args:
        ai_analysis_path: Absolute path to the sidecar JSON file (read-write)
        log_file_path: Absolute path to the original log file (metadata only)
        log_session_id: Tool session ID (e.g. mec-node-1705318245)
        claude_session_id: Claude's session ID (key in analyses dict)
        result: Analysis result text
        logger: Logger instance

    Raises:
        ClaudeResponseParseError: If the sidecar file cannot be read or written
    """
    path: Path = Path(ai_analysis_path)

    if not path.parent.exists():
        logger.error("Parent directory does not exist: %s", path.parent)
        raise ClaudeResponseParseError(
            f"Cannot write sidecar file '{ai_analysis_path}': parent directory does not exist"
        )

    sidecar_data: dict[str, Any]
    if path.exists():
        try:
            content = path.read_text().strip()
            sidecar_data = json.loads(content) if content else {}
        except (OSError, json.JSONDecodeError) as e:
            logger.debug("Sidecar file unreadable or empty, starting fresh: %s", e)
            sidecar_data = {}
    else:
        sidecar_data = {}

    sidecar_data.setdefault("log_session_id", log_session_id)
    sidecar_data.setdefault("log_file", log_file_path)
    sidecar_data.setdefault("analyses", {})

    entry_key: str = claude_session_id if claude_session_id else "unknown"
    sidecar_data["analyses"][entry_key] = {
        "timestamp": datetime.now(UTC).isoformat(),
        "result": result,
    }

    try:
        with path.open("w") as f:
            json.dump(sidecar_data, f, indent=2)
            f.write("\n")
    except OSError as e:
        logger.error("Failed to write sidecar file %s: %s", ai_analysis_path, e, exc_info=True)
        raise ClaudeResponseParseError(
            f"Cannot write sidecar file '{ai_analysis_path}': {e}",
            original_error=e,
        ) from e

    logger.debug("Wrote AI analysis to sidecar %s (key=%s)", ai_analysis_path, entry_key)
