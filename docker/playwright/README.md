# Playwright via Docker

Docker image providing Playwright with Chromium pre-installed. No manual browser installation step required at runtime.

- [Official documentation](https://playwright.dev/docs/docker)
- [Microsoft Playwright Docker](https://mcr.microsoft.com/product/playwright/about)

## Docker Image

**Registry:** `ghcr.io/my-ez-cli`
**Image:** `ghcr.io/my-ez-cli/playwright:latest`
**Base Image:** `mcr.microsoft.com/playwright:v1.44.0-jammy`
**Platforms:** linux/amd64, linux/arm64

## Building the Docker Image

### Using the build script

```bash
cd docker/playwright

# Build with default settings
./build

# Build with custom tag
IMAGE_TAG=1.0.0 ./build

# Build for specific platform
PLATFORM=linux/amd64 ./build
```

### Manual Docker build

```bash
cd docker/playwright

docker buildx build --platform linux/amd64 \
  --tag ghcr.io/my-ez-cli/playwright:latest \
  --load .
```

## Usage

Once installed (`mec install playwright`), use it like a regular binary:

```bash
playwright test                    # run all tests
playwright test --headed           # run with browser UI
playwright test src/foo.spec.ts    # run a specific test file
playwright --version               # show version
playwright codegen https://example.com  # record a test
```

The `playwright` wrapper passes all arguments directly to `npx playwright` inside the container, with your current directory mounted at `/app`.

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MEC_BIND_PORTS` | Port binding (format: `host:container`) | — | No |

## Notes

- Chromium is pre-installed in the image — no `npx playwright install chromium` needed
- Your project must have `@playwright/test` in `node_modules` (install with `npm install`)
- The container mounts `$PWD` at `/app` and runs with `--network=host --ipc=host`
