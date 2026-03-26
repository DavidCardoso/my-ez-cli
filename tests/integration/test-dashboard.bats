#!/usr/bin/env bats
# ============================================================================
# Integration tests for mec dashboard subcommand
#
# These tests exercise the real Docker container lifecycle: start, stop,
# status, and restart. They require Docker to be available and the dashboard
# image to be present (pulled or built locally).
#
# Run conditions: same as other integration tests — push to main, releases,
# and workflow_dispatch (see .github/workflows/test.yml).
# ============================================================================

BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
MEC="$BASEDIR/bin/mec"
CONTAINER="mec-dashboard"

setup() {
    if ! docker info >/dev/null 2>&1; then
        skip "Docker not available"
    fi

    export MEC_BASE_DIR="$BASEDIR"

    TEST_CONFIG_DIR=$(mktemp -d)
    export CONFIG_DIR="$TEST_CONFIG_DIR"
    export CONFIG_FILE="$TEST_CONFIG_DIR/config.yaml"
    export DEFAULT_CONFIG="$BASEDIR/config/config.default.yaml"

    # Use a non-default port so tests don't collide with a user's running dashboard
    export TEST_DASHBOARD_PORT=14242
    echo "ai:"               > "$CONFIG_FILE"
    echo "  dashboard:"     >> "$CONFIG_FILE"
    echo "  port: $TEST_DASHBOARD_PORT" >> "$CONFIG_FILE"

    # Ensure no leftover container from a previous failed run
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
}

teardown() {
    # Always clean up the container, even on test failure
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    [ -n "$TEST_CONFIG_DIR" ] && rm -rf "$TEST_CONFIG_DIR"
}

_image_available() {
    # Returns 0 if the dashboard image exists locally
    source "$BASEDIR/bin/utils/common.sh" 2>/dev/null || true
    local img="${MEC_IMAGE_DASHBOARD:-davidcardoso/my-ez-cli:dashboard-latest}"
    docker image inspect "$img" >/dev/null 2>&1
}

# ============================================================================
# mec dashboard status — no container running
# ============================================================================

@test "mec dashboard status reports not running when no container exists" {
    run "$MEC" dashboard status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "not running" ]]
}

# ============================================================================
# mec dashboard stop — no-op when container absent
# ============================================================================

@test "mec dashboard stop is a no-op when container is not running" {
    run "$MEC" dashboard stop
    [ "$status" -eq 0 ]
    [[ "$output" =~ "not running" ]]
}

# ============================================================================
# mec dashboard start / stop / status lifecycle
# ============================================================================

@test "mec dashboard start launches container successfully" {
    if ! _image_available; then
        skip "Dashboard image not present locally"
    fi
    run "$MEC" dashboard start
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dashboard started" ]]
    # Container must actually be running
    local state
    state=$(docker inspect --format '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
    [ "$state" = "running" ]
}

@test "mec dashboard start prints UI and API URLs" {
    if ! _image_available; then
        skip "Dashboard image not present locally"
    fi
    run "$MEC" dashboard start
    [ "$status" -eq 0 ]
    [[ "$output" =~ "http://localhost:" ]]
    [[ "$output" =~ "/api" ]]
}

@test "mec dashboard start is idempotent when already running" {
    if ! _image_available; then
        skip "Dashboard image not present locally"
    fi
    "$MEC" dashboard start >/dev/null
    run "$MEC" dashboard start
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already running" ]]
}

@test "mec dashboard status shows running after start" {
    if ! _image_available; then
        skip "Dashboard image not present locally"
    fi
    "$MEC" dashboard start >/dev/null
    run "$MEC" dashboard status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "running" ]]
}

@test "mec dashboard stop removes running container" {
    if ! _image_available; then
        skip "Dashboard image not present locally"
    fi
    "$MEC" dashboard start >/dev/null
    run "$MEC" dashboard stop
    [ "$status" -eq 0 ]
    [[ "$output" =~ "stopped" ]]
    # Container must be gone
    run docker inspect "$CONTAINER"
    [ "$status" -ne 0 ]
}

@test "mec dashboard status shows not running after stop" {
    if ! _image_available; then
        skip "Dashboard image not present locally"
    fi
    "$MEC" dashboard start >/dev/null
    "$MEC" dashboard stop  >/dev/null
    run "$MEC" dashboard status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "not running" ]]
}

# ============================================================================
# mec dashboard restart
# ============================================================================

@test "mec dashboard restart starts the container when it was stopped" {
    if ! _image_available; then
        skip "Dashboard image not present locally"
    fi
    # Start then stop so there's a clean stopped state
    "$MEC" dashboard start >/dev/null
    "$MEC" dashboard stop  >/dev/null
    run "$MEC" dashboard restart
    [ "$status" -eq 0 ]
    local state
    state=$(docker inspect --format '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
    [ "$state" = "running" ]
}

@test "mec dashboard restart replaces a running container" {
    if ! _image_available; then
        skip "Dashboard image not present locally"
    fi
    "$MEC" dashboard start >/dev/null
    run "$MEC" dashboard restart
    [ "$status" -eq 0 ]
    local state
    state=$(docker inspect --format '{{.State.Status}}' "$CONTAINER" 2>/dev/null)
    [ "$state" = "running" ]
}
