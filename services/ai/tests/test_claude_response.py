"""
Claude Response Parser Tests
=============================
Tests for claude_response.py — parse_claude_response and write_ai_analysis.
"""

import json
import logging
from pathlib import Path
from typing import Any
from unittest.mock import Mock

import pytest
from src.claude_response import parse_claude_response, write_ai_analysis
from src.exceptions import ClaudeResponseParseError


@pytest.fixture
def mock_logger() -> Mock:
    """Mock logger."""
    return Mock(spec=logging.Logger)


@pytest.fixture
def sample_claude_json() -> str:
    """Valid Claude Code JSON response."""
    return json.dumps(
        {
            "session_id": "abc-123-def",
            "result": "The command succeeded. No issues found.",
            "stop_reason": "end_turn",
        }
    )


@pytest.fixture
def log_file(tmp_path: Path) -> Path:
    """Temporary JSON log file with basic structure (never mutated by AI)."""
    data: dict[str, Any] = {
        "tool": "node",
        "image": "node:24-alpine",
        "exit_code": 1,
        "stdout": "some output",
        "stderr": "some error",
    }
    path: Path = tmp_path / "session.json"
    path.write_text(json.dumps(data, indent=2) + "\n")
    return path


# =============================================================================
# parse_claude_response
# =============================================================================


class TestParseClaudeResponse:
    """Tests for parse_claude_response()."""

    def test_valid_json_returns_session_id_and_result(
        self, sample_claude_json: str, mock_logger: Mock
    ) -> None:
        """Valid JSON produces correct session_id and result."""
        session_id, result = parse_claude_response(sample_claude_json, mock_logger)
        assert session_id == "abc-123-def"
        assert result == "The command succeeded. No issues found."

    def test_missing_session_id_returns_empty_string(self, mock_logger: Mock) -> None:
        """Missing session_id field returns empty string, not error."""
        raw = json.dumps({"result": "Some result"})
        session_id, result = parse_claude_response(raw, mock_logger)
        assert session_id == ""
        assert result == "Some result"

    def test_missing_result_returns_empty_string(self, mock_logger: Mock) -> None:
        """Missing result field returns empty string, not error."""
        raw = json.dumps({"session_id": "xyz-999"})
        session_id, result = parse_claude_response(raw, mock_logger)
        assert session_id == "xyz-999"
        assert result == ""

    def test_both_fields_missing_returns_empty_strings(self, mock_logger: Mock) -> None:
        """JSON with no relevant fields returns two empty strings."""
        raw = json.dumps({"stop_reason": "end_turn"})
        session_id, result = parse_claude_response(raw, mock_logger)
        assert session_id == ""
        assert result == ""

    def test_malformed_json_raises_parse_error(self, mock_logger: Mock) -> None:
        """Malformed JSON raises ClaudeResponseParseError."""
        with pytest.raises(ClaudeResponseParseError) as exc_info:
            parse_claude_response("{not valid json", mock_logger)
        assert "Invalid JSON" in str(exc_info.value)

    def test_empty_string_raises_parse_error(self, mock_logger: Mock) -> None:
        """Empty input raises ClaudeResponseParseError."""
        with pytest.raises(ClaudeResponseParseError) as exc_info:
            parse_claude_response("", mock_logger)
        assert "Empty response" in str(exc_info.value)

    def test_whitespace_only_raises_parse_error(self, mock_logger: Mock) -> None:
        """Whitespace-only input raises ClaudeResponseParseError."""
        with pytest.raises(ClaudeResponseParseError):
            parse_claude_response("   \n  ", mock_logger)

    def test_multiline_result_preserved(self, mock_logger: Mock) -> None:
        """Multi-line result text is preserved exactly."""
        expected: str = "Line 1\nLine 2\nLine 3"
        raw = json.dumps({"session_id": "s1", "result": expected})
        _, result = parse_claude_response(raw, mock_logger)
        assert result == expected

    def test_parse_error_chains_original_exception(self, mock_logger: Mock) -> None:
        """ClaudeResponseParseError chains the original JSONDecodeError."""
        with pytest.raises(ClaudeResponseParseError) as exc_info:
            parse_claude_response("bad json", mock_logger)
        assert exc_info.value.original_error is not None


# =============================================================================
# write_ai_analysis
# =============================================================================


