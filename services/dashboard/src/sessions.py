"""Session reader — loads log + AI sidecar files from ~/.my-ez-cli."""

from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import TypedDict

logger = logging.getLogger(__name__)

# Relative to the data root (/data inside container, ~/.my-ez-cli on host)
LOGS_SUBDIR = "logs"
AI_ANALYSES_SUBDIR = "ai-analyses"

TOOL_REGISTRY: list[dict[str, str]] = [
    # Runtime
    {
        "name": "node",
        "image": "node:24-alpine",
        "description": "Node.js runtime (v24, Active LTS)",
        "category": "runtime",
    },
    {
        "name": "node20",
        "image": "node:20-alpine",
        "description": "Node.js runtime (v20, Maintenance LTS)",
        "category": "runtime",
    },
    {
        "name": "node22",
        "image": "node:22-alpine",
        "description": "Node.js runtime (v22 LTS)",
        "category": "runtime",
    },
    {
        "name": "node24",
        "image": "node:24-alpine",
        "description": "Node.js runtime (v24, Active LTS)",
        "category": "runtime",
    },
    {
        "name": "npm",
        "image": "node:24-alpine",
        "description": "Node package manager (npm, v24)",
        "category": "runtime",
    },
    {
        "name": "npm20",
        "image": "node:20-alpine",
        "description": "Node package manager (npm, v20)",
        "category": "runtime",
    },
    {
        "name": "npm22",
        "image": "node:22-alpine",
        "description": "Node package manager (npm, v22)",
        "category": "runtime",
    },
    {
        "name": "npx",
        "image": "node:24-alpine",
        "description": "Node package runner (npx, v24)",
        "category": "runtime",
    },
    {
        "name": "npx20",
        "image": "node:20-alpine",
        "description": "Node package runner (npx, v20)",
        "category": "runtime",
    },
    {
        "name": "npx22",
        "image": "node:22-alpine",
        "description": "Node package runner (npx, v22)",
        "category": "runtime",
    },
    {
        "name": "yarn",
        "image": "node:24-alpine",
        "description": "Yarn package manager (v24)",
        "category": "runtime",
    },
    {
        "name": "yarn20",
        "image": "node:20-alpine",
        "description": "Yarn package manager (v20)",
        "category": "runtime",
    },
    {
        "name": "yarn22",
        "image": "node:22-alpine",
        "description": "Yarn package manager (v22)",
        "category": "runtime",
    },
    {
        "name": "yarn-berry",
        "image": "davidcardoso/my-ez-cli:yarn-berry-latest",
        "description": "Yarn Berry (v2+, Plug'n'Play)",
        "category": "runtime",
    },
    {
        "name": "yarn-plus",
        "image": "davidcardoso/my-ez-cli:yarn-plus-latest",
        "description": "Yarn with git, curl, jq extras",
        "category": "runtime",
    },
    {
        "name": "python",
        "image": "python:3.12",
        "description": "Python runtime (configurable via PYENV_VERSION)",
        "category": "runtime",
    },
    # Cloud
    {
        "name": "aws",
        "image": "amazon/aws-cli:latest",
        "description": "AWS CLI v2",
        "category": "cloud",
    },
    {
        "name": "aws-sso",
        "image": "amazon/aws-cli:latest",
        "description": "AWS SSO login helper",
        "category": "cloud",
    },
    {
        "name": "gcloud",
        "image": "google/cloud-sdk:alpine",
        "description": "Google Cloud CLI",
        "category": "cloud",
    },
    {
        "name": "gcloud-login",
        "image": "google/cloud-sdk:alpine",
        "description": "GCP interactive authentication",
        "category": "cloud",
    },
    # Infra
    {
        "name": "terraform",
        "image": "hashicorp/terraform:1.14.5",
        "description": "HashiCorp Terraform IaC tool",
        "category": "infra",
    },
    {
        "name": "serverless",
        "image": "davidcardoso/my-ez-cli:serverless-latest",
        "description": "Serverless Framework CLI",
        "category": "infra",
    },
    # Testing
    {
        "name": "playwright",
        "image": "mcr.microsoft.com/playwright:latest",
        "description": "Playwright end-to-end browser testing",
        "category": "testing",
    },
    {
        "name": "promptfoo",
        "image": "ghcr.io/promptfoo/promptfoo:latest",
        "description": "LLM prompt evaluation and testing",
        "category": "testing",
    },
    {
        "name": "speedtest",
        "image": "davidcardoso/my-ez-cli:speedtest-latest",
        "description": "Ookla Speedtest CLI",
        "category": "testing",
    },
    # AI
    {
        "name": "claude",
        "image": "davidcardoso/my-ez-cli:claude-latest",
        "description": "Claude Code CLI (Anthropic)",
        "category": "ai",
    },
]


