# Docker Hub Setup

My Ez CLI uses Docker Hub to host all custom Docker images for the project. This document explains the setup, structure, and maintenance of these images.

## Repository Structure

All custom Docker images are stored in a single Docker Hub repository using tool-specific tags:

**Repository**: `davidcardoso/my-ez-cli`

### Available Images

| Tool | Docker Image | Platforms | Build Workflow |
|------|-------------|-----------|----------------|
| AWS SSO Cred | `davidcardoso/my-ez-cli:aws-sso-cred-latest` | amd64, arm64 | `.github/workflows/docker-build-aws-sso-cred.yml` |
| CDKTF | `davidcardoso/my-ez-cli:cdktf-latest` | amd64 only* | `.github/workflows/docker-build-cdktf.yml` |
| Serverless | `davidcardoso/my-ez-cli:serverless-latest` | amd64, arm64 | `.github/workflows/docker-build-serverless.yml` |
| Speedtest | `davidcardoso/my-ez-cli:speedtest-latest` | amd64, arm64 | `.github/workflows/docker-build-speedtest.yml` |
| Yarn Berry | `davidcardoso/my-ez-cli:yarn-berry-latest` | amd64, arm64 | `.github/workflows/docker-build-yarn-berry.yml` |

**\* CDKTF Note:** ARM64 builds are disabled due to QEMU emulation issues with native module compilation. ARM64 users can run the AMD64 image using Docker's automatic emulation.

### Tag Formats

Each tool image uses multiple tags for versioning and tracking:

- `{tool}-latest` - Latest version from main branch
- `{tool}-main` - Main branch builds
- `{tool}-sha-{git-sha}` - Specific commit builds
- `{tool}-{version}` - Semantic version releases (e.g., `cdktf-1.0.0`)
- `{tool}-{major}.{minor}` - Major.minor version (e.g., `cdktf-1.0`)

**Examples**:
- `davidcardoso/my-ez-cli:aws-sso-cred-latest`
- `davidcardoso/my-ez-cli:aws-sso-cred-sha-a1b2c3d`
- `davidcardoso/my-ez-cli:serverless-1.0.0`

## GitHub Secrets Setup

The Docker build workflows require GitHub Secrets for authentication to Docker Hub.

### Required Secrets

Navigate to your GitHub repository settings: **Settings → Secrets and variables → Actions**

Add the following secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `DOCKERHUB_USERNAME` | `davidcardoso` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | `dckr_pat_...` | Docker Hub access token |

### Creating a Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Click on your username → **Account Settings**
3. Navigate to **Security** → **Access Tokens**
4. Click **New Access Token**
5. Configure the token:
   - **Description**: `GitHub Actions - My Ez CLI`
   - **Access permissions**: `Read & Write`
