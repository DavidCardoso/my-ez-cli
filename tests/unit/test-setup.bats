#!/usr/bin/env bats

# Test setup.sh script

setup() {
    MEC_PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    SETUP_SCRIPT="$MEC_PROJECT_DIR/setup.sh"
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
    [[ "$output" =~ "Unknown command" ]]
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
    grep -q 'mkdir -p.*MEC_HOME' "$SETUP_SCRIPT"
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

# Conflict detection tests
# Note: sourcing setup.sh requires basic system utilities in PATH (/usr/bin:/bin).
# Use `export PATH=...` (not inline assignment) so the path takes effect for subshells.
# Use a temp dir as the only tool directory so fake binaries override host tools.

_sys_path="/usr/bin:/bin"

@test "detect_existing_tool returns 'none' when tool not in PATH" {
    local fake_bin project_dir
    fake_bin=$(mktemp -d)
    project_dir="$(dirname "$SETUP_SCRIPT")"
    # Source setup.sh then reset BASEDIR (setup.sh recalculates BASEDIR from ${0})
    # fake_bin has no 'npm' — only system utils available
    run bash -c "export PATH='$fake_bin:$_sys_path'; source '$SETUP_SCRIPT'; export BASEDIR='$project_dir'; detect_existing_tool 'npm'"
    rm -rf "$fake_bin"
    [ "$status" -eq 0 ]
    [ "$output" = "none" ]
}

@test "detect_existing_tool returns 'mec' when tool resolves to BASEDIR/bin" {
    local fake_bin project_dir
    fake_bin=$(mktemp -d)
    project_dir="$(dirname "$SETUP_SCRIPT")"
    ln -sf "$project_dir/bin/npm" "$fake_bin/npm"
    run bash -c "export PATH='$fake_bin:$_sys_path'; source '$SETUP_SCRIPT'; export BASEDIR='$project_dir'; detect_existing_tool 'npm'"
    rm -rf "$fake_bin"
    [ "$status" -eq 0 ]
    [ "$output" = "mec" ]
}

@test "detect_existing_tool returns 'external:<path>' for non-mec binary" {
    local fake_bin project_dir
    fake_bin=$(mktemp -d)
    project_dir="$(dirname "$SETUP_SCRIPT")"
    echo '#!/bin/sh' > "$fake_bin/npm"; chmod +x "$fake_bin/npm"
    run bash -c "export PATH='$fake_bin:$_sys_path'; source '$SETUP_SCRIPT'; export BASEDIR='$project_dir'; detect_existing_tool 'npm'"
    rm -rf "$fake_bin"
    [ "$status" -eq 0 ]
    [[ "$output" == "external:"* ]]
}

@test "detect_existing_claude returns 'none' when claude not in PATH" {
    local fake_bin project_dir
    fake_bin=$(mktemp -d)
    project_dir="$(dirname "$SETUP_SCRIPT")"
    run bash -c "export PATH='$fake_bin:$_sys_path'; source '$SETUP_SCRIPT'; export BASEDIR='$project_dir'; detect_existing_claude"
    rm -rf "$fake_bin"
    [ "$status" -eq 0 ]
    [ "$output" = "none" ]
}

@test "detect_existing_claude returns 'mec' when claude resolves to BASEDIR/bin/claude" {
    local fake_bin project_dir
    fake_bin=$(mktemp -d)
    project_dir="$(dirname "$SETUP_SCRIPT")"
    ln -sf "$project_dir/bin/claude" "$fake_bin/claude"
    run bash -c "export PATH='$fake_bin:$_sys_path'; source '$SETUP_SCRIPT'; export BASEDIR='$project_dir'; detect_existing_claude"
    rm -rf "$fake_bin"
    [ "$status" -eq 0 ]
    [ "$output" = "mec" ]
}

@test "detect_claude_install_method returns 'anthropic-script' for ~/.claude/local/claude" {
    local project_dir user_home
    project_dir="$(dirname "$SETUP_SCRIPT")"
    user_home="$HOME"
    run bash -c "export HOME='$user_home'; source '$SETUP_SCRIPT'; export BASEDIR='$project_dir'; detect_claude_install_method '$user_home/.claude/local/claude'"
    [ "$status" -eq 0 ]
    [ "$output" = "anthropic-script" ]
}

@test "detect_claude_install_method returns 'anthropic-script' for ~/.local/bin/claude" {
    local project_dir user_home
    project_dir="$(dirname "$SETUP_SCRIPT")"
    user_home="$HOME"
    run bash -c "export HOME='$user_home'; source '$SETUP_SCRIPT'; export BASEDIR='$project_dir'; detect_claude_install_method '$user_home/.local/bin/claude'"
    [ "$status" -eq 0 ]
    [ "$output" = "anthropic-script" ]
}

@test "detect_claude_install_method returns 'unknown:<path>' for unknown path" {
    local project_dir
    project_dir="$(dirname "$SETUP_SCRIPT")"
    run bash -c "source '$SETUP_SCRIPT'; export BASEDIR='$project_dir'; detect_claude_install_method '/some/random/bin/claude'"
    [ "$status" -eq 0 ]
    [[ "$output" == "unknown:"* ]]
}

@test "setup.sh msg_ok outputs check icon and message" {
    run bash -c "source ${MEC_PROJECT_DIR}/setup.sh 2>/dev/null; msg_ok 'tool installed'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tool installed" ]]
    [[ "$output" =~ "✓" ]]
}

