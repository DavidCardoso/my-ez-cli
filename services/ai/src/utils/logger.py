"""
Logger Setup
============
Configures Python logging for the AI service.
"""

import logging
import sys
from typing import Any


def setup_logger(config: dict[str, Any]) -> logging.Logger:
    """
    Setup and configure logger.

    Args:
        config: Configuration dictionary

    Returns:
        Configured logger instance
    """
    # Get log level from config
    log_level_str = config.get("logs", {}).get("level", "info").upper()
    log_level = getattr(logging, log_level_str, logging.INFO)

    # Create logger
    logger = logging.getLogger("mec_ai")
    logger.setLevel(log_level)

    # Remove existing handlers
    logger.handlers = []

    # Create console handler
    handler = logging.StreamHandler(sys.stderr)
    handler.setLevel(log_level)

    # Create formatter
    formatter = logging.Formatter(
        "[%(asctime)s] [%(name)s] [%(levelname)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )
    handler.setFormatter(formatter)

    # Add handler to logger
    logger.addHandler(handler)

    return logger


def get_logger() -> logging.Logger:
    """
    Get existing logger instance.

    Returns:
        Logger instance
    """
    return logging.getLogger("mec_ai")
