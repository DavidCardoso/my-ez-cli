#!/usr/bin/env bats
# ============================================================================
# Tests for Log Manager
# ============================================================================

BASEDIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")/.." && pwd)"

setup() {
    # Source log-manager
    . "$BASEDIR/bin/utils/log-manager.sh"

    # Create temporary test directory
    TEST_LOG_DIR=$(mktemp -d)
    export LOG_DIR="$TEST_LOG_DIR"
    export MEC_LOG_DIR="$TEST_LOG_DIR"
}

teardown() {
    # Clean up test directory
    if [ -n "$TEST_LOG_DIR" ] && [ -d "$TEST_LOG_DIR" ]; then
        rm -rf "$TEST_LOG_DIR"
    fi
}

# ----------------------------------------------------------------------------
# Configuration Tests
# ----------------------------------------------------------------------------

@test "load_log_config sets default values" {
    unset MEC_LOGS_ENABLED
    unset MEC_LOG_LEVEL

    load_log_config

    [ "$LOG_ENABLED" = "false" ]
    [ "$LOG_LEVEL" = "info" ]
    [ "$LOG_FORMAT" = "json" ]
}

@test "load_log_config respects environment variables" {
    export MEC_LOGS_ENABLED="true"
    export MEC_LOG_LEVEL="debug"

    load_log_config

    [ "$LOG_ENABLED" = "true" ]
    [ "$LOG_LEVEL" = "debug" ]
}

@test "load_log_config supports legacy MEC_SAVE_LOGS" {
    export MEC_SAVE_LOGS="1"
    unset MEC_LOGS_ENABLED

    load_log_config

    [ "$LOG_ENABLED" = "true" ]
}

# ----------------------------------------------------------------------------
# Session Management Tests
# ----------------------------------------------------------------------------

@test "get_session_id generates correct format" {
    SESSION_ID=$(get_session_id "node")

    [[ "$SESSION_ID" =~ ^mec-node-[0-9]+$ ]]
}

@test "log_session_init creates log directory when enabled" {
    export MEC_LOGS_ENABLED="true"

    log_session_init "node" "node:24-alpine" "node server.js"

    [ -d "$TEST_LOG_DIR/node" ]
    [ "$LOG_SESSION_ENABLED" = "true" ]
    [ "$LOG_SESSION_TOOL" = "node" ]
    [ "$LOG_SESSION_IMAGE" = "node:24-alpine" ]
}

@test "log_session_init skips when disabled" {
    export MEC_LOGS_ENABLED="false"

    log_session_init "node" "node:24-alpine" "node server.js"

    [ "$LOG_SESSION_ENABLED" = "false" ]
}

@test "log_session_init creates log files" {
    export MEC_LOGS_ENABLED="true"

    log_session_init "node" "node:24-alpine" "node server.js"

    [ -f "$LOG_JSON_FILE" ]
    [ -f "$LOG_RAW_FILE" ]
}

# ----------------------------------------------------------------------------
# JSON Generation Tests
# ----------------------------------------------------------------------------

@test "escape_json escapes special characters" {
    INPUT='Line with "quotes"'
    OUTPUT=$(escape_json "$INPUT")

    # Output should contain escaped quote
    [ "$OUTPUT" != "$INPUT" ]
    echo "$OUTPUT" | grep -F '\"' > /dev/null
}

@test "log_session_finalize creates valid JSON" {
    export MEC_LOGS_ENABLED="true"

    log_session_init "node" "node:24-alpine" "node --version"
    log_session_finalize "v24.0.0" "" 0

    [ -f "$LOG_JSON_FILE" ]

    # Basic JSON validation (check for required fields)
    run grep '"version"' "$LOG_JSON_FILE"
    [ "$status" -eq 0 ]

    run grep '"session_id"' "$LOG_JSON_FILE"
    [ "$status" -eq 0 ]

    run grep '"tool": "node"' "$LOG_JSON_FILE"
    [ "$status" -eq 0 ]
}

# ----------------------------------------------------------------------------
# Environment Collection Tests
# ----------------------------------------------------------------------------

@test "get_log_environment collects MEC variables" {
    export MEC_BIND_PORTS="8080:80"
    export MEC_DEBUG="1"

    ENV_JSON=$(get_log_environment)

    [[ "$ENV_JSON" =~ MEC_BIND_PORTS ]]
    [[ "$ENV_JSON" =~ MEC_DEBUG ]]
}

@test "get_log_environment redacts sensitive variables" {
    export MEC_API_KEY="secret123"
    export MEC_TOKEN="token456"

    ENV_JSON=$(get_log_environment)

    [[ "$ENV_JSON" =~ \[REDACTED\] ]]
    [[ ! "$ENV_JSON" =~ secret123 ]]
}

# ----------------------------------------------------------------------------
# Log Rotation Tests
# ----------------------------------------------------------------------------

@test "log_rotate skips when logging disabled" {
    export MEC_LOGS_ENABLED="false"

    run log_rotate
    [ "$status" -eq 0 ]
}

