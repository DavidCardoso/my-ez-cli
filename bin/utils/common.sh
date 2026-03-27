#!/bin/bash
set -e

# ============================================================================
# My Ez CLI - Common Utilities
# ============================================================================
# This file provides shared utilities for all bin scripts.
# Version: 1.0.0
# ============================================================================

# ----------------------------------------------------------------------------
# Data Directory
# ----------------------------------------------------------------------------
MEC_HOME="${MEC_HOME:-${HOME}/.my-ez-cli}"
export MEC_HOME

# ----------------------------------------------------------------------------
# Docker Image Constants
# ----------------------------------------------------------------------------
MEC_IMAGE_REPO="${MEC_IMAGE_REPO:-davidcardoso/my-ez-cli}"
MEC_IMAGE_TAG="${MEC_IMAGE_TAG:-latest}"

MEC_IMAGE_AI_SERVICE="${MEC_IMAGE_AI_SERVICE:-${MEC_IMAGE_REPO}:ai-service-${MEC_IMAGE_TAG}}"
MEC_IMAGE_CONFIG_SERVICE="${MEC_IMAGE_CONFIG_SERVICE:-${MEC_IMAGE_REPO}:config-service-${MEC_IMAGE_TAG}}"
MEC_IMAGE_CLAUDE="${MEC_IMAGE_CLAUDE:-${MEC_IMAGE_REPO}:claude-${MEC_IMAGE_TAG}}"
MEC_IMAGE_SERVERLESS="${MEC_IMAGE_SERVERLESS:-${MEC_IMAGE_REPO}:serverless-${MEC_IMAGE_TAG}}"
MEC_IMAGE_SPEEDTEST="${MEC_IMAGE_SPEEDTEST:-${MEC_IMAGE_REPO}:speedtest-${MEC_IMAGE_TAG}}"
MEC_IMAGE_AWS_SSO_CRED="${MEC_IMAGE_AWS_SSO_CRED:-${MEC_IMAGE_REPO}:aws-sso-cred-${MEC_IMAGE_TAG}}"
MEC_IMAGE_YARN_BERRY="${MEC_IMAGE_YARN_BERRY:-${MEC_IMAGE_REPO}:yarn-berry-${MEC_IMAGE_TAG}}"
MEC_IMAGE_YARN_PLUS="${MEC_IMAGE_YARN_PLUS:-${MEC_IMAGE_REPO}:yarn-plus-${MEC_IMAGE_TAG}}"
MEC_IMAGE_DASHBOARD="${MEC_IMAGE_DASHBOARD:-${MEC_IMAGE_REPO}:dashboard-${MEC_IMAGE_TAG}}"

export MEC_IMAGE_REPO MEC_IMAGE_TAG
export MEC_IMAGE_AI_SERVICE MEC_IMAGE_CONFIG_SERVICE MEC_IMAGE_CLAUDE MEC_IMAGE_SERVERLESS
export MEC_IMAGE_SPEEDTEST MEC_IMAGE_AWS_SSO_CRED MEC_IMAGE_YARN_BERRY MEC_IMAGE_YARN_PLUS
export MEC_IMAGE_DASHBOARD

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
# Logging Setup
# ----------------------------------------------------------------------------
# Source log-manager for advanced logging capabilities
MEC_BASE_DIR=$(get_mec_base_dir)
if [ -f "${MEC_BASE_DIR}/bin/utils/log-manager.sh" ]; then
    . "${MEC_BASE_DIR}/bin/utils/log-manager.sh"
fi

# Source config-manager if available
if [ -f "${MEC_BASE_DIR}/bin/utils/config-manager.sh" ]; then
    . "${MEC_BASE_DIR}/bin/utils/config-manager.sh"
fi

# Auto-inject config into env vars (only if not already set by user)
# Bridges config.yaml -> env vars so 'mec ai enable' / 'mec logging enable' take effect
_load_mec_config() {
    if ! command -v config_get_default >/dev/null 2>&1; then
        return 0
    fi
    # [ -z "${VAR+x}" ] is true only if VAR is unset (not if it's set to empty or false)
    # This lets explicit env var overrides (e.g. MEC_AI_ENABLED=false) take precedence
    if [ -z "${MEC_LOGS_ENABLED+x}" ]; then
        MEC_LOGS_ENABLED=$(config_get_default "logs.enabled" "false")
        export MEC_LOGS_ENABLED
    fi
    if [ -z "${MEC_AI_ENABLED+x}" ]; then
        MEC_AI_ENABLED=$(config_get_default "ai.enabled" "false")
        export MEC_AI_ENABLED
    fi
}
_load_mec_config

