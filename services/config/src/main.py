"""CLI dispatcher for the config service.

Usage:
    python -m src.main get <file> <dotted-key>
    python -m src.main set <file> <dotted-key> <value>

Exit codes:
    0  success
    1  key not found (get) or write error (set)
    2  usage error
"""

import sys

from .exceptions import ConfigFileNotFoundError, ConfigKeyError, ConfigServiceError
from .yaml_manager import parse_yaml_key, set_yaml_key


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

    if command == "get":
        if len(args) != 3:
            print("Usage: python -m src.main get <file> <key>", file=sys.stderr)
            return 2
        _, file_path, key = args
        return _cmd_get(file_path, key)

    if command == "set":
        if len(args) != 4:
            print("Usage: python -m src.main set <file> <key> <value>", file=sys.stderr)
            return 2
        _, file_path, key, value = args
        return _cmd_set(file_path, key, value)

    print(f"Unknown command: {command}", file=sys.stderr)
    _usage()
    return 2


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


def _usage() -> None:
    """Print usage information to stderr."""
    print(
        "Usage:\n"
        "  python -m src.main get <file> <dotted-key>\n"
        "  python -m src.main set <file> <dotted-key> <value>",
        file=sys.stderr,
    )


if __name__ == "__main__":
    sys.exit(main())
