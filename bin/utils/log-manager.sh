#!/bin/bash
# ============================================================================
# My Ez CLI - Log Manager
# ============================================================================
# Modular logging system with JSON format and filtering capabilities
# Version: 1.0.0
# ============================================================================

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------
LOG_FORMAT_VERSION="1.0"
DEFAULT_LOG_DIR="${HOME}/.my-ez-cli/logs"
DEFAULT_CONFIG_FILE="${HOME}/.my-ez-cli/config.yaml"

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

# Load configuration from config file or environment variables
load_log_config() {
    # Default values
    LOG_ENABLED="${MEC_LOGS_ENABLED:-false}"
    LOG_LEVEL="${MEC_LOG_LEVEL:-info}"
    LOG_FORMAT="${MEC_LOG_FORMAT:-json}"
    LOG_DIR="${MEC_LOG_DIR:-$DEFAULT_LOG_DIR}"
    LOG_COMPRESSION_DAYS="${MEC_LOG_COMPRESSION_DAYS:-7}"
    LOG_RETENTION_DAYS="${MEC_LOG_RETENTION_DAYS:-30}"

    # Legacy support
    if [ "$MEC_SAVE_LOGS" = "1" ]; then
        LOG_ENABLED="true"
    fi

    # Export for other scripts
    export LOG_ENABLED
    export LOG_LEVEL
    export LOG_FORMAT
    export LOG_DIR
}

# ----------------------------------------------------------------------------
# Session Management
# ----------------------------------------------------------------------------

# Initialize a logging session for a tool
# Usage: log_session_init "node" "node:24-alpine" "node server.js"
log_session_init() {
    TOOL_NAME="$1"
    IMAGE_NAME="$2"
    COMMAND="$3"

    # Load configuration
    load_log_config

    # Check if logging is enabled
    if [ "$LOG_ENABLED" != "true" ]; then
        export LOG_SESSION_ENABLED="false"
        return 0
    fi

    # Create log directory for tool
    TOOL_LOG_DIR="${LOG_DIR}/${TOOL_NAME}"
    mkdir -p "$TOOL_LOG_DIR"

    # Generate session ID and timestamps
    SESSION_ID=$(get_session_id "$TOOL_NAME")
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%300Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
    LOG_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

    # Create log file paths
    JSON_LOG_FILE="${TOOL_LOG_DIR}/${LOG_TIMESTAMP}.json"
    RAW_LOG_FILE="${TOOL_LOG_DIR}/${LOG_TIMESTAMP}.raw.log"

    # Export session variables
    export LOG_SESSION_ENABLED="true"
    export LOG_SESSION_ID="$SESSION_ID"
    export LOG_SESSION_TOOL="$TOOL_NAME"
    export LOG_SESSION_IMAGE="$IMAGE_NAME"
    export LOG_SESSION_COMMAND="$COMMAND"
    export LOG_SESSION_START_TIME="$TIMESTAMP"
    export LOG_SESSION_CWD="$(pwd)"
    export LOG_JSON_FILE="$JSON_LOG_FILE"
    export LOG_RAW_FILE="$RAW_LOG_FILE"

    # Touch log files
    touch "$JSON_LOG_FILE"
    touch "$RAW_LOG_FILE"
}

# Generate session ID for a tool
# Usage: SESSION_ID=$(get_session_id "node")
get_session_id() {
    TOOL_NAME="${1:-unknown}"
    TIMESTAMP=$(date +%s)
    echo "mec-${TOOL_NAME}-${TIMESTAMP}"
}

# ----------------------------------------------------------------------------
# Output Capture
# ----------------------------------------------------------------------------

# Write raw output to raw log file
# Usage: log_raw_output "stdout content"
log_raw_output() {
    if [ "$LOG_SESSION_ENABLED" = "true" ] && [ -n "$LOG_RAW_FILE" ]; then
        echo "$1" >> "$LOG_RAW_FILE"
    fi
}

# ----------------------------------------------------------------------------
# JSON Log Entry Creation
# ----------------------------------------------------------------------------

# Finalize and write JSON log entry
# Usage: log_session_finalize "stdout content" "stderr content" EXIT_CODE
log_session_finalize() {
    if [ "$LOG_SESSION_ENABLED" != "true" ]; then
        return 0
    fi

    STDOUT="$1"
    STDERR="$2"
    EXIT_CODE="${3:-0}"

    # Calculate end time and duration
    END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.%300Z" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Get system information
    USERNAME=$(whoami)
    HOSTNAME=$(hostname)
    PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Collect environment variables (filtered)
    ENV_VARS=$(get_log_environment)

    # Escape JSON strings
    STDOUT_ESCAPED=$(escape_json "$STDOUT")
    STDERR_ESCAPED=$(escape_json "$STDERR")
    COMMAND_ESCAPED=$(escape_json "$LOG_SESSION_COMMAND")
    CWD_ESCAPED=$(escape_json "$LOG_SESSION_CWD")

    # Write JSON log entry
    cat > "$LOG_JSON_FILE" <<EOF
{
  "version": "$LOG_FORMAT_VERSION",
  "timestamp": "$LOG_SESSION_START_TIME",
  "session_id": "$LOG_SESSION_ID",
  "tool": "$LOG_SESSION_TOOL",
  "image": "$LOG_SESSION_IMAGE",
  "command": "$COMMAND_ESCAPED",
  "cwd": "$CWD_ESCAPED",
  "environment": $ENV_VARS,
  "execution": {
    "start_time": "$LOG_SESSION_START_TIME",
    "end_time": "$END_TIME",
    "exit_code": $EXIT_CODE
  },
  "output": {
    "stdout": "$STDOUT_ESCAPED",
    "stderr": "$STDERR_ESCAPED"
  },
  "metadata": {
    "user": "$USERNAME",
    "hostname": "$HOSTNAME",
    "platform": "$PLATFORM",
    "container_name": "$LOG_SESSION_ID"
  }
}
EOF
}