@dataclass
class SessionSummary:
    """Lightweight session entry for the list view."""

    session_id: str
    tool: str
    timestamp: str
    exit_code: int | None
    ai_status: str  # "none" | "pending" | "done"
    ai_execution_time_ms: int | None = None
    ai_tokens_input: int | None = None
    ai_tokens_output: int | None = None
    command: str = ""
    cwd: str = ""
    log_status: str = "none"  # "captured" | "none"


@dataclass
class SessionDetail(SessionSummary):
    """Full session data for the detail view."""

    command: str = ""
    cwd: str = ""
    stdout: str = ""
    stderr: str = ""
    output_capture_disabled: bool = False
    ai_result: str = ""
    claude_session_id: str = ""
    log_file: str = ""
    ai_file: str = ""
    extra: dict[str, object] = field(default_factory=dict)
    ai_execution_time_ms: int | None = None
    ai_tokens_input: int | None = None
    ai_tokens_output: int | None = None


class SessionList(TypedDict):
    """Result of list_sessions()."""

    sessions: list[SessionSummary]
    total: int


class DayCount(TypedDict):
    """Session count for one calendar day."""

    date: str
    count: int


class Stats(TypedDict):
    """Result of get_stats()."""

    total_sessions: int
    sessions_by_tool: dict[str, int]
    tool_stats: dict[str, dict[str, int]]
    exit_code_distribution: dict[str, int]
    ai_analysis_rate: dict[str, int]
    last_7_days: list[DayCount]
    telemetry_enabled: bool
    logs_enabled: bool
    ai_enabled: bool


# Log and sidecar files are written by shell scripts and may be hand-edited, so
# every value read from them is untrusted: these helpers narrow JSON values to
# the expected type and fall back instead of raising on malformed input.


def _as_dict(value: object) -> dict[str, object]:
    """Return value if it is a JSON object, else an empty dict."""
    if isinstance(value, dict):
        return value
    return {}


def _as_int(value: object) -> int | None:
    """Return value as int, or None if it is missing or not numeric."""
    if isinstance(value, int | float | str):
        try:
            return int(value)
        except (ValueError, OverflowError):  # "abc", NaN / Infinity
            return None
    return None


def _as_str(value: object) -> str:
    """Return value if it is a string, else an empty string."""
    return value if isinstance(value, str) else ""


def _read_json(path: Path) -> dict[str, object]:
    """Read and parse a JSON object file; return empty dict on any error.

    If the file contains raw ANSI/control characters that make it invalid JSON,
    strip them and retry once — this recovers sessions logged before escape_json
    was hardened to strip terminal control sequences.
    """
    try:
        content = path.read_text().strip()
        if not content:
            return {}
        try:
            return _as_dict(json.loads(content))
        except json.JSONDecodeError:
            # Strip ANSI escape sequences and C0 control characters, then retry
            clean = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", content)
            clean = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]", "", clean)
            return _as_dict(json.loads(clean))
    except (OSError, json.JSONDecodeError) as exc:
        logger.debug("Could not read %s: %s", path, exc)
        return {}


