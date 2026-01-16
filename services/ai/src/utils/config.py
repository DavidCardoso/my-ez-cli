"""
Configuration Loader
====================
Single Source of Truth for all configuration defaults and precedence.

Loads configuration with Terraform-style precedence:
1. Environment variables (highest priority)
2. User config (~/.my-ez-cli/config.yaml)
3. Default config (config/config.default.yaml)
"""

import os
from pathlib import Path
from typing import Any

import yaml

# Configuration paths
USER_CONFIG_PATH: Path = Path.home() / ".my-ez-cli" / "config.yaml"
DEFAULT_CONFIG_PATH: Path = (
    Path(__file__).parent.parent.parent.parent.parent / "config" / "config.default.yaml"
)


def load_config() -> dict[str, Any]:
    """
    Load configuration with Terraform-style precedence.

    Precedence order (highest to lowest):
    1. Environment variables (MEC_AI_*, MEC_LOG_*)
    2. User config (~/.my-ez-cli/config.yaml)
    3. Default config (config/config.default.yaml)

    Returns:
        Configuration dictionary
    """
    config: dict[str, Any] = _load_default_config()
    config = _apply_user_config(config)
    config = _apply_env_overrides(config)

    return config


def _load_default_config() -> dict[str, Any]:
    """
    Load default configuration.

    Returns:
        Default configuration dictionary
    """
    if DEFAULT_CONFIG_PATH.exists():
        with DEFAULT_CONFIG_PATH.open(encoding="utf-8") as f:
            config: dict[str, Any] = yaml.safe_load(f) or {}
    else:
        config = _get_hardcoded_defaults()

    return config


def _get_hardcoded_defaults() -> dict[str, Any]:
    """
    Get hardcoded default configuration.

    Used as fallback if config.default.yaml doesn't exist.

    Returns:
        Hardcoded defaults dictionary
    """
    return {
        "ai": {
            "enabled": False,
            "features": {
                "error_analysis": True,
                "port_detection": True,
                "command_suggestions": False,
                "output_explanation": False,
            },
            "filters": {
                "ignore_output": [
                    "^npm warn",
                    "^npm WARN",
                    r"^Downloading.*\d+%",
                    r"^\s*[├└│─┬┼]",
                ],
                "ignore_input": [
                    "node_modules/",
                    r"\.lock$",
                ],
            },
            "claude": {
                "enabled": True,
                "deep_analysis": False,
            },
            "context": {"use_filtered_logs": True, "history_size": 5},
        },
        "logging": {"enabled": False, "level": "info"},
    }


def _load_user_config() -> dict[str, Any] | None:
    """
    Load user configuration from ~/.my-ez-cli/config.yaml.

    Returns:
        User configuration dictionary or None if file doesn't exist
    """
    if USER_CONFIG_PATH.exists():
        try:
            with USER_CONFIG_PATH.open(encoding="utf-8") as f:
                return yaml.safe_load(f) or {}
        except Exception as e:
            print(f"Warning: Failed to load user config: {e}", flush=True)
            return None
    return None


def _apply_user_config(config: dict[str, Any]) -> dict[str, Any]:
    """
    Apply user configuration overrides.

    Args:
        config: Base configuration dictionary

    Returns:
        Configuration with user overrides applied
    """
    user_config: dict[str, Any] | None = _load_user_config()
    if user_config:
        config = _deep_merge(config, user_config)
    return config


def _apply_env_overrides(config: dict[str, Any]) -> dict[str, Any]:
    """
    Apply environment variable overrides.

    Supported environment variables:
    - MEC_AI_ENABLED: Enable/disable AI (true/false)
    - MEC_AI_DEEP: Enable deep Claude Code analysis (true/false)
    - MEC_LOG_LEVEL: Log level (debug/info/warn/error)

    Args:
        config: Base configuration dictionary

    Returns:
        Configuration with environment overrides applied
    """
    # AI enabled
    if os.getenv("MEC_AI_ENABLED"):
        enabled: bool = os.getenv("MEC_AI_ENABLED", "").lower() in ("true", "1", "yes")
        config.setdefault("ai", {})["enabled"] = enabled

    # Deep analysis via Claude Code
    if os.getenv("MEC_AI_DEEP"):
        deep: bool = os.getenv("MEC_AI_DEEP", "").lower() in ("true", "1", "yes")
        config.setdefault("ai", {}).setdefault("claude", {})["deep_analysis"] = deep

    # Log level
    if os.getenv("MEC_LOG_LEVEL"):
        config.setdefault("logging", {})["level"] = os.getenv("MEC_LOG_LEVEL")

    return config


def _deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """
    Deep merge two dictionaries.

    Args:
        base: Base dictionary
        override: Override dictionary

    Returns:
        Merged dictionary
    """
    result: dict[str, Any] = base.copy()

    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = _deep_merge(result[key], value)
        else:
            result[key] = value

    return result


def is_ai_enabled(config: dict[str, Any]) -> bool:
    """
    Check if AI integration is enabled.

    Args:
        config: Configuration dictionary

    Returns:
        True if AI is enabled, False otherwise
    """
    result: bool = config.get("ai", {}).get("enabled", False)
    return result
