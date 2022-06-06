#!/bin/bash
set -e

BASEDIR=$(cd $(dirname "${0}") && pwd)

# Helpers

show_msg() {
    cat <<EOF
==============================================================
$1
==============================================================
EOF
}

show_help() {
    show_msg "$1"

    cat <<EOF
==============================================================
Usage examples:
${BASEDIR}/setup.sh <OPTION>

Type the number of the OPTION:
# ALL: To activate all options
# aws: AWS CLI, AWS Get Session Token, AWS SSO, AWS SSO Get Credentials
# node: Node 14, Node 16
# yarn: Yarn with node 14 and 16
# serverless: Serverless Framework CLI
# terraform: Terraform CLI
# speedtest: Ookla Speedtest CLI
# EXIT: To leave this menu
==============================================================
EOF
}

show_begin() {
    cat <<EOF
==============================================================
                  Tooling Dev CLI Setup
==============================================================
  Hope you enjoy it! :D
==============================================================
  Note: Aliases may be created in '~/.zshrc' file...
==============================================================
  Note: Symbolic links may be created in '/usr/local/bin/' folder...
==============================================================
  Warning: Root access may be needed.
==============================================================
  GitHub: https://github.com/Tooling-Dev/cli
==============================================================

EOF
}

install_aws() {
    sudo ln -sf ${BASEDIR}/bin/aws /usr/local/bin/aws
    show_msg "Activating aws..."

    echo "alias aws-get-session-token=\"${BASEDIR}/bin/aws-get-session-token \"" >>~/.zshrc
    show_msg "Activating aws-get-session-token..."

    echo "alias aws-sso=\"${BASEDIR}/bin/aws-sso \"" >>~/.zshrc
    show_msg "Activating aws-sso..."

    sudo ln -sf ${BASEDIR}/bin/aws-sso-cred /usr/local/bin/aws-sso-cred
    show_msg "Activating aws-sso-cred..."
}

install_node() {
    sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/node
    show_msg "Activating node..."

    sudo ln -sf ${BASEDIR}/bin/node14 /usr/local/bin/node14
    show_msg "Activating node14..."
}

install_yarn() {
    sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/yarn
    show_msg "Activating yarn..."

    sudo ln -sf ${BASEDIR}/bin/yarn14 /usr/local/bin/yarn14
    show_msg "Activating yarn14..."
}

install_serverless() {
    sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/serverless
    show_msg "Activating serverless..."
}

install_terraform() {
    sudo ln -sf ${BASEDIR}/bin/terraform /usr/local/bin/terraform
    show_msg "Activating terraform..."
}

install_speedtest() {
    sudo ln -sf ${BASEDIR}/bin/speedtest /usr/local/bin/speedtest
    show_msg "Activating speedtest..."
}

install_all() {
    install_aws
    install_node
    install_yarn
    install_serverless
    install_terraform
    install_speedtest
}

# Main

show_begin

PS3="Choose an option: "
select opt in ALL aws node yarn serverless terraform speedtest EXIT; do
    case ${opt} in
    ALL) install_all ;;
    aws) install_aws ;;
    node) install_node ;;
    yarn) install_yarn ;;
    serverless) install_serverless ;;
    terraform) install_terraform ;;
    speedtest) install_speedtest ;;
    EXIT) show_msg "Bye o/" ;;
    *) show_help "Error: incorrect option." && exit 2 ;;
    esac
    break
done

# End

show_msg "Thanks for using Tooling Dev CLI ;)"
