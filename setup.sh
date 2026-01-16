#!/bin/bash
set -e

BASEDIR=$(cd $(dirname "${0}") && pwd)
TRACKING_FILE="$HOME/.my-ez-cli/installed"

# Create .my-ez-cli directory if it doesn't exist
mkdir -p "$HOME/.my-ez-cli"

# Helpers

show_msg() {
    cat <<EOF
--------------------------------------------------------------------------------
$1
--------------------------------------------------------------------------------
EOF
}

show_help() {
    local script_name="$(basename "${0}")"
    cat <<EOF
--------------------------------------------------------------------------------
                  My Ez CLI • Setup
--------------------------------------------------------------------------------
Usage:
  ${script_name} [command] [options]

Commands:
  install <tool1> <tool2> ...  Install specific tools
  install all                  Install all tools
  uninstall <tool1> <tool2>... Uninstall specific tools
  status                       Show installation status
  list                         List installed tools
  (no args)                    Interactive menu

Available tools:
  mec, aws, node, npm, npx, yarn, yarn-berry, yarn-plus, serverless, terraform,
  speedtest, gcloud, playwright, python, promptfoo, promptfoo-server, claude

Examples:
  ${script_name}                      # Interactive mode
  ${script_name} install node terraform
  ${script_name} install all
  ${script_name} uninstall node
  ${script_name} status
  ${script_name} list

For more information, visit:
  https://github.com/DavidCardoso/my-ez-cli
--------------------------------------------------------------------------------
EOF
}

show_begin() {
    cat <<EOF
--------------------------------------------------------------------------------
                  My Ez CLI • Setup
--------------------------------------------------------------------------------
  Hope you enjoy it! :D
--------------------------------------------------------------------------------
  Note: Aliases may be created in '~/.zshrc' file...
--------------------------------------------------------------------------------
  Note: Symbolic links may be created in '/usr/local/bin/' folder...
--------------------------------------------------------------------------------
  Warning: Root access may be needed.
--------------------------------------------------------------------------------
  GitHub: https://github.com/DavidCardoso/my-ez-cli
--------------------------------------------------------------------------------

EOF
}

# Tracking functions

track_install() {
    local tool="$1"
    touch "$TRACKING_FILE"
    if ! grep -q "^${tool}$" "$TRACKING_FILE" 2>/dev/null; then
        echo "$tool" >> "$TRACKING_FILE"
    fi
}

track_uninstall() {
    local tool="$1"
    if [ -f "$TRACKING_FILE" ]; then
        sed -i.bak "/^${tool}$/d" "$TRACKING_FILE" && rm -f "${TRACKING_FILE}.bak"
    fi
}

is_tracked() {
    local tool="$1"
    [ -f "$TRACKING_FILE" ] && grep -q "^${tool}$" "$TRACKING_FILE" 2>/dev/null
}

list_installed() {
    if [ -f "$TRACKING_FILE" ]; then
        cat "$TRACKING_FILE"
    fi
}

# Verification functions

verify_symlink() {
    local link_path="$1"
    local tool_name="$(basename "$link_path")"

    if [ -L "$link_path" ]; then
        local target=$(readlink "$link_path")
        if [ -f "$target" ]; then
            return 0
        else
            echo "Warning: Broken symlink for $tool_name (target: $target)"
            return 1
        fi
    else
        echo "Warning: $tool_name not found at $link_path"
        return 1
    fi
}

verify_installation() {
    local tool="$1"
    local verified=0

    case "$tool" in
        claude)
            if verify_symlink "/usr/local/bin/claude" 2>/dev/null || \
               verify_symlink "/usr/local/bin/mec-claude" 2>/dev/null; then
                verified=1
            fi
            ;;
        node|npm|yarn|terraform|python|aws|gcloud|serverless|speedtest|playwright|promptfoo|npx)
            if verify_symlink "/usr/local/bin/$tool" 2>/dev/null || \
               verify_symlink "/usr/local/bin/mec-$tool" 2>/dev/null; then
                verified=1
            fi
            ;;
        mec)
            if verify_symlink "/usr/local/bin/$tool"; then
                verified=1
            fi
            ;;
        yarn-plus|yarn-berry|promptfoo-server)
            if verify_symlink "/usr/local/bin/$tool"; then
                verified=1
            fi
            ;;
    esac

    return $((1 - verified))
}

# Install functions

