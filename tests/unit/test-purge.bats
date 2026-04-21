#!/usr/bin/env bats
# ============================================================================
# Tests for mec purge subcommand
# ============================================================================

BASEDIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")/.." && pwd)"

setup() {
    export MEC_BASE_DIR="$BASEDIR"

    TEST_DATA_DIR=$(mktemp -d)
    export MEC_DATA_DIR="$TEST_DATA_DIR"
    export MEC_LOG_DIR="$TEST_DATA_DIR/logs"
}

teardown() {
    [ -n "$TEST_DATA_DIR" ] && rm -rf "$TEST_DATA_DIR"
}

# ============================================================================
# mec purge help
# ============================================================================

@test "bin/mec has mec_purge function" {
    grep -q 'mec_purge' "$BASEDIR/bin/mec"
}

@test "mec purge --help prints usage" {
    run "$BASEDIR/bin/mec" purge --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mec purge" ]]
}

@test "mec purge help prints usage" {
    run "$BASEDIR/bin/mec" purge help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "mec purge" ]]
}

@test "mec purge help lists data subcommand" {
    run "$BASEDIR/bin/mec" purge help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "data" ]]
}

@test "mec purge help lists available flags" {
    run "$BASEDIR/bin/mec" purge help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--tool" ]]
    [[ "$output" =~ "--older-than" ]]
    [[ "$output" =~ "--dry-run" ]]
    [[ "$output" =~ "--only-logs" ]]
    [[ "$output" =~ "--only-ai-analyses" ]]
}

@test "mec purge unknown subcommand exits non-zero" {
    run "$BASEDIR/bin/mec" purge all
    [ "$status" -ne 0 ]
}

# ============================================================================
# mec purge data --dry-run (no actual deletion)
# ============================================================================

@test "mec purge data --dry-run with empty dirs prints no-files message" {
    mkdir -p "$TEST_DATA_DIR/logs" "$TEST_DATA_DIR/ai-analyses"
    run "$BASEDIR/bin/mec" purge data --dry-run
    [ "$status" -eq 0 ]
}

@test "mec purge data --dry-run lists files without deleting" {
    mkdir -p "$TEST_DATA_DIR/logs/node"
    echo '{"session_id":"s1"}' > "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json"

    run "$BASEDIR/bin/mec" purge data --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "[dry-run]" ]]
    # File must still exist after dry run
    [ -f "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json" ]
}

# ============================================================================
# mec purge data -y (non-interactive deletion)
# ============================================================================

@test "mec purge data -y deletes log files" {
    mkdir -p "$TEST_DATA_DIR/logs/node"
    echo '{"session_id":"s1"}' > "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json"

    run "$BASEDIR/bin/mec" purge data -y
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json" ]
}

@test "mec purge data --only-logs -y deletes only log files" {
    mkdir -p "$TEST_DATA_DIR/logs/node" "$TEST_DATA_DIR/ai-analyses/node"
    echo '{"session_id":"s1"}' > "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json"
    echo '{"analyses":{}}' > "$TEST_DATA_DIR/ai-analyses/node/2026-01-01_00-00-00.json"

    run "$BASEDIR/bin/mec" purge data --only-logs -y
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json" ]
    [ -f "$TEST_DATA_DIR/ai-analyses/node/2026-01-01_00-00-00.json" ]
}

@test "mec purge data --only-ai-analyses -y deletes only AI analyses" {
    mkdir -p "$TEST_DATA_DIR/logs/node" "$TEST_DATA_DIR/ai-analyses/node"
    echo '{"session_id":"s1"}' > "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json"
    echo '{"analyses":{}}' > "$TEST_DATA_DIR/ai-analyses/node/2026-01-01_00-00-00.json"

    run "$BASEDIR/bin/mec" purge data --only-ai-analyses -y
    [ "$status" -eq 0 ]
    [ -f "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json" ]
    [ ! -f "$TEST_DATA_DIR/ai-analyses/node/2026-01-01_00-00-00.json" ]
}

@test "mec purge data --tool node -y deletes only node files" {
    mkdir -p "$TEST_DATA_DIR/logs/node" "$TEST_DATA_DIR/logs/aws"
    echo '{"session_id":"s1"}' > "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json"
    echo '{"session_id":"s2"}' > "$TEST_DATA_DIR/logs/aws/2026-01-01_00-00-00.json"

    run "$BASEDIR/bin/mec" purge data --tool node -y
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_DATA_DIR/logs/node/2026-01-01_00-00-00.json" ]
    [ -f "$TEST_DATA_DIR/logs/aws/2026-01-01_00-00-00.json" ]
}

@test "mec purge data rejects invalid --tool path traversal" {
    run "$BASEDIR/bin/mec" purge data --tool "../etc" -y
    [ "$status" -ne 0 ]
}

@test "mec purge data rejects non-numeric --older-than" {
    run "$BASEDIR/bin/mec" purge data --older-than "abc" -y
    [ "$status" -ne 0 ]
}

@test "mec purge data rejects unknown flags" {
    run "$BASEDIR/bin/mec" purge data --unknown-flag -y
    [ "$status" -ne 0 ]
}
