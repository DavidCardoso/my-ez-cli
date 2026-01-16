"""YAML key read/write using indent-depth tracking (no regex).

Supports arbitrary dotted keys (1-level, 2-level, 3-level+).
Preserves all comments, blank lines, and existing formatting.
"""

import logging
from pathlib import Path

from .exceptions import ConfigFileNotFoundError, ConfigWriteError
from .types import DottedKey, YamlValue

logger = logging.getLogger(__name__)


def _indent_of(line: str) -> int:
    """Return the number of leading spaces for a non-empty line."""
    return len(line) - len(line.lstrip(" "))


def _is_content_line(line: str) -> bool:
    """Return True if a line has YAML content (not blank, not comment-only)."""
    stripped = line.strip()
    return bool(stripped) and not stripped.startswith("#")


def _key_indent(depth: int) -> str:
    """Return the indentation string for a given nesting depth (0-based)."""
    return "  " * depth


def parse_yaml_key(path: str, dotted_key: DottedKey) -> str | None:
    """Read a scalar value for *dotted_key* from the YAML file at *path*.

    Uses indent-depth tracking rather than regex so it handles arbitrary
    nesting correctly, including keys that share a prefix (e.g. ``ai:`` and
    ``ai_service:`` are distinct).

    Args:
        path: Absolute path to the YAML file.
        dotted_key: Key in dotted notation, e.g. ``"ai.claude.model"``.

    Returns:
        The scalar value as a string (stripped), or ``None`` if not found.

    Raises:
        ConfigFileNotFoundError: If *path* does not exist.
    """
    p = Path(path)
    if not p.exists():
        raise ConfigFileNotFoundError(path)

    parts = dotted_key.split(".")
    depth = 0  # which part index we are currently matching
    target_depth = len(parts)

    try:
        lines = p.read_text(encoding="utf-8").splitlines()
    except OSError as e:
        logger.error("Failed to read config file %s: %s", path, e, exc_info=True)
        raise ConfigFileNotFoundError(path) from e

    # indent_stack[i] = the leading-space count for depth i
    indent_stack: list[int] = [-1]  # depth 0 lives at indent -1 (before any line)

    for line in lines:
        if not _is_content_line(line):
            continue

        indent = _indent_of(line)
        stripped = line.strip()

        # Pop the stack when indentation decreases (or stays same and isn't deeper)
        while len(indent_stack) > 1 and indent <= indent_stack[-1]:
            indent_stack.pop()
            depth = len(indent_stack) - 1

        # We are now at the correct stack depth for this line's parent
        current_depth = len(indent_stack) - 1

        if current_depth != depth:
            # We've gone deeper than expected — skip
            continue

        # Check if this line matches the next key part
        expected_key = parts[depth]
        if stripped.startswith(expected_key + ":"):
            remainder = stripped[len(expected_key) + 1 :].strip()
            # Strip inline comments
            if "#" in remainder:
                remainder = remainder[: remainder.index("#")].strip()

            if depth == target_depth - 1:
                # This is the final key — return its inline value (or empty → None)
                return remainder if remainder else None

            # Intermediate key — descend
            depth += 1
            indent_stack.append(indent)
        # else: this key doesn't match; remain at current depth

    return None


