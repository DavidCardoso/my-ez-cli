"""
Filter Engine Tests
===================
Tests for I/O filtering engine.
"""

import logging
from unittest.mock import Mock

import pytest
from src.filters.engine import FilterEngine


@pytest.fixture
def mock_logger():
    """Mock logger."""
    return Mock(spec=logging.Logger)


@pytest.fixture
def default_config():
    """Config with default filters."""
    return {"ai": {"enabled": True}}


@pytest.fixture
def custom_config():
    """Config with custom filters."""
    return {
        "ai": {
            "enabled": True,
            "filters": {
                "ignore_output": [
                    "^npm warn",
                    "^DEBUG:",
                    r"^\d+%",
                ],
                "ignore_input": [
                    "node_modules/",
                    r"\.pyc$",
                ],
            },
        }
    }


@pytest.fixture
def engine(custom_config, mock_logger):
    """Filter engine instance with custom config."""
    return FilterEngine(custom_config, mock_logger)


@pytest.fixture
def default_engine(default_config, mock_logger):
    """Filter engine instance with default config."""
    return FilterEngine(default_config, mock_logger)


class TestOutputFiltering:
    """Test output filtering."""

    def test_filter_npm_warnings(self, engine):
        """Test filtering npm warn lines."""
        text = """npm warn deprecated package@1.0
npm warn peer dependency
Server listening on port 3000
npm warn optional dependency"""

        result = engine.filter_output(text)

        assert "npm warn" not in result
        assert "Server listening on port 3000" in result

    def test_filter_debug_lines(self, engine):
        """Test filtering debug lines."""
        text = """DEBUG: starting
Application ready
DEBUG: connected"""

        result = engine.filter_output(text)

        assert "DEBUG:" not in result
        assert "Application ready" in result

    def test_filter_progress_percentages(self, engine):
        """Test filtering progress percentages."""
        text = """10% complete
50% complete
Installing packages
100% complete"""

        result = engine.filter_output(text)

        assert "10% complete" not in result
        assert "Installing packages" in result

    def test_empty_input(self, engine):
        """Test with empty input."""
        assert engine.filter_output("") == ""

    def test_no_matching_patterns(self, engine):
        """Test when no lines match filters."""
        text = "Server started\nListening on port 8080"
        result = engine.filter_output(text)
        assert result == text

    def test_all_lines_filtered(self, engine):
        """Test when all lines match filters."""
        text = "npm warn foo\nnpm warn bar"
        result = engine.filter_output(text)
        assert result == ""


class TestInputFiltering:
    """Test input filtering."""

    def test_filter_node_modules(self, engine):
        """Test filtering node_modules references."""
        text = """src/index.js
node_modules/express/index.js
src/utils.js
node_modules/lodash/lodash.js"""

        result = engine.filter_input(text)

        assert "node_modules/" not in result
        assert "src/index.js" in result
        assert "src/utils.js" in result

    def test_filter_pyc_files(self, engine):
        """Test filtering .pyc files."""
        text = """src/main.py
__pycache__/main.pyc
src/utils.py"""

        result = engine.filter_input(text)

        assert "main.pyc" not in result
        assert "src/main.py" in result

    def test_empty_input(self, engine):
        """Test with empty input."""
        assert engine.filter_input("") == ""


class TestConfiguration:
    """Test filter configuration."""

    def test_default_patterns_loaded(self, default_engine):
        """Test that default patterns are loaded when no config."""
        stats = default_engine.get_stats()
        assert stats["output_patterns"] > 0
        assert stats["input_patterns"] > 0

    def test_custom_patterns_loaded(self, engine):
        """Test that custom patterns override defaults."""
        stats = engine.get_stats()
        assert stats["output_patterns"] == 3
        assert stats["input_patterns"] == 2

    def test_invalid_pattern_skipped(self, mock_logger):
        """Test that invalid regex patterns are skipped."""
        config = {
            "ai": {
                "filters": {
                    "ignore_output": ["[invalid", "^valid"],
                    "ignore_input": [],
                }
            }
        }
        engine = FilterEngine(config, mock_logger)
        stats = engine.get_stats()
        assert stats["output_patterns"] == 1  # Only "^valid" compiled

    def test_empty_filter_config(self, mock_logger):
        """Test with empty filter lists."""
        config = {
            "ai": {
                "filters": {
                    "ignore_output": [],
                    "ignore_input": [],
                }
            }
        }
        engine = FilterEngine(config, mock_logger)
        text = "npm warn something"
        assert engine.filter_output(text) == text