# Setup logging for a tool (legacy wrapper)
# Usage: setup_logging "node" "node:24-alpine" "node server.js"
setup_logging() {
    TOOL_NAME="$1"
    IMAGE_NAME="${2:-unknown}"
    COMMAND="${3:-unknown}"

    # Use new log-manager if available
    if command -v log_session_init >/dev/null 2>&1; then
        log_session_init "$TOOL_NAME" "$IMAGE_NAME" "$COMMAND"

        # Export legacy variables for backward compatibility
        LOG_ENABLED="$LOG_SESSION_ENABLED"
        LOG_FILE="$LOG_JSON_FILE"

        export LOG_ENABLED
        export LOG_FILE
    else
        # Fallback to simple logging
        LOG_DIR="${MEC_LOG_DIR:-${MEC_HOME}/logs}/${TOOL_NAME}"

        if [ "$MEC_SAVE_LOGS" = "1" ] || [ "${MEC_LOGS_ENABLED:-false}" = "true" ]; then
            mkdir -p "$LOG_DIR"

            TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
            LOG_FILE="${LOG_DIR}/${TIMESTAMP}.log"

            LOG_ENABLED=true
        else
            LOG_ENABLED=false
            LOG_FILE=""
        fi

        export LOG_ENABLED
        export LOG_FILE
    fi
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
# AI Analysis Integration
# ----------------------------------------------------------------------------
# Analysis runs through Claude Code when MEC_AI_ENABLED=true.
# The Python middleware (ai-service) handles I/O filtering only.
# ----------------------------------------------------------------------------

# Analyze log output with Claude Code
# Usage: analyze_with_claude "path/to/log.json"
analyze_with_claude() {
    local log_file="$1"

    # Check if AI is enabled
    if [ "${MEC_AI_ENABLED:-false}" != "true" ]; then
        return 0
    fi

    # Check if a valid credential is available (API key or OAuth token)
    if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
        if [ "${MEC_DEBUG:-0}" = "1" ]; then
            echo "[mec-ai] Skipping analysis: no auth credential set (ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN)." >&2
        fi
        return 0
    fi

    # Check if log file exists
    if [ ! -f "$log_file" ]; then
        return 0
    fi

    # Check if Claude Code Docker image is available (silent check)
    if ! docker image inspect "$MEC_IMAGE_CLAUDE" >/dev/null 2>&1; then
        return 0
    fi

    # Check if ai-service Docker image is available (silent check)
    if ! docker image inspect "$MEC_IMAGE_AI_SERVICE" >/dev/null 2>&1; then
        return 0
    fi

    # Read log content for the prompt, stripping control characters that would
    # corrupt the shell string when embedded inline in the -p argument
    local log_content
    log_content=$(cat "$log_file" 2>/dev/null | tr -d '\000-\010\013\014\016-\037' || echo "")
    if [ -z "$log_content" ]; then
        return 0
    fi

    # Read Claude execution settings from config
    local claude_model
    claude_model=$(config_get_default "ai.claude.model" "sonnet")

    local claude_max_tokens
    claude_max_tokens=$(config_get_default "ai.claude.max_output_tokens" "8096")

    local claude_effort_level
    claude_effort_level=$(config_get_default "ai.claude.effort_level" "medium")

    local dashboard_port
    dashboard_port=$(config_get_default "ai.dashboard.port" "4242")

    # Compute sidecar path: $MEC_HOME/logs/tool/ts.json -> $MEC_HOME/ai-analyses/tool/ts.json
    local log_dir
    log_dir=$(dirname "$log_file")
    local ai_analyses_dir
    ai_analyses_dir=$(echo "$log_dir" | sed 's|/logs/|/ai-analyses/|')
    mkdir -p "$ai_analyses_dir"
    local ai_file="${ai_analyses_dir}/$(basename "$log_file")"
    # Pre-create the sidecar file so Docker mounts it as a file, not a directory
    touch "$ai_file"

    # Ensure ~/.claude dir and ~/.claude.json exist so the volume mounts succeed
    [ ! -d "${HOME}/.claude" ] && mkdir -p "${HOME}/.claude"
    [ ! -f "${HOME}/.claude.json" ] && touch "${HOME}/.claude.json"

    # Print session info immediately so the user has the link before analysis finishes
    local session_id="${LOG_SESSION_ID:-$(basename "$log_file" .json)}"
    echo "" >&2
    echo "[mec-ai] Analysis running in background..." >&2
    echo "[mec-ai] Session:  $session_id" >&2
    echo "[mec-ai] Results:  http://localhost:${dashboard_port}/sessions/${session_id}" >&2
    echo "[mec-ai]           (or: mec ai last)" >&2

    # Snapshot env vars needed inside the subshell before backgrounding
    local _api_key="${ANTHROPIC_API_KEY:-}"
    local _oauth_token="${CLAUDE_CODE_OAUTH_TOKEN:-}"
    local _ai_enabled="${MEC_AI_ENABLED:-}"
    local _home="${HOME}"
    local _pwd="${PWD}"
    local _image_claude="${MEC_IMAGE_CLAUDE}"
    local _image_ai_service="${MEC_IMAGE_AI_SERVICE}"

    # Run analysis in background — shell returns immediately
    (
        local _start_ms
        _start_ms=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo "0")

        local analysis_output
        analysis_output=$(docker run --rm \
            --env ANTHROPIC_API_KEY="${_api_key}" \
            --env CLAUDE_CODE_OAUTH_TOKEN="${_oauth_token}" \
            --env MEC_AI_ENABLED="${_ai_enabled}" \
            --env CLAUDE_CODE_MAX_OUTPUT_TOKENS="$claude_max_tokens" \
            --env CLAUDE_CODE_EFFORT_LEVEL="$claude_effort_level" \
            --volume "${_home}/.claude:/home/node/.claude" \
            --volume "${_home}/.claude.json:/home/node/.claude.json" \
            --volume "${_pwd}:${_pwd}" \
            --workdir "${_pwd}" \
            "$_image_claude" \
            --model "$claude_model" \
            --tools "" \
            -p "Analyze this tool execution log and provide concise suggestions for fixing any issues. Focus on actionable fixes. Log content: $log_content" \
            --output-format json \
            --max-turns 1 2>/dev/null \
          | docker run --rm -i \
            --volume "$log_file:/log.json:ro" \
            --volume "$ai_file:/ai-analyses.json" \
            --env MEC_AI_ENABLED="${_ai_enabled}" \
            "$_image_ai_service" \
            parse-claude-response \
              --ai-file /ai-analyses.json \
              --log-file /log.json \
              --log-session-id "${session_id}" \
            2>/dev/null || echo "")

        local _end_ms
        _end_ms=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo "0")
        local _elapsed
        _elapsed=$(( _end_ms - _start_ms ))

        # Patch execution_time_ms into the latest sidecar entry
        if [ -f "$ai_file" ] && command -v python3 >/dev/null 2>&1 && [ "$_elapsed" -gt 0 ]; then
            python3 - "$ai_file" "$_elapsed" <<'PYEOF'
import sys, json
path, elapsed = sys.argv[1], int(sys.argv[2])
try:
    data = json.loads(open(path).read())
    analyses = data.get("analyses", {})
    if analyses:
        last_key = sorted(analyses, key=lambda k: analyses[k].get("timestamp", ""))[-1]
        analyses[last_key]["execution_time_ms"] = elapsed
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
except Exception:
    pass
PYEOF
        fi

        # Auth failure — write a marker so mec ai last can report it
        if echo "$analysis_output" | grep -qiE "not logged in|login|authentication|401|unauthorized"; then
            echo "[mec-ai] Auth failed for session $session_id. Set ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN." >&2
        fi
    ) &
    disown
}

