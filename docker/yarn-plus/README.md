# Yarn Plus via Docker

Docker image providing Yarn package manager with extra system tools pre-installed. Unlike the standard Yarn wrapper (which uses the official `node` image), Yarn Plus includes `git`, `curl`, `jq`, and other utilities needed by tools like [Projen](https://github.com/projen/projen) that run package scripts requiring git access.

- [Yarn Documentation](https://classic.yarnpkg.com/)
- [Projen](https://github.com/projen/projen)

## Docker Image

**Repository:** `davidcardoso/my-ez-cli`
**Tag:** `yarn-plus-latest`
**Base Image:** `node:{NODE_VERSION}-alpine` (default: `node:22-alpine`)
**Extra tools:** `bash`, `git`, `ca-certificates`, `openssl`, `curl`, `jq`
**Platforms:** linux/amd64, linux/arm64

## Building the Docker Image

### Using the build script

```bash
cd docker/yarn-plus

# Build with default settings (IMAGE_TAG=latest, NODE_VERSION=22)
./build

# Build with custom tag
IMAGE_TAG=1.0.0 ./build

# Build with a different Node.js version
NODE_VERSION=20 ./build

# Build for specific platform
PLATFORM=linux/amd64 ./build
```

### Manual Docker build

```bash
cd docker/yarn-plus

# Single platform (local use)
docker buildx build --platform linux/amd64 \
  --build-arg NODE_VERSION=22 \
  --tag davidcardoso/my-ez-cli:yarn-plus-latest \
  --load .

# Multi-platform (push to registry)
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg NODE_VERSION=22 \
  --tag davidcardoso/my-ez-cli:yarn-plus-latest \
  --push .
```

## Build Arguments

| Argument       | Description              | Default |
| -------------- | ------------------------ | ------- |
| `NODE_VERSION` | Node.js major version    | `22`    |

## Environment Variables

| Variable                      | Description                                              | Default              | Required |
| ----------------------------- | -------------------------------------------------------- | -------------------- | -------- |
| `NPM_TOKEN`                   | Authentication token for private NPM registries          | -                    | No       |
| `NPMRC_FILE`                  | Path to .npmrc configuration file                        | `$HOME/.npmrc`       | No       |
| `YARNRC_FILE`                 | Path to .yarnrc.yml configuration file                   | `$HOME/.yarnrc.yml`  | No       |
| `YARN_CACHE_FOLDER`           | Host cache folder path                                   | `$HOME/.cache/yarn/` | No       |
| `CONTAINER_YARN_CACHE_FOLDER` | Container cache path                                     | `/root/.cache/yarn/` | No       |
| `MEC_BIND_PORTS`              | Port binding (format: "host:container host2:container2") | -                    | No       |

## Usage Examples

### Basic Usage

```bash
# Check version
yarn-plus --version

# Initialize a new project
yarn-plus init

# Install dependencies
yarn-plus install

# Add a package
yarn-plus add lodash

# Add dev dependency
yarn-plus add --dev jest

# Run scripts (git available inside container)
yarn-plus run build
yarn-plus test
```

### With Projen

Projen generates project configuration and runs scripts that may call `git` internally. Use `yarn-plus` instead of `yarn` for these workflows:

```bash
# Initialize a projen project
yarn-plus dlx projen new typescript

# Synthesize and run projen tasks (git available)
yarn-plus projen
yarn-plus projen build
```

### With NPM Token (Private Registries)

```bash
# One-time usage
NPM_TOKEN=your-token-here yarn-plus install

# Or export for session
export NPM_TOKEN=your-token-here
yarn-plus install
yarn-plus add @private-org/package
```

### With Port Binding (Development Servers)

```bash
# Bind single port
MEC_BIND_PORTS="3000:3000" yarn-plus dev

# Bind multiple ports
MEC_BIND_PORTS="3000:3000 8080:8080" yarn-plus start
```

### With Custom Configuration Paths

```bash
# Custom .npmrc location
NPMRC_FILE=/path/to/custom/.npmrc yarn-plus install

# Custom .yarnrc.yml location
YARNRC_FILE=/path/to/custom/.yarnrc.yml yarn-plus install

# Custom cache folder
YARN_CACHE_FOLDER=/tmp/yarn-cache yarn-plus install
```

## What's Different from `yarn`

| Feature              | `yarn`                    | `yarn-plus`                        |
| -------------------- | ------------------------- | ---------------------------------- |
| Base image           | `node:24-alpine` (slim)   | `node:22-alpine` + extra tools     |
| `git` available      | No                        | Yes                                |
| `curl` available     | No                        | Yes                                |
| `jq` available       | No                        | Yes                                |
| Use case             | Standard package installs | Tools that need git or shell utils |

## CI/CD Integration

The Docker image is automatically built and published via GitHub Actions:

- **Trigger:** Push to main, pull requests, releases, manual dispatch
- **Platforms:** linux/amd64, linux/arm64
- **Registry:** Docker Hub (`davidcardoso/my-ez-cli:yarn-plus-latest`)
- **Workflow:** `.github/workflows/docker-build-yarn-plus.yml`

## Troubleshooting

### Git operations failing

`yarn-plus` includes `git` inside the container, but git operations that require host SSH keys (e.g., private git dependencies) need the key mounted:

```bash
# Mount your SSH key for private git dependencies
docker run --rm -it \
  --volume $HOME/.ssh:/root/.ssh:ro \
  --volume $PWD:/app \
  --workdir /app \
  davidcardoso/my-ez-cli:yarn-plus-latest install
```

### Authentication Issues

```bash
# Verify .npmrc is properly configured
cat ~/.npmrc

# Verify NPM_TOKEN is set
echo $NPM_TOKEN
```

### Cache Issues

```bash
# Clear Yarn cache
rm -rf ~/.cache/yarn

# Clear node_modules and reinstall
rm -rf node_modules
yarn-plus install
```

## Related Resources

- [Yarn Classic Documentation](https://classic.yarnpkg.com/docs)
- [Projen Documentation](https://projen.io/)
- [My Ez CLI Documentation](../../README.md)
