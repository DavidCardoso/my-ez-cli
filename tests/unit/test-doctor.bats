#!/usr/bin/env bats
# ============================================================================
# Tests for mec doctor subcommand
# ============================================================================

BASEDIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")/.." && pwd)"

setup() {
    export MEC_BASE_DIR="$BASEDIR"

    # Temporary config dir so tests don't touch ~/.my-ez-cli
    TEST_CONFIG_DIR=$(mktemp -d)
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export CONFIG_FILE="$TEST_CONFIG_DIR/config.yaml"
    export DEFAULT_CONFIG="$BASEDIR/config/config.default.yaml"

    # Temporary data dir
    TEST_DATA_DIR=$(mktemp -d)
    export MEC_DATA_DIR="$TEST_DATA_DIR"
    export MEC_LOG_DIR="$TEST_DATA_DIR/logs"
}

teardown() {
    [ -n "$TEST_CONFIG_DIR" ] && rm -rf "$TEST_CONFIG_DIR"
    [ -n "$TEST_DATA_DIR" ] && rm -rf "$TEST_DATA_DIR"
}

# ============================================================================
# mec doctor help
# ============================================================================

@test "bin/mec has mec_doctor function" {
    grep -q 'mec_doctor' "$BASEDIR/bin/mec"
}

@test "mec doctor --help prints usage" {
    run "$BASEDIR/bin/mec" doctor --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage: mec doctor" ]]
}

@test "mec doctor help prints usage" {
    run "$BASEDIR/bin/mec" doctor help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage: mec doctor" ]]
}

# ============================================================================
# mec doctor (no subcommand = run checks)
# ============================================================================

@test "mec doctor runs without arguments" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "mec doctor output contains check symbols" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [[ "$output" =~ "✓" ]] || [[ "$output" =~ "⚠" ]] || [[ "$output" =~ "✗" ]]
}

@test "mec doctor output contains Docker check" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [[ "$output" =~ "Docker" ]]
}

@test "mec doctor output contains Zsh check" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [[ "$output" =~ "Zsh" ]]
}

@test "mec doctor output contains Oh My Zsh check" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [[ "$output" =~ "Oh My Zsh" ]]
}

@test "mec doctor output contains data directory check" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [[ "$output" =~ "Data directory" ]]
}

@test "mec doctor output contains AI check" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [[ "$output" =~ "AI" ]]
}

@test "mec doctor output contains Dashboard check" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [[ "$output" =~ "Dashboard" ]]
}

@test "mec doctor output ends with summary line" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    run "$BASEDIR/bin/mec" doctor
    [[ "$output" =~ "doctor:" ]]
}

@test "mec doctor exits 0 or 1 with pre-created data dir" {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi
    mkdir -p "$MEC_DATA_DIR"
    mkdir -p "$TEST_CONFIG_DIR"
    cp "$BASEDIR/config/config.default.yaml" "$CONFIG_FILE"
    run "$BASEDIR/bin/mec" doctor
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "mec doctor unknown subcommand returns error" {
    run "$BASEDIR/bin/mec" doctor xyz
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown" ]]
}
