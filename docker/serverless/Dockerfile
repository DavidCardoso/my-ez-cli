FROM node:25-alpine

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="serverless" \
      org.opencontainers.image.title="My Ez CLI - Serverless Framework" \
      org.opencontainers.image.description="Serverless Framework with AWS CLI and Node.js" \
      org.opencontainers.image.authors="David Cardoso <dev+github@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

ARG MEC_SERVERLESS_VERSION=4.33.0
ARG AWS_CLI_VERSION=2.15.0

# Install runtime dependencies
# hadolint ignore=DL3018
RUN apk add --no-cache \
    bash \
    groff \
    zip \
    unzip \
    jq \
    ca-certificates

# Install AWS CLI v2 (static binary)
# hadolint ignore=DL3018,DL3059,SC2086
RUN apk add --no-cache --virtual .build-deps curl && \
    ARCH=$(apk info --print-arch) && \
    case "$ARCH" in \
    aarch64) AWS_ARCH=aarch64 ;; \
    *)       AWS_ARCH=x86_64  ;; \
    esac && \
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWS_CLI_VERSION}.zip" -o awscliv2.zip && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip && \
    apk del .build-deps

# Install Serverless Framework
# hadolint ignore=DL3016,DL3059
RUN npm install --global --no-audit --no-fund serverless@${MEC_SERVERLESS_VERSION}

ENTRYPOINT [ "serverless" ]
