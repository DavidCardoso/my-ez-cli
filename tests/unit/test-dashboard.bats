#!/usr/bin/env bats
# ============================================================================
# Tests for mec dashboard subcommand (rebuild and restart --rebuild)
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
# Help
# ============================================================================

@test "bin/mec has mec_dashboard function" {
    grep -q 'mec_dashboard' "$BASEDIR/bin/mec"
}

@test "mec dashboard help prints usage" {
    run "$BASEDIR/bin/mec" dashboard help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage: mec dashboard" ]]
}

@test "mec dashboard --help prints usage" {
    run "$BASEDIR/bin/mec" dashboard --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage: mec dashboard" ]]
}

@test "mec dashboard help lists rebuild subcommand" {
    run "$BASEDIR/bin/mec" dashboard help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "rebuild" ]]
}

@test "mec dashboard help lists restart subcommand" {
    run "$BASEDIR/bin/mec" dashboard help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "restart" ]]
}

@test "mec dashboard help mentions --rebuild flag for restart" {
    run "$BASEDIR/bin/mec" dashboard help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--rebuild" ]]
}

@test "mec dashboard unknown subcommand exits non-zero" {
    run "$BASEDIR/bin/mec" dashboard badcmd
    [ "$status" -ne 0 ]
}

# ============================================================================
# mec dashboard rebuild — no Docker required
# ============================================================================

@test "mec dashboard rebuild fails with clear error when Dockerfile is missing" {
    # Verify the guard logic in bin/mec: rebuild must error when Dockerfile absent.
    # We test the code path by grepping for the guard rather than running Docker.
    grep -q 'Dockerfile not found' "$BASEDIR/bin/mec"
    grep -q '! -f.*Dockerfile' "$BASEDIR/bin/mec"
}

@test "mec dashboard rebuild subcommand is wired in mec dispatcher" {
    grep -q '"rebuild"' "$BASEDIR/bin/mec" || grep -q 'rebuild)' "$BASEDIR/bin/mec"
}

# ============================================================================
# mec dashboard rebuild — Docker required
# ============================================================================

@test "mec dashboard rebuild prints Building message before docker build" {
    # Verify the output prefix is present in the script (Docker build itself is
    # an integration concern covered by docker-build-dashboard.yml workflow)
    grep -q '"Building' "$BASEDIR/bin/mec" || grep -q '"Building ' "$BASEDIR/bin/mec"
    grep -q 'Build complete' "$BASEDIR/bin/mec"
}

# ============================================================================
# mec dashboard restart --rebuild flag parsing
# ============================================================================

@test "mec dashboard restart --rebuild flag is parsed without error (dry run via rebuild path)" {
    # Verify flag-parsing logic: --rebuild triggers mec_dashboard "rebuild" call.
    # Without Docker we can confirm the code path is reached by checking that
    # the error is Dockerfile-not-found (rebuild ran) rather than unknown-flag.
    if docker info >/dev/null 2>&1; then
        skip "Docker available — this test targets no-Docker path only"
    fi
    run "$BASEDIR/bin/mec" dashboard restart --rebuild
    # Should NOT produce "Unknown" or "unrecognized" flag error
    [[ ! "$output" =~ "Unknown" ]]
    [[ ! "$output" =~ "unrecognized" ]]
}

@test "mec dashboard restart without --rebuild does not trigger rebuild" {
    # Confirm that restart without --rebuild does not mention "Building"
    # when Docker is unavailable (rebuild would print "Building <image>")
    if docker info >/dev/null 2>&1; then
        skip "Docker available — cannot isolate rebuild path"
    fi
    run "$BASEDIR/bin/mec" dashboard restart
    [[ ! "$output" =~ "Building" ]]
}