@test "setup.sh msg_warn outputs warning icon and message" {
    run bash -c "source ${MEC_PROJECT_DIR}/setup.sh 2>/dev/null; msg_warn 'side-by-side' 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "side-by-side" ]]
    [[ "$output" =~ "⚠" ]]
}

@test "setup.sh msg_err outputs error icon and message" {
    run bash -c "source ${MEC_PROJECT_DIR}/setup.sh 2>/dev/null; msg_err 'failed' 2>&1"
    [[ "$output" =~ "failed" ]]
    [[ "$output" =~ "✗" ]]
}

@test "setup.sh msg_info outputs info icon and message" {
    run bash -c "source ${MEC_PROJECT_DIR}/setup.sh 2>/dev/null; msg_info 'note about something'"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "note about something" ]]
    [[ "$output" =~ "→" ]]
}

# install_python mec-python symlink tests

@test "install_python creates mec-python symlink in primary (no conflict) path" {
    # mec-python must always be available for host scripts (common.sh shell standards)
    local func_body
    func_body=$(awk '/^install_python\(\)/{found=1} found{print; if(/^\}$/ && found > 1){exit} found++}' "$SETUP_SCRIPT")
    # Primary path = first ln block (before handle_tool_conflict). Must include mec-python.
    local primary_block
    primary_block=$(echo "$func_body" | awk '/if.*detected.*none.*mec/{found=1} found{print; if(/^\s*else\s*$/ && found){exit}}')
    echo "$primary_block" | grep -q 'mec-python'
}

@test "install_python creates mec-python symlink in replace path" {
    local func_body
    func_body=$(awk '/^install_python\(\)/{found=1} found{print; if(/^\}$/ && found > 1){exit} found++}' "$SETUP_SCRIPT")
    # Replace path = result -eq 0 block. Must include mec-python.
    local replace_block
    replace_block=$(echo "$func_body" | awk '/result -eq 0/{found=1} found{print; if(/elif/ && found > 1){exit} found++}')
    echo "$replace_block" | grep -q 'mec-python'
}

@test "install_python mec-python symlink count covers all active install paths" {
    # Expects mec-python in: primary path, replace path, side-by-side path = 3 occurrences
    local func_body count
    func_body=$(awk '/^install_python\(\)/{found=1} found{print; if(/^\}$/ && found > 1){exit} found++}' "$SETUP_SCRIPT")
    count=$(echo "$func_body" | grep -c 'mec-python')
    [ "$count" -ge 3 ]
}

@test "_mec_first_run_onboarding function exists in setup.sh" {
    grep -q '_mec_first_run_onboarding()' "$SETUP_SCRIPT"
}

@test "install_mec calls _mec_first_run_onboarding" {
    local func_body
    func_body=$(awk '/^install_mec\(\)/{found=1} found{print; if(/^\}$/ && found > 1){exit} found++}' "$SETUP_SCRIPT")
    echo "$func_body" | grep -q '_mec_first_run_onboarding'
}
