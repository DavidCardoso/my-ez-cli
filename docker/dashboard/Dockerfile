# ===========================================================================
# Stage 1: Build Vue 3 + PrimeVue frontend
# ===========================================================================
FROM node:22-alpine AS frontend-builder

WORKDIR /frontend

# Copy registry config and package manifest (no lockfile — let npm resolve
# optional native deps for the current platform, e.g. rollup-linux-x64-musl)
COPY frontend/.npmrc frontend/package.json ./
RUN npm install

# Copy source and build — output lands in /frontend/dist/
COPY frontend/ ./
RUN npx vite build

# ===========================================================================
# Stage 2: Python / FastAPI runtime
# ===========================================================================
FROM python:3.12-alpine

LABEL org.opencontainers.image.title="mec-dashboard" \
      org.opencontainers.image.description="My Ez CLI — log and AI analysis dashboard" \
      org.opencontainers.image.source="https://github.com/DavidCardoso/my-ez-cli" \
      com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="dashboard"

WORKDIR /app

# Install Poetry
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir poetry==1.8.4

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Install all deps (including dev for tests) — no virtualenv in container
RUN poetry config virtualenvs.create false && \
    poetry install --no-root --no-interaction --no-ansi

# Copy FastAPI source and tests
COPY src/ ./src/
COPY tests/ ./tests/

# Copy built Vue app into the static directory FastAPI serves
COPY --from=frontend-builder /frontend/dist/ ./src/static/

# /data is mounted from ~/.my-ez-cli on the host (read-only)
VOLUME ["/data"]

EXPOSE 4242

ENV MEC_DATA_ROOT=/data

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "4242"]
