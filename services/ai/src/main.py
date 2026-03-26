#!/usr/bin/env python3
"""
My Ez CLI - AI Service
======================
Main entry point for I/O filtering and middleware.

Commands:
- filter <text>: Filter output using configured patterns
- --help: Show help message
- --version: Show version
"""

import sys
import tomllib
from collections.abc import Callable
from pathlib import Path
from typing import Any, NoReturn

from .claude_response import parse_claude_response, write_ai_analysis
from .exceptions import ClaudeResponseParseError
from .filters.engine import FilterEngine
from .utils.config import is_ai_enabled, load_config
from .utils.logger import setup_logger


def _get_version() -> str:
    """
    Get version from pyproject.toml.

    Returns:
        Version string (e.g., '1.0.0')
    """
    try:
        pyproject_path: Path = Path(__file__).parent.parent / "pyproject.toml"
        with pyproject_path.open("rb") as f:
            pyproject_data: dict[str, Any] = tomllib.load(f)
        version: str = pyproject_data.get("tool", {}).get("poetry", {}).get("version", "unknown")
        return version
    except Exception:
        return "unknown"


def _error_response(error: str, error_type: str = "Error", **kwargs: Any) -> dict[str, Any]:
    """
    Create standardized error response.

    Args:
        error: Error message
        error_type: Error type classification
        **kwargs: Additional fields to include

    Returns:
        Error response dictionary
    """
    response: dict[str, Any] = {
        "status": "error",
        "error": error,
        "error_type": error_type,
    }
    response.update(kwargs)
    return response


def show_help() -> None:
    """Display help message."""
    version: str = _get_version()
    help_text: str = f"""
My Ez CLI - AI Service (v{version})

Usage: ai-service <command> [arguments]

Commands:
  filter <text>                   Filter output using configured patterns
  parse-claude-response           Parse Claude Code JSON from stdin, print result
    [--ai-file <path>]            Write analysis to sidecar file
    [--log-file <path>]           Original log path (stored as metadata in sidecar)
    [--log-session-id <id>]       Tool session ID (stored in sidecar)
  --help, -h                      Show this help message
  --version, -v                   Show version

Examples:
  echo "npm warn ..." | ai-service filter -
  echo '{...}' | ai-service parse-claude-response
  echo '{...}' | ai-service parse-claude-response \
    --ai-file /path/to/ai-analyses.json \
    --log-file /path/to/log.json \
    --log-session-id mec-node-1705318245

Environment Variables:
  MEC_AI_ENABLED       Enable/disable AI (true/false)

Configuration:
  Default: config/config.default.yaml
  User:    ~/.my-ez-cli/config.yaml

For more information:
  https://github.com/DavidCardoso/my-ez-cli
"""
    print(help_text)


def show_version() -> None:
    """Display version information."""
    version: str = _get_version()
    print(f"My Ez CLI AI Service v{version}")
    print("I/O middleware and filtering for My Ez CLI tools")


def filter_output(config: dict[str, Any], logger: Any) -> None:
    """
    Filter input from stdin or argument using configured patterns.

    Reads from stdin if argument is "-", otherwise reads from file.

    Args:
        config: Configuration dictionary
        logger: Logger instance
    """
    engine: FilterEngine = FilterEngine(config, logger)

    if len(sys.argv) < 3:
        _print_error_and_exit(
            "Missing text argument", "UsageError", usage="ai-service filter <text|->"
        )

    source: str = sys.argv[2]

    if source == "-":
        text: str = sys.stdin.read()
    else:
        text = source

    filtered: str = engine.filter_output(text)
    print(filtered)


def _print_error_and_exit(
    error: str, error_type: str = "Error", code: int = 1, **kwargs: Any
) -> NoReturn:
    """
    Print error as JSON and exit.

    Args:
        error: Error message
        error_type: Error type
        code: Exit code
        **kwargs: Additional fields
    """
    import json

    response: dict[str, Any] = _error_response(error, error_type, **kwargs)
    print(json.dumps(response), file=sys.stderr)
    sys.exit(code)


