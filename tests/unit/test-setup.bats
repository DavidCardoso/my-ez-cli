#!/usr/bin/env bats

# Test setup.sh script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    SETUP_SCRIPT="$BASEDIR/setup.sh"
}

@test "setup.sh exists and is executable" {
    [ -x "$SETUP_SCRIPT" ]
}

@test "setup.sh help command works" {
    run "$SETUP_SCRIPT" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "My Ez CLI • Setup" ]]
    [[ "$output" =~ "Commands:" ]]
}

@test "setup.sh --help flag works" {
    run "$SETUP_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "My Ez CLI • Setup" ]]
}

@test "setup.sh status command works" {
    run "$SETUP_SCRIPT" status
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Installation Status" ]]
    [[ "$output" =~ "Tool" ]]
}

@test "setup.sh list command works" {
    run "$SETUP_SCRIPT" list
    [ "$status" -eq 0 ]
    # Should either show installed tools or message about no tools
    [[ "$output" =~ "Installed tools:" ]] || [[ "$output" =~ "No tools" ]]
}

@test "setup.sh rejects unknown command" {
    run "$SETUP_SCRIPT" unknown-command
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Error: Unknown command" ]]
}

@test "setup.sh install requires tool name" {
    run "$SETUP_SCRIPT" install
    [ "$status" -ne 0 ]
    [[ "$output" =~ "No tools specified" ]]
}

@test "setup.sh install rejects unknown tool" {
    run "$SETUP_SCRIPT" install nonexistent-tool
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown tool" ]]
}

@test "setup.sh uninstall requires tool name" {
    run "$SETUP_SCRIPT" uninstall
    [ "$status" -ne 0 ]
    [[ "$output" =~ "No tools specified" ]]
}

@test "setup.sh has proper shebang" {
    head -n 1 "$SETUP_SCRIPT" | grep -q "^#!/bin/bash"
}

@test "setup.sh sources correct base directory" {
    grep -q "BASEDIR=" "$SETUP_SCRIPT"
}

@test "setup.sh creates tracking directory" {
    grep -q "mkdir -p.*/.my-ez-cli" "$SETUP_SCRIPT"
}

@test "setup.sh has install functions for all tools" {
    # Check that install functions exist for main tools
    grep -q "install_node()" "$SETUP_SCRIPT"
    grep -q "install_npm()" "$SETUP_SCRIPT"
    grep -q "install_terraform()" "$SETUP_SCRIPT"
    grep -q "install_aws()" "$SETUP_SCRIPT"
    grep -q "install_python()" "$SETUP_SCRIPT"
}

@test "setup.sh has uninstall functions for all tools" {
    # Check that uninstall functions exist
    grep -q "uninstall_node()" "$SETUP_SCRIPT"
    grep -q "uninstall_npm()" "$SETUP_SCRIPT"
    grep -q "uninstall_terraform()" "$SETUP_SCRIPT"
}

@test "setup.sh has tracking functions" {
    grep -q "track_install()" "$SETUP_SCRIPT"
    grep -q "track_uninstall()" "$SETUP_SCRIPT"
    grep -q "is_tracked()" "$SETUP_SCRIPT"
}

@test "setup.sh has verification functions" {
    grep -q "verify_symlink()" "$SETUP_SCRIPT"
    grep -q "verify_installation()" "$SETUP_SCRIPT"
}

@test "setup.sh has interactive menu function" {
    grep -q "interactive_menu()" "$SETUP_SCRIPT"
}

@test "setup.sh help shows all available tools" {
    run "$SETUP_SCRIPT" help
    [[ "$output" =~ "aws" ]]
    [[ "$output" =~ "node" ]]
    [[ "$output" =~ "terraform" ]]
    [[ "$output" =~ "python" ]]
}