install_aws() {
    local detected
    detected=$(detect_existing_tool "aws")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        sudo ln -sf ${BASEDIR}/bin/aws /usr/local/bin/aws
        show_msg "Activating aws..."

        echo "alias aws-get-session-token=\"${BASEDIR}/bin/aws-get-session-token \"" >>~/.zshrc
        show_msg "Activating aws-get-session-token..."

        echo "alias aws-sso=\"${BASEDIR}/bin/aws-sso \"" >>~/.zshrc
        show_msg "Activating aws-sso..."

        sudo ln -sf ${BASEDIR}/bin/aws-sso-cred /usr/local/bin/aws-sso-cred
        show_msg "Activating aws-sso-cred..."
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "aws" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            sudo ln -sf ${BASEDIR}/bin/aws /usr/local/bin/aws
            show_msg "Activating aws..."

            echo "alias aws-get-session-token=\"${BASEDIR}/bin/aws-get-session-token \"" >>~/.zshrc
            show_msg "Activating aws-get-session-token..."

            echo "alias aws-sso=\"${BASEDIR}/bin/aws-sso \"" >>~/.zshrc
            show_msg "Activating aws-sso..."

            sudo ln -sf ${BASEDIR}/bin/aws-sso-cred /usr/local/bin/aws-sso-cred
            show_msg "Activating aws-sso-cred..."
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-aws' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/aws /usr/local/bin/mec-aws
            sudo ln -sf ${BASEDIR}/bin/aws-sso-cred /usr/local/bin/aws-sso-cred
            echo "> Run 'mec-aws' to use the Docker wrapper."
        else
            echo "Skipping aws installation."
            echo "> You can still run 'mec aws' or '${BASEDIR}/bin/aws' directly."
            return
        fi
    fi

    track_install "aws"
}

install_node() {
    local detected
    detected=$(detect_existing_tool "node")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        show_msg "Activating node (v22)..."
        sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/node
        sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/node24

        show_msg "Activating node22..."
        sudo ln -sf ${BASEDIR}/bin/node22 /usr/local/bin/node22

        show_msg "Activating node20..."
        sudo ln -sf ${BASEDIR}/bin/node20 /usr/local/bin/node20
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "node" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            show_msg "Activating node..."
            sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/node
            sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/node24
            sudo ln -sf ${BASEDIR}/bin/node22 /usr/local/bin/node22
            sudo ln -sf ${BASEDIR}/bin/node20 /usr/local/bin/node20
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-node' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/mec-node
            sudo ln -sf ${BASEDIR}/bin/node22 /usr/local/bin/node22
            sudo ln -sf ${BASEDIR}/bin/node20 /usr/local/bin/node20
            echo "> Run 'mec-node' to use the Docker wrapper."
        else
            echo "Skipping node installation."
            echo "> You can still run 'mec node' or '${BASEDIR}/bin/node' directly."
            return
        fi
    fi

    track_install "node"
}

install_npm() {
    local detected
    detected=$(detect_existing_tool "npm")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        show_msg "Activating npm (over NodeJS v22)..."
        sudo ln -sf ${BASEDIR}/bin/npm /usr/local/bin/npm
        sudo ln -sf ${BASEDIR}/bin/npm /usr/local/bin/npm24

        show_msg "Activating npm22 (over NodeJS v22)..."
        sudo ln -sf ${BASEDIR}/bin/npm22 /usr/local/bin/npm22

        show_msg "Activating npm20 (over NodeJS v20)..."
        sudo ln -sf ${BASEDIR}/bin/npm20 /usr/local/bin/npm20
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "npm" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            show_msg "Activating npm..."
            sudo ln -sf ${BASEDIR}/bin/npm /usr/local/bin/npm
            sudo ln -sf ${BASEDIR}/bin/npm /usr/local/bin/npm24
            sudo ln -sf ${BASEDIR}/bin/npm22 /usr/local/bin/npm22
            sudo ln -sf ${BASEDIR}/bin/npm20 /usr/local/bin/npm20
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-npm' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/npm /usr/local/bin/mec-npm
            sudo ln -sf ${BASEDIR}/bin/npm22 /usr/local/bin/npm22
            sudo ln -sf ${BASEDIR}/bin/npm20 /usr/local/bin/npm20
            echo "> Run 'mec-npm' to use the Docker wrapper."
        else
            echo "Skipping npm installation."
            echo "> You can still run 'mec npm' or '${BASEDIR}/bin/npm' directly."
            return
        fi
    fi

    track_install "npm"
}

