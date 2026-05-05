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

# --- _mec_tool_field ---

_load_mec_functions() {
    # Extract the registry and _mec_tool_field function directly from bin/mec
    # This avoids sourcing the entire script which has `set -e` and relative path issues
    eval "$(sed -n '/^_MEC_TOOL_REGISTRY=/,/^}/p' "$BASEDIR/bin/mec")"
}

@test "_mec_tool_field returns type for public tool" {
    _load_mec_functions
    result=$(_mec_tool_field "terraform" "type")
    [ "$result" = "public" ]
}

@test "_mec_tool_field returns type for custom tool" {
    _load_mec_functions
    result=$(_mec_tool_field "playwright" "type")
    [ "$result" = "custom" ]
}

@test "_mec_tool_field returns type for internal service" {
    _load_mec_functions
    result=$(_mec_tool_field "dashboard" "type")
    [ "$result" = "internal" ]
}

@test "_mec_tool_field returns image_var for terraform" {
    _load_mec_functions
    result=$(_mec_tool_field "terraform" "image_var")
    [ "$result" = "MEC_IMAGE_TERRAFORM" ]
}

@test "_mec_tool_field returns version_var for terraform" {
    _load_mec_functions
    result=$(_mec_tool_field "terraform" "version_var")
    [ "$result" = "MEC_TERRAFORM_VERSION" ]
}

@test "_mec_tool_field returns slug for custom tool" {
    _load_mec_functions
    result=$(_mec_tool_field "playwright" "slug")
    [ "$result" = "playwright" ]
}

@test "_mec_tool_field returns empty for unknown tool" {
    _load_mec_functions
    result=$(_mec_tool_field "notarealtool" "type")
    [ -z "$result" ]
}

@test "_mec_tool_field returns empty slug for public tool" {
    _load_mec_functions
    result=$(_mec_tool_field "terraform" "slug")
    [ -z "$result" ]
}

# --- Registry integrity ---

@test "registry: all tools have non-empty type" {
    _load_mec_functions
    for _tool in aws terraform gcloud python node promptfoo claude playwright serverless speedtest aws-sso-cred yarn-berry yarn-plus dashboard ai-service config-service; do
        result=$(_mec_tool_field "$_tool" "type")
        [ -n "$result" ] || { echo "Missing type for: $_tool"; return 1; }
    done
}

@test "registry: all tools have non-empty image_var" {
    _load_mec_functions
    for _tool in aws terraform gcloud python node promptfoo claude playwright serverless speedtest aws-sso-cred yarn-berry yarn-plus dashboard ai-service config-service; do
        result=$(_mec_tool_field "$_tool" "image_var")
        [ -n "$result" ] || { echo "Missing image_var for: $_tool"; return 1; }
    done
}

@test "registry: all tools have non-empty version_var" {
    _load_mec_functions
    for _tool in aws terraform gcloud python node promptfoo claude playwright serverless speedtest aws-sso-cred yarn-berry yarn-plus dashboard ai-service config-service; do
        result=$(_mec_tool_field "$_tool" "version_var")
        [ -n "$result" ] || { echo "Missing version_var for: $_tool"; return 1; }
    done
}

@test "registry: custom and internal tools have non-empty slug" {
    _load_mec_functions
    for _tool in claude playwright serverless speedtest aws-sso-cred yarn-berry yarn-plus dashboard ai-service config-service; do
        result=$(_mec_tool_field "$_tool" "slug")
        [ -n "$result" ] || { echo "Missing slug for: $_tool"; return 1; }
    done
}

@test "registry: type values are valid" {
    _load_mec_functions
    for _tool in aws terraform gcloud python node promptfoo claude playwright serverless speedtest aws-sso-cred yarn-berry yarn-plus dashboard ai-service config-service; do
        result=$(_mec_tool_field "$_tool" "type")
        case "$result" in
            public|custom|internal) ;;
            *) echo "Invalid type '$result' for: $_tool"; return 1 ;;
        esac
    done
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

# --- mec list — version-aware display ---

@test "mec list shows VERSION column header" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'VERSION'
}

