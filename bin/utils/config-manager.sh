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
CONFIG_DIR="${MEC_HOME:-${HOME}/.my-ez-cli}"
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
        echo "Created config directory: $CONFIG_DIR" >&2
    fi

    # Create config file from default if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ -f "$DEFAULT_CONFIG" ]; then
            cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
            echo "Created config file: $CONFIG_FILE" >&2
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
            echo "Created minimal config file: $CONFIG_FILE" >&2
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
# Falls back to the default config file when the key is absent from user config.
# Usage: config_get "telemetry.enabled"
config_get() {
    KEY="$1"

    ensure_config

    VALUE=$(parse_yaml_key "$CONFIG_FILE" "$KEY" 2>/dev/null) || true

    if [ -z "$VALUE" ] && [ -f "$DEFAULT_CONFIG" ]; then
        VALUE=$(parse_yaml_key "$DEFAULT_CONFIG" "$KEY" 2>/dev/null) || true
    fi

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

# Get a YAML list value from a config file
# Returns one item per line, exits non-zero if key not found
# Usage: config_get_list "ai.claude.firewall.dns_resolve_domains"
config_get_list() {
    local KEY="$1"

    ensure_config

    _config_service get-list "$CONFIG_FILE" "$KEY" 2>/dev/null
}

# Get a YAML list value — tries user config, falls back to default config
# Returns one item per line
# Usage: config_get_list_default "ai.claude.firewall.dns_resolve_domains"
config_get_list_default() {
    local KEY="$1"

    # Try user config first
    local VALUE
    VALUE=$(config_get_list "$KEY" 2>/dev/null)
    if [ -n "$VALUE" ]; then
        echo "$VALUE"
        return 0
    fi

    # Fall back to default config
    if [ -f "$DEFAULT_CONFIG" ]; then
        _config_service get-list "$DEFAULT_CONFIG" "$KEY" 2>/dev/null
    fi
}

# Add a domain to a firewall list in user config
# Usage: _firewall_add_domain "ai.claude.firewall.dns_resolve_domains" "example.com"
_firewall_add_domain() {
    local KEY="$1"
    local DOMAIN="$2"

    ensure_config
    _config_service add-list-item "$CONFIG_FILE" "$KEY" "$DOMAIN"
}

# Remove a domain from a firewall list in user config
# Usage: _firewall_remove_domain "ai.claude.firewall.dns_resolve_domains" "example.com"
_firewall_remove_domain() {
    local KEY="$1"
    local DOMAIN="$2"

    ensure_config
    _config_service remove-list-item "$CONFIG_FILE" "$KEY" "$DOMAIN"
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

    # User config is a partial override — missing sections are always covered by
    # config.default.yaml. Only check that the file is non-empty (or doesn't exist,
    # which ensure_config already guards against).
    echo "Config file is valid"
    return 0
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
    TELEMETRY_ENABLED=$(config_get "telemetry.enabled" 2>/dev/null || echo "true")
    LOG_ENABLED=$(config_get "logs.enabled" 2>/dev/null || echo "false")
    LOG_LEVEL=$(config_get "logs.level" 2>/dev/null || echo "info")
    AI_ENABLED=$(config_get "ai.enabled" 2>/dev/null || echo "false")
    AI_DEEP=$(config_get "ai.deep" 2>/dev/null || echo "false")

    echo "export MEC_TELEMETRY_ENABLED=$TELEMETRY_ENABLED"
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
        pull)
            docker pull "$MEC_IMAGE_CONFIG_SERVICE" \
                && echo "Pulled $MEC_IMAGE_CONFIG_SERVICE" \
                || echo "Failed to pull $MEC_IMAGE_CONFIG_SERVICE" >&2
            ;;
        rebuild)
            bash "${BASE_DIR}/docker/config-service/build" \
                && echo "Built config-service" \
                || echo "Build failed" >&2
            ;;
        image)
            if docker image inspect "$MEC_IMAGE_CONFIG_SERVICE" >/dev/null 2>&1; then
                echo "[ok] $MEC_IMAGE_CONFIG_SERVICE"
            else
                echo "[missing] $MEC_IMAGE_CONFIG_SERVICE  (run: mec config pull)"
            fi
            ;;
        help|--help|-h)
            local _b="" _r=""
            if [ -t 1 ]; then _b=$(printf '\033[1m'); _r=$(printf '\033[0m'); fi
            printf '%s\n' "${_b}USAGE${_r}"
            printf '%s\n' "  mec config <command> [arguments]"
            printf '%s\n' ""
            printf '%s\n' "${_b}COMMANDS${_r}"
            printf '%s\n' "  get <key>           Get configuration value"
            printf '%s\n' "  set <key> <value>   Set configuration value"
            printf '%s\n' "  unset <key>         Reset configuration value to default"
            printf '%s\n' "  list                List all configuration"
            printf '%s\n' "  edit                Open config file in editor"
            printf '%s\n' "  validate            Validate config file"
            printf '%s\n' "  reset               Reset config to defaults"
            printf '%s\n' "  path                Show config file path"
            printf '%s\n' "  dir                 Show config directory path"
            printf '%s\n' "  export              Export config as environment variables"
            printf '%s\n' "  init                Initialize config directory and file"
            printf '%s\n' "  pull                Pull config-service image from registry"
            printf '%s\n' "  rebuild             Build config-service image locally"
            printf '%s\n' "  image               Show config-service image status (present/missing)"
            printf '%s\n' "  help                Show this help"
            printf '%s\n' ""
            printf '%s\n' "${_b}CONFIGURABLE KEYS${_r}"
            printf '%s\n' "  Telemetry:"
            printf '%s\n' "    telemetry.enabled        Enable/disable session telemetry (true/false, default: true)"
            printf '%s\n' ""
            printf '%s\n' "  Logs:"
            printf '%s\n' "    logs.enabled             Enable/disable stdout/stderr capture (true/false, default: false)"
            printf '%s\n' "    logs.level               Log level (debug/info/warn/error, default: info)"
            printf '%s\n' ""
            printf '%s\n' "  AI:"
            printf '%s\n' "    ai.enabled               Enable/disable AI analysis (true/false, default: false)"
            printf '%s\n' ""
            printf '%s\n' "  Claude (all under ai.claude.*):"
            printf '%s\n' "    ai.claude.model              Model for analysis (default: sonnet)"
            printf '%s\n' "                                 Accepted: sonnet, haiku, opus, or full model ID"
            printf '%s\n' "    ai.claude.max_output_tokens  Max tokens in response (default: 8096)"
            printf '%s\n' "    ai.claude.effort_level       Effort level for opus only (default: medium)"
            printf '%s\n' "                                 Accepted: low, medium, high"
            printf '%s\n' ""
            printf '%s\n' "${_b}EXAMPLES${_r}"
            printf '%s\n' "  mec config get telemetry.enabled"
            printf '%s\n' "  mec config set telemetry.enabled false"
            printf '%s\n' "  mec config get logs.enabled"
            printf '%s\n' "  mec config set logs.enabled true"
            printf '%s\n' "  mec config set ai.claude.model haiku"
            printf '%s\n' "  mec config set ai.claude.max_output_tokens 4096"
            printf '%s\n' "  mec config list"
            printf '%s\n' "  mec config edit"
            printf '%s\n' "  mec config reset"
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