install_npx() {
    # npx is bundled with Node.js — check for native node first
    local node_detected
    node_detected=$(detect_existing_tool "node")

    if [[ "$node_detected" != "none" && "$node_detected" != "mec" ]]; then
        # Native node is installed — npx is likely system-managed; run specific npx conflict check
        local npx_detected
        npx_detected=$(detect_existing_tool "npx")

        if [[ "$npx_detected" == "none" || "$npx_detected" == "mec" ]]; then
            # npx not found or already mec — safe to install
            show_msg "Activating npx (over NodeJS v22)..."
            sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx
            sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx24
            sudo ln -sf ${BASEDIR}/bin/npx22 /usr/local/bin/npx22
            sudo ln -sf ${BASEDIR}/bin/npx20 /usr/local/bin/npx20
        else
            local existing_path="${npx_detected#external:}"
            echo "--------------------------------------------------------------------------------"
            echo "  Note: Native Node.js detected at '$(command -v node)' which manages npx."
            echo "  Replacing npx system-wide may break native node/npx functionality."
            echo "--------------------------------------------------------------------------------"
            handle_tool_conflict "npx" "$existing_path"
            local result=$?
            if [[ $result -eq 0 ]]; then
                show_msg "Activating npx..."
                sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx
                sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx24
                sudo ln -sf ${BASEDIR}/bin/npx22 /usr/local/bin/npx22
                sudo ln -sf ${BASEDIR}/bin/npx20 /usr/local/bin/npx20
            elif [[ $result -eq 1 ]]; then
                show_msg "Installing as 'mec-npx' (side-by-side)..."
                sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/mec-npx
                sudo ln -sf ${BASEDIR}/bin/npx22 /usr/local/bin/npx22
                sudo ln -sf ${BASEDIR}/bin/npx20 /usr/local/bin/npx20
                echo "> Run 'mec-npx' to use the Docker wrapper."
            else
                echo "Skipping npx installation."
                echo "> You can still run 'mec npx' or '${BASEDIR}/bin/npx' directly."
                return
            fi
        fi
    else
        # No native node — run standard conflict check for npx
        local detected
        detected=$(detect_existing_tool "npx")

        if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
            show_msg "Activating npx (over NodeJS v22)..."
            sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx
            sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx24
            sudo ln -sf ${BASEDIR}/bin/npx22 /usr/local/bin/npx22
            sudo ln -sf ${BASEDIR}/bin/npx20 /usr/local/bin/npx20
        else
            local existing_path="${detected#external:}"
            handle_tool_conflict "npx" "$existing_path"
            local result=$?
            if [[ $result -eq 0 ]]; then
                show_msg "Activating npx..."
                sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx
                sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx24
                sudo ln -sf ${BASEDIR}/bin/npx22 /usr/local/bin/npx22
                sudo ln -sf ${BASEDIR}/bin/npx20 /usr/local/bin/npx20
            elif [[ $result -eq 1 ]]; then
                show_msg "Installing as 'mec-npx' (side-by-side)..."
                sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/mec-npx
                sudo ln -sf ${BASEDIR}/bin/npx22 /usr/local/bin/npx22
                sudo ln -sf ${BASEDIR}/bin/npx20 /usr/local/bin/npx20
                echo "> Run 'mec-npx' to use the Docker wrapper."
            else
                echo "Skipping npx installation."
                echo "> You can still run 'mec npx' or '${BASEDIR}/bin/npx' directly."
                return
            fi
        fi
    fi

    track_install "npx"
}

install_yarn() {
    local detected
    detected=$(detect_existing_tool "yarn")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        show_msg "Activating yarn (using NodeJS v22)..."
        sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/yarn
        sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/yarn24

        show_msg "Activating yarn22..."
        sudo ln -sf ${BASEDIR}/bin/yarn22 /usr/local/bin/yarn22

        show_msg "Activating yarn20..."
        sudo ln -sf ${BASEDIR}/bin/yarn20 /usr/local/bin/yarn20
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "yarn" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            show_msg "Activating yarn..."
            sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/yarn
            sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/yarn24
            sudo ln -sf ${BASEDIR}/bin/yarn22 /usr/local/bin/yarn22
            sudo ln -sf ${BASEDIR}/bin/yarn20 /usr/local/bin/yarn20
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-yarn' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/mec-yarn
            sudo ln -sf ${BASEDIR}/bin/yarn22 /usr/local/bin/yarn22
            sudo ln -sf ${BASEDIR}/bin/yarn20 /usr/local/bin/yarn20
            echo "> Run 'mec-yarn' to use the Docker wrapper."
        else
            echo "Skipping yarn installation."
            echo "> You can still run 'mec yarn' or '${BASEDIR}/bin/yarn' directly."
            return
        fi
    fi

    track_install "yarn"
}

install_serverless() {
    local detected
    detected=$(detect_existing_tool "serverless")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        show_msg "Activating serverless..."
        sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/serverless
        sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/sls
        show_msg "> You can use 'serverless' or just 'sls' alias."
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "serverless" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            show_msg "Activating serverless..."
            sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/serverless
            sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/sls
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-serverless' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/mec-serverless
            echo "> Run 'mec-serverless' to use the Docker wrapper."
        else
            echo "Skipping serverless installation."
            echo "> You can still run 'mec serverless' or '${BASEDIR}/bin/serverless' directly."
            return
        fi
    fi

    track_install "serverless"
}

install_terraform() {
    local detected
    detected=$(detect_existing_tool "terraform")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        sudo ln -sf ${BASEDIR}/bin/terraform /usr/local/bin/terraform
        show_msg "Activating terraform..."
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "terraform" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            sudo ln -sf ${BASEDIR}/bin/terraform /usr/local/bin/terraform
            show_msg "Activating terraform..."
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-terraform' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/terraform /usr/local/bin/mec-terraform
            echo "> Run 'mec-terraform' to use the Docker wrapper."
        else
            echo "Skipping terraform installation."
            echo "> You can still run 'mec terraform' or '${BASEDIR}/bin/terraform' directly."
            return
        fi
    fi

    track_install "terraform"
}

