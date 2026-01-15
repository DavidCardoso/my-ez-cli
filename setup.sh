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
  aws, node, npm, npx, yarn, yarn-berry, serverless, terraform,
  speedtest, gcloud, playwright, cdktf, python, promptfoo, promptfoo-server

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
        node|npm|terraform|python|gcloud|cdktf|promptfoo|speedtest)
            if verify_symlink "/usr/local/bin/$tool"; then
                verified=1
            fi
            ;;
        aws|yarn|serverless|playwright)
            if verify_symlink "/usr/local/bin/$tool"; then
                verified=1
            fi
            ;;
        npx|yarn-berry|promptfoo-server)
            if verify_symlink "/usr/local/bin/$tool"; then
                verified=1
            fi
            ;;
    esac

    return $((1 - verified))
}

# Install functions

install_aws() {
    sudo ln -sf ${BASEDIR}/bin/aws /usr/local/bin/aws
    show_msg "Activating aws..."

    echo "alias aws-get-session-token=\"${BASEDIR}/bin/aws-get-session-token \"" >>~/.zshrc
    show_msg "Activating aws-get-session-token..."

    echo "alias aws-sso=\"${BASEDIR}/bin/aws-sso \"" >>~/.zshrc
    show_msg "Activating aws-sso..."

    sudo ln -sf ${BASEDIR}/bin/aws-sso-cred /usr/local/bin/aws-sso-cred
    show_msg "Activating aws-sso-cred..."

    track_install "aws"
}

install_node() {
    show_msg "Activating node (v24)..."
    sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/node
    sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/node24

    show_msg "Activating node22..."
    sudo ln -sf ${BASEDIR}/bin/node22 /usr/local/bin/node22

    track_install "node"
}

install_npm() {
    show_msg "Activating npm (over NodeJS v24)..."
    sudo ln -sf ${BASEDIR}/bin/npm /usr/local/bin/npm
    sudo ln -sf ${BASEDIR}/bin/npm /usr/local/bin/npm24

    show_msg "Activating npm22 (over NodeJS v22)..."
    sudo ln -sf ${BASEDIR}/bin/npm22 /usr/local/bin/npm22

    track_install "npm"
}

install_npx() {
    show_msg "Activating npx (over NodeJS v24)..."
    sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx
    sudo ln -sf ${BASEDIR}/bin/npx /usr/local/bin/npx24

    track_install "npx"
}

install_yarn() {
    show_msg "Activating yarn (using NodeJS v24)..."
    sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/yarn
    sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/yarn24

    show_msg "Activating yarn22..."
    sudo ln -sf ${BASEDIR}/bin/yarn22 /usr/local/bin/yarn22

    track_install "yarn"
}

install_serverless() {
    show_msg "Activating serverless..."
    sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/serverless
    sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/sls
    show_msg "> You can use 'serverless' or just 'sls' alias."

    track_install "serverless"
}

install_terraform() {
    sudo ln -sf ${BASEDIR}/bin/terraform /usr/local/bin/terraform
    show_msg "Activating terraform..."

    track_install "terraform"
}

install_speedtest() {
    sudo ln -sf ${BASEDIR}/bin/speedtest /usr/local/bin/speedtest
    show_msg "Activating speedtest..."

    track_install "speedtest"
}

install_gcloud() {
    sudo ln -sf ${BASEDIR}/bin/gcloud-login /usr/local/bin/gcloud-login
    show_msg "Activating gcloud-login..."

    sudo ln -sf ${BASEDIR}/bin/gcloud /usr/local/bin/gcloud
    show_msg "Activating gcloud..."

    track_install "gcloud"
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
    show_msg "Activating playwright..."
    sudo ln -sf ${BASEDIR}/bin/playwright /usr/local/bin/playwright

    track_install "playwright"
}

install_cdktf() {
    show_msg "Activating cdktf..."
    sudo ln -sf ${BASEDIR}/bin/cdktf /usr/local/bin/cdktf

    track_install "cdktf"
}

install_python() {
    show_msg "Activating python..."
    sudo ln -sf ${BASEDIR}/bin/python /usr/local/bin/python

    track_install "python"
}

install_promptfoo() {
    show_msg "Activating promptfoo..."
    sudo ln -sf ${BASEDIR}/bin/promptfoo /usr/local/bin/promptfoo

    track_install "promptfoo"
}

install_promptfoo-server() {
    show_msg "Activating promptfoo-server..."
    sudo ln -sf ${BASEDIR}/bin/promptfoo-server /usr/local/bin/promptfoo-server

    track_install "promptfoo-server"
}

install_all() {
    install_aws
    install_node
    install_npm
    install_npx
    install_yarn
    install_yarn-berry
    install_serverless
    install_terraform
    install_speedtest
    install_gcloud
    install_playwright
    install_cdktf
    install_python
    install_promptfoo
    install_promptfoo-server
}

