"""
Filter Engine
=============
Pattern-based I/O filtering for token optimization.

Applies regex patterns to tool output before passing to Claude Code,
reducing token usage by filtering noise (progress bars, warnings, tree formatting).

Filter rules can be defined in config YAML (ai.filters section).
"""

import logging
import re
from re import Pattern
from typing import Any

# Default filter patterns applied when no config is provided
DEFAULT_OUTPUT_FILTERS: list[str] = [
    r"^npm warn",
    r"^npm WARN",
    r"^Downloading.*\d+%",
    r"^\s*[├└│─┬┼]",
    r"^\s*\+[-]+\+$",
    r"^\.\.\.$",
]

DEFAULT_INPUT_FILTERS: list[str] = [
    r"node_modules/",
    r"\.lock$",
]


class FilterEngine:
    """
    Pattern-based I/O filtering engine.

    Reads filter rules from config YAML and applies regex patterns
    to tool output to reduce noise before AI analysis.

    Attributes:
        config: Configuration dictionary
        logger: Logger instance
        output_patterns: Compiled patterns for output filtering
        input_patterns: Compiled patterns for input filtering
    """

    def __init__(self, config: dict[str, Any], logger: logging.Logger) -> None:
        """
        Initialize filter engine.

        Args:
            config: Configuration dictionary with ai.filters section
            logger: Logger instance
        """
        self.config: dict[str, Any] = config
        self.logger: logging.Logger = logger

        # Load filter patterns from config
        filter_config: dict[str, Any] = config.get("ai", {}).get("filters", {})

        output_patterns: list[str] = filter_config.get("ignore_output", DEFAULT_OUTPUT_FILTERS)
        input_patterns: list[str] = filter_config.get("ignore_input", DEFAULT_INPUT_FILTERS)

        self.output_patterns: list[Pattern[str]] = self._compile_patterns(output_patterns)
        self.input_patterns: list[Pattern[str]] = self._compile_patterns(input_patterns)

    def _compile_patterns(self, patterns: list[str]) -> list[Pattern[str]]:
        """
        Compile regex patterns, skipping invalid ones.

        Args:
            patterns: List of regex pattern strings

        Returns:
            List of compiled regex patterns
        """
        compiled: list[Pattern[str]] = []
        for pattern_str in patterns:
            try:
                compiled.append(re.compile(pattern_str))
            except re.error as e:
                self.logger.warning("Invalid filter pattern '%s': %s", pattern_str, e)
        return compiled

    def filter_output(self, text: str) -> str:
        """
        Filter tool output by removing lines matching ignore patterns.

        Each line is tested against all output patterns. Lines matching
        any pattern are removed. This reduces noise from progress bars,
        deprecation warnings, tree formatting, etc.

        Args:
            text: Raw tool output text

        Returns:
            Filtered text with noise lines removed
        """
        if not text or not self.output_patterns:
            return text

        lines: list[str] = text.splitlines()
        filtered_lines: list[str] = [
            line for line in lines if not self._matches_any(line, self.output_patterns)
        ]

        filtered: str = "\n".join(filtered_lines)
        removed_count: int = len(lines) - len(filtered_lines)

        if removed_count > 0:
            self.logger.debug(
                "Filtered %d lines from output (%d -> %d)",
                removed_count,
                len(lines),
                len(filtered_lines),
            )

        return filtered

    def filter_input(self, text: str) -> str:
        """
        Filter input text by removing lines matching ignore patterns.

        Used to filter paths or content before sending to AI analysis,
        e.g., removing node_modules references or lock file contents.

        Args:
            text: Raw input text

        Returns:
            Filtered text
        """
        if not text or not self.input_patterns:
            return text

        lines: list[str] = text.splitlines()
        filtered_lines: list[str] = [
            line for line in lines if not self._matches_any(line, self.input_patterns)
        ]

        return "\n".join(filtered_lines)

    def _matches_any(self, line: str, patterns: list[Pattern[str]]) -> bool:
        """
        Check if a line matches any of the given patterns.

        Args:
            line: Text line to check
            patterns: List of compiled regex patterns

        Returns:
            True if line matches any pattern
        """
        return any(pattern.search(line) for pattern in patterns)

    def get_stats(self) -> dict[str, int]:
        """
        Get filter engine statistics.

        Returns:
            Dictionary with pattern counts
        """
        return {
            "output_patterns": len(self.output_patterns),
            "input_patterns": len(self.input_patterns),
        }
