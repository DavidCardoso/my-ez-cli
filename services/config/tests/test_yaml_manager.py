"""Tests for yaml_manager — get and set operations at 1/2/3 key depths."""

import textwrap
from pathlib import Path

import pytest
from src.exceptions import ConfigFileNotFoundError, ConfigKeyError
from src.main import main
from src.yaml_manager import parse_yaml_key, set_yaml_key

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture()
def config_file(tmp_path: Path) -> Path:
    """Return a temp YAML file with a representative config."""
    content = textwrap.dedent("""\
        # My Ez CLI config
        logs:
          enabled: false
          level: info

        ai:
          enabled: true
          claude:
            model: sonnet
            max_output_tokens: 8096
            effort_level: medium

        tools:
          node:
            default_version: 22
    """)
    f = tmp_path / "config.yaml"
    f.write_text(content)
    return f


@pytest.fixture()
def minimal_file(tmp_path: Path) -> Path:
    """Return a minimal YAML file with just one top-level key."""
    f = tmp_path / "minimal.yaml"
    f.write_text("ai:\n  enabled: false\n")
    return f


# ---------------------------------------------------------------------------
# parse_yaml_key — 1-level
# ---------------------------------------------------------------------------


class TestParseYamlKey1Level:
    """Tests for reading top-level keys."""

    def test_missing_file_raises(self, tmp_path: Path) -> None:
        with pytest.raises(ConfigFileNotFoundError):
            parse_yaml_key(str(tmp_path / "missing.yaml"), "logs")

    def test_top_level_key_not_found_returns_none(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "nonexistent") is None

    def test_section_key_without_inline_value_returns_none(self, config_file: Path) -> None:
        # "logging:" has no inline value
        assert parse_yaml_key(str(config_file), "logs") is None


# ---------------------------------------------------------------------------
# parse_yaml_key — 2-level
# ---------------------------------------------------------------------------


class TestParseYamlKey2Level:
    """Tests for reading 2-level nested keys."""

    def test_reads_boolean_value(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "logs.enabled") == "false"

    def test_reads_string_value(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "logs.level") == "info"

    def test_reads_ai_enabled(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "ai.enabled") == "true"

    def test_missing_key_returns_none(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "logs.nonexistent") == None  # noqa: E711

    def test_missing_section_returns_none(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "nosection.key") is None


# ---------------------------------------------------------------------------
# parse_yaml_key — 3-level
# ---------------------------------------------------------------------------


class TestParseYamlKey3Level:
    """Tests for reading 3-level nested keys."""

    def test_reads_claude_model(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "ai.claude.model") == "sonnet"

    def test_reads_max_output_tokens(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "ai.claude.max_output_tokens") == "8096"

    def test_reads_effort_level(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "ai.claude.effort_level") == "medium"

    def test_reads_default_version(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "tools.node.default_version") == "22"

    def test_missing_3rd_level_key_returns_none(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "ai.claude.nonexistent") is None

    def test_missing_2nd_level_section_returns_none(self, config_file: Path) -> None:
        assert parse_yaml_key(str(config_file), "ai.nosection.key") is None


# ---------------------------------------------------------------------------
# set_yaml_key — replace existing
# ---------------------------------------------------------------------------


class TestSetYamlKeyReplace:
    """Tests for updating existing keys."""

    def test_replace_2nd_level_value(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "logs.enabled", "true")
        assert parse_yaml_key(str(config_file), "logs.enabled") == "true"

    def test_replace_3rd_level_value(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "ai.claude.model", "haiku")
        assert parse_yaml_key(str(config_file), "ai.claude.model") == "haiku"

    def test_replace_does_not_create_duplicates(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "ai.claude.model", "opus")
        set_yaml_key(str(config_file), "ai.claude.model", "sonnet")
        content = config_file.read_text()
        assert content.count("model:") == 1

    def test_replace_preserves_other_keys(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "ai.claude.model", "haiku")
        assert parse_yaml_key(str(config_file), "ai.claude.max_output_tokens") == "8096"
        assert parse_yaml_key(str(config_file), "ai.enabled") == "true"

    def test_replace_preserves_comments(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "logs.enabled", "true")
        content = config_file.read_text()
        assert "# My Ez CLI config" in content

    def test_no_duplicate_ai_section(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "ai.enabled", "false")
        content = config_file.read_text()
        assert content.count("ai:") == 1


