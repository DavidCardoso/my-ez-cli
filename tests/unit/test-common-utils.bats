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
    MEC_TELEMETRY_ENABLED=true setup_logging "test-tool"
    [ -n "$LOG_FILE" ]
}

@test "setup_logging respects disabled logging" {
    MEC_TELEMETRY_ENABLED=false MEC_SAVE_LOGS=0 setup_logging "test-tool"
    [ "$LOG_ENABLED" = "false" ]
}

@test "MEC_VERSION is set" {
    [ -n "$MEC_VERSION" ]
    [[ "$MEC_VERSION" =~ "1.0.0" ]]
}

# ----------------------------------------------------------------------------
# is_valid_json_file
# ----------------------------------------------------------------------------

@test "is_valid_json_file returns 0 for empty file" {
    local f; f=$(mktemp)
    run is_valid_json_file "$f"
    rm -f "$f"
    [ "$status" -eq 0 ]
}

@test "is_valid_json_file returns 0 for valid JSON" {
    local f; f=$(mktemp)
    echo '{"key":"value"}' > "$f"
    run is_valid_json_file "$f"
    rm -f "$f"
    [ "$status" -eq 0 ]
}

@test "is_valid_json_file returns 1 for corrupted JSON" {
    local f; f=$(mktemp)
    printf '{"key":' > "$f"
    run is_valid_json_file "$f"
    rm -f "$f"
    [ "$status" -eq 1 ]
}

@test "is_valid_json_file returns 1 for non-existent file" {
    run is_valid_json_file "/tmp/mec-nonexistent-$$.json"
    [ "$status" -eq 1 ]
}

# ----------------------------------------------------------------------------
# reset_claude_config
# ----------------------------------------------------------------------------

@test "reset_claude_config truncates corrupted file and creates backup" {
    local orig; orig=$(mktemp)
    printf '{"key":' > "$orig"
    # Point HOME to a temp dir so reset_claude_config operates on our test file
    local fake_home; fake_home=$(mktemp -d)
    cp "$orig" "${fake_home}/.claude.json"
    HOME="$fake_home" run reset_claude_config
    [ "$status" -eq 0 ]
    # Original file must now be empty
    [ ! -s "${fake_home}/.claude.json" ]
    # A backup must exist
    local backups; backups=$(ls "${fake_home}/.claude.json.bak."* 2>/dev/null | wc -l)
    [ "$backups" -ge 1 ]
    rm -rf "$fake_home" "$orig"
}
