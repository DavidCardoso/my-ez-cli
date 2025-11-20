FROM node:24-alpine

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="aws-sso-cred" \
      org.opencontainers.image.title="My Ez CLI - AWS SSO Cred" \
      org.opencontainers.image.description="AWS SSO credentials getter wrapper" \
      org.opencontainers.image.authors="David Cardoso <dev@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

ARG AWS_CLI_VERSION=2.15.0

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    groff \
    zip \
    unzip \
    jq \
    ca-certificates

# Install AWS CLI v2 (static binary)
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

# Install aws-sso-credentials-getter
RUN npm install --global --no-audit --no-fund aws-sso-credentials-getter

ENTRYPOINT [ "/bin/bash" ]