install_speedtest() {
    local detected
    detected=$(detect_existing_tool "speedtest")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        sudo ln -sf ${BASEDIR}/bin/speedtest /usr/local/bin/speedtest
        show_msg "Activating speedtest..."
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "speedtest" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            sudo ln -sf ${BASEDIR}/bin/speedtest /usr/local/bin/speedtest
            show_msg "Activating speedtest..."
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-speedtest' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/speedtest /usr/local/bin/mec-speedtest
            echo "> Run 'mec-speedtest' to use the Docker wrapper."
        else
            echo "Skipping speedtest installation."
            echo "> You can still run 'mec speedtest' or '${BASEDIR}/bin/speedtest' directly."
            return
        fi
    fi

    track_install "speedtest"
}

install_gcloud() {
    local detected
    detected=$(detect_existing_tool "gcloud")

    # gcloud-login is mec-specific — always install it
    sudo ln -sf ${BASEDIR}/bin/gcloud-login /usr/local/bin/gcloud-login
    show_msg "Activating gcloud-login..."

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        sudo ln -sf ${BASEDIR}/bin/gcloud /usr/local/bin/gcloud
        show_msg "Activating gcloud..."
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "gcloud" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            sudo ln -sf ${BASEDIR}/bin/gcloud /usr/local/bin/gcloud
            show_msg "Activating gcloud..."
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-gcloud' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/gcloud /usr/local/bin/mec-gcloud
            echo "> Run 'mec-gcloud' to use the Docker wrapper."
        else
            echo "Skipping gcloud installation."
            echo "> You can still run 'mec gcloud' or '${BASEDIR}/bin/gcloud' directly."
            track_install "gcloud"
            return
        fi
    fi

    track_install "gcloud"
}

install_yarn-plus() {
    show_msg "Activating yarn-plus (Yarn with extra tools)..."
    sudo ln -sf ${BASEDIR}/bin/yarn-plus /usr/local/bin/yarn-plus

    track_install "yarn-plus"
}

install_yarn-berry() {
    if [[ $(which yarn) ]]; then
        echo "A yarn version was found: $(yarn --version)"
        echo "Do you want to replace it? (Y/n)"
        read REPLACE_YARN
        if [[ $REPLACE_YARN == "Y" || $REPLACE_YARN == "y" ]]; then
            sudo ln -sf ${BASEDIR}/bin/yarn-berry $(which yarn)
            sudo ln -sf ${BASEDIR}/bin/yarn-berry /usr/local/bin/yarn
            show_msg "Replacing yarn by yarn berry version..."
        fi
    fi

    sudo ln -sf ${BASEDIR}/bin/yarn-berry /usr/local/bin/yarn-berry
    show_msg "Activating yarn-berry..."

    track_install "yarn-berry"
}

install_playwright() {
    local detected
    detected=$(detect_existing_tool "playwright")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        show_msg "Activating playwright..."
        sudo ln -sf ${BASEDIR}/bin/playwright /usr/local/bin/playwright
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "playwright" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            show_msg "Activating playwright..."
            sudo ln -sf ${BASEDIR}/bin/playwright /usr/local/bin/playwright
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-playwright' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/playwright /usr/local/bin/mec-playwright
            echo "> Run 'mec-playwright' to use the Docker wrapper."
        else
            echo "Skipping playwright installation."
            echo "> You can still run 'mec playwright' or '${BASEDIR}/bin/playwright' directly."
            return
        fi
    fi

    track_install "playwright"
}

install_python() {
    local detected
    detected=$(detect_existing_tool "python")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        show_msg "Activating python..."
        sudo ln -sf ${BASEDIR}/bin/python /usr/local/bin/python
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "python" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            show_msg "Activating python..."
            sudo ln -sf ${BASEDIR}/bin/python /usr/local/bin/python
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-python' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/python /usr/local/bin/mec-python
            echo "> Run 'mec-python' to use the Docker wrapper."
        else
            echo "Skipping python installation."
            echo "> You can still run 'mec python' or '${BASEDIR}/bin/python' directly."
            return
        fi
    fi

    track_install "python"
}

install_promptfoo() {
    local detected
    detected=$(detect_existing_tool "promptfoo")

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        show_msg "Activating promptfoo..."
        sudo ln -sf ${BASEDIR}/bin/promptfoo /usr/local/bin/promptfoo
    else
        local existing_path="${detected#external:}"
        handle_tool_conflict "promptfoo" "$existing_path"
        local result=$?
        if [[ $result -eq 0 ]]; then
            # Replace
            show_msg "Activating promptfoo..."
            sudo ln -sf ${BASEDIR}/bin/promptfoo /usr/local/bin/promptfoo
        elif [[ $result -eq 1 ]]; then
            # Side-by-side
            show_msg "Installing as 'mec-promptfoo' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/promptfoo /usr/local/bin/mec-promptfoo
            echo "> Run 'mec-promptfoo' to use the Docker wrapper."
        else
            echo "Skipping promptfoo installation."
            echo "> You can still run 'mec promptfoo' or '${BASEDIR}/bin/promptfoo' directly."
            return
        fi
    fi

    track_install "promptfoo"
}

