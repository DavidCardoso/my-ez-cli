"""Tests for POST /api/sessions/{session_id}/analyze endpoint."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from src.main import create_app

from tests.test_sessions import _write_log, _write_sidecar


@pytest.fixture()
def data_root(tmp_path: Path) -> Path:
    (tmp_path / "logs").mkdir()
    (tmp_path / "ai-analyses").mkdir()
    return tmp_path


@pytest.fixture()
def client(data_root: Path) -> TestClient:
    app = create_app(data_root=data_root)
    return TestClient(app)


class TestAnalyzeEndpoint:
    """Tests for POST /api/sessions/{session_id}/analyze."""

    def test_returns_404_when_session_not_found(self, client: TestClient) -> None:
        res = client.post("/api/sessions/mec-npm-nonexistent/analyze")
        assert res.status_code == 404

    def test_returns_202_when_analysis_triggered(self, client: TestClient, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        with patch("src.api.sessions.trigger_analysis", return_value=True):
            res = client.post("/api/sessions/mec-npm-1/analyze")
        assert res.status_code == 202
        assert res.json() == {"status": "triggered", "session_id": "mec-npm-1"}

    def test_returns_409_when_ai_already_done(self, client: TestClient, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        _write_sidecar(data_root, "npm", "2026-03-25_12-00-00", result="Already analyzed.")
        with patch("src.api.sessions.trigger_analysis", return_value=True):
            res = client.post("/api/sessions/mec-npm-1/analyze")
        assert res.status_code == 409
        assert "already" in res.json()["detail"].lower()

    def test_returns_409_when_ai_pending(self, client: TestClient, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        _write_sidecar(data_root, "npm", "2026-03-25_12-00-00", result="")
        with patch("src.api.sessions.trigger_analysis", return_value=True):
            res = client.post("/api/sessions/mec-npm-1/analyze")
        assert res.status_code == 409
