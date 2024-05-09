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
# yarn-berry: Yarn Berry (v2+)
# serverless: Serverless Framework CLI
# terraform: Terraform CLI
# speedtest: Ookla Speedtest CLI
# gcloud: Google Cloud CLI
# docker-compose-viz: Graph Viz for docker compose
# EXIT: To leave this menu
==============================================================
EOF
}

show_begin() {
    cat <<EOF
==============================================================
                  My Ez CLI • Setup
==============================================================
  Hope you enjoy it! :D
==============================================================
  Note: Aliases may be created in '~/.zshrc' file...
==============================================================
  Note: Symbolic links may be created in '/usr/local/bin/' folder...
==============================================================
  Warning: Root access may be needed.
==============================================================
  GitHub: https://github.com/My-Tooling/my-ez-cli
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
    sudo ln -sf ${BASEDIR}/bin/docker-compose-viz /usr/local/bin/docker-compose-viz
    show_msg "Activating docker-compose-viz..."
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
}

# Main

show_begin

PS3="Choose an option: "
select opt in ALL aws node yarn yarn-berry serverless terraform speedtest gcloud docker-compose-viz EXIT; do
    case ${opt} in
    ALL) install_all ;;
    aws) install_aws ;;
    node) install_node ;;
    yarn) install_yarn ;;
    yarn-berry) install_yarn-berry ;;
    serverless) install_serverless ;;
    terraform) install_terraform ;;
    speedtest) install_speedtest ;;
    gcloud) install_gcloud ;;
    docker-compose-viz) install_docker-compose-viz ;;
    EXIT) show_msg "Bye o/" ;;
    *) show_help "Error: incorrect option." && exit 2 ;;
    esac
    break
done

# End

show_msg "Thanks for using My Ez CLI ;)"