@test "mec list shows terraform version from MEC_TERRAFORM_VERSION" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep 'terraform' | grep -q '1.14.5'
}

@test "mec list shows node version from MEC_NODE_VERSION" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep '^  node ' | grep -q '22-alpine'
}

@test "mec list shows [pinned] when tool is pinned in user images.conf" {
    echo "MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.12.0" > "$MEC_HOME/images.conf"
    echo "MEC_TERRAFORM_VERSION=1.12.0" >> "$MEC_HOME/images.conf"
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep 'terraform' | grep -q '\[pinned\]'
}

@test "mec list does not show [pinned] for unmodified tool" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep '^  aws ' | grep -qv '\[pinned\]'
}

@test "mec list shows internal service dashboard" {
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep -q 'dashboard'
}

@test "mec list shows [pinned] for internal service pinned to sha" {
    echo "MEC_IMAGE_DASHBOARD=ghcr.io/my-ez-cli/dashboard:sha-abc1234" > "$MEC_HOME/images.conf"
    echo "MEC_DASHBOARD_VERSION=sha-abc1234" >> "$MEC_HOME/images.conf"
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep 'dashboard' | grep -q '\[pinned\]'
}

# --- mec update — typed handlers ---

@test "mec update public tool writes MEC_IMAGE var to user images.conf" {
    # Mock docker to skip actual pull and validation
    export PATH="$BATS_TMPDIR/mock_bin:$PATH"
    mkdir -p "$BATS_TMPDIR/mock_bin"
    # Mock docker: always succeed, print version string for validation
    cat > "$BATS_TMPDIR/mock_bin/docker" <<'EOF'
#!/bin/sh
if [ "$1" = "run" ]; then echo "Terraform v1.15.0"; exit 0; fi
if [ "$1" = "pull" ]; then exit 0; fi
exit 0
EOF
    chmod +x "$BATS_TMPDIR/mock_bin/docker"

    run "$BASEDIR/bin/mec" update terraform 1.15.0
    [ "$status" -eq 0 ]
    grep -q 'MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.15.0' "$MEC_HOME/images.conf"
}

@test "mec update public tool writes MEC_<TOOL>_VERSION to user images.conf" {
    export PATH="$BATS_TMPDIR/mock_bin:$PATH"
    mkdir -p "$BATS_TMPDIR/mock_bin"
    cat > "$BATS_TMPDIR/mock_bin/docker" <<'EOF'
#!/bin/sh
if [ "$1" = "run" ]; then echo "Terraform v1.15.0"; exit 0; fi
if [ "$1" = "pull" ]; then exit 0; fi
exit 0
EOF
    chmod +x "$BATS_TMPDIR/mock_bin/docker"

    run "$BASEDIR/bin/mec" update terraform 1.15.0
    [ "$status" -eq 0 ]
    grep -q 'MEC_TERRAFORM_VERSION=1.15.0' "$MEC_HOME/images.conf"
}

@test "mec update public tool: validation failure aborts pin" {
    export PATH="$BATS_TMPDIR/mock_bin:$PATH"
    mkdir -p "$BATS_TMPDIR/mock_bin"
    # Mock docker: return output that doesn't match expected string (no mention of tool)
    cat > "$BATS_TMPDIR/mock_bin/docker" <<'EOF'
#!/bin/sh
if [ "$1" = "run" ]; then echo "unrelated output from wrong image"; exit 0; fi
exit 0
EOF
    chmod +x "$BATS_TMPDIR/mock_bin/docker"

    run "$BASEDIR/bin/mec" update terraform 1.15.0
    [ "$status" -ne 0 ]
    ! grep -q 'MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.15.0' "$MEC_HOME/images.conf" 2>/dev/null
}

