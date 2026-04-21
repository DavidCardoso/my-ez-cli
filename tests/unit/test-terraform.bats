#!/usr/bin/env bats

# Test terraform wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "terraform script exists and is executable" {
    [ -x "$BASEDIR/bin/terraform" ]
}

@test "terraform runs and shows version" {
    run "$BASEDIR/bin/terraform" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Terraform" ]]
}

@test "terraform version matches expected" {
    run "$BASEDIR/bin/terraform" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v1.9" ]] || [[ "$output" =~ "v1." ]]
}

@test "terraform sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/terraform"
    [ "$status" -eq 0 ]
}

@test "terraform help command works" {
    run "$BASEDIR/bin/terraform" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage: terraform" ]]
}