def _ai_status(ai_path: Path) -> tuple[str, str, str, int | None, int | None, int | None]:
    """Return (status, result_text, claude_session_id, exec_time_ms, tokens_in, tokens_out) from a sidecar file."""
    if not ai_path.exists() or ai_path.is_dir():
        return "none", "", "", None, None, None
    data = _read_json(ai_path)
    analyses = {key: _as_dict(value) for key, value in _as_dict(data.get("analyses")).items()}
    if not analyses:
        return "pending", "", "", None, None, None
    # Pick the latest entry by timestamp (sorted() is stable: last wins on ties)
    claude_session_id, entry = sorted(
        analyses.items(), key=lambda kv: _as_str(kv[1].get("timestamp"))
    )[-1]
    exec_time = _as_int(entry.get("execution_time_ms"))
    tokens = _as_dict(entry.get("tokens"))
    tok_in = _as_int(tokens.get("input", 0))
    tok_out = _as_int(tokens.get("output", 0))
    result = _as_str(entry.get("result"))
    if result:
        return "done", result, claude_session_id, exec_time, tok_in, tok_out
    return "pending", "", claude_session_id, exec_time, tok_in, tok_out


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


def list_sessions(data_root: Path, limit: int = 50) -> SessionList:
    """Return up to `limit` sessions newest-first, plus the total count of valid sessions."""
    all_files = _log_files(data_root)
    results: list[SessionSummary] = []
    total = 0
    for log_path in all_files:
        data = _read_json(log_path)
        if not data:
            continue
        total += 1
        if len(results) >= limit:
            continue
        execution = _as_dict(data.get("execution"))
        exit_code = _as_int(execution.get("exit_code"))
        output = _as_dict(data.get("output"))
        log_status = "captured" if output.get("stdout") else "none"
        ai_path = _sidecar_path(log_path, data_root)
        status, _, _claude_id, exec_time, tok_in, tok_out = _ai_status(ai_path)
        results.append(
            SessionSummary(
                session_id=str(data.get("session_id", "")),
                tool=str(data.get("tool", "")),
                timestamp=str(execution.get("start_time", data.get("timestamp", ""))),
                exit_code=exit_code,
                ai_status=status,
                ai_execution_time_ms=exec_time,
                ai_tokens_input=tok_in,
                ai_tokens_output=tok_out,
                command=str(data.get("command", "")),
                cwd=str(data.get("cwd", "")),
                log_status=log_status,
            )
        )
    return {"sessions": results, "total": total}


def get_session(data_root: Path, session_id: str) -> SessionDetail | None:
    """Find and return full detail for a session by ID."""
    for log_path in _log_files(data_root):
        data = _read_json(log_path)
        if str(data.get("session_id", "")) != session_id:
            continue
        execution = _as_dict(data.get("execution"))
        exit_code = _as_int(execution.get("exit_code"))
        output = _as_dict(data.get("output"))
        output_capture_disabled = output.get("stdout") is None and output.get("stderr") is None
        ai_path = _sidecar_path(log_path, data_root)
        status, result, claude_session_id, exec_time, tok_in, tok_out = _ai_status(ai_path)
        return SessionDetail(
            session_id=session_id,
            tool=str(data.get("tool", "")),
            timestamp=str(execution.get("start_time", data.get("timestamp", ""))),
            exit_code=exit_code,
            ai_status=status,
            command=str(data.get("command", "")),
            cwd=str(data.get("cwd", "")),
            stdout=str(output.get("stdout") or ""),
            stderr=str(output.get("stderr") or ""),
            output_capture_disabled=output_capture_disabled,
            ai_result=result,
            claude_session_id=claude_session_id,
            log_file="$MEC_HOME/" + str(log_path.relative_to(data_root)),
            ai_file=str(ai_path) if ai_path.exists() else "",
            ai_execution_time_ms=exec_time,
            ai_tokens_input=tok_in,
            ai_tokens_output=tok_out,
        )
    return None


