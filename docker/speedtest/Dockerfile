FROM alpine:3.20

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="speedtest" \
      org.opencontainers.image.title="My Ez CLI - Speedtest" \
      org.opencontainers.image.description="Ookla Speedtest CLI" \
      org.opencontainers.image.authors="David Cardoso <dev+github@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

ARG VERSION=1.2.0

# Install speedtest binary only
RUN apk add --no-cache ca-certificates && \
    apk add --no-cache --virtual .build-deps tar curl && \
    ARCH=$(apk info --print-arch) && \
    case "$ARCH" in \
    x86)    _arch=i386      ;; \
    armv7)  _arch=armhf     ;; \
    *)      _arch="$ARCH"   ;; \
    esac && \
    curl -sSL https://install.speedtest.net/app/cli/ookla-speedtest-${VERSION}-linux-${_arch}.tgz | tar xz -C /tmp && \
    mv /tmp/speedtest /usr/local/bin/ && \
    chmod +x /usr/local/bin/speedtest && \
    rm -rf /tmp/* && \
    apk del .build-deps

ENTRYPOINT ["/usr/local/bin/speedtest", "--accept-license", "--accept-gdpr"]
