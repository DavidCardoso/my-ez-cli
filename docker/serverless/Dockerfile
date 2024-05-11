FROM amazonlinux:latest

LABEL Author: David Cardoso <dev+github@davidcardoso.me>

ENV NODE_VERSION=20
ENV SERVERLESS_VERSION=3.38.0

# include aws exec in the PATH env var
ENV PATH=$PATH:/root/.local/bin/

# Add AWS CLI
RUN yum install -y python-pip groff zip unzip jq bc &&\
    pip install --user awscli &&\
    # Add NodeJS + Yarn
    curl -sL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - &&\
    curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo &&\
    yum install -y yarn &&\
    # Add Serverless Framework
    yarn global add serverless@${SERVERLESS_VERSION}

ENTRYPOINT [ "serverless" ]
