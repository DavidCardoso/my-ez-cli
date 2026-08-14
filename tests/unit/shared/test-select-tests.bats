#!/usr/bin/env bats
# ============================================================================
# Tests for tests/helpers/select-tests.sh
# Verifies that staged file changes map to the correct scoped bats test
# file(s)/group, and that unmapped changes fall back to running the full
# suite. See tests/README.md for the tool vs. shared/ grouping convention.
# ============================================================================

BASEDIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")/../.." && pwd)"

setup() {
    TEST_REPO="$(mktemp -d)"
    mkdir -p "$TEST_REPO/tests/helpers" "$TEST_REPO/tests/unit/shared"
    cp "$BASEDIR/tests/helpers/select-tests.sh" "$TEST_REPO/tests/helpers/select-tests.sh"

    # Existing tool test files, so the script's on-disk resolution can find
    # them (it derives tests/unit/test-<tool>.bats and checks it exists).
    for tool in pnpm npm npm20 npx node terraform yarn gcloud; do
        touch "$TEST_REPO/tests/unit/test-${tool}.bats"
    done
    touch "$TEST_REPO/tests/unit/shared/test-common-utils.bats"

    git -C "$TEST_REPO" init -q
    git -C "$TEST_REPO" config user.email "test@example.com"
    git -C "$TEST_REPO" config user.name "Test"
    git -C "$TEST_REPO" add -A
    git -C "$TEST_REPO" -c commit.gpgsign=false commit -q -m "initial"
}

teardown() {
    [ -n "$TEST_REPO" ] && rm -rf "$TEST_REPO"
}

stage_change() {
    local file="$1"
    mkdir -p "$(dirname "$TEST_REPO/$file")"
    echo "# touched" >> "$TEST_REPO/$file"
    git -C "$TEST_REPO" add "$file"
}

run_select() {
    run bash -c "cd '$TEST_REPO' && bash tests/helpers/select-tests.sh"
}

@test "select-tests.sh exists and is executable" {
    [ -f "$BASEDIR/tests/helpers/select-tests.sh" ]
    [ -x "$BASEDIR/tests/helpers/select-tests.sh" ]
}

@test "single tool change scopes to only that tool's test file" {
    stage_change "bin/pnpm"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/test-pnpm.bats" ]]
}

@test "versioned tool binary is stripped to its base tool test file" {
    stage_change "bin/pnpm24"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/test-pnpm.bats" ]]
}

@test "shared lib change selects the whole shared group, not a hand-picked list" {
    stage_change "bin/utils/common.sh"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/shared/" ]]
}

@test "a brand-new shared lib with no matching case still selects the shared group" {
    # Regression test: this is the exact gap that motivated the rewrite.
    # bin/utils/brand-new-lib.sh has never been seen by this script before
    # and there is no case arm for it, yet it must still be covered.
    stage_change "bin/utils/brand-new-lib.sh"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/shared/" ]]
}

@test "bin/mec change selects the shared group" {
    stage_change "bin/mec"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/shared/" ]]
}

@test "setup.sh change selects the shared group" {
    stage_change "setup.sh"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/shared/" ]]
}

@test "config file change selects the shared group" {
    stage_change "config/config.default.yaml"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/shared/" ]]
}

@test "a brand-new tool with a matching test file is auto-discovered, no script change needed" {
    touch "$TEST_REPO/tests/unit/test-newtool.bats"
    git -C "$TEST_REPO" add "tests/unit/test-newtool.bats"
    stage_change "bin/newtool"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/test-newtool.bats" ]]
}

@test "a brand-new tool with no test file falls back to the full suite" {
    stage_change "bin/brand-new-tool"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/" ]]
}

@test "multiple staged changes across tools return deduped union" {
    stage_change "bin/pnpm"
    stage_change "bin/npm"
    stage_change "bin/npm20"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tests/unit/test-pnpm.bats" ]]
    [[ "$output" =~ "tests/unit/test-npm.bats" ]]

    npm_count=$(grep -c "test-npm.bats" <<< "$output")
    [ "$npm_count" -eq 1 ]
}

@test "shared change alongside a tool change collapses to the shared group plus tool test" {
    stage_change "bin/pnpm"
    stage_change "bin/mec"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tests/unit/shared/" ]]
    [[ "$output" =~ "tests/unit/test-pnpm.bats" ]]
    # The shared group must not also list individual shared/*.bats files.
    [[ "$output" != *"tests/unit/shared/test-common-utils.bats"* ]]
}

@test "changing a shared bats test file directly scopes to itself" {
    stage_change "tests/unit/shared/test-common-utils.bats"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/shared/test-common-utils.bats" ]]
}

@test "changing a tool bats test file directly scopes to itself" {
    stage_change "tests/unit/test-terraform.bats"

    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/test-terraform.bats" ]]
}

@test "no staged changes falls back to full suite" {
    run_select
    [ "$status" -eq 0 ]
    [[ "$output" == "tests/unit/" ]]
}
