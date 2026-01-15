#!/usr/bin/env bats

# Test AWS CLI wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "aws script exists and is executable" {
    [ -x "$BASEDIR/bin/aws" ]
}

@test "aws runs and shows version" {
    run "$BASEDIR/bin/aws" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "aws-cli" ]]
}

@test "aws sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/aws"
    [ "$status" -eq 0 ]
}

@test "aws help command works" {
    # Disable pager to prevent interactive mode (AWS_PAGER="" or AWS_PAGER=cat)
    run bash -c "AWS_PAGER=cat '$BASEDIR/bin/aws' help"
    [ "$status" -eq 0 ]
    # Verify help output contains expected content
    [[ "$output" =~ "AWS" ]] || [[ "$output" =~ "DESCRIPTION" ]]
}
