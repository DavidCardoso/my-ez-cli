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

# --- config/images.conf version vars ---

@test "config/images.conf defines MEC_TERRAFORM_VERSION" {
    grep -q 'MEC_TERRAFORM_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_AWS_VERSION" {
    grep -q 'MEC_AWS_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_GCLOUD_VERSION" {
    grep -q 'MEC_GCLOUD_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_PYTHON_VERSION" {
    grep -q 'MEC_PYTHON_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_NODE_VERSION" {
    grep -q 'MEC_NODE_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_PROMPTFOO_VERSION" {
    grep -q 'MEC_PROMPTFOO_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_CLAUDE_VERSION" {
    grep -q 'MEC_CLAUDE_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_PLAYWRIGHT_VERSION" {
    grep -q 'MEC_PLAYWRIGHT_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_SERVERLESS_VERSION" {
    grep -q 'MEC_SERVERLESS_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_SPEEDTEST_VERSION" {
    grep -q 'MEC_SPEEDTEST_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_AWS_SSO_CRED_VERSION" {
    grep -q 'MEC_AWS_SSO_CRED_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_YARN_PLUS_VERSION" {
    grep -q 'MEC_YARN_PLUS_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_DASHBOARD_VERSION" {
    grep -q 'MEC_DASHBOARD_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_AI_SERVICE_VERSION" {
    grep -q 'MEC_AI_SERVICE_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf defines MEC_CONFIG_SERVICE_VERSION" {
    grep -q 'MEC_CONFIG_SERVICE_VERSION' "$BASEDIR/config/images.conf"
}

@test "config/images.conf version var declared before image var for terraform" {
    local _vline _iline
    _vline=$(grep -n 'MEC_TERRAFORM_VERSION=' "$BASEDIR/config/images.conf" | head -1 | cut -d: -f1)
    _iline=$(grep -n 'MEC_IMAGE_TERRAFORM=' "$BASEDIR/config/images.conf" | head -1 | cut -d: -f1)
    [ "$_vline" -lt "$_iline" ]
}

@test "config/images.conf MEC_IMAGE_TERRAFORM derived from MEC_TERRAFORM_VERSION" {
    grep 'MEC_IMAGE_TERRAFORM=' "$BASEDIR/config/images.conf" | grep -q 'MEC_TERRAFORM_VERSION'
}

# --- mec list ---

@test "mec list exits 0" {
    run "$BASEDIR/bin/mec" list
    [ "$status" -eq 0 ]
}

@test "mec list shows Public images section" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'Public images'
}

@test "mec list shows MEC custom tools section" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'MEC custom tools'
}

@test "mec list shows MEC internal services section" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'MEC internal services'
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

@test "mec update with invalid version on custom tool prints validation error" {
    run "$BASEDIR/bin/mec" update claude davidcardoso/my-ez-cli:claude-test
    echo "$output" | grep -qi 'aborted\|failed\|invalid'
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

@test "mec reset on custom tool exits zero" {
    run "$BASEDIR/bin/mec" reset claude
    [ "$status" -eq 0 ]
}

@test "mec reset on custom tool prints reset confirmation" {
    run "$BASEDIR/bin/mec" reset claude
    echo "$output" | grep -qi 'reset'
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

# --- mec ai image management ---

@test "mec ai help mentions pull" {
    run "$BASEDIR/bin/mec" ai help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "pull" ]]
}

@test "mec ai help mentions rebuild" {
    run "$BASEDIR/bin/mec" ai help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "rebuild" ]]
}

@test "mec ai help mentions images" {
    run "$BASEDIR/bin/mec" ai help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "images" ]]
}

@test "mec ai images exits 0 even when images missing" {
    run "$BASEDIR/bin/mec" ai images
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AI images" ]]
}
