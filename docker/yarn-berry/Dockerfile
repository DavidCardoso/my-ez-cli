FROM node:24-alpine

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="yarn-berry" \
      org.opencontainers.image.title="My Ez CLI - Yarn Berry" \
      org.opencontainers.image.description="Yarn Berry (v4+) package manager" \
      org.opencontainers.image.authors="David Cardoso <dev+github@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

ARG YARN_VERSION=4.12.0

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    git \
    ca-certificates

# Enable corepack and set Yarn version
RUN corepack enable && \
    corepack prepare yarn@${YARN_VERSION} --activate

# Create cache directory for Yarn
RUN mkdir -p /root/.cache/yarn && \
    chmod -R 777 /root/.cache/yarn

# Set working directory
WORKDIR /app

ENTRYPOINT [ "yarn" ]