# Uninstall functions

uninstall_aws() {
    sudo rm -f /usr/local/bin/aws
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
    sudo rm -f /usr/local/bin/node22
    sudo rm -f /usr/local/bin/node24

    track_uninstall "node"
    show_msg "Uninstalled node..."
}

uninstall_npm() {
    sudo rm -f /usr/local/bin/npm
    sudo rm -f /usr/local/bin/npm22
    sudo rm -f /usr/local/bin/npm24

    track_uninstall "npm"
    show_msg "Uninstalled npm..."
}

uninstall_npx() {
    sudo rm -f /usr/local/bin/npx
    sudo rm -f /usr/local/bin/npx24

    track_uninstall "npx"
    show_msg "Uninstalled npx..."
}

uninstall_yarn() {
    sudo rm -f /usr/local/bin/yarn
    sudo rm -f /usr/local/bin/yarn22
    sudo rm -f /usr/local/bin/yarn24

    track_uninstall "yarn"
    show_msg "Uninstalled yarn..."
}

uninstall_yarn-berry() {
    sudo rm -f /usr/local/bin/yarn-berry

    track_uninstall "yarn-berry"
    show_msg "Uninstalled yarn-berry..."
}

uninstall_serverless() {
    sudo rm -f /usr/local/bin/serverless
    sudo rm -f /usr/local/bin/sls

    track_uninstall "serverless"
    show_msg "Uninstalled serverless..."
}

uninstall_terraform() {
    sudo rm -f /usr/local/bin/terraform

    track_uninstall "terraform"
    show_msg "Uninstalled terraform..."
}

uninstall_speedtest() {
    sudo rm -f /usr/local/bin/speedtest

    track_uninstall "speedtest"
    show_msg "Uninstalled speedtest..."
}

uninstall_gcloud() {
    sudo rm -f /usr/local/bin/gcloud
    sudo rm -f /usr/local/bin/gcloud-login

    track_uninstall "gcloud"
    show_msg "Uninstalled gcloud..."
}

uninstall_playwright() {
    sudo rm -f /usr/local/bin/playwright

    track_uninstall "playwright"
    show_msg "Uninstalled playwright..."
}

uninstall_cdktf() {
    sudo rm -f /usr/local/bin/cdktf

    track_uninstall "cdktf"
    show_msg "Uninstalled cdktf..."
}

uninstall_python() {
    sudo rm -f /usr/local/bin/python

    track_uninstall "python"
    show_msg "Uninstalled python..."
}

uninstall_promptfoo() {
    sudo rm -f /usr/local/bin/promptfoo

    track_uninstall "promptfoo"
    show_msg "Uninstalled promptfoo..."
}

uninstall_promptfoo-server() {
    sudo rm -f /usr/local/bin/promptfoo-server

    track_uninstall "promptfoo-server"
    show_msg "Uninstalled promptfoo-server..."
}

# Status functions

show_status() {
    echo "================================================================================
                  My Ez CLI • Installation Status
================================================================================"
    echo ""

    local tools=("aws" "node" "npm" "npx" "yarn" "yarn-berry" "serverless" "terraform" "speedtest" "gcloud" "playwright" "cdktf" "python" "promptfoo" "promptfoo-server")

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

    local tools=("aws" "node" "npm" "npx" "yarn" "yarn-berry" "serverless" "terraform" "speedtest" "gcloud" "playwright" "cdktf" "python" "promptfoo" "promptfoo-server")
    local descriptions=("AWS CLI and SSO tools" "Node.js (v14-v24)" "NPM package manager" "NPX package runner" "Yarn package manager" "Yarn Berry (v2+)" "Serverless Framework" "Terraform CLI" "Ookla Speedtest CLI" "Google Cloud CLI" "Docker Compose visualizer" "Playwright testing" "CDK for Terraform" "Python interpreter" "Promptfoo evaluation" "Promptfoo server")

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
                            aws|node|npm|npx|yarn|yarn-berry|serverless|terraform|speedtest|gcloud|playwright|cdktf|python|promptfoo|promptfoo-server)
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
                        aws|node|npm|npx|yarn|yarn-berry|serverless|terraform|speedtest|gcloud|playwright|cdktf|python|promptfoo|promptfoo-server)
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
            aws|node|npm|npx|yarn|yarn-berry|serverless|terraform|speedtest|gcloud|playwright|cdktf|python|promptfoo|promptfoo-server)
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
            aws|node|npm|npx|yarn|yarn-berry|serverless|terraform|speedtest|gcloud|playwright|cdktf|python|promptfoo|promptfoo-server)
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

# Main

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
