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
DEFAULT_LOG_DIR="${MEC_HOME:-${HOME}/.my-ez-cli}/logs"
DEFAULT_CONFIG_FILE="${MEC_HOME:-${HOME}/.my-ez-cli}/config.yaml"

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

# Load configuration from config file or environment variables
load_log_config() {
    # Default values
    TELEMETRY_ENABLED="${MEC_TELEMETRY_ENABLED:-true}"
    LOG_ENABLED="${MEC_LOGS_ENABLED:-false}"
    LOG_LEVEL="${MEC_LOG_LEVEL:-info}"
    LOG_FORMAT="${MEC_LOG_FORMAT:-json}"
    LOG_DIR="${MEC_LOG_DIR:-$DEFAULT_LOG_DIR}"
    LOG_COMPRESSION_DAYS="${MEC_LOG_COMPRESSION_DAYS:-7}"
    LOG_RETENTION_DAYS="${MEC_LOG_RETENTION_DAYS:-30}"

    # Legacy support
    if [ "$MEC_SAVE_LOGS" = "1" ]; then
        TELEMETRY_ENABLED="true"
    fi

    # Export for other scripts
    export TELEMETRY_ENABLED LOG_ENABLED LOG_LEVEL LOG_FORMAT LOG_DIR
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

    # Check if telemetry is enabled
    if [ "$TELEMETRY_ENABLED" != "true" ]; then
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
    LOG_SESSION_START_EPOCH=$(date +%s)

    # Create log file paths
    JSON_LOG_FILE="${TOOL_LOG_DIR}/${LOG_TIMESTAMP}.json"

    # Export session variables
    export LOG_SESSION_ENABLED="true"
    export LOG_SESSION_ID="$SESSION_ID"
    export LOG_SESSION_TOOL="$TOOL_NAME"
    export LOG_SESSION_IMAGE="$IMAGE_NAME"
    export LOG_SESSION_COMMAND="$COMMAND"
    export LOG_SESSION_START_TIME="$TIMESTAMP"
    export LOG_SESSION_CWD="$(pwd)"
    export LOG_JSON_FILE="$JSON_LOG_FILE"
    export LOG_SESSION_START_EPOCH
    export LOG_ENABLED

    # Touch log file
    touch "$JSON_LOG_FILE"
}

# Generate session ID for a tool
# Usage: SESSION_ID=$(get_session_id "node")
get_session_id() {
    TOOL_NAME="${1:-unknown}"
    TIMESTAMP=$(date +%s)
    echo "mec-${TOOL_NAME}-${TIMESTAMP}"
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
    END_EPOCH=$(date +%s)
    DURATION_MS=$(( (END_EPOCH - ${LOG_SESSION_START_EPOCH:-END_EPOCH}) * 1000 ))

    # Get system information
    USERNAME=$(whoami)
    HOSTNAME=$(hostname)
    PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Collect environment variables (filtered)
    ENV_VARS=$(get_log_environment)

    # Escape JSON strings
    COMMAND_ESCAPED=$(escape_json "$LOG_SESSION_COMMAND")
    CWD_ESCAPED=$(escape_json "$LOG_SESSION_CWD")

    # Build output block — null when capture is disabled, real strings when enabled
    if [ "$LOG_ENABLED" = "true" ]; then
        STDOUT_ESCAPED=$(escape_json "$STDOUT")
        STDERR_ESCAPED=$(escape_json "$STDERR")
        OUTPUT_BLOCK="\"output\": {\"stdout\": \"$STDOUT_ESCAPED\", \"stderr\": \"$STDERR_ESCAPED\"}"
    else
        OUTPUT_BLOCK="\"output\": {\"stdout\": null, \"stderr\": null}"
    fi

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
    "exit_code": $EXIT_CODE,
    "duration_ms": $DURATION_MS
  },
  $OUTPUT_BLOCK,
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

    # Logging-system internals — not useful for AI analysis of tool output
    _LOG_SKIP="MEC_LOG_DIR|MEC_LOG_LEVEL|MEC_LOG_FORMAT|MEC_LOG_COMPRESSION_DAYS|MEC_LOG_RETENTION_DAYS|MEC_SAVE_LOGS"

    # Collect MEC_* variables (excluding logging internals)
    for VAR in $(env | grep '^MEC_' | cut -d= -f1 | grep -vE "$_LOG_SKIP"); do
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
    # Strip ANSI/terminal escape sequences (e.g. \x1b[1G\x1b[0K cursor controls, color codes)
    # then escape backslashes and double-quotes, collapse newlines to \n
    printf '%s' "$STRING" \
        | sed 's/\x1b\[[0-9;]*[A-Za-z]//g; s/\x1b[()]//g' \
        | tr -d '\000-\010\013\014\016-\037\177' \
        | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' \
        | tr -d '\n\r' \
        | sed 's/\\n$//'
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

    if [ "$TELEMETRY_ENABLED" != "true" ]; then
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

# Find a log file by session ID
# Usage: log_find_by_session_id "mec-node-1774880478"
# Returns: absolute path to .json log file, or empty string if not found
log_find_by_session_id() {
    local session_id="$1"
    local log_dir="${LOG_DIR:-$DEFAULT_LOG_DIR}"

    [ -z "$session_id" ] && return 0
    [ ! -d "$log_dir" ] && return 0

    grep -rl "\"session_id\"[[:space:]]*:[[:space:]]*\"${session_id}\"" "$log_dir" 2>/dev/null \
        | grep -v "\.bak$" \
        | grep "\.json$" \
        | head -1
}

# ----------------------------------------------------------------------------
# Initialization
# ----------------------------------------------------------------------------

# Auto-load configuration when sourced
load_log_config
