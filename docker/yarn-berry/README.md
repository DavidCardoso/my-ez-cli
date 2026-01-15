# Yarn Berry (v4+) via Docker

Docker image providing Yarn Berry (v4+) package manager with full authentication and caching support.

- [GitHub Yarn Berry](https://github.com/yarnpkg/berry)
- [Yarn Berry Documentation](https://yarnpkg.com/)

## Docker Image

**Repository:** `davidcardoso/my-ez-cli`
**Tag:** `yarn-berry-latest`
**Base Image:** `node:24-alpine`
**Yarn Version:** 4.12.0
**Platforms:** linux/amd64, linux/arm64

## Building the Docker Image

### Using the build script

```bash
cd docker/yarn-berry

# Build with default settings (IMAGE_TAG=latest, YARN_VERSION=4.12.0)
./build

# Build with custom tag
IMAGE_TAG=1.0.0 ./build

# Build with custom Yarn version
YARN_VERSION=4.6.0 ./build

# Build for specific platform
PLATFORM=linux/amd64 ./build
```

### Manual Docker build

```bash
cd docker/yarn-berry

# Single platform
docker buildx build --platform linux/amd64 \
  --build-arg YARN_VERSION=4.12.0 \
  --tag davidcardoso/my-ez-cli:yarn-berry-latest \
  --load .

# Multi-platform
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg YARN_VERSION=4.12.0 \
  --tag davidcardoso/my-ez-cli:yarn-berry-latest \
  --push .
```

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
yarn-berry --version

# Initialize a new project
yarn-berry init

# Install dependencies
yarn-berry install

# Add a package
yarn-berry add lodash

# Add dev dependency
yarn-berry add --dev jest

# Run scripts
yarn-berry run build
yarn-berry test
```

### With NPM Token (Private Registries)

#### Method 1: Environment variable

```bash
# One-time usage
NPM_TOKEN=your-token-here yarn-berry install

# Or export for session
export NPM_TOKEN=your-token-here
yarn-berry install
yarn-berry add @private-org/package
```

#### Method 2: .npmrc configuration

```bash
# Create/edit ~/.npmrc
cat > ~/.npmrc << EOF
registry=https://private.npm.registry.com/
//private.npm.registry.com/:_authToken=\${NPM_TOKEN}
EOF

# Use yarn-berry (automatically mounts ~/.npmrc)
export NPM_TOKEN=your-token-here
yarn-berry install
```

### With Port Binding (Development Servers)

```bash
# Bind single port
MEC_BIND_PORTS="3000:3000" yarn-berry dev

# Bind multiple ports
MEC_BIND_PORTS="3000:3000 8080:8080" yarn-berry start

# Or export for session
export MEC_BIND_PORTS="3000:3000"
yarn-berry dev
```

### With Custom Configuration Paths

```bash
# Custom .npmrc location
NPMRC_FILE=/path/to/custom/.npmrc yarn-berry install

# Custom .yarnrc.yml location
YARNRC_FILE=/path/to/custom/.yarnrc.yml yarn-berry install

# Custom cache folder
YARN_CACHE_FOLDER=/tmp/yarn-cache yarn-berry install
```

## Cache Performance

The yarn-berry wrapper automatically mounts the Yarn cache folder for improved performance:

```bash
# First install (downloads packages to cache)
yarn-berry install
# ➤ YN0000: ... Fetch step (5.2s)
# ➤ YN0000: Done in 15s

# Subsequent installs (uses cache - much faster)
rm -rf node_modules
yarn-berry install
# ➤ YN0000: ... Fetch step (0.3s)
# ➤ YN0000: Done in 2s
```

**Cache Location:**
- Host: `$HOME/.cache/yarn/` (customizable via `YARN_CACHE_FOLDER`)
- Container: `/root/.cache/yarn/` (customizable via `CONTAINER_YARN_CACHE_FOLDER`)

## Configuration Files

The wrapper automatically creates and mounts configuration files if they don't exist:

- **~/.npmrc** - NPM registry authentication and settings
- **~/.yarnrc.yml** - Yarn Berry configuration
- **~/.cache/yarn/** - Yarn cache directory

These files are automatically mounted into the container at:
- `/root/.npmrc`
- `/root/.yarnrc.yml`
- `/root/.cache/yarn/`

## Yarn Classic vs Yarn Berry

You can use both Yarn Classic (`yarn`) and Yarn Berry (`yarn-berry`) simultaneously:

- **Yarn Classic** (v1.x): Use the `yarn` command
- **Yarn Berry** (v4.x): Use the `yarn-berry` command

Choose which to install during the setup process: `./setup.sh`

## CI/CD Integration

The Docker image is automatically built and published via GitHub Actions:

- **Trigger:** Push to main, pull requests, releases, manual dispatch, weekly schedule
- **Platforms:** linux/amd64, linux/arm64
- **Registry:** Docker Hub (`davidcardoso/my-ez-cli:yarn-berry-latest`)
- **Security:** Trivy vulnerability scanning
- **Workflow:** `.github/workflows/docker-build-yarn-berry.yml`

## Troubleshooting

### Authentication Issues

```bash
# Verify .npmrc is properly configured
cat ~/.npmrc

# Verify NPM_TOKEN is set
echo $NPM_TOKEN

# Test authentication
NPM_TOKEN=your-token yarn-berry npm whoami
```

### Cache Issues

```bash
# Clear Yarn cache
rm -rf ~/.cache/yarn

# Clear node_modules and reinstall
rm -rf node_modules
yarn-berry install
```

### Port Binding Not Working

```bash
# Verify port binding syntax
MEC_BIND_PORTS="3000:3000" yarn-berry dev

# Check if port is already in use
lsof -i :3000
```

## Related Resources

- [Yarn Berry Migration Guide](https://yarnpkg.com/getting-started/migration)
- [Yarn Berry Configuration](https://yarnpkg.com/configuration/yarnrc)
- [My Ez CLI Documentation](../../README.md)
