#!/bin/bash
set -e

BASEDIR=$(cd $(dirname "${0}") && pwd)

# Helpers

show_msg() {
    cat <<EOF
--------------------------------------------------------------------------------
$1
--------------------------------------------------------------------------------
EOF
}

show_help() {
    show_msg "$1"

    cat <<EOF
--------------------------------------------------------------------------------
Usage examples:
${BASEDIR}/setup.sh <OPTION>

Type the number of the OPTION:
# ALL: To activate all options
# aws: AWS CLI, AWS Get Session Token, AWS SSO, AWS SSO Get Credentials
# cdktf: AWS Cloud Development Kit for Terraform
# terraform: Terraform CLI
# gcloud: Google Cloud CLI
# node: Node 14, 16, 18, and 20 (default)
# yarn: Yarn classic with Node 14, 16, 18, and 20 (default)
# yarn-berry: Yarn Berry (v2+)
# serverless: Serverless Framework CLI
# speedtest: Ookla Speedtest CLI
# docker-compose-viz: Graph Viz for docker compose
# playwright: End-to-end testing for web apps
# EXIT: To leave this menu
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
    show_msg "Activating node (v20)..."
    sudo ln -sf ${BASEDIR}/bin/node /usr/local/bin/node

    show_msg "Activating node14..."
    sudo ln -sf ${BASEDIR}/bin/node14 /usr/local/bin/node14

    show_msg "Activating node16..."
    sudo ln -sf ${BASEDIR}/bin/node16 /usr/local/bin/node16

    show_msg "Activating node18..."
    sudo ln -sf ${BASEDIR}/bin/node18 /usr/local/bin/node18
}

install_yarn() {
    show_msg "Activating yarn (using node v20)..."
    sudo ln -sf ${BASEDIR}/bin/yarn /usr/local/bin/yarn

    show_msg "Activating yarn14..."
    sudo ln -sf ${BASEDIR}/bin/yarn14 /usr/local/bin/yarn14

    show_msg "Activating yarn16..."
    sudo ln -sf ${BASEDIR}/bin/yarn16 /usr/local/bin/yarn16

    show_msg "Activating yarn18..."
    sudo ln -sf ${BASEDIR}/bin/yarn18 /usr/local/bin/yarn18
}

install_serverless() {
    show_msg "Activating serverless..."
    sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/serverless
    sudo ln -sf ${BASEDIR}/bin/serverless /usr/local/bin/sls
    show_msg "> You can use 'serverless' or just 'sls' alias."
}

install_terraform() {
    sudo ln -sf ${BASEDIR}/bin/terraform /usr/local/bin/terraform
    show_msg "Activating terraform..."
}

install_speedtest() {
    sudo ln -sf ${BASEDIR}/bin/speedtest /usr/local/bin/speedtest
    show_msg "Activating speedtest..."
}

install_gcloud() {
    sudo ln -sf ${BASEDIR}/bin/gcloud-login /usr/local/bin/gcloud-login
    show_msg "Activating gcloud-login..."

    sudo ln -sf ${BASEDIR}/bin/gcloud /usr/local/bin/gcloud
    show_msg "Activating gcloud..."
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
}

install_docker-compose-viz() {
    show_msg "Activating docker-compose-viz..."
    sudo ln -sf ${BASEDIR}/bin/docker-compose-viz /usr/local/bin/docker-compose-viz
}

install_playwright() {
    show_msg "Activating playwright..."
    sudo ln -sf ${BASEDIR}/bin/playwright /usr/local/bin/playwright
}

install_cdktf() {
    show_msg "Activating cdktf..."
    sudo ln -sf ${BASEDIR}/bin/cdktf /usr/local/bin/cdktf
}

install_all() {
    install_aws
    install_node
    install_yarn
    install_yarn-berry
    install_serverless
    install_terraform
    install_speedtest
    install_gcloud
    install_docker-compose-viz
    install_playwright
    install_cdktf
}

# Main

show_begin

PS3="Choose an option: "
select opt in ALL aws terraform cdktf gcloud node yarn yarn-berry serverless speedtest docker-compose-viz playwright EXIT; do
    case ${opt} in
    ALL) install_all ;;
    aws) install_aws ;;
    terraform) install_terraform ;;
    cdktf) install_cdktf ;;
    gcloud) install_gcloud ;;
    node) install_node ;;
    yarn) install_yarn ;;
    yarn-berry) install_yarn-berry ;;
    serverless) install_serverless ;;
    speedtest) install_speedtest ;;
    docker-compose-viz) install_docker-compose-viz ;;
    playwright) install_playwright ;;
    cdktf) install_cdktf ;;
    EXIT) show_msg "Bye o/" ;;
    *) show_help "Error: incorrect option." && exit 2 ;;
    esac
    break
done

# TODO: add 'uninstall' option

show_msg "> If you want to check and/or adapt how each script is being executed, just check them inside '${BASEDIR}/bin/' folder."

show_msg "> For more info, check the README."

# End

show_msg "Thanks for using My Ez CLI ;)"
