ARG MEC_PLAYWRIGHT_BASE_TAG=v1.59.1-jammy
FROM mcr.microsoft.com/playwright:${MEC_PLAYWRIGHT_BASE_TAG}

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="playwright" \
      org.opencontainers.image.title="My Ez CLI - Playwright" \
      org.opencontainers.image.description="Playwright testing with Chromium pre-installed" \
      org.opencontainers.image.authors="David Cardoso <dev+github@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

WORKDIR /app

# Pre-install Chromium browser so the image is self-sufficient.
# No manual 'npx playwright install chromium' step needed at runtime.
RUN npx playwright install chromium

ENTRYPOINT ["npx", "playwright"]
