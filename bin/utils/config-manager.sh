#!/bin/bash
# ============================================================================
# My Ez CLI - Configuration Manager
# ============================================================================
# Git-style configuration management for my-ez-cli
# Version: 1.0.0
# ============================================================================

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------
CONFIG_DIR="${HOME}/.my-ez-cli"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
DEFAULT_CONFIG="${MEC_BASE_DIR:-$(dirname "$0")}/config/config.default.yaml"

# ----------------------------------------------------------------------------
# Initialization
# ----------------------------------------------------------------------------

# Initialize config directory and file
init_config() {
    # Create config directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        echo "Created config directory: $CONFIG_DIR"
    fi

    # Create config file from default if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ -f "$DEFAULT_CONFIG" ]; then
            cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
            echo "Created config file: $CONFIG_FILE"
        else
            # Create minimal config if default doesn't exist
            cat > "$CONFIG_FILE" <<'EOF'
# My Ez CLI Configuration
# Version: 1.0.0

logs:
  enabled: false
  level: info
  format: json

ai:
  enabled: false
  deep: false
  model_tier: faster
EOF
            echo "Created minimal config file: $CONFIG_FILE"
        fi
    fi
}

# ----------------------------------------------------------------------------
# Config File Operations
# ----------------------------------------------------------------------------

# Check if config file exists
config_exists() {
    [ -f "$CONFIG_FILE" ]
}

# Ensure config exists (create if needed)
ensure_config() {
    if ! config_exists; then
        init_config
    fi
}

# ----------------------------------------------------------------------------
# Read Operations
# ----------------------------------------------------------------------------

# Get a configuration value
# Usage: config_get "logs.enabled"
config_get() {
    KEY="$1"

    ensure_config

    # Simple YAML parser using sed/awk
    # This is a basic implementation; for complex YAML, consider using yq
    VALUE=$(parse_yaml_key "$CONFIG_FILE" "$KEY")

    if [ -z "$VALUE" ]; then
        echo "Key not found: $KEY" >&2
        return 1
    fi

    echo "$VALUE"
}

# Get a configuration value with default
# Usage: config_get_default "logs.enabled" "false"
config_get_default() {
    KEY="$1"
    DEFAULT="$2"

    VALUE=$(config_get "$KEY" 2>/dev/null)

    if [ -z "$VALUE" ]; then
        echo "$DEFAULT"
    else
        echo "$VALUE"
    fi
}

# ---------------------------------------------------------------------------
# Config Service Helper
# ---------------------------------------------------------------------------
# Invokes the Python config service via its dedicated Docker image.
# The config file is mounted read-write at /config/config.yaml inside the
# container so both 'get' and 'set' operations work correctly.
#
# Usage: _config_service get <file> <key>
#        _config_service set <file> <key> <value>
_config_service() {
    local cmd="$1"
    local host_file="$2"
    shift 2  # remaining args are key [value]

    docker run --rm \
        --volume "${host_file}:/config/config.yaml" \
        "${MEC_IMAGE_CONFIG_SERVICE:-davidcardoso/my-ez-cli:config-service-latest}" \
        "$cmd" /config/config.yaml "$@"
}

# Parse YAML key — delegates to the Python config service for correctness
# at all nesting depths (1-level, 2-level, 3-level+).
parse_yaml_key() {
    local file="$1"
    local key="$2"
    _config_service get "$file" "$key" 2>/dev/null
}

# List all configuration keys and values
# Usage: config_list
config_list() {
    ensure_config

    echo "Configuration file: $CONFIG_FILE"
    echo ""
    cat "$CONFIG_FILE"
}

# ----------------------------------------------------------------------------
# Write Operations
# ----------------------------------------------------------------------------

# Set a configuration value
# Usage: config_set "logs.enabled" "true"
config_set() {
    KEY="$1"
    VALUE="$2"

    ensure_config

    # Delegate to the Python config service for correct handling of all depths
    # (1-level, 2-level, 3-level+) without awk/sed fragility.
    # Create backup before modifying
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"

    _config_service set "$CONFIG_FILE" "$KEY" "$VALUE"

    echo "Set $KEY = $VALUE"
}

