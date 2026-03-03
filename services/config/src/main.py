"""CLI dispatcher for the config service.

Usage:
    python -m src.main get <file> <dotted-key>
    python -m src.main set <file> <dotted-key> <value>
    python -m src.main get-list <file> <dotted-key>
    python -m src.main add-list-item <file> <dotted-key> <item>
    python -m src.main remove-list-item <file> <dotted-key> <item>

Exit codes:
    0  success
    1  key not found (get) or write error (set)
    2  usage error
"""

import sys

from .exceptions import ConfigFileNotFoundError, ConfigKeyError, ConfigServiceError
from .yaml_manager import (
    add_yaml_list_item,
    parse_yaml_key,
    parse_yaml_list,
    remove_yaml_list_item,
    set_yaml_key,
)


def main(argv: list[str] | None = None) -> int:
    """Entry point for the config service CLI.

    Args:
        argv: Command-line arguments (defaults to sys.argv[1:]).

    Returns:
        Exit code (0 = success, 1 = error, 2 = usage error).
    """
    args = argv if argv is not None else sys.argv[1:]

    if not args:
        _usage()
        return 2

    command = args[0]
    return _dispatch(command, args[1:])


def _dispatch(command: str, args: list[str]) -> int:
    """Route *command* to the appropriate handler.

    Args:
        command: Sub-command name.
        args: Remaining arguments after the command name.

    Returns:
        Exit code.
    """
    if command == "get":
        return _check_args(args, 2, "get <file> <key>") or _cmd_get(args[0], args[1])
    if command == "set":
        return _check_args(args, 3, "set <file> <key> <value>") or _cmd_set(
            args[0], args[1], args[2]
        )
    if command == "get-list":
        return _check_args(args, 2, "get-list <file> <key>") or _cmd_get_list(args[0], args[1])
    if command == "add-list-item":
        return _check_args(args, 3, "add-list-item <file> <key> <item>") or _cmd_add_list_item(
            args[0], args[1], args[2]
        )
    if command == "remove-list-item":
        return _check_args(
            args, 3, "remove-list-item <file> <key> <item>"
        ) or _cmd_remove_list_item(args[0], args[1], args[2])
    print(f"Unknown command: {command}", file=sys.stderr)
    _usage()
    return 2


def _check_args(args: list[str], expected: int, usage: str) -> int:
    """Return 2 and print usage if *args* length doesn't match *expected*, else 0.

    Args:
        args: Argument list to check (excluding the command itself).
        expected: Expected number of arguments.
        usage: Usage string to print on mismatch.

    Returns:
        2 if wrong count, 0 if correct (caller should short-circuit on non-zero).
    """
    if len(args) != expected:
        print(f"Usage: python -m src.main {usage}", file=sys.stderr)
        return 2
    return 0


def _cmd_get(file_path: str, key: str) -> int:
    """Handle the 'get' sub-command.

    Args:
        file_path: Path to the YAML config file.
        key: Dotted key to read.

    Returns:
        Exit code.
    """
    try:
        value = parse_yaml_key(file_path, key)
    except ConfigFileNotFoundError as e:
        print(str(e), file=sys.stderr)
        return 1
    except ConfigServiceError as e:
        print(str(e), file=sys.stderr)
        return 1

    if value is None:
        raise ConfigKeyError(key)

    print(value)
    return 0


def _cmd_set(file_path: str, key: str, value: str) -> int:
    """Handle the 'set' sub-command.

    Args:
        file_path: Path to the YAML config file.
        key: Dotted key to write.
        value: Scalar value to set.

    Returns:
        Exit code.
    """
    try:
        set_yaml_key(file_path, key, value)
    except ConfigFileNotFoundError as e:
        print(str(e), file=sys.stderr)
        return 1
    except ConfigServiceError as e:
        print(str(e), file=sys.stderr)
        return 1

    return 0


def _cmd_get_list(file_path: str, key: str) -> int:
    """Handle the 'get-list' sub-command.

    Args:
        file_path: Path to the YAML config file.
        key: Dotted key to read as a list.

    Returns:
        Exit code.
    """
    try:
        items = parse_yaml_list(file_path, key)
    except ConfigFileNotFoundError as e:
        print(str(e), file=sys.stderr)
        return 1
    except ConfigServiceError as e:
        print(str(e), file=sys.stderr)
        return 1

    if items is None:
        raise ConfigKeyError(key)

    for item in items:
        print(item)
    return 0


def _cmd_add_list_item(file_path: str, key: str, item: str) -> int:
    """Handle the 'add-list-item' sub-command.

    Args:
        file_path: Path to the YAML config file.
        key: Dotted key of the list.
        item: Item to append.

    Returns:
        Exit code.
    """
    try:
        add_yaml_list_item(file_path, key, item)
    except ConfigFileNotFoundError as e:
        print(str(e), file=sys.stderr)
        return 1
    except ConfigServiceError as e:
        print(str(e), file=sys.stderr)
        return 1

    return 0


def _cmd_remove_list_item(file_path: str, key: str, item: str) -> int:
    """Handle the 'remove-list-item' sub-command.

    Args:
        file_path: Path to the YAML config file.
        key: Dotted key of the list.
        item: Item to remove.

    Returns:
        Exit code.
    """
    try:
        remove_yaml_list_item(file_path, key, item)
    except ConfigKeyError as e:
        print(str(e), file=sys.stderr)
        return 1
    except ConfigFileNotFoundError as e:
        print(str(e), file=sys.stderr)
        return 1
    except ConfigServiceError as e:
        print(str(e), file=sys.stderr)
        return 1

    return 0


def _usage() -> None:
    """Print usage information to stderr."""
    print(
        "Usage:\n"
        "  python -m src.main get <file> <dotted-key>\n"
        "  python -m src.main set <file> <dotted-key> <value>\n"
        "  python -m src.main get-list <file> <dotted-key>\n"
        "  python -m src.main add-list-item <file> <dotted-key> <item>\n"
        "  python -m src.main remove-list-item <file> <dotted-key> <item>",
        file=sys.stderr,
    )


if __name__ == "__main__":
    sys.exit(main())
