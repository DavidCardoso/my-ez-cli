#!/usr/bin/env bats

# Test common utilities

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    source "$BASEDIR/bin/utils/common.sh"
}

@test "common.sh exists" {
    [ -f "$BASEDIR/bin/utils/common.sh" ]
}

@test "common.sh can be sourced" {
    run bash -c "source '$BASEDIR/bin/utils/common.sh'"
    [ "$status" -eq 0 ]
}

@test "get_tty_flag returns valid value" {
    result=$(get_tty_flag)
    [[ "$result" = "-t" ]] || [[ "$result" = "" ]]
}

@test "get_port_flags works with empty MEC_BIND_PORTS" {
    MEC_BIND_PORTS="" result=$(get_port_flags)
    [ -z "$result" ]
}

@test "get_port_flags works with single port" {
    MEC_BIND_PORTS="8080:80" result=$(get_port_flags)
    [[ "$result" =~ "-p 8080:80" ]]
}

@test "get_port_flags works with multiple ports" {
    MEC_BIND_PORTS="8080:80 9090:90" result=$(get_port_flags)
    [[ "$result" =~ "-p 8080:80" ]]
    [[ "$result" =~ "-p 9090:90" ]]
}

@test "check_docker succeeds when Docker is available" {
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        run check_docker
        [ "$status" -eq 0 ]
    else
        skip "Docker not available"
    fi
}

@test "setup_logging creates variables" {
    MEC_SAVE_LOGS=1 setup_logging "test-tool"
    [ "$LOG_ENABLED" = "true" ]
    [ -n "$LOG_FILE" ]
}

@test "setup_logging respects disabled logging" {
    MEC_SAVE_LOGS=0 setup_logging "test-tool"
    [ "$LOG_ENABLED" = "false" ]
}

@test "MEC_VERSION is set" {
    [ -n "$MEC_VERSION" ]
    [[ "$MEC_VERSION" =~ "1.0.0" ]]
}
