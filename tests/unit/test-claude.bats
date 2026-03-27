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

@test "claude Dockerfile sets entrypoint (entrypoint.sh which execs claude)" {
    grep -q 'ENTRYPOINT.*entrypoint.sh' "$BASEDIR/docker/claude/Dockerfile"
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

# ----------------------------------------------------------------------------
# Firewall config tests
# ----------------------------------------------------------------------------

@test "config.default.yaml contains firewall section" {
    grep -q 'firewall:' "$BASEDIR/config/config.default.yaml"
}

@test "config.default.yaml firewall.enabled defaults to false" {
    grep -A3 'firewall:' "$BASEDIR/config/config.default.yaml" | grep -q 'enabled: false'
}

@test "config.default.yaml has github_meta_endpoints list" {
    grep -q 'github_meta_endpoints:' "$BASEDIR/config/config.default.yaml"
}

@test "config.default.yaml has dns_resolve_domains list" {
    grep -q 'dns_resolve_domains:' "$BASEDIR/config/config.default.yaml"
}

@test "config.default.yaml dns_resolve_domains includes api.anthropic.com" {
    grep -q 'api.anthropic.com' "$BASEDIR/config/config.default.yaml"
}

@test "bin/mec has mec_claude_firewall function" {
    grep -q 'mec_claude_firewall' "$BASEDIR/bin/mec"
}

@test "mec claude firewall help outputs usage" {
    run "$BASEDIR/bin/mec" claude firewall help
    [ "$status" -eq 0 ]
    echo "$output" | grep -q 'mec claude firewall'
}

@test "docker/claude/entrypoint.sh exists and is a script" {
    [ -f "$BASEDIR/docker/claude/entrypoint.sh" ]
    head -n 1 "$BASEDIR/docker/claude/entrypoint.sh" | grep -q '^#!/bin/bash'
}

@test "docker/claude/resolve-domains.sh exists and is a script" {
    [ -f "$BASEDIR/docker/claude/resolve-domains.sh" ]
    head -n 1 "$BASEDIR/docker/claude/resolve-domains.sh" | grep -q '^#!/bin/bash'
}

@test "docker/claude/Dockerfile references entrypoint.sh" {
    grep -q 'entrypoint.sh' "$BASEDIR/docker/claude/Dockerfile"
}

@test "docker/claude/init-firewall.sh loads from resolved-cidrs.txt" {
    grep -q 'resolved-cidrs.txt' "$BASEDIR/docker/claude/init-firewall.sh"
}

@test "bin/claude passes MEC_FIREWALL_ENABLED when firewall enabled" {
    grep -q 'MEC_FIREWALL_ENABLED' "$BASEDIR/bin/claude"
}

@test "bin/claude adds NET_ADMIN capability when firewall enabled" {
    grep -q 'NET_ADMIN' "$BASEDIR/bin/claude"
}