# ----------------------------------------------------------------------------
# Helper Functions
# ----------------------------------------------------------------------------

# Collect relevant environment variables for logging
get_log_environment() {
    ENV_JSON="{"
    FIRST=true

    # Collect MEC_* variables
    for VAR in $(env | grep '^MEC_' | cut -d= -f1); do
        VALUE=$(eval echo \$$VAR)
        # Skip sensitive variables
        if echo "$VAR" | grep -qi "token\|key\|secret\|password"; then
            VALUE="[REDACTED]"
        fi
        VALUE_ESCAPED=$(escape_json "$VALUE")
        if [ "$FIRST" = true ]; then
            ENV_JSON="${ENV_JSON}\"$VAR\": \"$VALUE_ESCAPED\""
            FIRST=false
        else
            ENV_JSON="${ENV_JSON}, \"$VAR\": \"$VALUE_ESCAPED\""
        fi
    done

    # Add common tool-specific variables
    for VAR in NODE_ENV AWS_PROFILE PYENV_VERSION TF_WORKSPACE; do
        if [ -n "$(eval echo \$$VAR)" ]; then
            VALUE=$(eval echo \$$VAR)
            VALUE_ESCAPED=$(escape_json "$VALUE")
            if [ "$FIRST" = true ]; then
                ENV_JSON="${ENV_JSON}\"$VAR\": \"$VALUE_ESCAPED\""
                FIRST=false
            else
                ENV_JSON="${ENV_JSON}, \"$VAR\": \"$VALUE_ESCAPED\""
            fi
        fi
    done

    ENV_JSON="${ENV_JSON}}"
    echo "$ENV_JSON"
}

# Escape string for JSON
escape_json() {
    STRING="$1"
    # Basic escaping for JSON
    printf '%s' "$STRING" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n\r' | sed 's/\\n$//'
}

# Redact sensitive data from string
redact_sensitive() {
    STRING="$1"

    # Redact common patterns
    # AWS Access Keys
    STRING=$(echo "$STRING" | sed -E 's/AKIA[0-9A-Z]{16}/[REDACTED_AWS_KEY]/g')
    # Generic API keys (40+ alphanumeric characters)
    STRING=$(echo "$STRING" | sed -E 's/[A-Za-z0-9_-]{40,}/[REDACTED_TOKEN]/g')

    echo "$STRING"
}

# ----------------------------------------------------------------------------
# Log Rotation and Cleanup
# ----------------------------------------------------------------------------

# Rotate and compress old logs
# Usage: log_rotate
log_rotate() {
    load_log_config

    if [ "$LOG_ENABLED" != "true" ]; then
        return 0
    fi

    # Compress logs older than threshold
    if command -v gzip >/dev/null 2>&1; then
        find "$LOG_DIR" -type f -name "*.log" -mtime "+${LOG_COMPRESSION_DAYS}" ! -name "*.gz" -exec gzip {} \;
        find "$LOG_DIR" -type f -name "*.json" -mtime "+${LOG_COMPRESSION_DAYS}" ! -name "*.gz" -exec gzip {} \;
    fi

    # Delete logs older than retention period
    find "$LOG_DIR" -type f -mtime "+${LOG_RETENTION_DAYS}" -delete
}

# Clean up logs for a specific tool
# Usage: log_cleanup "node"
log_cleanup() {
    TOOL_NAME="$1"
    load_log_config

    if [ -d "${LOG_DIR}/${TOOL_NAME}" ]; then
        rm -rf "${LOG_DIR}/${TOOL_NAME}"
    fi
}

# ----------------------------------------------------------------------------
# Query and Analysis
# ----------------------------------------------------------------------------

# List recent log sessions for a tool
# Usage: log_list "node" 10
log_list() {
    TOOL_NAME="$1"
    LIMIT="${2:-10}"

    load_log_config

    if [ ! -d "${LOG_DIR}/${TOOL_NAME}" ]; then
        echo "No logs found for tool: $TOOL_NAME" >&2
        return 1
    fi

    # List JSON log files
    find "${LOG_DIR}/${TOOL_NAME}" -type f -name "*.json" -o -name "*.json.gz" | \
        sort -r | \
        head -n "$LIMIT"
}

# Get the most recent log for a tool
# Usage: log_latest "node"
log_latest() {
    TOOL_NAME="$1"
    log_list "$TOOL_NAME" 1
}

# ----------------------------------------------------------------------------
# Initialization
# ----------------------------------------------------------------------------

# Auto-load configuration when sourced
load_log_config