install_promptfoo-server() {
    show_msg "Activating promptfoo-server..."
    sudo ln -sf ${BASEDIR}/bin/promptfoo-server /usr/local/bin/promptfoo-server

    track_install "promptfoo-server"
}

# Generic conflict detection helpers

# Returns: "none" | "mec" | "external:<path>"
detect_existing_tool() {
    local tool="$1"
    local bin_script="${2:-$tool}"   # bin script name (defaults to tool name)
    local existing
    existing=$(command -v "$tool" 2>/dev/null) || { echo "none"; return; }
    local real
    real=$(readlink -f "$existing" 2>/dev/null || realpath "$existing" 2>/dev/null || echo "$existing")
    if [[ "$real" == "$BASEDIR/bin/$bin_script" ]]; then
        echo "mec"
    else
        echo "external:$existing"
    fi
}

# Presents 3-option conflict menu. Returns 0=replace, 1=side-by-side, 2=skip
handle_tool_conflict() {
    local tool="$1"
    local existing_path="$2"

    echo "--------------------------------------------------------------------------------"
    echo "  Conflict detected: '$tool' already exists at: $existing_path"
    echo ""
    echo "  Note: 'mec $tool' is always available regardless of your choice."
    echo "--------------------------------------------------------------------------------"
    echo ""
    echo "How would you like to proceed?"
    echo "  1) Side-by-side  — Install mec's wrapper as 'mec-$tool' (existing untouched)"
    echo "  2) Replace        — Overwrite existing '$tool' with mec's wrapper"
    echo "  3) Skip           — Do not install"
    echo ""
    read -p "Your choice [1/2/3]: " choice

    case "$choice" in
        1) return 1 ;;
        2)
            echo ""
            echo "Warning: This will overwrite your existing '$tool'."
            read -p "Are you sure? [y/N]: " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                return 0
            else
                echo "Cancelled. Falling back to side-by-side..."
                return 1
            fi
            ;;
        3|*) return 2 ;;
    esac
}

detect_existing_claude() {
    local existing
    existing=$(command -v claude 2>/dev/null) || { echo "none"; return; }
    local real
    real=$(readlink -f "$existing" 2>/dev/null || realpath "$existing" 2>/dev/null || echo "$existing")
    if [[ "$real" == "$BASEDIR/bin/claude" ]]; then
        echo "mec"
    else
        echo "external:$existing"
    fi
}

detect_claude_install_method() {
    local claude_path="$1"
    local brew_prefix
    brew_prefix=$(brew --prefix 2>/dev/null)
    if [[ -n "$brew_prefix" && "$claude_path" == "$brew_prefix"* ]]; then
        echo "homebrew"
    elif [[ "$claude_path" == "$HOME/.claude/local/claude" || \
            "$claude_path" == "$HOME/.local/bin/claude" ]]; then
        echo "anthropic-script"
    else
        echo "unknown:$claude_path"
    fi
}

uninstall_native_claude() {
    local claude_path="$1"
    local method
    method=$(detect_claude_install_method "$claude_path")

    case "$method" in
        homebrew)
            echo "Uninstalling via Homebrew: brew uninstall claude"
            if brew uninstall claude 2>/dev/null; then
                return 0
            else
                echo "Warning: brew uninstall failed."
                return 1
            fi
            ;;
        anthropic-script)
            echo "Removing Anthropic script install: rm -f $claude_path"
            if rm -f "$claude_path" 2>/dev/null; then
                return 0
            else
                echo "Warning: Could not remove $claude_path"
                return 1
            fi
            ;;
        unknown:*)
            echo "Unknown installation method. Cannot uninstall automatically."
            echo "Please remove it manually: $claude_path"
            return 1
            ;;
    esac
}

