"""Tests for sessions.py — session list and detail reader."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from src.sessions import SessionDetail, SessionSummary, get_session, list_sessions


@pytest.fixture()
def data_root(tmp_path: Path) -> Path:
    """Create a minimal ~/.my-ez-cli-like directory tree."""
    (tmp_path / "logs").mkdir()
    (tmp_path / "ai-analyses").mkdir()
    return tmp_path


def _write_log(data_root: Path, tool: str, ts: str, session_id: str, exit_code: int = 0) -> Path:
    log_dir = data_root / "logs" / tool
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / f"{ts}.json"
    log_path.write_text(
        json.dumps(
            {
                "session_id": session_id,
                "tool": tool,
                "command": f"{tool} --version",
                "execution": {
                    "start_time": f"2026-03-25T{ts[:8].replace('-', ':')}Z",
                    "end_time": f"2026-03-25T{ts[:8].replace('-', ':')}Z",
                    "exit_code": exit_code,
                },
                "output": {"stdout": "1.0.0", "stderr": ""},
            }
        )
    )
    return log_path


def _write_sidecar(data_root: Path, tool: str, ts: str, result: str = "") -> Path:
    ai_dir = data_root / "ai-analyses" / tool
    ai_dir.mkdir(parents=True, exist_ok=True)
    ai_path = ai_dir / f"{ts}.json"
    analyses = {}
    if result:
        analyses["abc-123"] = {"timestamp": "2026-03-25T12:00:00Z", "result": result}
    ai_path.write_text(json.dumps({"log_session_id": "x", "analyses": analyses}))
    return ai_path


class TestListSessions:
    """Tests for list_sessions()."""

    def test_empty_data_root_returns_empty(self, data_root: Path) -> None:
        assert list_sessions(data_root) == []

    def test_returns_session_summary(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        sessions = list_sessions(data_root)
        assert len(sessions) == 1
        assert isinstance(sessions[0], SessionSummary)
        assert sessions[0].session_id == "mec-npm-1"
        assert sessions[0].tool == "npm"
        assert sessions[0].exit_code == 0

    def test_ai_status_none_when_no_sidecar(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        assert list_sessions(data_root)[0].ai_status == "none"

    def test_ai_status_pending_when_sidecar_empty(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        _write_sidecar(data_root, "npm", "2026-03-25_12-00-00", result="")
        assert list_sessions(data_root)[0].ai_status == "pending"

    def test_ai_status_done_when_result_present(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        _write_sidecar(data_root, "npm", "2026-03-25_12-00-00", result="All good.")
        assert list_sessions(data_root)[0].ai_status == "done"

    def test_sorted_newest_first(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_10-00-00", "mec-npm-old")
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-new")
        sessions = list_sessions(data_root)
        assert sessions[0].session_id == "mec-npm-new"
        assert sessions[1].session_id == "mec-npm-old"

    def test_limit_respected(self, data_root: Path) -> None:
        for i in range(5):
            _write_log(data_root, "npm", f"2026-03-25_1{i}-00-00", f"mec-npm-{i}")
        assert len(list_sessions(data_root, limit=3)) == 3

    def test_multiple_tools_sorted_by_filename(self, data_root: Path) -> None:
        _write_log(data_root, "terraform", "2026-03-25_10-00-00", "mec-terraform-1")
        _write_log(data_root, "npm", "2026-03-25_11-00-00", "mec-npm-1")
        sessions = list_sessions(data_root)
        # npm session is newer — must come first despite "terraform" > "npm" alphabetically
        assert sessions[0].session_id == "mec-npm-1"

    def test_skips_directory_entries(self, data_root: Path) -> None:
        # Simulate old directory-style sidecar artifacts in logs dir
        fake_dir = data_root / "logs" / "npm" / "2026-03-25_09-00-00.json"
        fake_dir.mkdir(parents=True)
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        sessions = list_sessions(data_root)
        assert all(s.session_id == "mec-npm-1" for s in sessions)


class TestGetSession:
    """Tests for get_session()."""

    def test_returns_none_for_unknown_id(self, data_root: Path) -> None:
        assert get_session(data_root, "mec-npm-nonexistent") is None

    def test_returns_detail_for_known_id(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        detail = get_session(data_root, "mec-npm-1")
        assert isinstance(detail, SessionDetail)
        assert detail.session_id == "mec-npm-1"
        assert detail.command == "npm --version"
        assert detail.stdout == "1.0.0"

    def test_includes_ai_result_when_done(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        _write_sidecar(data_root, "npm", "2026-03-25_12-00-00", result="No issues.")
        detail = get_session(data_root, "mec-npm-1")
        assert detail is not None
        assert detail.ai_status == "done"
        assert detail.ai_result == "No issues."

    def test_exit_code_failure(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1", exit_code=1)
        detail = get_session(data_root, "mec-npm-1")
        assert detail is not None
        assert detail.exit_code == 1

    def test_cwd_defaults_to_empty_when_missing(self, tmp_path: Path) -> None:
        """cwd field should be empty string when not present in log data."""
        _write_log(tmp_path, "node", "2026-01-01_00-00-01", "mec-node-1", exit_code=0)
        detail = get_session(tmp_path, "mec-node-1")
        assert detail is not None
        assert detail.cwd == ""

    def test_cwd_populated_from_log_data(self, tmp_path: Path) -> None:
        """cwd field should be populated from log data when present."""
        log_dir = tmp_path / "logs" / "node"
        log_dir.mkdir(parents=True)
        (log_dir / "2026-01-01_00-00-01.json").write_text(
            json.dumps(
                {
                    "session_id": "mec-node-cwd",
                    "tool": "node",
                    "cwd": "/home/user/myproject",
                    "execution": {"exit_code": 0, "start_time": "2026-01-01T00:00:01Z"},
                    "output": {"stdout": "", "stderr": ""},
                }
            )
        )
        detail = get_session(tmp_path, "mec-node-cwd")
        assert detail is not None
        assert detail.cwd == "/home/user/myproject"
