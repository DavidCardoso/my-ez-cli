#!/usr/bin/env bats
# ============================================================================
# Tests for Configuration Manager
# ============================================================================

BASEDIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")/.." && pwd)"

setup() {
    # Create temporary config directory
    TEST_CONFIG_DIR=$(mktemp -d)
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export CONFIG_FILE="$TEST_CONFIG_DIR/config.yaml"
    export DEFAULT_CONFIG="$BASEDIR/config/config.default.yaml"

    # Source config-manager
    export MEC_BASE_DIR="$BASEDIR"
    . "$BASEDIR/bin/utils/config-manager.sh"
}

teardown() {
    # Clean up test directory
    if [ -n "$TEST_CONFIG_DIR" ] && [ -d "$TEST_CONFIG_DIR" ]; then
        rm -rf "$TEST_CONFIG_DIR"
    fi
}

# ----------------------------------------------------------------------------
# Initialization Tests
# ----------------------------------------------------------------------------

@test "init_config creates config directory" {
    run init_config

    [ -d "$TEST_CONFIG_DIR" ]
    [ "$status" -eq 0 ]
}

@test "init_config creates config file" {
    run init_config

    [ -f "$CONFIG_FILE" ]
    [ "$status" -eq 0 ]
}

@test "config_exists returns false when file missing" {
    # Ensure file doesn't exist
    rm -f "$CONFIG_FILE"

    run config_exists
    [ "$status" -eq 1 ]
}

@test "config_exists returns true when file exists" {
    init_config

    run config_exists
    [ "$status" -eq 0 ]
}

@test "ensure_config creates config if missing" {
    ensure_config

    [ -f "$CONFIG_FILE" ]
}

# ----------------------------------------------------------------------------
# Read Operations Tests
# ----------------------------------------------------------------------------

@test "config_get retrieves top-level value" {
    init_config

    # Manually set a value for testing
    cat > "$CONFIG_FILE" <<'EOF'
test_key: test_value
EOF

    run config_get "test_key"
    [ "$status" -eq 0 ]
    [ "$output" = "test_value" ]
}

@test "config_get returns error for missing key" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
existing_key: value
EOF

    run config_get "missing_key"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Key not found" ]]
}

@test "config_get_default returns default when key missing" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
existing_key: value
EOF

    run config_get_default "missing_key" "default_value"
    [ "$status" -eq 0 ]
    [ "$output" = "default_value" ]
}

@test "config_get_default returns value when key exists" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
existing_key: actual_value
EOF

    run config_get_default "existing_key" "default_value"
    [ "$status" -eq 0 ]
    [ "$output" = "actual_value" ]
}

@test "config_list displays config file" {
    init_config

    run config_list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Configuration file:" ]]
}

# ----------------------------------------------------------------------------
# Write Operations Tests
# ----------------------------------------------------------------------------

@test "config_set updates top-level value" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
test_key: old_value
EOF

    run config_set "test_key" "new_value"
    [ "$status" -eq 0 ]

    # Verify the value was updated
    run grep "test_key:" "$CONFIG_FILE"
    [[ "$output" =~ "new_value" ]]
}

@test "config_set creates backup" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
test_key: value
EOF

    config_set "test_key" "new_value"

    [ -f "${CONFIG_FILE}.backup" ]
}

# ----------------------------------------------------------------------------
# Path Operations Tests
# ----------------------------------------------------------------------------

@test "config_path returns config file path" {
    run config_path
    [ "$status" -eq 0 ]
    [ "$output" = "$CONFIG_FILE" ]
}

@test "config_dir returns config directory path" {
    run config_dir
    [ "$status" -eq 0 ]
    [ "$output" = "$CONFIG_DIR" ]
}

# ----------------------------------------------------------------------------
# Validation Tests
# ----------------------------------------------------------------------------

@test "config_validate passes with valid config" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
logs:
  enabled: false

ai:
  enabled: false
EOF

    run config_validate
    [ "$status" -eq 0 ]
    [[ "$output" =~ "valid" ]]
}

@test "config_validate fails with missing sections" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
some_key: value
EOF

    run config_validate
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ERROR" ]]
}

# ----------------------------------------------------------------------------
# Reset Operations Tests
# ----------------------------------------------------------------------------

@test "config_reset restores defaults" {
    init_config

    # Modify config
    cat > "$CONFIG_FILE" <<'EOF'
custom_key: custom_value
EOF

    run config_reset
    [ "$status" -eq 0 ]

    # Should have default config now
    run grep "logs:" "$CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "config_reset creates backup" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
test_key: value
EOF

    config_reset

    # Backup should exist with timestamp
    run ls "${CONFIG_FILE}.backup."*
    [ "$status" -eq 0 ]
}

# ----------------------------------------------------------------------------
# Command Dispatcher Tests
# ----------------------------------------------------------------------------

@test "mec_config handles get command" {
    init_config

    cat > "$CONFIG_FILE" <<'EOF'
test: value
EOF

    run mec_config get "test"
    [ "$status" -eq 0 ]
    [ "$output" = "value" ]
}

@test "mec_config handles path command" {
    run mec_config path
    [ "$status" -eq 0 ]
    [ "$output" = "$CONFIG_FILE" ]
}

@test "mec_config handles help command" {
    run mec_config help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "mec_config returns error for unknown command" {
    run mec_config unknown_command
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command" ]]
}
