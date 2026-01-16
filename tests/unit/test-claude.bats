#!/usr/bin/env bats

# Test claude wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "claude script exists and is executable" {
    [ -x "$BASEDIR/bin/claude" ]
}

@test "claude script has proper shebang" {
    head -n 1 "$BASEDIR/bin/claude" | grep -q "^#!/bin/bash"
}

@test "claude script sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/claude"
    [ "$status" -eq 0 ]
}

@test "claude script uses correct Docker image" {
    # Image is resolved from MEC_IMAGE_CLAUDE env var (set in common.sh)
    grep -q 'MEC_IMAGE_CLAUDE' "$BASEDIR/bin/claude"
}

@test "claude script mounts workspace volume" {
    grep -q '\$PWD:\$WORKDIR' "$BASEDIR/bin/claude"
}

@test "claude script mounts auth directory" {
    grep -q 'CLAUDE_AUTH_DIR.*:/home/node/.claude' "$BASEDIR/bin/claude"
}

@test "claude script passes ANTHROPIC env vars" {
    grep -q 'ANTHROPIC_' "$BASEDIR/bin/claude"
}

@test "claude script passes CLAUDE env vars" {
    grep -q 'CLAUDE_' "$BASEDIR/bin/claude"
}

@test "claude script passes MEC env vars" {
    grep -q 'MEC_' "$BASEDIR/bin/claude"
}

@test "claude script uses get_container_name" {
    grep -q 'get_container_name.*claude' "$BASEDIR/bin/claude"
}

@test "claude script uses get_container_labels" {
    grep -q 'get_container_labels.*claude' "$BASEDIR/bin/claude"
}

@test "claude script workspace mount covers project .claude directory" {
    # $PWD:$WORKDIR mount already includes .claude/ — no separate mount needed
    grep -q '\$PWD:\$WORKDIR' "$BASEDIR/bin/claude"
    ! grep -q 'PROJECT_CLAUDE_MOUNT' "$BASEDIR/bin/claude"
}

@test "claude Dockerfile exists" {
    [ -f "$BASEDIR/docker/claude/Dockerfile" ]
}

@test "claude Dockerfile uses node base image" {
    grep -q 'FROM node:' "$BASEDIR/docker/claude/Dockerfile"
}

@test "claude Dockerfile installs claude-code npm package" {
    grep -q '@anthropic-ai/claude-code' "$BASEDIR/docker/claude/Dockerfile"
}

@test "claude Dockerfile sets claude as entrypoint" {
    grep -q 'ENTRYPOINT.*claude' "$BASEDIR/docker/claude/Dockerfile"
}

@test "claude Dockerfile has project labels" {
    grep -q 'com.my-ez-cli.project' "$BASEDIR/docker/claude/Dockerfile"
    grep -q 'com.my-ez-cli.tool="claude"' "$BASEDIR/docker/claude/Dockerfile"
}

@test "setup.sh has install_claude function" {
    grep -q "install_claude()" "$BASEDIR/setup.sh"
}

@test "setup.sh has uninstall_claude function" {
    grep -q "uninstall_claude()" "$BASEDIR/setup.sh"
}

@test "setup.sh includes claude in tool lists" {
    grep -q '"claude"' "$BASEDIR/setup.sh"
}