6. Click **Generate**
7. **IMPORTANT**: Copy the token immediately (it won't be shown again)
8. Add it as `DOCKERHUB_TOKEN` secret in GitHub

### Verifying Secrets Setup

After adding the secrets, trigger a workflow manually to verify the setup:

```bash
# Via GitHub UI
Go to Actions → Select any Docker workflow → Run workflow

# Or via GitHub CLI
gh workflow run docker-build-aws-sso-cred.yml
```

Check the workflow logs for successful authentication:
```
Run docker/login-action@v3
  with:
    username: ***
    password: ***
Login Succeeded
```

## CI/CD Workflows

### Automatic Builds

Docker images are automatically built when:

1. **Push to main** - Changes to docker files or workflows
   - Triggers individual tool workflows based on path filters
   - Example: Changes to `docker/serverless/**` triggers serverless build

2. **Pull Requests** - Build only (no push to Docker Hub)
   - Validates image builds without publishing

3. **Manual Dispatch** - Trigger builds manually
   - Via GitHub Actions UI or `gh` CLI

4. **Release Published** - Build all images with version tags
   - Triggered when creating GitHub releases

5. **Weekly Schedule** - Every Sunday at 2 AM UTC
   - Rebuilds all images to include security updates

### Build Status

Check build status at:
- GitHub Actions: https://github.com/davidcardoso/my-ez-cli/actions
- Docker Hub: https://hub.docker.com/r/davidcardoso/my-ez-cli

## Docker Hub Repository Settings

### Public Access

The repository is configured as **public** to allow users to pull images without authentication:

```bash
docker pull davidcardoso/my-ez-cli:aws-sso-cred-latest
```

### Security Scanning

All images are scanned for vulnerabilities using:
- **Trivy** - During GitHub Actions build
- **Docker Hub Scanning** - Automatic scanning on push

Security scan results are available in:
- GitHub Security tab
- Docker Hub repository page

## Local Development

### Building Images Locally

Each Docker image has a dedicated directory with a Dockerfile:

```bash
# Build specific tool image
cd docker/aws-sso-cred
docker build -t davidcardoso/my-ez-cli:aws-sso-cred-local .

# Build with specific platform
docker buildx build --platform linux/amd64,linux/arm64 \
  -t davidcardoso/my-ez-cli:serverless-local .
```

### Testing Images Locally

Test the image before pushing:

```bash
# Run the image
docker run --rm davidcardoso/my-ez-cli:aws-sso-cred-local --help

# Or use the bin script with local image
IMAGE=davidcardoso/my-ez-cli:aws-sso-cred-local ./bin/aws-sso-cred
```

### Pushing to Docker Hub

Manual push (requires Docker Hub login):

```bash
# Login to Docker Hub
docker login

# Tag the image
docker tag local-image:tag davidcardoso/my-ez-cli:tool-version

# Push to Docker Hub
docker push davidcardoso/my-ez-cli:tool-version
```

## Maintenance

### Updating Base Images

Docker images should be updated periodically for security patches:

1. Update the base image version in `docker/{tool}/Dockerfile`
2. Test locally
3. Commit and push to trigger CI build
4. Verify successful build in GitHub Actions

### Pruning Old Tags

Docker Hub has storage limits. To clean up old tags:

1. Go to https://hub.docker.com/r/davidcardoso/my-ez-cli/tags
2. Select old SHA-based tags
3. Click **Delete tags**
4. Keep:
   - `*-latest` tags
   - Recent version tags
   - Last 5-10 SHA tags per tool

### Monitoring Image Sizes

Keep images small for faster pulls and reduced storage:

```bash
# Check image size
docker images davidcardoso/my-ez-cli

# Use multi-stage builds in Dockerfiles
# Use Alpine Linux when possible
# Remove unnecessary dependencies
```

## Troubleshooting

### Authentication Failed

**Error**: `Error: Cannot perform an interactive login from a non TTY device`

**Solution**: Ensure `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets are correctly set in GitHub

### Build Fails with "manifest unknown"

**Error**: `manifest for davidcardoso/my-ez-cli:tool-latest not found`

**Solution**: The image hasn't been built yet. Trigger the workflow manually or push to main

### Pull Rate Limit

**Error**: `toomanyrequests: You have reached your pull rate limit`

**Solution**:
- Public repositories have generous limits (200 pulls/6 hours for anonymous)
- Authenticate to Docker Hub for higher limits:
  ```bash
  docker login
  ```

### Platform Mismatch

**Error**: `no matching manifest for linux/arm64 in the manifest list entries`

**Solution**: Ensure multi-platform build is configured in workflows:
```yaml
platforms: linux/amd64,linux/arm64
```

## Migration from GitHub Container Registry

Previous setup used GitHub Container Registry (`ghcr.io`). All images have been migrated to Docker Hub.

### Old vs New Images

| Old (ghcr.io) | New (Docker Hub) |
|--------------|------------------|
| `ghcr.io/davidcardoso/my-ez-cli/aws-sso-cred:latest` | `davidcardoso/my-ez-cli:aws-sso-cred-latest` |
| `ghcr.io/davidcardoso/my-ez-cli/cdktf:latest` | `davidcardoso/my-ez-cli:cdktf-latest` |
| `ghcr.io/davidcardoso/my-ez-cli/serverless:latest` | `davidcardoso/my-ez-cli:serverless-latest` |
| `ghcr.io/davidcardoso/my-ez-cli/speedtest:latest` | `davidcardoso/my-ez-cli:speedtest-latest` |
| `ghcr.io/davidcardoso/my-ez-cli/yarn-berry:latest` | `davidcardoso/my-ez-cli:yarn-berry-latest` |

**Note**: Old images on ghcr.io are deprecated and will not receive updates.

## Resources

- Docker Hub Repository: https://hub.docker.com/r/davidcardoso/my-ez-cli
- GitHub Actions: https://github.com/davidcardoso/my-ez-cli/actions
- Docker Documentation: https://docs.docker.com/
- GitHub Actions Documentation: https://docs.github.com/en/actions