# ---------------------------------------------------------------------------
# set_yaml_key — insert into existing section
# ---------------------------------------------------------------------------


class TestSetYamlKeyInsert:
    """Tests for inserting a new key into an existing section."""

    def test_insert_2nd_level_into_existing_section(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "logs.new_key", "myvalue")
        assert parse_yaml_key(str(config_file), "logs.new_key") == "myvalue"

    def test_insert_3rd_level_into_existing_subsection(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "ai.claude.temperature", "0.7")
        assert parse_yaml_key(str(config_file), "ai.claude.temperature") == "0.7"

    def test_insert_3rd_level_creates_missing_subsection(self, minimal_file: Path) -> None:
        set_yaml_key(str(minimal_file), "ai.claude.model", "sonnet")
        assert parse_yaml_key(str(minimal_file), "ai.claude.model") == "sonnet"

    def test_insert_does_not_duplicate_existing_section_header(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "ai.claude.new_key", "x")
        content = config_file.read_text()
        assert content.count("claude:") == 1


# ---------------------------------------------------------------------------
# set_yaml_key — append new section
# ---------------------------------------------------------------------------


class TestSetYamlKeyAppend:
    """Tests for appending an entirely new key hierarchy."""

    def test_append_top_level_key(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "newkey", "val")
        assert parse_yaml_key(str(config_file), "newkey") == "val"

    def test_append_new_2nd_level_section(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "newsection.key", "hello")
        assert parse_yaml_key(str(config_file), "newsection.key") == "hello"

    def test_append_new_3rd_level_section(self, config_file: Path) -> None:
        set_yaml_key(str(config_file), "newsection.sub.key", "world")
        assert parse_yaml_key(str(config_file), "newsection.sub.key") == "world"


# ---------------------------------------------------------------------------
# set_yaml_key — error handling
# ---------------------------------------------------------------------------


class TestSetYamlKeyErrors:
    """Tests for error conditions in set_yaml_key."""

    def test_missing_file_raises(self, tmp_path: Path) -> None:
        with pytest.raises(ConfigFileNotFoundError):
            set_yaml_key(str(tmp_path / "missing.yaml"), "key", "value")


# ---------------------------------------------------------------------------
# main() CLI dispatcher
# ---------------------------------------------------------------------------


class TestMainCLI:
    """Tests for the main() CLI dispatcher."""

    def test_get_existing_key(self, config_file: Path, capsys: pytest.CaptureFixture) -> None:
        rc = main(["get", str(config_file), "ai.claude.model"])
        assert rc == 0
        captured = capsys.readouterr()
        assert captured.out.strip() == "sonnet"

    def test_get_missing_key_exits_1(self, config_file: Path) -> None:
        with pytest.raises(ConfigKeyError):
            main(["get", str(config_file), "nonexistent.key"])

    def test_set_and_get_roundtrip(self, config_file: Path, capsys: pytest.CaptureFixture) -> None:
        rc = main(["set", str(config_file), "ai.claude.model", "haiku"])
        assert rc == 0

        rc2 = main(["get", str(config_file), "ai.claude.model"])
        assert rc2 == 0
        captured = capsys.readouterr()
        assert captured.out.strip() == "haiku"

    def test_no_args_returns_usage_error(self) -> None:
        rc = main([])
        assert rc == 2

    def test_unknown_command_returns_usage_error(self) -> None:
        rc = main(["unknown"])
        assert rc == 2

    def test_get_wrong_arg_count_returns_2(self) -> None:
        rc = main(["get", "file"])
        assert rc == 2

    def test_set_wrong_arg_count_returns_2(self) -> None:
        rc = main(["set", "file", "key"])
        assert rc == 2
