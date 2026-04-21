FROM node:24-alpine

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="yarn-berry" \
      org.opencontainers.image.title="My Ez CLI - Yarn Berry" \
      org.opencontainers.image.description="Yarn Berry (v4+) package manager" \
      org.opencontainers.image.authors="David Cardoso <dev+github@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    git \
    ca-certificates

# Enable corepack so `yarn` dispatches through the version manager
RUN corepack enable

# Set working directory
WORKDIR /app

ENTRYPOINT [ "yarn" ]
