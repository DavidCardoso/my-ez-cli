FROM python:3.12-alpine

LABEL org.opencontainers.image.title="mec-dashboard" \
      org.opencontainers.image.description="My Ez CLI — log and AI analysis dashboard" \
      org.opencontainers.image.source="https://github.com/DavidCardoso/my-ez-cli" \
      com.my-ez-cli.project="my-ez-cli" \
      com.my-ez-cli.tool="dashboard"

WORKDIR /app

# Install dependencies — watchfiles has binary wheels for manylinux; prefer them
RUN pip install --no-cache-dir --prefer-binary \
    fastapi==0.115.12 \
    "uvicorn[standard]==0.34.0" \
    watchfiles==1.0.5

COPY src/ ./src/

# /data is mounted from ~/.my-ez-cli on the host (read-only)
VOLUME ["/data"]

EXPOSE 4242

ENV MEC_DATA_ROOT=/data

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "4242"]
