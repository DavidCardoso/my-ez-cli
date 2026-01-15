#!/usr/bin/env bats

# Test node wrapper script

setup() {
    # Load the base directory
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "node script exists and is executable" {
    [ -x "$BASEDIR/bin/node" ]
}

@test "node runs with default version 24" {
    run "$BASEDIR/bin/node" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v24" ]]
}

@test "node can execute JavaScript code" {
    run "$BASEDIR/bin/node" -e "console.log('Hello from test')"
    [ "$status" -eq 0 ]
    [[ "$output" = "Hello from test" ]]
}

@test "node22 uses correct version" {
    run "$BASEDIR/bin/node22" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v22" ]]
}

@test "node sources common.sh correctly" {
    # Check that script can be sourced without errors
    run bash -n "$BASEDIR/bin/node"
    [ "$status" -eq 0 ]
}