def set_yaml_key(path: str, dotted_key: DottedKey, value: YamlValue) -> None:
    """Write *value* for *dotted_key* into the YAML file at *path* in-place.

    - If the key already exists: replaces only that line.
    - If an ancestor section exists but the key is missing: inserts the
      remaining hierarchy directly after the ancestor's last sub-line.
    - If nothing matches: appends the full hierarchy at EOF.

    All comments, blank lines, and existing formatting are preserved.

    Args:
        path: Absolute path to the YAML file.
        dotted_key: Key in dotted notation, e.g. ``"ai.claude.model"``.
        value: Scalar value to write.

    Raises:
        ConfigFileNotFoundError: If *path* does not exist.
        ConfigWriteError: If writing the file fails.
    """
    p = Path(path)
    if not p.exists():
        raise ConfigFileNotFoundError(path)

    try:
        original = p.read_text(encoding="utf-8")
    except OSError as e:
        logger.error("Failed to read config file %s: %s", path, e, exc_info=True)
        raise ConfigFileNotFoundError(path) from e

    parts = dotted_key.split(".")
    lines = original.splitlines(keepends=True)

    result = _set_in_lines(lines, parts, value)

    try:
        p.write_text("".join(result), encoding="utf-8")
    except OSError as e:
        logger.error("Failed to write config file %s: %s", path, e, exc_info=True)
        raise ConfigWriteError(path, str(e)) from e

    logger.debug("Set %s = %s in %s", dotted_key, value, path)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _set_in_lines(lines: list[str], parts: list[str], value: str) -> list[str]:
    """Return a new list of lines with *parts* key set to *value*.

    Walks lines using the same indent-depth tracking as ``parse_yaml_key``.
    Handles replace-in-place, insert-into-section, and append-at-EOF.
    """
    target_depth = len(parts)

    # Phase 1: scan for the deepest matched ancestor and whether the key exists.
    # We track: for each depth level matched, the line index where that key header was.
    matched_depth = 0  # how many key parts have been matched consecutively
    match_line_idx: list[int] = []  # line indices for each matched key part
    indent_stack: list[int] = [-1]
    depth = 0
    # Once we have matched some ancestors and then pop above them, stop scanning.
    # This prevents re-matching the same top-level key later in the file.

    for i, line in enumerate(lines):
        if not _is_content_line(line):
            continue

        indent = _indent_of(line)
        stripped = line.strip()

        # Pop the stack on dedent
        while len(indent_stack) > 1 and indent <= indent_stack[-1]:
            indent_stack.pop()
            depth = len(indent_stack) - 1

        current_depth = len(indent_stack) - 1
        if current_depth != depth:
            continue

        # If we've already matched some ancestors but popped back above them,
        # stop — we have our best match.
        if depth < len(match_line_idx):
            break

        if depth >= target_depth:
            # We're deeper than needed; skip
            continue

        expected_key = parts[depth]
        if stripped.startswith(expected_key + ":"):
            match_line_idx.append(i)
            matched_depth = depth + 1

            if matched_depth == target_depth:
                # Found the target key — replace inline value
                return _replace_line_value(lines, i, parts[-1], value)

            # Intermediate key — descend
            depth += 1
            indent_stack.append(indent)

    # Key not found; matched_depth tells us the deepest ancestor we found.
    if matched_depth == 0:
        # Nothing matched — append full hierarchy at EOF
        return _append_hierarchy(lines, parts, value)

    # We matched some ancestors. Find the insertion point:
    # just after the last line belonging to the deepest matched ancestor's block.
    ancestor_line_idx = match_line_idx[matched_depth - 1]
    insert_at = _find_block_end(lines, ancestor_line_idx)
    remaining_parts = parts[matched_depth:]
    base_indent = matched_depth  # depth of deepest matched ancestor

    insert_lines = _build_hierarchy(remaining_parts, value, base_indent)
    return lines[:insert_at] + insert_lines + lines[insert_at:]


def _replace_line_value(lines: list[str], idx: int, key: str, value: str) -> list[str]:
    """Replace the value of *key* on line *idx*, preserving indentation."""
    line = lines[idx]
    indent = _indent_of(line)
    new_line = " " * indent + key + ": " + value + "\n"
    result = list(lines)
    result[idx] = new_line
    return result


def _find_block_end(lines: list[str], header_idx: int) -> int:
    """Return the index *after* the last line of the block starting at *header_idx*.

    The block ends when we encounter a content line whose indent is ≤ the
    header's indent (i.e. we've left the section), or at EOF.
    """
    header_indent = _indent_of(lines[header_idx])
    i = header_idx + 1
    last_content = header_idx + 1  # default: insert right after header

    while i < len(lines):
        line = lines[i]
        if _is_content_line(line):
            if _indent_of(line) <= header_indent:
                # We've left the block
                break
            last_content = i + 1
        i += 1

    return last_content


def _build_hierarchy(parts: list[str], value: str, base_depth: int) -> list[str]:
    """Build indented YAML lines for *parts* key hierarchy ending with *value*.

    Args:
        parts: Key parts that still need to be written.
        value: Scalar value for the deepest key.
        base_depth: Indentation depth of the first part (0-based levels).

    Returns:
        List of lines (with newlines) to insert.
    """
    result: list[str] = []
    for i, part in enumerate(parts[:-1]):
        indent = _key_indent(base_depth + i)
        result.append(f"{indent}{part}:\n")
    # Final key with value
    final_indent = _key_indent(base_depth + len(parts) - 1)
    result.append(f"{final_indent}{parts[-1]}: {value}\n")
    return result


def _append_hierarchy(lines: list[str], parts: list[str], value: str) -> list[str]:
    """Append a full key hierarchy at EOF, with a blank separator line if needed."""
    result = list(lines)
    # Add a blank line before the new section if the file doesn't end with one
    if result and result[-1].strip():
        result.append("\n")
    result.extend(_build_hierarchy(parts, value, 0))
    return result