install_claude() {
    local detected
    detected=$(detect_existing_claude)

    if [[ "$detected" == "none" || "$detected" == "mec" ]]; then
        # Fresh install or already mec-managed — install both symlinks
        show_msg "Activating claude (Claude Code CLI)..."
        sudo ln -sf ${BASEDIR}/bin/claude /usr/local/bin/claude
        sudo ln -sf ${BASEDIR}/bin/claude /usr/local/bin/mec-claude
        track_install "claude"
        return
    fi

    # Conflict detected
    local existing_path="${detected#external:}"
    local method
    method=$(detect_claude_install_method "$existing_path")

    echo "--------------------------------------------------------------------------------"
    echo "  Conflict detected: 'claude' already exists at: $existing_path"
    case "$method" in
        homebrew)        echo "  Installed via:    Homebrew" ;;
        anthropic-script) echo "  Installed via:    Anthropic install script" ;;
        unknown:*)       echo "  Installed via:    Unknown method" ;;
    esac
    echo ""
    echo "  Note: 'mec claude' is always available regardless of your choice."
    echo "--------------------------------------------------------------------------------"
    echo ""
    echo "How would you like to proceed?"
    echo "  1) Side-by-side  — Install mec's wrapper as 'mec-claude' (native 'claude' untouched)"
    echo "  2) Replace        — Uninstall existing 'claude', then install mec's wrapper as 'claude' + 'mec-claude'"
    echo "  3) Skip           — Do not install any symlink"
    echo ""
    read -p "Your choice [1/2/3]: " choice

    case "$choice" in
        1)
            show_msg "Installing as 'mec-claude' (side-by-side)..."
            sudo ln -sf ${BASEDIR}/bin/claude /usr/local/bin/mec-claude
            track_install "claude"
            echo "> Run 'mec-claude' to use the Docker wrapper."
            ;;
        2)
            echo ""
            echo "Warning: This will remove your existing 'claude' installation."
            read -p "Are you sure? [y/N]: " confirm
            if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                echo "Cancelled. Falling back to side-by-side install..."
                sudo ln -sf ${BASEDIR}/bin/claude /usr/local/bin/mec-claude
                track_install "claude"
                echo "> Run 'mec-claude' to use the Docker wrapper."
                return
            fi
            if uninstall_native_claude "$existing_path"; then
                show_msg "Installing claude (Claude Code CLI)..."
                sudo ln -sf ${BASEDIR}/bin/claude /usr/local/bin/claude
                sudo ln -sf ${BASEDIR}/bin/claude /usr/local/bin/mec-claude
                track_install "claude"
            else
                echo "Uninstall failed. Falling back to side-by-side install..."
                sudo ln -sf ${BASEDIR}/bin/claude /usr/local/bin/mec-claude
                track_install "claude"
                echo "> Run 'mec-claude' to use the Docker wrapper."
            fi
            ;;
        3|*)
            echo "Skipping claude installation."
            echo "> You can still run 'mec claude' or '${BASEDIR}/bin/claude' directly."
            ;;
    esac
}

install_mec() {
    show_msg "Activating mec (my-ez-cli command)..."
    sudo ln -sf ${BASEDIR}/bin/mec /usr/local/bin/mec

    track_install "mec"
}

install_all() {
    install_mec
    install_aws
    install_node
    install_npm
    install_npx
    install_yarn
    install_yarn-plus
    install_yarn-berry
    install_serverless
    install_terraform
    install_speedtest
    install_gcloud
    install_playwright
    install_python
    install_promptfoo
    install_promptfoo-server
    install_claude
}

# Uninstall functions

uninstall_aws() {
    sudo rm -f /usr/local/bin/aws
    sudo rm -f /usr/local/bin/mec-aws
    sudo rm -f /usr/local/bin/aws-sso-cred

    # Remove aliases from ~/.zshrc
    if [ -f ~/.zshrc ]; then
        sed -i.bak '/aws-get-session-token/d' ~/.zshrc
        sed -i.bak '/aws-sso.*bin\/aws-sso/d' ~/.zshrc
        rm -f ~/.zshrc.bak
    fi

    track_uninstall "aws"
    show_msg "Uninstalled aws..."
}

uninstall_node() {
    sudo rm -f /usr/local/bin/node
    sudo rm -f /usr/local/bin/mec-node
    sudo rm -f /usr/local/bin/node20
    sudo rm -f /usr/local/bin/node22
    sudo rm -f /usr/local/bin/node24

    track_uninstall "node"
    show_msg "Uninstalled node..."
}

uninstall_npm() {
    sudo rm -f /usr/local/bin/npm
    sudo rm -f /usr/local/bin/mec-npm
    sudo rm -f /usr/local/bin/npm20
    sudo rm -f /usr/local/bin/npm22
    sudo rm -f /usr/local/bin/npm24

    track_uninstall "npm"
    show_msg "Uninstalled npm..."
}

uninstall_npx() {
    sudo rm -f /usr/local/bin/npx
    sudo rm -f /usr/local/bin/mec-npx
    sudo rm -f /usr/local/bin/npx20
    sudo rm -f /usr/local/bin/npx22
    sudo rm -f /usr/local/bin/npx24

    track_uninstall "npx"
    show_msg "Uninstalled npx..."
}

uninstall_yarn() {
    sudo rm -f /usr/local/bin/yarn
    sudo rm -f /usr/local/bin/mec-yarn
    sudo rm -f /usr/local/bin/yarn20
    sudo rm -f /usr/local/bin/yarn22
    sudo rm -f /usr/local/bin/yarn24

    track_uninstall "yarn"
    show_msg "Uninstalled yarn..."
}

uninstall_yarn-plus() {
    sudo rm -f /usr/local/bin/yarn-plus

    track_uninstall "yarn-plus"
    show_msg "Uninstalled yarn-plus..."
}

uninstall_yarn-berry() {
    sudo rm -f /usr/local/bin/yarn-berry

    track_uninstall "yarn-berry"
    show_msg "Uninstalled yarn-berry..."
}

