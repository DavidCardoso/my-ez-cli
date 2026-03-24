#!/usr/bin/env bats

# Test npx wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "npx script exists and is executable" {
    [ -x "$BASEDIR/bin/npx" ]
}

@test "npx runs with default version" {
    run "$BASEDIR/bin/npx" --version
    [ "$status" -eq 0 ]
    # npx version should be numeric (e.g., 10.x.x) - may have warnings before it
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "npx uses Node 22 by default" {
    run "$BASEDIR/bin/npx" node --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v22" ]]
}

@test "npx22 uses Node.js 22" {
    run "$BASEDIR/bin/npx22" node --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v22" ]]
}

@test "npx20 uses Node.js 20" {
    run "$BASEDIR/bin/npx20" node --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v20" ]]
}

@test "npx sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/npx"
    [ "$status" -eq 0 ]
}