def _handle_filter(config: dict[str, Any], logger: Any) -> None:
    """Handle filter command."""
    filter_output(config, logger)


def _handle_parse_claude_response(_config: dict[str, Any], logger: Any) -> None:
    """
    Parse Claude Code JSON response and optionally write to sidecar file.

    Reads raw Claude Code --output-format json from stdin.
    Prints session_id on the first line and result text on subsequent lines
    to stdout (for the shell to capture and display).
    If --ai-file <path> is provided, writes analysis to the sidecar file
    instead of mutating the original log file.

    Args:
        _config: Unused — parse-claude-response uses stdlib only
        logger: Logger instance
    """
    args: list[str] = sys.argv[2:]

    def _get_arg(flag: str) -> str:
        if flag in args:
            idx: int = args.index(flag)
            if idx + 1 < len(args):
                return args[idx + 1]
            _print_error_and_exit(f"{flag} requires a path argument", "UsageError")
        return ""

    ai_file_path: str = _get_arg("--ai-file")
    log_file_path: str = _get_arg("--log-file")
    log_session_id: str = _get_arg("--log-session-id")

    raw_json: str = sys.stdin.read()

    try:
        session_id: str
        result: str
        input_tokens: int
        output_tokens: int
        session_id, result, input_tokens, output_tokens = parse_claude_response(raw_json, logger)
    except ClaudeResponseParseError as e:
        logger.error("Failed to parse Claude response: %s", e, exc_info=True)
        _print_error_and_exit(str(e), "ClaudeResponseParseError")

    # Output: first line = session_id, rest = result text
    print(session_id)
    print(result)

    if ai_file_path:
        try:
            write_ai_analysis(
                ai_analysis_path=ai_file_path,
                log_file_path=log_file_path,
                log_session_id=log_session_id,
                claude_session_id=session_id,
                result=result,
                logger=logger,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
            )
        except ClaudeResponseParseError as e:
            logger.error("Failed to write AI analysis sidecar: %s", e, exc_info=True)
            _print_error_and_exit(str(e), "ClaudeResponseParseError")


def main() -> None:
    """Main CLI dispatcher."""
    if len(sys.argv) < 2:
        _print_error_and_exit(
            "No command specified",
            "UsageError",
            suggestion="Run 'ai-service --help' for usage information",
        )

    command: str = sys.argv[1]

    if command in ("--help", "-h", "help"):
        show_help()
        return

    if command in ("--version", "-v", "version"):
        show_version()
        return

    # parse-claude-response is a utility command — always available, no AI check needed
    if command == "parse-claude-response":
        try:
            config: dict[str, Any] = load_config()
            logger: Any = setup_logger(config)
        except (OSError, RuntimeError, ValueError) as e:
            _print_error_and_exit(f"Failed to load configuration: {e}", "ConfigurationError")
        _handle_parse_claude_response(config, logger)
        return

    try:
        config = load_config()
        logger = setup_logger(config)
    except (OSError, RuntimeError, ValueError) as e:
        _print_error_and_exit(f"Failed to load configuration: {e}", "ConfigurationError")

    if config and not is_ai_enabled(config):
        import json

        response: dict[str, Any] = {
            "status": "disabled",
            "error": "AI integration is disabled",
            "suggestion": "Enable with: mec config set ai.enabled true",
        }
        print(json.dumps(response, indent=2))
        sys.exit(1)

    command_handlers: dict[str, Callable[[dict[str, Any], Any], None]] = {
        "filter": _handle_filter,
        "parse-claude-response": _handle_parse_claude_response,
    }

    try:
        handler: Callable[[dict[str, Any], Any], None] | None = command_handlers.get(command)

        if not handler:
            _print_error_and_exit(
                f"Unknown command: {command}",
                "UsageError",
                suggestion="Run 'ai-service --help' for usage information",
            )
            return

        handler(config, logger)

    except (OSError, RuntimeError, ValueError) as e:
        logger.error("Unexpected error: %s", e, exc_info=True)
        _print_error_and_exit(str(e), type(e).__name__)


if __name__ == "__main__":
    main()