uninstall_serverless() {
    sudo rm -f /usr/local/bin/serverless
    sudo rm -f /usr/local/bin/mec-serverless
    sudo rm -f /usr/local/bin/sls

    track_uninstall "serverless"
    show_msg "Uninstalled serverless..."
}

uninstall_terraform() {
    sudo rm -f /usr/local/bin/terraform
    sudo rm -f /usr/local/bin/mec-terraform

    track_uninstall "terraform"
    show_msg "Uninstalled terraform..."
}

uninstall_speedtest() {
    sudo rm -f /usr/local/bin/speedtest
    sudo rm -f /usr/local/bin/mec-speedtest

    track_uninstall "speedtest"
    show_msg "Uninstalled speedtest..."
}

uninstall_gcloud() {
    sudo rm -f /usr/local/bin/gcloud
    sudo rm -f /usr/local/bin/mec-gcloud
    sudo rm -f /usr/local/bin/gcloud-login

    track_uninstall "gcloud"
    show_msg "Uninstalled gcloud..."
}

uninstall_playwright() {
    sudo rm -f /usr/local/bin/playwright
    sudo rm -f /usr/local/bin/mec-playwright

    track_uninstall "playwright"
    show_msg "Uninstalled playwright..."
}

uninstall_python() {
    sudo rm -f /usr/local/bin/python
    sudo rm -f /usr/local/bin/mec-python

    track_uninstall "python"
    show_msg "Uninstalled python..."
}

uninstall_promptfoo() {
    sudo rm -f /usr/local/bin/promptfoo
    sudo rm -f /usr/local/bin/mec-promptfoo

    track_uninstall "promptfoo"
    show_msg "Uninstalled promptfoo..."
}

uninstall_promptfoo-server() {
    sudo rm -f /usr/local/bin/promptfoo-server

    track_uninstall "promptfoo-server"
    show_msg "Uninstalled promptfoo-server..."
}

uninstall_claude() {
    sudo rm -f /usr/local/bin/claude
    sudo rm -f /usr/local/bin/mec-claude

    track_uninstall "claude"
    show_msg "Uninstalled claude..."
}

uninstall_mec() {
    sudo rm -f /usr/local/bin/mec

    track_uninstall "mec"
    show_msg "Uninstalled mec..."
}

# Status functions

show_status() {
    echo "================================================================================
                  My Ez CLI • Installation Status
================================================================================"
    echo ""

    local tools=("mec" "aws" "node" "npm" "npx" "yarn" "yarn-plus" "yarn-berry" "serverless" "terraform" "speedtest" "gcloud" "playwright" "python" "promptfoo" "promptfoo-server" "claude")

    echo "Tool                  Status        Verified"
    echo "--------------------------------------------------------------------------------"

    for tool in "${tools[@]}"; do
        local status="Not Installed"
        local verified=""

        if is_tracked "$tool"; then
            status="Installed"
            if verify_installation "$tool" 2>/dev/null; then
                verified="✓"
            else
                verified="✗"
            fi
        fi

        printf "%-20s  %-13s %-10s\n" "$tool" "$status" "$verified"
    done

    echo "================================================================================
"
}

# Interactive multi-select menu - Terminal-based

