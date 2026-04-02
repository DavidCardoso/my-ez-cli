#!/usr/bin/env bats

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    export MEC_HOME="$(mktemp -d)"
}

teardown() {
    rm -rf "$MEC_HOME"
}

# --- config/images.conf ---

@test "config/images.conf exists" {
    [ -f "$BASEDIR/config/images.conf" ]
}

@test "config/images.conf defines MEC_IMAGE_TERRAFORM" {
    grep -q 'MEC_IMAGE_TERRAFORM' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_IMAGE_NODE" {
    grep -q 'MEC_IMAGE_NODE' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_IMAGE_CLAUDE" {
    grep -q 'MEC_IMAGE_CLAUDE' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_IMAGE_AWS" {
    grep -q 'MEC_IMAGE_AWS' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_IMAGE_GCLOUD" {
    grep -q 'MEC_IMAGE_GCLOUD' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_IMAGE_PYTHON" {
    grep -q 'MEC_IMAGE_PYTHON' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_IMAGE_PROMPTFOO" {
    grep -q 'MEC_IMAGE_PROMPTFOO' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_IMAGE_PLAYWRIGHT" {
    grep -q 'MEC_IMAGE_PLAYWRIGHT' "$BASEDIR/config/images.conf"
}

# --- mec list ---

@test "mec list exits 0" {
    run "$BASEDIR/bin/mec" list
    [ "$status" -eq 0 ]
}

@test "mec list shows Public tools section" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'Public tools'
}

@test "mec list shows Custom builds section" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'Custom builds'
}

@test "mec list shows terraform" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'terraform'
}

@test "mec list shows aws" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'aws'
}

@test "mec list shows node" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'node'
}

@test "mec list shows claude" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'claude'
}

@test "mec list shows playwright" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'playwright'
}

@test "mec list shows terraform default image" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep 'terraform' | grep -q '1.14.5'
}

@test "mec list shows node default image" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep '^  node ' | grep -q 'node:22-alpine'
}

@test "mec list respects user pin in MEC_HOME/images.conf" {
    echo "MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.12.0" > "$MEC_HOME/images.conf"
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep 'terraform' | grep -q '1.12.0'
}

# --- mec update (pin public tool) ---

@test "mec update with tag on custom tool exits non-zero" {
    run "$BASEDIR/bin/mec" update claude davidcardoso/my-ez-cli:claude-test
    [ "$status" -ne 0 ]
}

@test "mec update with tag on custom tool prints 'custom' error" {
    run "$BASEDIR/bin/mec" update claude davidcardoso/my-ez-cli:claude-test
    echo "$output" | grep -qi 'custom'
}

@test "mec update unknown tool exits non-zero" {
    run "$BASEDIR/bin/mec" update notarealtool some-image:tag
    [ "$status" -ne 0 ]
}

@test "mec update unknown tool mentions mec list" {
    run "$BASEDIR/bin/mec" update notarealtool some-image:tag
    echo "$output" | grep -q 'mec list'
}

# --- mec reset ---

@test "mec reset removes pin from user images.conf" {
    echo "MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.12.0" > "$MEC_HOME/images.conf"
    run "$BASEDIR/bin/mec" reset terraform
    [ "$status" -eq 0 ]
    ! grep -q 'MEC_IMAGE_TERRAFORM' "$MEC_HOME/images.conf" 2>/dev/null
}

@test "mec reset reverts to default in list" {
    echo "MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.12.0" > "$MEC_HOME/images.conf"
    "$BASEDIR/bin/mec" reset terraform
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep 'terraform' | grep -q '1.14.5'
}

@test "mec reset on custom tool exits non-zero" {
    run "$BASEDIR/bin/mec" reset claude
    [ "$status" -ne 0 ]
}

@test "mec reset on custom tool prints 'custom' error" {
    run "$BASEDIR/bin/mec" reset claude
    echo "$output" | grep -qi 'custom'
}

@test "mec reset without args exits non-zero" {
    run "$BASEDIR/bin/mec" reset
    [ "$status" -ne 0 ]
}

@test "mec reset unknown tool exits non-zero" {
    run "$BASEDIR/bin/mec" reset notarealtool
    [ "$status" -ne 0 ]
}

@test "mec reset succeeds when no images.conf exists" {
    run "$BASEDIR/bin/mec" reset terraform
    [ "$status" -eq 0 ]
}

# --- mec help ---

@test "mec help mentions list" {
    run "$BASEDIR/bin/mec" help
    echo "$output" | grep -q 'list'
}

@test "mec help mentions update" {
    run "$BASEDIR/bin/mec" help
    echo "$output" | grep -q 'update'
}

@test "mec help mentions reset" {
    run "$BASEDIR/bin/mec" help
    echo "$output" | grep -q 'reset'
}