def _read_config(data_root: Path) -> dict[str, dict[str, object]]:
    """Read ~/.my-ez-cli/config.yaml using a minimal YAML subset parser.

    Handles the simple nested structure used by mec config:
      logs:
        enabled: true
      ai:
        enabled: false
    """
    config_path = data_root / "config.yaml"
    try:
        content = config_path.read_text()
    except OSError as exc:
        logger.debug("Could not read config %s: %s", config_path, exc)
        return {}

    result: dict[str, dict[str, object]] = {}
    current_section: str | None = None
    for line in content.splitlines():
        # Top-level key (no leading whitespace, ends with colon)
        top = re.match(r"^([a-z_][a-z0-9_]*)\s*:\s*$", line)
        if top:
            current_section = top.group(1)
            result[current_section] = {}
            continue
        # Nested key under current section
        if current_section:
            nested = re.match(r"^\s+([a-z_][a-z0-9_]*)\s*:\s*(.+)$", line)
            if nested:
                key, raw = nested.group(1), nested.group(2).strip()
                val: object
                if raw.lower() == "true":
                    val = True
                elif raw.lower() == "false":
                    val = False
                elif re.match(r"^\d+$", raw):
                    val = int(raw)
                else:
                    val = raw.strip("\"'")
                result[current_section][key] = val
    return result


def get_stats(data_root: Path) -> Stats:
    """Aggregate statistics across all sessions for the dashboard home page."""
    total = 0
    by_tool: dict[str, int] = {}
    exit_dist = {"success": 0, "failure": 0}
    ai_rate = {"done": 0, "pending": 0, "none": 0}
    # Per-tool breakdown: {tool: {"sessions": N, "success": N, "ai_done": N}}
    tool_stats: dict[str, dict[str, int]] = {}

    # Build last-7-days bucket map (today - 6 days through today)
    today = datetime.now(UTC).date()
    day_counts: dict[str, int] = {str(today - timedelta(days=i)): 0 for i in range(6, -1, -1)}

    for log_path in _log_files(data_root):
        data = _read_json(log_path)
        if not data:
            continue
        total += 1

        tool = str(data.get("tool", "unknown"))
        by_tool[tool] = by_tool.get(tool, 0) + 1

        execution = _as_dict(data.get("execution"))
        exit_code = _as_int(execution.get("exit_code"))
        is_success = exit_code == 0
        if is_success:
            exit_dist["success"] += 1
        else:
            exit_dist["failure"] += 1

        ai_path = _sidecar_path(log_path, data_root)
        status, _, _claude_id, *_ = _ai_status(ai_path)
        ai_rate[status] = ai_rate.get(status, 0) + 1

        # Accumulate per-tool breakdown
        if tool not in tool_stats:
            tool_stats[tool] = {"sessions": 0, "success": 0, "ai_done": 0}
        tool_stats[tool]["sessions"] += 1
        if is_success:
            tool_stats[tool]["success"] += 1
        if status == "done":
            tool_stats[tool]["ai_done"] += 1

        # Bucket by date
        ts_str = str(execution.get("start_time", data.get("timestamp", "")))
        if ts_str:
            try:
                date_str = ts_str[:10]  # "YYYY-MM-DD"
                if date_str in day_counts:
                    day_counts[date_str] += 1
            except Exception:
                pass

    last_7_days: list[DayCount] = [{"date": d, "count": c} for d, c in day_counts.items()]

    config = _read_config(data_root)
    telemetry_cfg = config.get("telemetry", {})
    logs_cfg = config.get("logs", {})
    ai_cfg = config.get("ai", {})

    return {
        "total_sessions": total,
        "sessions_by_tool": by_tool,
        "tool_stats": tool_stats,
        "exit_code_distribution": exit_dist,
        "ai_analysis_rate": ai_rate,
        "last_7_days": last_7_days,
        "telemetry_enabled": bool(telemetry_cfg.get("enabled", False)),
        "logs_enabled": bool(logs_cfg.get("enabled", False)),
        "ai_enabled": bool(ai_cfg.get("enabled", False)),
    }


def get_tools(data_root: Path) -> list[dict[str, str]]:
    """Return the hardcoded mec tool registry."""
    return TOOL_REGISTRY