@test "mec update custom tool with explicit version writes both vars" {
    export PATH="$BATS_TMPDIR/mock_bin:$PATH"
    mkdir -p "$BATS_TMPDIR/mock_bin"
    cat > "$BATS_TMPDIR/mock_bin/docker" <<'EOF'
#!/bin/sh
if [ "$1" = "run" ]; then echo "1.52.0"; exit 0; fi
if [ "$1" = "pull" ]; then exit 0; fi
exit 0
EOF
    chmod +x "$BATS_TMPDIR/mock_bin/docker"

    run "$BASEDIR/bin/mec" update playwright:1.52.0
    [ "$status" -eq 0 ]
    grep -q 'MEC_IMAGE_PLAYWRIGHT=ghcr.io/my-ez-cli/playwright:1.52.0' "$MEC_HOME/images.conf"
    grep -q 'MEC_PLAYWRIGHT_VERSION=1.52.0' "$MEC_HOME/images.conf"
}

@test "mec update internal service with sha writes both vars" {
    export PATH="$BATS_TMPDIR/mock_bin:$PATH"
    mkdir -p "$BATS_TMPDIR/mock_bin"
    cat > "$BATS_TMPDIR/mock_bin/docker" <<'EOF'
#!/bin/sh
if [ "$1" = "pull" ]; then exit 0; fi
exit 0
EOF
    chmod +x "$BATS_TMPDIR/mock_bin/docker"

    run "$BASEDIR/bin/mec" update dashboard:sha-18d92e9
    [ "$status" -eq 0 ]
    grep -q 'MEC_IMAGE_DASHBOARD=ghcr.io/my-ez-cli/dashboard:sha-18d92e9' "$MEC_HOME/images.conf"
    grep -q 'MEC_DASHBOARD_VERSION=sha-18d92e9' "$MEC_HOME/images.conf"
}

@test "mec update unknown tool exits non-zero" {
    run "$BASEDIR/bin/mec" update notarealtool 1.0.0
    [ "$status" -ne 0 ]
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

# --- mec reset — registry-driven ---

@test "mec reset removes MEC_IMAGE var from user images.conf" {
    echo "MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.12.0" > "$MEC_HOME/images.conf"
    echo "MEC_TERRAFORM_VERSION=1.12.0" >> "$MEC_HOME/images.conf"
    run "$BASEDIR/bin/mec" reset terraform
    [ "$status" -eq 0 ]
    ! grep -q 'MEC_IMAGE_TERRAFORM' "$MEC_HOME/images.conf" 2>/dev/null
}

@test "mec reset removes MEC_<TOOL>_VERSION from user images.conf" {
    echo "MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.12.0" > "$MEC_HOME/images.conf"
    echo "MEC_TERRAFORM_VERSION=1.12.0" >> "$MEC_HOME/images.conf"
    run "$BASEDIR/bin/mec" reset terraform
    [ "$status" -eq 0 ]
    ! grep -q 'MEC_TERRAFORM_VERSION' "$MEC_HOME/images.conf" 2>/dev/null
}

@test "mec reset is a no-op when tool is not pinned" {
    run "$BASEDIR/bin/mec" reset terraform
    [ "$status" -eq 0 ]
}

@test "mec reset reverts mec list to show default version" {
    echo "MEC_IMAGE_TERRAFORM=hashicorp/terraform:1.12.0" > "$MEC_HOME/images.conf"
    echo "MEC_TERRAFORM_VERSION=1.12.0" >> "$MEC_HOME/images.conf"
    "$BASEDIR/bin/mec" reset terraform
    run "$BASEDIR/bin/mec" list
    echo "$output" | grep 'terraform' | grep -q '1.14.5'
}

@test "mec reset internal service removes both vars" {
    echo "MEC_IMAGE_DASHBOARD=ghcr.io/my-ez-cli/dashboard:sha-18d92e9" > "$MEC_HOME/images.conf"
    echo "MEC_DASHBOARD_VERSION=sha-18d92e9" >> "$MEC_HOME/images.conf"
    run "$BASEDIR/bin/mec" reset dashboard
    [ "$status" -eq 0 ]
    ! grep -q 'MEC_IMAGE_DASHBOARD' "$MEC_HOME/images.conf" 2>/dev/null
    ! grep -q 'MEC_DASHBOARD_VERSION' "$MEC_HOME/images.conf" 2>/dev/null
}
