#!/usr/bin/env bats

# Test yarn wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "yarn script exists and is executable" {
    [ -x "$BASEDIR/bin/yarn" ]
}

@test "yarn runs with default version (node 22)" {
    run "$BASEDIR/bin/yarn" --version
    [ "$status" -eq 0 ]
    # Yarn version should be displayed
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "yarn uses Node 22 by default" {
    run "$BASEDIR/bin/yarn" node --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v22" ]]
}

@test "yarn can run help command" {
    run "$BASEDIR/bin/yarn" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "yarn" ]]
}

@test "yarn22 uses Node.js 22" {
    run "$BASEDIR/bin/yarn22" node --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v22" ]]
}

@test "yarn20 uses Node.js 20" {
    run "$BASEDIR/bin/yarn20" node --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v20" ]]
}

@test "yarn sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/yarn"
    [ "$status" -eq 0 ]
}

@test "yarn-berry script exists and is executable" {
    [ -x "$BASEDIR/bin/yarn-berry" ]
}

@test "yarn-berry runs and shows version" {
    # Skip custom image tests (tested separately)
    skip "Custom Docker images (yarn-berry, serverless, cdktf, etc.) not tested in CI"
}
