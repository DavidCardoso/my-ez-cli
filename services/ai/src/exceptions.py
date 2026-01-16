"""
Custom Exceptions for AI Service
=================================

This module defines custom exception classes for the AI service.

Exception Hierarchy:
    AIServiceError (base)
    ├── ConfigurationError
    │   └── InvalidConfigurationError
    ├── FilterError
    └── ClaudeResponseParseError
"""

from typing import Any


class AIServiceError(Exception):
    """
    Base exception for all AI service errors.

    Attributes:
        message: Human-readable error message
        details: Optional dictionary with additional error context
        original_error: Optional original exception that caused this error
    """

    def __init__(
        self,
        message: str,
        details: dict[str, Any] | None = None,
        original_error: Exception | None = None,
    ) -> None:
        """
        Initialize AIServiceError.

        Args:
            message: Human-readable error message
            details: Optional dict with additional context
            original_error: Optional original exception
        """
        super().__init__(message)
        self.message: str = message
        self.details: dict[str, Any] = details or {}
        self.original_error: Exception | None = original_error

    def __str__(self) -> str:
        """Return string representation of the error."""
        if self.details:
            details_str: str = ", ".join(f"{k}={v}" for k, v in self.details.items())
            return f"{self.message} ({details_str})"
        return self.message

    def to_dict(self) -> dict[str, Any]:
        """
        Convert exception to dictionary format.

        Returns:
            Dictionary representation of the error
        """
        return {
            "error_type": self.__class__.__name__,
            "message": self.message,
            "details": self.details,
        }


# =============================================================================
# Configuration Errors
# =============================================================================


class ConfigurationError(AIServiceError):
    """Base exception for configuration-related errors."""


class InvalidConfigurationError(ConfigurationError):
    """Raised when configuration values are invalid."""

    def __init__(self, config_key: str, invalid_value: Any, reason: str) -> None:
        """
        Initialize InvalidConfigurationError.

        Args:
            config_key: Configuration key that is invalid
            invalid_value: The invalid value
            reason: Explanation of why it's invalid
        """
        message: str = f"Invalid configuration for '{config_key}': {reason}"
        details: dict[str, Any] = {
            "config_key": config_key,
            "invalid_value": str(invalid_value),
            "reason": reason,
        }
        super().__init__(message, details)
        self.config_key: str = config_key


# =============================================================================
# Filter Errors
# =============================================================================


class FilterError(AIServiceError):
    """Raised when filtering fails."""

    def __init__(self, reason: str, original_error: Exception | None = None) -> None:
        """
        Initialize FilterError.

        Args:
            reason: Reason for filter failure
            original_error: Optional original exception
        """
        message: str = f"Filter error: {reason}"
        details: dict[str, Any] = {"reason": reason}
        super().__init__(message, details, original_error)


# =============================================================================
# Claude Response Errors
# =============================================================================


class ClaudeResponseParseError(AIServiceError):
    """Raised when parsing Claude Code JSON response fails."""

    def __init__(self, reason: str, original_error: Exception | None = None) -> None:
        """
        Initialize ClaudeResponseParseError.

        Args:
            reason: Reason for parse failure
            original_error: Optional original exception
        """
        message: str = f"Claude response parse error: {reason}"
        details: dict[str, Any] = {"reason": reason}
        super().__init__(message, details, original_error)