# Unset a configuration value (restore to default)
# Usage: config_unset "logs.enabled"
config_unset() {
    KEY="$1"

    ensure_config

    # Get default value
    DEFAULT_VALUE=$(parse_yaml_key "$DEFAULT_CONFIG" "$KEY")

    if [ -n "$DEFAULT_VALUE" ]; then
        config_set "$KEY" "$DEFAULT_VALUE"
        echo "Reset $KEY to default: $DEFAULT_VALUE"
    else
        echo "No default value found for: $KEY" >&2
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Editor Operations
# ----------------------------------------------------------------------------

# Open config file in editor
# Usage: config_edit
config_edit() {
    ensure_config

    # Use EDITOR environment variable or fall back to vi
    EDITOR="${EDITOR:-vi}"

    # Open config file
    $EDITOR "$CONFIG_FILE"

    echo "Config file edited: $CONFIG_FILE"
}

# ----------------------------------------------------------------------------
# Validation
# ----------------------------------------------------------------------------

# Validate config file
# Usage: config_validate
config_validate() {
    ensure_config

    # Basic validation
    ERRORS=0

    # Check for valid YAML structure (basic)
    if ! grep -q "^logs:" "$CONFIG_FILE"; then
        echo "ERROR: Missing 'logs' section" >&2
        ERRORS=$((ERRORS + 1))
    fi

    if ! grep -q "^ai:" "$CONFIG_FILE"; then
        echo "ERROR: Missing 'ai' section" >&2
        ERRORS=$((ERRORS + 1))
    fi

    if [ $ERRORS -eq 0 ]; then
        echo "Config file is valid"
        return 0
    else
        echo "Config file has $ERRORS error(s)" >&2
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Reset Operations
# ----------------------------------------------------------------------------

# Reset config to defaults
# Usage: config_reset
config_reset() {
    ensure_config

    # Backup current config
    if [ -f "$CONFIG_FILE" ]; then
        BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        echo "Backed up current config to: $BACKUP_FILE"
    fi

    # Copy default config
    if [ -f "$DEFAULT_CONFIG" ]; then
        cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
        echo "Reset config to defaults: $CONFIG_FILE"
    else
        echo "ERROR: Default config not found: $DEFAULT_CONFIG" >&2
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Path Operations
# ----------------------------------------------------------------------------

# Show config file path
# Usage: config_path
config_path() {
    echo "$CONFIG_FILE"
}

# Show config directory path
# Usage: config_dir
config_dir() {
    echo "$CONFIG_DIR"
}

# ----------------------------------------------------------------------------
# Export Configuration
# ----------------------------------------------------------------------------

# Export config as environment variables
# Usage: eval $(config_export)
config_export() {
    ensure_config

    # Export common settings as environment variables
    LOG_ENABLED=$(config_get "logs.enabled" 2>/dev/null || echo "false")
    LOG_LEVEL=$(config_get "logs.level" 2>/dev/null || echo "info")
    AI_ENABLED=$(config_get "ai.enabled" 2>/dev/null || echo "false")
    AI_DEEP=$(config_get "ai.deep" 2>/dev/null || echo "false")

    echo "export MEC_LOGS_ENABLED=$LOG_ENABLED"
    echo "export MEC_LOG_LEVEL=$LOG_LEVEL"
    echo "export MEC_AI_ENABLED=$AI_ENABLED"
    echo "export MEC_AI_DEEP=$AI_DEEP"
}

# ----------------------------------------------------------------------------
# Command Dispatch
# ----------------------------------------------------------------------------

# Main config command dispatcher
# Usage: mec_config <command> [args...]
mec_config() {
    COMMAND="${1:-help}"
    shift

    case "$COMMAND" in
        get)
            config_get "$@"
            ;;
        set)
            config_set "$@"
            ;;
        unset)
            config_unset "$@"
            ;;
        list)
            config_list "$@"
            ;;
        edit)
            config_edit "$@"
            ;;
        validate)
            config_validate "$@"
            ;;
        reset)
            config_reset "$@"
            ;;
        path)
            config_path "$@"
            ;;
        dir)
            config_dir "$@"
            ;;
        export)
            config_export "$@"
            ;;
        init)
            init_config "$@"
            ;;
        help|--help|-h)
            cat <<'EOF'
Usage: mec config <command> [arguments]

Commands:
  get <key>           Get configuration value
  set <key> <value>   Set configuration value
  unset <key>         Reset configuration value to default
  list                List all configuration
  edit                Open config file in editor
  validate            Validate config file
  reset               Reset config to defaults
  path                Show config file path
  dir                 Show config directory path
  export              Export config as environment variables
  init                Initialize config directory and file
  help                Show this help message

Configurable Keys:
  Logs:
    logs.enabled             Enable/disable logging (true/false, default: false)
    logs.level               Log level (debug/info/warn/error, default: info)

  AI:
    ai.enabled               Enable/disable AI analysis (true/false, default: false)

  Claude settings (all under ai.claude.*):
    ai.claude.model              Model for analysis (default: sonnet)
                                 Accepted: sonnet, haiku, opus, or full model ID
    ai.claude.max_output_tokens  Max tokens in response (default: 8096)
    ai.claude.effort_level       Effort level for opus only (default: medium)
                                 Accepted: low, medium, high

Examples:
  mec config get logs.enabled
  mec config set logs.enabled true
  mec config set ai.claude.model haiku
  mec config set ai.claude.max_output_tokens 4096
  mec config list
  mec config edit
  mec config reset
EOF
            ;;
        *)
            echo "Unknown command: $COMMAND" >&2
            echo "Run 'mec config help' for usage information" >&2
            return 1
            ;;
    esac
}

# ----------------------------------------------------------------------------
# Auto-initialization
# ----------------------------------------------------------------------------

# Initialize config on first source
if [ ! -f "$CONFIG_FILE" ]; then
    init_config >/dev/null 2>&1 || true
fi
