FROM alpine:3.23

ARG YARN_VERSION=4.14.1

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="yarn-berry" \
      org.opencontainers.image.title="My Ez CLI - Yarn Berry" \
      org.opencontainers.image.description="Yarn Berry (v4+) package manager" \
      org.opencontainers.image.authors="David Cardoso <dev+github@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

# Install runtime dependencies.
# npm is needed only to install corepack (not bundled in Alpine's nodejs package)
# and is removed afterwards.
# hadolint ignore=DL3018
RUN apk add --no-cache \
    bash \
    git \
    ca-certificates \
    nodejs \
    npm \
    && npm install -g corepack@0.34.7 \
    && corepack enable \
    && corepack prepare yarn@${YARN_VERSION} --activate \
    && apk del npm

# Set working directory
WORKDIR /app

ENTRYPOINT [ "yarn" ]