interactive_menu() {
    echo "================================================================================
                  My Ez CLI • Interactive Setup
================================================================================

Select tools to install/uninstall (enter tool numbers separated by spaces)
or type 'all' to install all tools, 'done' when finished.

Available tools:"
    echo "--------------------------------------------------------------------------------"

    local tools=("mec" "aws" "node" "npm" "npx" "yarn" "yarn-plus" "yarn-berry" "serverless" "terraform" "speedtest" "gcloud" "playwright" "python" "promptfoo" "promptfoo-server" "claude")
    local descriptions=("My Ez CLI command" "AWS CLI and SSO tools" "Node.js (v22, v24 LTS)" "NPM package manager" "NPX package runner" "Yarn package manager" "Yarn + git/curl/jq tools" "Yarn Berry (v2+)" "Serverless Framework" "Terraform CLI" "Ookla Speedtest CLI" "Google Cloud CLI" "Playwright testing" "Python interpreter" "Promptfoo evaluation" "Promptfoo server" "Claude Code CLI")

    local i=1
    for tool in "${tools[@]}"; do
        local status="  "
        if is_tracked "$tool"; then
            status="✓ "
        fi
        printf "%2d. [%s] %-20s - %s\n" "$i" "$status" "$tool" "${descriptions[$((i-1))]}"
        ((i++))
    done

    echo "--------------------------------------------------------------------------------"
    echo ""
    echo "Options:"
    echo "  • Enter numbers (e.g., '1 2 5' to install aws, node, and yarn)"
    echo "  • Type 'all' to install all tools"
    echo "  • Type 'done' or press Enter to finish"
    echo "  • Type 'uninstall <numbers>' to uninstall (e.g., 'uninstall 1 3')"
    echo ""

    while true; do
        read -p "Your selection: " selection

        # Exit conditions
        if [ -z "$selection" ] || [ "$selection" = "done" ] || [ "$selection" = "exit" ] || [ "$selection" = "quit" ]; then
            echo "Setup complete!"
            break
        fi

        # Install all
        if [ "$selection" = "all" ]; then
            echo "Installing all tools..."
            install_all
            show_msg "> All tools installed successfully!"
            break
        fi

        # Uninstall mode
        if [[ "$selection" =~ ^uninstall ]]; then
            local numbers=$(echo "$selection" | sed 's/uninstall //')
            for num in $numbers; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#tools[@]}" ]; then
                    local tool="${tools[$((num-1))]}"
                    if is_tracked "$tool"; then
                        echo "Uninstalling $tool..."
                        # Use explicit function dispatch for security
                        case "$tool" in
                            mec|aws|node|npm|npx|yarn|yarn-plus|yarn-berry|serverless|terraform|speedtest|gcloud|playwright|python|promptfoo|promptfoo-server|claude)
                                "uninstall_${tool}"
                                ;;
                            *)
                                echo "Error: Invalid tool name: $tool"
                                ;;
                        esac
                    else
                        echo "Tool '$tool' is not installed."
                    fi
                else
                    echo "Invalid number: $num"
                fi
            done
            continue
        fi

        # Install selected tools
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#tools[@]}" ]; then
                local tool="${tools[$((num-1))]}"
                if is_tracked "$tool"; then
                    echo "Tool '$tool' is already installed. Skipping..."
                else
                    echo "Installing $tool..."
                    # Use explicit function dispatch for security
                    case "$tool" in
                        mec|aws|node|npm|npx|yarn|yarn-plus|yarn-berry|serverless|terraform|speedtest|gcloud|playwright|python|promptfoo|promptfoo-server|claude)
                            "install_${tool}"
                            ;;
                        *)
                            echo "Error: Invalid tool name: $tool"
                            ;;
                    esac
                fi
            else
                echo "Invalid selection: $num (must be 1-${#tools[@]})"
            fi
        done

        echo ""
        echo "Select more tools, type 'done', or press Enter to finish:"
    done
}

# Command handling

handle_install() {
    if [ $# -eq 0 ]; then
        echo "Error: No tools specified."
        echo "Usage: ${0} install <tool1> <tool2> ... | all"
        exit 1
    fi

    # Handle help request
    if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
        show_help
        exit 0
    fi

    if [ "$1" = "all" ]; then
        install_all
        show_msg "> All tools installed successfully!"
        return
    fi

    for tool in "$@"; do
        case "$tool" in
            mec|aws|node|npm|npx|yarn|yarn-plus|yarn-berry|serverless|terraform|speedtest|gcloud|playwright|python|promptfoo|promptfoo-server|claude)
                if is_tracked "$tool"; then
                    echo "Tool '$tool' is already installed."
                else
                    install_$tool
                fi
                ;;
            *)
                echo "Error: Unknown tool '$tool'"
                echo "Run '${0} help' for usage information"
                exit 1
                ;;
        esac
    done
}

handle_uninstall() {
    if [ $# -eq 0 ]; then
        echo "Error: No tools specified."
        echo "Usage: ${0} uninstall <tool1> <tool2> ..."
        exit 1
    fi

    # Handle help request
    if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
        show_help
        exit 0
    fi

    for tool in "$@"; do
        case "$tool" in
            mec|aws|node|npm|npx|yarn|yarn-plus|yarn-berry|serverless|terraform|speedtest|gcloud|playwright|python|promptfoo|promptfoo-server|claude)
                if is_tracked "$tool"; then
                    uninstall_$tool
                else
                    echo "Tool '$tool' is not installed."
                fi
                ;;
            *)
                echo "Error: Unknown tool '$tool'"
                echo "Run '${0} help' for usage information"
                exit 1
                ;;
        esac
    done
}

handle_list() {
    local installed=$(list_installed)

    if [ -z "$installed" ]; then
        echo "No tools are currently installed."
    else
        echo "Installed tools:"
        echo "--------------------------------------------------------------------------------"
        echo "$installed"
        echo "--------------------------------------------------------------------------------"
    fi
}

# Main — skip when sourced (e.g., for testing)

[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

if [ $# -eq 0 ]; then
    # No arguments - run interactive mode
    show_begin
    interactive_menu
else
    # Command-line mode
    command="$1"
    shift

    case "$command" in
        install)
            show_begin
            handle_install "$@"
            ;;
        uninstall)
            handle_uninstall "$@"
            ;;
        status)
            show_status
            exit 0
            ;;
        list)
            handle_list
            exit 0
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown command '$command'"
            echo ""
            show_help
            exit 1
            ;;
    esac
fi

# End message
show_msg "> Check the scripts in '${BASEDIR}/bin/' folder."
show_msg "> Check the '${BASEDIR}/README.md' file."
show_msg "Thanks for using My Ez CLI ;)"
