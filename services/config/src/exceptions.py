"""Custom exceptions for the config service."""


class ConfigServiceError(Exception):
    """Base exception for config service errors."""


class ConfigFileNotFoundError(ConfigServiceError):
    """Raised when the config file does not exist."""

    def __init__(self, path: str) -> None:
        """Initialize with the missing file path."""
        super().__init__(f"Config file not found: {path}")
        self.path = path


class ConfigKeyError(ConfigServiceError):
    """Raised when a key is not found in the config file."""

    def __init__(self, key: str) -> None:
        """Initialize with the missing key."""
        super().__init__(f"Key not found: {key}")
        self.key = key


class ConfigWriteError(ConfigServiceError):
    """Raised when writing to the config file fails."""

    def __init__(self, path: str, reason: str) -> None:
        """Initialize with the file path and failure reason."""
        super().__init__(f"Failed to write config file {path}: {reason}")
        self.path = path
        self.reason = reason
