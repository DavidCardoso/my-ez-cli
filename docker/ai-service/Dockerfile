FROM python:3.14-alpine

# Metadata
LABEL com.my-ez-cli.project="my-ez-cli"
LABEL com.my-ez-cli.component="ai-service"
LABEL com.my-ez-cli.version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/DavidCardoso/my-ez-cli"
LABEL org.opencontainers.image.description="I/O filtering and middleware service for My Ez CLI"
LABEL org.opencontainers.image.licenses="MIT"

# Set working directory
WORKDIR /app

# Install Poetry
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir poetry==1.8.4

# Copy Poetry files for dependency installation
COPY pyproject.toml poetry.lock* ./

# Configure Poetry to not create virtual environment (we're already in a container)
# Install production dependencies + dev dependencies for testing
RUN poetry config virtualenvs.create false && \
    poetry install --no-root --no-interaction --no-ansi

# Copy application code
COPY src/ ./src/

# Copy tests for running pytest
COPY tests/ ./tests/

# Create non-root user for security
RUN addgroup -g 1000 mecai && \
    adduser -D -u 1000 -G mecai mecai && \
    chown -R mecai:mecai /app

# Switch to non-root user
USER mecai

# Set Python path
ENV PYTHONPATH=/app

# Entry point
ENTRYPOINT ["python", "-m", "src.main"]

# Default command (show help)
CMD ["--help"]
