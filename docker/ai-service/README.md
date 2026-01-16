# AI Service (I/O Middleware) via Docker

Docker image providing the My Ez CLI AI middleware service — a lightweight Python layer for I/O filtering and token optimization. It acts as a pre-processing step between tool output and Claude Code, removing noise to reduce token usage.

This service does **not** perform AI analysis. All analysis goes through Claude Code. See [AI_INTEGRATION.md](../../docs/AI_INTEGRATION.md) for the full architecture.

## Docker Image

**Repository:** `davidcardoso/my-ez-cli`
**Tag:** `ai-service-latest`
**Base Image:** `python:3.14-alpine`
**Platforms:** linux/amd64, linux/arm64

## Building the Docker Image

The build script uses the `services/ai/` directory as the build context (not `docker/ai-service/`), because the application source lives there.

### Using the build script

```bash
cd docker/ai-service

# Build with default settings (IMAGE_TAG=latest)
./build

# Build with custom tag
IMAGE_TAG=1.0.0 ./build

# Build for specific platform
PLATFORM=linux/amd64 ./build
```

### Manual Docker build

```bash
# Build from repo root — context is services/ai/
docker buildx build --platform linux/amd64 \
  --file docker/ai-service/Dockerfile \
  --tag davidcardoso/my-ez-cli:ai-service-latest \
  --load \
  services/ai/
```

## Available Commands

```
filter <text|->   Filter output using configured patterns (reads stdin if "-")
--help, -h        Show help
--version, -v     Show version
```

## Usage Examples

### Filter noisy output

```bash
# Filter from stdin (pipe tool output through the service)
echo "npm warn deprecated some-package" | docker run --rm -i \
  davidcardoso/my-ez-cli:ai-service-latest \
  filter -

# Filter inline text
docker run --rm \
  davidcardoso/my-ez-cli:ai-service-latest \
  filter "noisy output text here"
```

### Show version / help

```bash
docker run --rm davidcardoso/my-ez-cli:ai-service-latest --version
docker run --rm davidcardoso/my-ez-cli:ai-service-latest --help
```

## Running Tests

```bash
# Run all tests
docker run --rm --entrypoint python \
  davidcardoso/my-ez-cli:ai-service-latest \
  -m pytest tests/ -v

# Run filter engine tests only
docker run --rm --entrypoint python \
  davidcardoso/my-ez-cli:ai-service-latest \
  -m pytest tests/test_filter_engine.py -v
```

## Configuration

Filter patterns are configured in `config/config.default.yaml`:

```yaml
ai:
  filters:
    ignore_output:
      - "^npm warn"
      - "^Downloading.*\\d+%"
      - "├──|└──|│"
    ignore_input:
      - "node_modules/"
      - "*.lock"
      - ".git/"
```

Users can override these in `~/.my-ez-cli/config.yaml`.

## CI/CD Integration

The Docker image is automatically built and published via GitHub Actions:

- **Trigger:** Push to main, pull requests, releases, manual dispatch
- **Platforms:** linux/amd64, linux/arm64
- **Registry:** Docker Hub (`davidcardoso/my-ez-cli:ai-service-latest`)
- **Build context:** `services/ai/` (not `docker/ai-service/`)
- **Workflow:** `.github/workflows/docker-build-ai-service.yml`

## Related Resources

- [AI Integration Guide](../../docs/AI_INTEGRATION.md)
- [Code Standards](../../docs/CODE_STANDARDS.md)
- [My Ez CLI Documentation](../../README.md)
