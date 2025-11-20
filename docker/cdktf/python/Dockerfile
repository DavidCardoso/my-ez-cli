# Multi-stage build for optimized image size and build time
ARG TF_VERSION=1.13.0
ARG PYTHON_VERSION=3.12

# Stage 1: Build Node.js dependencies
FROM node:24-alpine AS node-builder

# Pin CDKTF version for reproducible builds (update as needed)
# Using a specific version avoids breaking changes and improves build cache hits
ARG CDKTF_VERSION=0.21.0

# Install build dependencies for native modules and create python symlink
RUN apk add --no-cache \
    python3 \
    make \
    g++ && \
    ln -sf python3 /usr/bin/python

# Install CDKTF globally
# Note: --prefer-offline and --no-audit speed up installation
RUN npm install --global --no-audit --no-fund cdktf-cli@${CDKTF_VERSION}

# Stage 2: Final image
FROM hashicorp/terraform:${TF_VERSION}

LABEL com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="cdktf" \
      org.opencontainers.image.title="My Ez CLI - CDKTF" \
      org.opencontainers.image.description="CDK for Terraform with Python support" \
      org.opencontainers.image.authors="David Cardoso <dev+github@davidcardoso.me>" \
      org.opencontainers.image.source="https://github.com/davidcardoso/my-ez-cli"

ARG PYTHON_VERSION

# Install runtime dependencies (Python, Node.js, and required libraries)
RUN apk add --no-cache \
    bash \
    curl \
    nodejs \
    npm \
    python3~=${PYTHON_VERSION} \
    py3-pip \
    && ln -sf python3 /usr/bin/python

# Copy Node.js global packages from builder stage
COPY --from=node-builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node-builder /usr/local/bin/cdktf /usr/local/bin/cdktf

# Install pipenv (required by cdktf to initialize python templates)
ENV PIP_ROOT_USER_ACTION=ignore \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    LANG=en_US.UTF-8

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir pipenv

ENTRYPOINT [ "cdktf" ]
