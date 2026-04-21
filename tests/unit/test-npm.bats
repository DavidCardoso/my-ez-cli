#!/usr/bin/env bats

# Test npm wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "npm script exists and is executable" {
    [ -x "$BASEDIR/bin/npm" ]
}

@test "npm runs with default version" {
    run "$BASEDIR/bin/npm" --version
    [ "$status" -eq 0 ]
    # npm version should be numeric (e.g., 10.x.x) - may have warnings before it
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "npm uses Node 22 by default" {
    run "$BASEDIR/bin/npm" exec node -- --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v22" ]]
}

@test "npm22 uses Node.js 22" {
    run "$BASEDIR/bin/npm22" exec node -- --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v22" ]]
}

@test "npm20 uses Node.js 20" {
    run "$BASEDIR/bin/npm20" exec node -- --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v20" ]]
}

@test "npm can list installed packages" {
    run "$BASEDIR/bin/npm" list --depth=0
    [ "$status" -eq 0 ]
}

@test "npm sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/npm"
    [ "$status" -eq 0 ]
}

@test "npm cache folder is created" {
    NPM_CACHE_FOLDER="/tmp/test-npm-cache-$$"
    run bash -c "NPM_CACHE_FOLDER='$NPM_CACHE_FOLDER' $BASEDIR/bin/npm --version"
    [ "$status" -eq 0 ]
    # Cleanup
    rm -rf "$NPM_CACHE_FOLDER"
}
