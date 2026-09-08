#!/usr/bin/env bats

# Regression test for GHSA-3vmh-fm2p-pcv2 — Host Command Injection via `eval`
# Re-evaluation of $PWD in Docker Wrappers.
#
# bin/<tool> wrappers used to build a `docker run ...` string that embedded
# $PWD unquoted, then handed it to exec_with_ai() (bin/utils/common.sh),
# which ran the string through `eval`. Any shell metacharacters present in
# the *name* of the current working directory (e.g. "$(...)") were
# therefore re-parsed and executed as real host shell commands — before
# docker was ever invoked, and regardless of whether docker was even
# installed. This mirrors the report's PoC: run each wrapper from a
# directory whose name contains "$(touch PWNED)" and confirm the file is
# never created.

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"

    # Stub `docker` so no real daemon is needed: `docker info` succeeds
    # (check_docker passes), `docker image`/`inspect` succeed or fail in
    # ways that keep each wrapper's pre-flight checks happy, everything
    # else is an inert no-op — the point is proving the injected command
    # never runs, not that docker itself does anything.
    STUB_DIR="$BATS_TMPDIR/docker-stub-$$"
    mkdir -p "$STUB_DIR"
    cat > "$STUB_DIR/docker" <<'EOF'
#!/bin/bash
case "$1" in
    info) exit 0 ;;
    image) exit 1 ;;
    inspect) exit 0 ;;
    ps) exit 0 ;;
    rm) exit 0 ;;
    *) exit 0 ;;
esac
EOF
    chmod +x "$STUB_DIR/docker"

    ATTACK_ROOT="$BATS_TMPDIR/mec-attack-$$"
    ATTACK_DIR="$ATTACK_ROOT/mec-\$(touch\${IFS}PWNED)-case"
    mkdir -p "$ATTACK_DIR"
    MARKER="$ATTACK_DIR/PWNED"

    MEC_HOME="$BATS_TMPDIR/mec-home-$$"
    mkdir -p "$MEC_HOME"
}

teardown() {
    rm -rf "$STUB_DIR" "$ATTACK_ROOT" "$MEC_HOME"
}

run_from_attack_dir() {
    local tool="$1"
    shift
    (
        cd "$ATTACK_DIR" || exit 1
        PATH="$STUB_DIR:$PATH" MEC_HOME="$MEC_HOME" HOME="$MEC_HOME" \
            MEC_TELEMETRY_ENABLED=false \
            bash "$BASEDIR/bin/$tool" "$@"
    )
}

@test "node does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir node --version
    [ ! -f "$MARKER" ]
}

@test "npm does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir npm --version
    [ ! -f "$MARKER" ]
}

@test "npx does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir npx --version
    [ ! -f "$MARKER" ]
}

@test "pnpm does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir pnpm --version
    [ ! -f "$MARKER" ]
}

@test "yarn does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir yarn --version
    [ ! -f "$MARKER" ]
}

@test "yarn-berry does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir yarn-berry --version
    [ ! -f "$MARKER" ]
}

@test "yarn-plus does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir yarn-plus --version
    [ ! -f "$MARKER" ]
}

@test "aws does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir aws --version
    [ ! -f "$MARKER" ]
}

@test "gcloud does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir gcloud version
    [ ! -f "$MARKER" ]
}

@test "python does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir python --version
    [ ! -f "$MARKER" ]
}

@test "playwright does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir playwright --version
    [ ! -f "$MARKER" ]
}

@test "promptfoo does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir promptfoo --version
    [ ! -f "$MARKER" ]
}

@test "serverless does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir serverless --version
    [ ! -f "$MARKER" ]
}

@test "speedtest does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir speedtest --version
    [ ! -f "$MARKER" ]
}

@test "terraform does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir terraform --version
    [ ! -f "$MARKER" ]
}

@test "claude does not execute shell metacharacters embedded in the cwd name" {
    run_from_attack_dir claude --version
    [ ! -f "$MARKER" ]
}