# Execute command with optional logging and AI analysis
# This is the main wrapper that bin scripts should use
# Usage: exec_with_ai "docker run ..."
exec_with_ai() {
    local docker_cmd="$1"

    # If logging is not enabled, just run the command
    if [ "$LOG_SESSION_ENABLED" != "true" ]; then
        eval "$docker_cmd"
        return $?
    fi

    # Create temp files for capturing output
    local tmpdir_path
    tmpdir_path=$(mktemp -d)
    local stdout_tmp="${tmpdir_path}/stdout"
    local stderr_tmp="${tmpdir_path}/stderr"

    # Run docker command with output capture
    set +e
    eval "$docker_cmd" > >(tee "$stdout_tmp") 2> >(tee "$stderr_tmp" >&2)
    local exit_code=$?
    set -e

    # Wait for background processes (tee) to finish
    wait

    # Read captured output
    local stdout_content
    stdout_content=$(cat "$stdout_tmp" 2>/dev/null || echo "")
    local stderr_content
    stderr_content=$(cat "$stderr_tmp" 2>/dev/null || echo "")

    # Print exit-code banner for failed commands
    if [ "$exit_code" -ne 0 ]; then
        echo "" >&2
        echo "[mec] Command failed (exit code $exit_code)" >&2
    fi

    # Finalize log session (creates JSON file)
    if command -v log_session_finalize >/dev/null 2>&1; then
        log_session_finalize "$stdout_content" "$stderr_content" "$exit_code"
    fi

    # Run Claude Code analysis if log file was created
    if [ -n "$LOG_JSON_FILE" ] && [ -f "$LOG_JSON_FILE" ]; then
        analyze_with_claude "$LOG_JSON_FILE"
    fi

    # Cleanup
    rm -rf "$tmpdir_path"

    return $exit_code
}

# ----------------------------------------------------------------------------
# Version Information
# ----------------------------------------------------------------------------
MEC_VERSION="1.0.0-rc"
export MEC_VERSION
