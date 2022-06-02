FROM amazonlinux:latest

LABEL Author: David Cardoso <dev@davidcardoso.me>

ENV NODE_VERSION=16

# include aws exec in the PATH env var
ENV PATH=$PATH:/root/.local/bin/

# Add AWS CLI
RUN yum install -y python-pip groff zip unzip jq bc &&\
    pip install --user awscli &&\
    # Add NodeJS + Yarn
    yum install -y curl &&\
    curl -sL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - &&\
    curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo &&\
    yum install -y yarn &&\
    # Add SSO Cred
    yarn global add aws-sso-credentials-getter

ENTRYPOINT [ "/bin/bash" ]
