#!/usr/bin/env bats

# Integration test: Symlink execution

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    SYMLINK_DIR="$BATS_TMPDIR/mec-symlinks-$$"
    mkdir -p "$SYMLINK_DIR"
}

teardown() {
    rm -rf "$SYMLINK_DIR"
}

@test "node works when executed via symlink" {
    ln -sf "$BASEDIR/bin/node" "$SYMLINK_DIR/node"
    run "$SYMLINK_DIR/node" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "v24" ]]
}

@test "npm works when executed via symlink" {
    ln -sf "$BASEDIR/bin/npm" "$SYMLINK_DIR/npm"
    run "$SYMLINK_DIR/npm" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "terraform works when executed via symlink" {
    ln -sf "$BASEDIR/bin/terraform" "$SYMLINK_DIR/terraform"
    run "$SYMLINK_DIR/terraform" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Terraform" ]]
}

@test "python works when executed via symlink" {
    ln -sf "$BASEDIR/bin/python" "$SYMLINK_DIR/python"
    run "$SYMLINK_DIR/python" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Python" ]]
}

@test "aws works when executed via symlink" {
    ln -sf "$BASEDIR/bin/aws" "$SYMLINK_DIR/aws"
    run "$SYMLINK_DIR/aws" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "aws-cli" ]]
}

@test "multiple symlinks can coexist" {
    ln -sf "$BASEDIR/bin/node" "$SYMLINK_DIR/node"
    ln -sf "$BASEDIR/bin/npm" "$SYMLINK_DIR/npm"
    ln -sf "$BASEDIR/bin/python" "$SYMLINK_DIR/python"

    run "$SYMLINK_DIR/node" --version
    [ "$status" -eq 0 ]

    run "$SYMLINK_DIR/npm" --version
    [ "$status" -eq 0 ]

    run "$SYMLINK_DIR/python" --version
    [ "$status" -eq 0 ]
}
