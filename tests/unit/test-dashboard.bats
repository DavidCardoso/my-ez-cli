#!/usr/bin/env bats
# ============================================================================
# Unit tests for mec dashboard subcommand
#
# These tests verify structure, help output, static code properties, and
# guard logic that does not require Docker or a live container.
#
# Real container lifecycle tests (start/stop/status/restart) live in:
#   tests/integration/test-dashboard.bats
# ============================================================================

BASEDIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")/.." && pwd)"

setup() {
    export MEC_BASE_DIR="$BASEDIR"

    TEST_CONFIG_DIR=$(mktemp -d)
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export CONFIG_FILE="$TEST_CONFIG_DIR/config.yaml"
    export DEFAULT_CONFIG="$BASEDIR/config/config.default.yaml"

    TEST_DATA_DIR=$(mktemp -d)
    export MEC_DATA_DIR="$TEST_DATA_DIR"
    export MEC_LOG_DIR="$TEST_DATA_DIR/logs"
}

teardown() {
    [ -n "$TEST_CONFIG_DIR" ] && rm -rf "$TEST_CONFIG_DIR"
    [ -n "$TEST_DATA_DIR" ] && rm -rf "$TEST_DATA_DIR"
}

# ============================================================================
# Structure
# ============================================================================

@test "bin/mec has mec_dashboard function" {
    grep -q 'mec_dashboard' "$BASEDIR/bin/mec"
}

@test "mec_dashboard container name constant is defined" {
    grep -q 'MEC_DASHBOARD_CONTAINER=' "$BASEDIR/bin/mec"
}

@test "mec dashboard dispatcher wires all subcommands" {
    grep -q 'start)'   "$BASEDIR/bin/mec"
    grep -q 'stop)'    "$BASEDIR/bin/mec"
    grep -q 'restart)' "$BASEDIR/bin/mec"
    grep -q 'rebuild)' "$BASEDIR/bin/mec"
    grep -q 'status)'  "$BASEDIR/bin/mec"
    grep -q 'open)'    "$BASEDIR/bin/mec"
}

# ============================================================================
# Help
# ============================================================================

@test "mec dashboard with no args prints usage" {
    run "$BASEDIR/bin/mec" dashboard
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mec dashboard" ]]
}

@test "mec dashboard help prints usage" {
    run "$BASEDIR/bin/mec" dashboard help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mec dashboard" ]]
}

@test "mec dashboard --help prints usage" {
    run "$BASEDIR/bin/mec" dashboard --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mec dashboard" ]]
}

@test "mec dashboard -h prints usage" {
    run "$BASEDIR/bin/mec" dashboard -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mec dashboard" ]]
}

@test "mec dashboard help lists all subcommands" {
    run "$BASEDIR/bin/mec" dashboard help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "start"   ]]
    [[ "$output" =~ "stop"    ]]
    [[ "$output" =~ "restart" ]]
    [[ "$output" =~ "rebuild" ]]
    [[ "$output" =~ "status"  ]]
    [[ "$output" =~ "open"    ]]
}

@test "mec dashboard help mentions --rebuild flag for restart" {
    run "$BASEDIR/bin/mec" dashboard help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--rebuild" ]]
}

@test "mec dashboard help mentions default port 4242" {
    run "$BASEDIR/bin/mec" dashboard help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "4242" ]]
}

@test "mec dashboard unknown subcommand exits non-zero" {
    run "$BASEDIR/bin/mec" dashboard badcmd
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown dashboard command" ]]
}

@test "mec dashboard unknown subcommand suggests help" {
    run "$BASEDIR/bin/mec" dashboard badcmd
    [ "$status" -ne 0 ]
    [[ "$output" =~ "mec dashboard help" ]]
}

# ============================================================================
# Port configuration
# ============================================================================

@test "mec dashboard default port 4242 is hardcoded as fallback" {
    grep -q '"4242"' "$BASEDIR/bin/mec" || grep -q "'4242'" "$BASEDIR/bin/mec"
}

@test "mec dashboard config key for port is ai.dashboard.port" {
    grep -q 'ai.dashboard.port' "$BASEDIR/bin/mec"
}

# ============================================================================
# mec dashboard open — code-level checks
# ============================================================================

@test "mec dashboard open falls back to echo URL when no browser is found" {
    # Verify the fallback else branch exists in the script
    grep -q 'echo.*http://localhost' "$BASEDIR/bin/mec"
}

@test "mec dashboard open supports open command for macOS" {
    grep -q 'command -v open' "$BASEDIR/bin/mec"
}

@test "mec dashboard open supports xdg-open for Linux" {
    grep -q 'xdg-open' "$BASEDIR/bin/mec"
}

# ============================================================================
# mec dashboard start — guard logic
# ============================================================================

@test "mec dashboard start guard message references docker pull" {
    grep -q 'docker pull' "$BASEDIR/bin/mec"
}

@test "mec dashboard start guard exits non-zero when image absent (no Docker)" {
    if docker info >/dev/null 2>&1; then
        skip "Docker available"
    fi
    run "$BASEDIR/bin/mec" dashboard start
    [ "$status" -ne 0 ]
}

@test "mec dashboard start already-running message is present in script" {
    grep -q 'already running' "$BASEDIR/bin/mec"
}

# ============================================================================
# mec dashboard stop — guard logic
# ============================================================================

@test "mec dashboard stop not-running message is present in script" {
    grep -q 'not running' "$BASEDIR/bin/mec"
}

# ============================================================================
# mec dashboard rebuild — guard logic
# ============================================================================

@test "mec dashboard rebuild guard checks for Dockerfile presence" {
    grep -q '! -f.*_dockerfile' "$BASEDIR/bin/mec"
    grep -q 'Dockerfile not found' "$BASEDIR/bin/mec"
}

@test "mec dashboard rebuild guard checks for build context directory" {
    grep -q '! -d.*_build_context' "$BASEDIR/bin/mec"
    grep -q 'Build context not found' "$BASEDIR/bin/mec"
}

@test "mec dashboard rebuild prints Building and Build complete messages" {
    grep -q 'Building' "$BASEDIR/bin/mec"
    grep -q 'Build complete' "$BASEDIR/bin/mec"
}

# ============================================================================
# mec dashboard restart — flag parsing logic
# ============================================================================

@test "mec dashboard restart --rebuild flag parsing logic is present in script" {
    grep -q '_do_rebuild' "$BASEDIR/bin/mec"
    grep -q '"--rebuild"' "$BASEDIR/bin/mec"
}

@test "mec dashboard restart --rebuild does not produce unknown-flag error (no Docker)" {
    if docker info >/dev/null 2>&1; then
        skip "Docker available — rebuild would actually run"
    fi
    run "$BASEDIR/bin/mec" dashboard restart --rebuild
    [[ ! "$output" =~ "Unknown" ]]
    [[ ! "$output" =~ "unrecognized" ]]
}

@test "mec dashboard restart without --rebuild does not trigger rebuild (no Docker)" {
    if docker info >/dev/null 2>&1; then
        skip "Docker available — cannot isolate rebuild output"
    fi
    run "$BASEDIR/bin/mec" dashboard restart
    [[ ! "$output" =~ "Building" ]]
}