@test "log_cleanup removes tool log directory" {
    export MEC_LOGS_ENABLED="true"

    mkdir -p "$TEST_LOG_DIR/node"
    echo "test" > "$TEST_LOG_DIR/node/test.log"

    log_cleanup "node"

    [ ! -d "$TEST_LOG_DIR/node" ]
}

# ----------------------------------------------------------------------------
# Query Tests
# ----------------------------------------------------------------------------

@test "log_list returns empty when no logs exist" {
    run log_list "node"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No logs found" ]]
}

@test "log_list finds JSON log files" {
    export MEC_LOGS_ENABLED="true"

    mkdir -p "$TEST_LOG_DIR/node"
    touch "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json"
    touch "$TEST_LOG_DIR/node/2026-01-15_11-00-00.json"

    run log_list "node" 10
    [ "$status" -eq 0 ]

    # Should list files in reverse order (newest first)
    [[ "$output" =~ 2026-01-15_11-00-00.json ]]
}

@test "log_latest returns most recent log" {
    export MEC_LOGS_ENABLED="true"

    mkdir -p "$TEST_LOG_DIR/node"
    touch "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json"
    sleep 1
    touch "$TEST_LOG_DIR/node/2026-01-15_11-00-00.json"

    run log_latest "node"
    [ "$status" -eq 0 ]

    [[ "$output" =~ 2026-01-15_11-00-00.json ]]
    [[ ! "$output" =~ 2026-01-15_10-00-00.json ]]
}

# ----------------------------------------------------------------------------
# JSON Field Extraction Tests (grep+sed, BSD-awk compatible)
# These validate the parsing strategy used by mec logs list / mec logs failures
# ----------------------------------------------------------------------------

_make_test_log() {
    local path="$1" tool="$2" exit_code="$3"
    cat > "$path" <<EOF
{
  "version": "1.0",
  "timestamp": "2026-01-15T10:00:00.300Z",
  "session_id": "mec-${tool}-12345",
  "tool": "${tool}",
  "image": "test-image:latest",
  "command": "${tool} --version",
  "cwd": "/tmp",
  "environment": {},
  "execution": {
    "start_time": "2026-01-15T10:00:00.300Z",
    "end_time": "2026-01-15T10:00:01.300Z",
    "exit_code": ${exit_code}
  },
  "output": {"stdout": "", "stderr": ""},
  "metadata": {}
}
EOF
}

@test "grep+sed extracts tool name from JSON log" {
    mkdir -p "$TEST_LOG_DIR/node"
    _make_test_log "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json" "node" 0

    result=$(grep '"tool"' "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json" \
        | sed 's/.*"tool"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)

    [ "$result" = "node" ]
}

@test "grep+sed extracts exit_code from JSON log" {
    mkdir -p "$TEST_LOG_DIR/node"
    _make_test_log "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json" "node" 1

    result=$(grep '"exit_code"' "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json" \
        | sed 's/.*"exit_code"[[:space:]]*:[[:space:]]*\(-\{0,1\}[0-9][0-9]*\).*/\1/' | head -1)

    [ "$result" = "1" ]
}

@test "grep+sed extracts start_time from JSON log" {
    mkdir -p "$TEST_LOG_DIR/node"
    _make_test_log "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json" "node" 0

    result=$(grep '"start_time"' "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json" \
        | sed 's/.*"start_time"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)

    [ "$result" = "2026-01-15T10:00:00.300Z" ]
}

@test "grep+sed extracts end_time from JSON log" {
    mkdir -p "$TEST_LOG_DIR/node"
    _make_test_log "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json" "node" 0

    result=$(grep '"end_time"' "$TEST_LOG_DIR/node/2026-01-15_10-00-00.json" \
        | sed 's/.*"end_time"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)

    [ "$result" = "2026-01-15T10:00:01.300Z" ]
}

@test "grep+sed extracts tool name for non-zero exit log" {
    mkdir -p "$TEST_LOG_DIR/terraform"
    _make_test_log "$TEST_LOG_DIR/terraform/2026-01-15_10-00-00.json" "terraform" 2

    tool=$(grep '"tool"' "$TEST_LOG_DIR/terraform/2026-01-15_10-00-00.json" \
        | sed 's/.*"tool"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    exit_code=$(grep '"exit_code"' "$TEST_LOG_DIR/terraform/2026-01-15_10-00-00.json" \
        | sed 's/.*"exit_code"[[:space:]]*:[[:space:]]*\(-\{0,1\}[0-9][0-9]*\).*/\1/' | head -1)

    [ "$tool" = "terraform" ]
    [ "$exit_code" = "2" ]
}

@test "log_session_finalize JSON is parseable by grep+sed extraction" {
    export MEC_LOGS_ENABLED="true"

    log_session_init "yarn" "node:22-alpine" "yarn install"
    log_session_finalize "Done" "" 0

    tool=$(grep '"tool"' "$LOG_JSON_FILE" \
        | sed 's/.*"tool"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    exit_code=$(grep '"exit_code"' "$LOG_JSON_FILE" \
        | sed 's/.*"exit_code"[[:space:]]*:[[:space:]]*\(-\{0,1\}[0-9][0-9]*\).*/\1/' | head -1)

    [ "$tool" = "yarn" ]
    [ "$exit_code" = "0" ]
}
