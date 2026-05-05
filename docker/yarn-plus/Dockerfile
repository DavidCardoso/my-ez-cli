ARG MEC_YARN_PLUS_VERSION=${MEC_YARN_PLUS_VERSION:-22}

FROM node:${MEC_YARN_PLUS_VERSION}-alpine

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="yarn-plus" \
      org.opencontainers.image.title="My Ez CLI - Yarn Plus" \
      org.opencontainers.image.description="Yarn package manager with additional tools" \
      org.opencontainers.image.authors="David Cardoso <dev+github@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

# Install runtime dependencies
# hadolint ignore=DL3018
RUN apk add --no-cache \
    bash \
    git \
    ca-certificates \
    openssl \
    curl \
    jq \
    && rm -rf /var/cache/apk/*

# Set working directory
WORKDIR /app

ENTRYPOINT [ "yarn" ]
