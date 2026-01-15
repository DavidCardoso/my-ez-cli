#!/usr/bin/env bats

# Test python wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "python script exists and is executable" {
    [ -x "$BASEDIR/bin/python" ]
}

@test "python runs and shows version" {
    run "$BASEDIR/bin/python" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Python" ]]
}

@test "python can execute code" {
    run "$BASEDIR/bin/python" -c "print('Hello from Python')"
    [ "$status" -eq 0 ]
    [[ "$output" = "Hello from Python" ]]
}

@test "python sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/python"
    [ "$status" -eq 0 ]
}

@test "python can import standard library" {
    run "$BASEDIR/bin/python" -c "import sys; print(sys.version)"
    [ "$status" -eq 0 ]
}
