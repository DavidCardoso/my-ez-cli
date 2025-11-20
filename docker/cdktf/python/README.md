# Cloud Development Kit for Terraform (CDKTF) via Docker

Docker image for CDKTF with Python support, combining Terraform, Node.js, Python, and CDKTF CLI in a single container.

- [CDKTF Documentation](https://developer.hashicorp.com/terraform/cdktf)
- [CDKTF Python Guide](https://developer.hashicorp.com/terraform/cdktf/create-and-deploy/python)

## Docker Image

**Repository:** `davidcardoso/my-ez-cli`
**Tag:** `cdktf-latest`
**Base Image:** `hashicorp/terraform:1.13.0`
**CDKTF Version:** 0.21.0
**Platforms:** linux/amd64

> **Note:** ARM64 builds are currently disabled due to QEMU emulation issues with native module compilation during the build process. ARM64 users can run the AMD64 image using Docker's automatic emulation (Rosetta 2 on macOS).

## Contents

- **Terraform:** Official HashiCorp Terraform CLI
- **Node.js 24:** Alpine-based Node.js runtime
- **NPM:** Node package manager
- **CDKTF CLI:** Cloud Development Kit for Terraform
- **Python 3.12:** Python runtime with pip
- **Pipenv:** Python dependency management (required by CDKTF)

## Building the Image

### Using the build script

```bash
cd docker/cdktf/python

# Build with default settings
./build

# Build with custom versions
export TF_VERSION=1.13.0
export CDKTF_VERSION=0.21.0
export PYTHON_VERSION=3.12
./build

# Or inline
TF_VERSION=1.13.0 CDKTF_VERSION=0.21.0 ./build
```

### Manual Docker build

```bash
cd docker/cdktf/python

# Single platform (AMD64)
docker buildx build --platform linux/amd64 \
  --build-arg TF_VERSION=1.13.0 \
  --build-arg CDKTF_VERSION=0.21.0 \
  --build-arg PYTHON_VERSION=3.12 \
  --tag davidcardoso/my-ez-cli:cdktf-latest \
  --load .
```

### Build variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TF_VERSION` | 1.13.0 | Terraform version |
| `CDKTF_VERSION` | 0.21.0 | CDKTF CLI version (pinned for stability) |
| `PYTHON_VERSION` | 3.12 | Python version |

## Usage

```bash
# Initialize a new CDKTF project with Python
mkdir my-cdktf-project
cd my-cdktf-project
cdktf init --template=python --providers=aws@~>4.0

# Synthesize Terraform configuration
cdktf synth

# Deploy infrastructure
cdktf deploy

# Destroy infrastructure
cdktf destroy
```

## Platform Support

### AMD64 (x86_64)
✅ **Fully supported** - Native builds via CI/CD

### ARM64 (Apple Silicon, Graviton)
⚠️ **Limited support** - ARM64 users can run the AMD64 image:

```bash
# Docker automatically uses emulation (Rosetta 2 on macOS)
docker run --platform linux/amd64 davidcardoso/my-ez-cli:cdktf-latest --version
```

**Why no native ARM64 build?**
- CDKTF requires native module compilation (g++, make, Python extensions)
- QEMU emulation of ARM64 during CI builds is extremely slow (6+ hours) and unstable
- The AMD64 image runs efficiently on ARM64 via Docker's emulation layer

**To build ARM64 locally** (if needed):
```bash
# Warning: This may take 30-60 minutes
docker buildx build --platform linux/arm64 \
  --build-arg CDKTF_VERSION=0.21.0 \
  --tag my-ez-cli:cdktf-arm64 \
  --load .
```

## CI/CD Integration

The Docker image is automatically built and published via GitHub Actions:

- **Trigger:** Push to main, pull requests, releases
- **Platform:** linux/amd64 only
- **Registry:** Docker Hub (`davidcardoso/my-ez-cli:cdktf-latest`)
- **Security:** Trivy vulnerability scanning
- **Workflow:** `.github/workflows/docker-build-cdktf.yml`

## Troubleshooting

### Slow builds locally

The CDKTF CLI installation involves compiling native modules, which can be slow:

```bash
# Use build cache to speed up subsequent builds
docker buildx build --cache-from=type=local,src=/tmp/buildx-cache \
  --cache-to=type=local,dest=/tmp/buildx-cache \
  --tag my-ez-cli:cdktf-latest .
```

### Version conflicts

If you encounter version conflicts, update the build args:

```bash
# Use latest stable versions
CDKTF_VERSION=0.21.0 TF_VERSION=1.13.0 ./build
```

### ARM64 build timeout in CI

This is expected. ARM64 builds are disabled in CI due to QEMU limitations. Use the AMD64 image or build locally if you need ARM64.

## Related Resources

- [CDKTF Documentation](https://developer.hashicorp.com/terraform/cdktf)
- [Terraform Documentation](https://developer.hashicorp.com/terraform)
- [My Ez CLI Documentation](../../../README.md)
