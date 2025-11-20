#!/bin/sh
set -e

# ============================================================================
# My Ez CLI - Common Utilities
# ============================================================================
# This file provides shared utilities for all bin scripts.
# Version: 1.0.0
# ============================================================================

# ----------------------------------------------------------------------------
# Path Resolution (works with symlinks)
# ----------------------------------------------------------------------------
# Resolves the real path of the script, following symlinks
# This is critical for scripts installed via symlinks in /usr/local/bin
get_script_real_path() {
    SCRIPT="$0"

    # Follow symlink if exists (works on both macOS and Linux)
    if [ -L "$SCRIPT" ]; then
        if command -v readlink >/dev/null 2>&1; then
            # Try GNU readlink first (Linux)
            if readlink -f "$SCRIPT" >/dev/null 2>&1; then
                SCRIPT=$(readlink -f "$SCRIPT")
            else
                # macOS readlink (no -f flag)
                SCRIPT=$(readlink "$SCRIPT")
            fi
        fi
    fi

    # Get the directory of the script
    SCRIPT_DIR=$(cd "$(dirname "$SCRIPT")" && pwd)
    echo "$SCRIPT_DIR"
}

# ----------------------------------------------------------------------------
# Get the base directory of my-ez-cli installation
# ----------------------------------------------------------------------------
# Returns the root directory of my-ez-cli (parent of bin/)
get_mec_base_dir() {
    SCRIPT_DIR=$(get_script_real_path)
    # If script is in bin/, go up one level
    if [ "$(basename "$SCRIPT_DIR")" = "bin" ]; then
        echo "$(cd "$SCRIPT_DIR/.." && pwd)"
    else
        echo "$SCRIPT_DIR"
    fi
}

# ----------------------------------------------------------------------------
# TTY Detection
# ----------------------------------------------------------------------------
# Detect if we're running in a TTY and return appropriate Docker flag
# Returns: "-t" if TTY detected, empty string otherwise
get_tty_flag() {
    if [ -t 0 ]; then
        echo "-t"
    else
        echo ""
    fi
}

# ----------------------------------------------------------------------------
# Logging Setup (for future log persistence)
# ----------------------------------------------------------------------------
# Setup logging for a tool
# Usage: setup_logging "node"
setup_logging() {
    TOOL_NAME="$1"
    LOG_DIR="${MEC_LOG_DIR:-${HOME}/.my-ez-cli/logs}/${TOOL_NAME}"

    # Only create log directory if logging is enabled
    if [ "$MEC_SAVE_LOGS" = "1" ] || [ "${MEC_LOGS_ENABLED:-false}" = "true" ]; then
        mkdir -p "$LOG_DIR"

        TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
        LOG_FILE="${LOG_DIR}/${TIMESTAMP}.log"
        RAW_LOG_FILE="${LOG_DIR}/${TIMESTAMP}.raw.log"

        LOG_ENABLED=true
    else
        LOG_ENABLED=false
        LOG_FILE=""
        RAW_LOG_FILE=""
    fi

    # Export for use in scripts
    export LOG_ENABLED
    export LOG_FILE
    export RAW_LOG_FILE
}

# ----------------------------------------------------------------------------
# Environment Validation
# ----------------------------------------------------------------------------
# Check if Docker is available
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "[mec] ERROR: Docker is not installed or not in PATH" >&2
        echo "" >&2
        echo "Please install Docker first:" >&2
        echo "  https://docker.com/get-started" >&2
        echo "" >&2
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        echo "[mec] ERROR: Docker daemon is not running" >&2
        echo "" >&2
        echo "Please start Docker:" >&2
        echo "  macOS: open -a Docker" >&2
        echo "  Linux: sudo systemctl start docker" >&2
        echo "" >&2
        exit 1
    fi
}

# ----------------------------------------------------------------------------
# Port Binding Helper
# ----------------------------------------------------------------------------
# Parse MEC_BIND_PORTS and return Docker port flags
# Usage: PORTS=$(get_port_flags)
# Format: MEC_BIND_PORTS="8080:80 9090:90"
get_port_flags() {
    PORTS=""
    if [ -n "$MEC_BIND_PORTS" ]; then
        for PORT in $MEC_BIND_PORTS; do
            PORTS="$PORTS -p $PORT"
        done
    fi
    echo "$PORTS"
}

# ----------------------------------------------------------------------------
# Container Naming and Labeling
# ----------------------------------------------------------------------------
# Generate a consistent container name for my-ez-cli tools
# Usage: CONTAINER_NAME=$(get_container_name "node")
# Output: mec-node-1700000000
get_container_name() {
    TOOL_NAME="${1:-unknown}"
    TIMESTAMP=$(date +%s)
    echo "mec-${TOOL_NAME}-${TIMESTAMP}"
}

# Generate Docker label flags for container identification
# Usage: LABELS=$(get_container_labels "node" "node:22-alpine")
# Output: --label com.my-ez-cli.project=my-ez-cli --label com.my-ez-cli.tool=node --label com.my-ez-cli.image=node:22-alpine
get_container_labels() {
    TOOL_NAME="${1:-unknown}"
    IMAGE_NAME="${2:-unknown}"
    echo "--label com.my-ez-cli.project=my-ez-cli --label com.my-ez-cli.tool=${TOOL_NAME} --label com.my-ez-cli.image=${IMAGE_NAME}"
}

# ----------------------------------------------------------------------------
# Debug Mode
# ----------------------------------------------------------------------------
# Enable debug output if MEC_DEBUG is set
if [ "${MEC_DEBUG:-0}" = "1" ]; then
    set -x
fi

# ----------------------------------------------------------------------------
# Version Information
# ----------------------------------------------------------------------------
MEC_VERSION="1.0.0-alpha"
export MEC_VERSION