class TestWriteAiAnalysis:
    """Tests for write_ai_analysis()."""

    def test_creates_sidecar_when_absent(self, tmp_path: Path, mock_logger: Mock) -> None:
        """Creates sidecar file with correct schema when it doesn't exist."""
        ai_path = tmp_path / "ai-analyses.json"
        write_ai_analysis(
            str(ai_path),
            "/logs/node/session.json",
            "mec-node-1705318245",
            "abc-123-def",
            "Fix the import error.",
            mock_logger,
        )

        sidecar: dict[str, Any] = json.loads(ai_path.read_text())
        assert sidecar["log_session_id"] == "mec-node-1705318245"
        assert sidecar["log_file"] == "/logs/node/session.json"
        assert "abc-123-def" in sidecar["analyses"]
        assert sidecar["analyses"]["abc-123-def"]["result"] == "Fix the import error."
        assert "timestamp" in sidecar["analyses"]["abc-123-def"]

    def test_appends_second_entry_without_overwriting_first(
        self, tmp_path: Path, mock_logger: Mock
    ) -> None:
        """A second call adds a new entry without overwriting the first."""
        ai_path = tmp_path / "ai-analyses.json"
        write_ai_analysis(
            str(ai_path),
            "/logs/node/s.json",
            "mec-node-1",
            "session-A",
            "First analysis",
            mock_logger,
        )
        write_ai_analysis(
            str(ai_path),
            "/logs/node/s.json",
            "mec-node-1",
            "session-B",
            "Second analysis",
            mock_logger,
        )

        sidecar: dict[str, Any] = json.loads(ai_path.read_text())
        assert "session-A" in sidecar["analyses"]
        assert "session-B" in sidecar["analyses"]
        assert sidecar["analyses"]["session-A"]["result"] == "First analysis"
        assert sidecar["analyses"]["session-B"]["result"] == "Second analysis"

    def test_original_log_file_not_modified(
        self, log_file: Path, tmp_path: Path, mock_logger: Mock
    ) -> None:
        """The original log file is never modified by write_ai_analysis."""
        original_content: str = log_file.read_text()
        ai_path = tmp_path / "ai-analyses.json"

        write_ai_analysis(
            str(ai_path), str(log_file), "mec-node-1", "session-1", "Some analysis", mock_logger
        )

        assert log_file.read_text() == original_content
        assert "ai_analyses" not in log_file.read_text()

    def test_empty_session_id_uses_unknown_key(self, tmp_path: Path, mock_logger: Mock) -> None:
        """Empty claude_session_id falls back to 'unknown' as the key."""
        ai_path = tmp_path / "ai-analyses.json"
        write_ai_analysis(
            str(ai_path), "/logs/node/s.json", "mec-node-1", "", "Some result", mock_logger
        )

        sidecar: dict[str, Any] = json.loads(ai_path.read_text())
        assert "unknown" in sidecar["analyses"]

    def test_missing_parent_directory_raises_parse_error(self, mock_logger: Mock) -> None:
        """Missing parent directory raises ClaudeResponseParseError."""
        with pytest.raises(ClaudeResponseParseError):
            write_ai_analysis(
                "/nonexistent/dir/ai-analyses.json",
                "/logs/node/s.json",
                "mec-node-1",
                "session-1",
                "result",
                mock_logger,
            )

    def test_corrupt_sidecar_starts_fresh(self, tmp_path: Path, mock_logger: Mock) -> None:
        """Corrupt existing sidecar is discarded and a fresh one is written."""
        ai_path = tmp_path / "ai-analyses.json"
        ai_path.write_text("{ not valid json }")

        write_ai_analysis(
            str(ai_path), "/logs/node/s.json", "mec-node-1", "s1", "result", mock_logger
        )

        sidecar: dict[str, Any] = json.loads(ai_path.read_text())
        assert "s1" in sidecar["analyses"]
        assert sidecar["analyses"]["s1"]["result"] == "result"

    def test_empty_sidecar_starts_fresh(self, tmp_path: Path, mock_logger: Mock) -> None:
        """Empty pre-created sidecar (touch) is treated as missing and written fresh."""
        ai_path = tmp_path / "ai-analyses.json"
        ai_path.write_text("")  # simulates `touch`

        write_ai_analysis(
            str(ai_path), "/logs/node/s.json", "mec-node-1", "s1", "result", mock_logger
        )

        sidecar: dict[str, Any] = json.loads(ai_path.read_text())
        assert "s1" in sidecar["analyses"]
        assert sidecar["analyses"]["s1"]["result"] == "result"

    def test_output_is_valid_json_ending_with_newline(
        self, tmp_path: Path, mock_logger: Mock
    ) -> None:
        """Output sidecar file is valid JSON and ends with a newline."""
        ai_path = tmp_path / "ai-analyses.json"
        write_ai_analysis(
            str(ai_path), "/logs/node/s.json", "mec-node-1", "s1", "result", mock_logger
        )

        content: str = ai_path.read_text()
        assert content.endswith("\n")
        json.loads(content)  # Must parse without error
