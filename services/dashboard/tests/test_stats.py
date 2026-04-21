"""Tests for get_stats() and get_tools()."""

from __future__ import annotations

import json
from datetime import UTC, datetime, timedelta
from pathlib import Path

from src.sessions import get_stats, get_tools


def _write_log(
    data_root: Path,
    session_id: str,
    tool: str,
    *,
    exit_code: int | None = 0,
    timestamp: str | None = None,
) -> None:
    """Write a minimal log file to the test data root."""
    log_dir = data_root / "logs" / tool
    log_dir.mkdir(parents=True, exist_ok=True)
    ts = timestamp or "2026-01-01T00:00:00Z"
    filename = ts[:10].replace("-", "-") + "_00-00-00.json"
    # Use unique filenames for multiple writes
    count = len(list(log_dir.glob("*.json")))
    filename = f"2026-01-01_00-00-{count:02d}.json"
    (log_dir / filename).write_text(
        json.dumps(
            {
                "session_id": session_id,
                "tool": tool,
                "execution": {"exit_code": exit_code, "start_time": ts},
                "output": {"stdout": "", "stderr": ""},
            }
        )
    )


def _write_ai_sidecar(data_root: Path, tool: str, filename: str, result: str = "ok") -> None:
    """Write an AI sidecar file."""
    ai_dir = data_root / "ai-analyses" / tool
    ai_dir.mkdir(parents=True, exist_ok=True)
    (ai_dir / filename).write_text(
        json.dumps(
            {"analyses": {"uuid-1": {"timestamp": "2026-01-01T00:00:01Z", "result": result}}}
        )
    )


class TestGetStats:
    def test_empty_root_returns_zero_shape(self, tmp_path: Path) -> None:
        stats = get_stats(tmp_path)
        assert stats["total_sessions"] == 0
        assert stats["sessions_by_tool"] == {}
        assert stats["exit_code_distribution"] == {"success": 0, "failure": 0}
        assert stats["ai_analysis_rate"] == {"done": 0, "pending": 0, "none": 0}
        assert len(stats["last_7_days"]) == 7

    def test_counts_sessions_by_tool(self, tmp_path: Path) -> None:
        _write_log(tmp_path, "mec-node-1", "node")
        _write_log(tmp_path, "mec-node-2", "node")
        _write_log(tmp_path, "mec-npm-1", "npm")
        stats = get_stats(tmp_path)
        assert stats["total_sessions"] == 3
        assert stats["sessions_by_tool"]["node"] == 2  # type: ignore[index]
        assert stats["sessions_by_tool"]["npm"] == 1  # type: ignore[index]

    def test_exit_code_distribution(self, tmp_path: Path) -> None:
        _write_log(tmp_path, "mec-node-1", "node", exit_code=0)
        _write_log(tmp_path, "mec-node-2", "node", exit_code=1)
        _write_log(tmp_path, "mec-node-3", "node", exit_code=None)
        stats = get_stats(tmp_path)
        assert stats["exit_code_distribution"]["success"] == 1  # type: ignore[index]
        assert stats["exit_code_distribution"]["failure"] == 2  # type: ignore[index]

    def test_ai_analysis_rate_done(self, tmp_path: Path) -> None:
        _write_log(tmp_path, "mec-node-1", "node")
        # Write AI sidecar with a result
        ai_dir = tmp_path / "ai-analyses" / "node"
        ai_dir.mkdir(parents=True)
        log_file = sorted((tmp_path / "logs" / "node").glob("*.json"))[0]
        sidecar = ai_dir / log_file.name
        sidecar.write_text(
            json.dumps(
                {
                    "analyses": {
                        "uuid-1": {"timestamp": "2026-01-01T00:00:01Z", "result": "Analysis text"}
                    }
                }
            )
        )
        stats = get_stats(tmp_path)
        assert stats["ai_analysis_rate"]["done"] == 1  # type: ignore[index]

    def test_ai_analysis_rate_pending(self, tmp_path: Path) -> None:
        _write_log(tmp_path, "mec-node-1", "node")
        # Write AI sidecar with empty result (pending)
        ai_dir = tmp_path / "ai-analyses" / "node"
        ai_dir.mkdir(parents=True)
        log_file = sorted((tmp_path / "logs" / "node").glob("*.json"))[0]
        sidecar = ai_dir / log_file.name
        sidecar.write_text(json.dumps({"analyses": {}}))
        stats = get_stats(tmp_path)
        assert stats["ai_analysis_rate"]["pending"] == 1  # type: ignore[index]

    def test_ai_analysis_rate_none(self, tmp_path: Path) -> None:
        _write_log(tmp_path, "mec-node-1", "node")
        # No sidecar file = none
        stats = get_stats(tmp_path)
        assert stats["ai_analysis_rate"]["none"] == 1  # type: ignore[index]

    def test_last_7_days_always_7_entries(self, tmp_path: Path) -> None:
        stats = get_stats(tmp_path)
        assert len(stats["last_7_days"]) == 7
        for entry in stats["last_7_days"]:
            assert "date" in entry  # type: ignore[operator]
            assert "count" in entry  # type: ignore[operator]
            assert isinstance(entry["count"], int)  # type: ignore[index]

    def test_last_7_days_dates_are_correct(self, tmp_path: Path) -> None:
        stats = get_stats(tmp_path)
        today = datetime.now(UTC).date()
        dates = [e["date"] for e in stats["last_7_days"]]  # type: ignore[index]
        assert dates[0] == str(today - timedelta(days=6))
        assert dates[-1] == str(today)

    def test_telemetry_enabled_defaults_false_when_no_config(self, tmp_path: Path) -> None:
        stats = get_stats(tmp_path)
        assert stats["telemetry_enabled"] is False

    def test_logs_enabled_defaults_false_when_no_config(self, tmp_path: Path) -> None:
        stats = get_stats(tmp_path)
        assert stats["logs_enabled"] is False

    def test_ai_enabled_defaults_false_when_no_config(self, tmp_path: Path) -> None:
        stats = get_stats(tmp_path)
        assert stats["ai_enabled"] is False

    def test_reads_enabled_flags_from_config(self, tmp_path: Path) -> None:
        (tmp_path / "config.yaml").write_text(
            "telemetry:\n  enabled: true\nlogs:\n  enabled: true\nai:\n  enabled: true\n"
        )
        stats = get_stats(tmp_path)
        assert stats["telemetry_enabled"] is True
        assert stats["logs_enabled"] is True
        assert stats["ai_enabled"] is True


class TestGetTools:
    def test_returns_non_empty_list(self, tmp_path: Path) -> None:
        tools = get_tools(tmp_path)
        assert len(tools) > 0

    def test_each_item_has_required_keys(self, tmp_path: Path) -> None:
        tools = get_tools(tmp_path)
        for tool in tools:
            assert "name" in tool
            assert "image" in tool
            assert "description" in tool
            assert "category" in tool

    def test_names_are_unique(self, tmp_path: Path) -> None:
        tools = get_tools(tmp_path)
        names = [t["name"] for t in tools]
        assert len(names) == len(set(names))

    def test_categories_are_valid(self, tmp_path: Path) -> None:
        valid_categories = {"runtime", "cloud", "infra", "testing", "ai"}
        tools = get_tools(tmp_path)
        for tool in tools:
            assert tool["category"] in valid_categories
