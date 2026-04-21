# GitHub Container Registry Setup

My Ez CLI uses GitHub Container Registry (`ghcr.io`) to host all custom Docker images for the project. This document explains the setup, structure, and maintenance of these images.

## Registry Structure

All custom Docker images are published to per-tool repositories under the `ghcr.io/my-ez-cli` namespace:

**Registry**: `ghcr.io/my-ez-cli`

### Available Images

| Tool | Docker Image | Platforms | Build Workflow |
|------|-------------|-----------|----------------|
| AI Service | `ghcr.io/my-ez-cli/ai-service:latest` | amd64, arm64 | `.github/workflows/docker-build-ai-service.yml` |
| AWS SSO Cred | `ghcr.io/my-ez-cli/aws-sso-cred:latest` | amd64, arm64 | `.github/workflows/docker-build-aws-sso-cred.yml` |
| Claude Code | `ghcr.io/my-ez-cli/claude:latest` | amd64, arm64 | `.github/workflows/docker-build-claude.yml` |
| Serverless | `ghcr.io/my-ez-cli/serverless:latest` | amd64, arm64 | `.github/workflows/docker-build-serverless.yml` |
| Speedtest | `ghcr.io/my-ez-cli/speedtest:latest` | amd64, arm64 | `.github/workflows/docker-build-speedtest.yml` |
| Yarn Berry | `ghcr.io/my-ez-cli/yarn-berry:latest` | amd64, arm64 | `.github/workflows/docker-build-yarn-berry.yml` |
| Yarn Plus | `ghcr.io/my-ez-cli/yarn-plus:latest` | amd64, arm64 | `.github/workflows/docker-build-yarn-plus.yml` |

### Tag Formats

Each tool image uses multiple tags for versioning and tracking:

- `latest` - Latest version from main branch
- `<branch>` - Branch builds
- `sha-{git-sha}` - Specific commit builds
- `{version}` - Semantic version releases (e.g., `1.0.0`)
- `{major}.{minor}` - Major.minor version (e.g., `1.0`)

**Examples**:
- `ghcr.io/my-ez-cli/aws-sso-cred:latest`
- `ghcr.io/my-ez-cli/aws-sso-cred:sha-a1b2c3d`
- `ghcr.io/my-ez-cli/serverless:1.0.0`

## GitHub Secrets Setup

The Docker build workflows require a GitHub Secret for authentication to GitHub Container Registry.

### Required Secrets

Navigate to your GitHub repository settings: **Settings → Secrets and variables → Actions**

Add the following secret:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `GHCR_TOKEN` | `ghp_...` | GitHub PAT with `write:packages` scope |

### Creating a GitHub PAT for ghcr.io

1. Log in to [GitHub](https://github.com/)
2. Click on your avatar → **Settings**
3. Navigate to **Developer settings** → **Personal access tokens** → **Tokens (classic)**
4. Click **Generate new token (classic)**
5. Configure the token:
   - **Note**: `GHCR_TOKEN - My Ez CLI CI`
   - **Expiration**: 1 year (or as appropriate)
   - **Scopes**: check `write:packages` (automatically includes `read:packages`)
6. Click **Generate token**
7. **IMPORTANT**: Copy the token immediately (it won't be shown again)
8. Add it as `GHCR_TOKEN` secret in the GitHub repository

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

2. **Pull Requests** - Build only (no push to ghcr.io)
   - Validates image builds without publishing

3. **Manual Dispatch** - Trigger builds manually
   - Via GitHub Actions UI or `gh` CLI

4. **Release Published** - Build all images with version tags
   - Triggered when creating GitHub releases

5. **Weekly Schedule** - Every Sunday at 2 AM UTC
   - Rebuilds all images to include security updates

### Build Status

Check build status at:
- GitHub Actions: https://github.com/DavidCardoso/my-ez-cli/actions
- GitHub Packages: https://github.com/orgs/my-ez-cli/packages

## GitHub Container Registry Settings

### Public Access

All images are configured as **public** to allow users to pull without authentication:

```bash
docker pull ghcr.io/my-ez-cli/aws-sso-cred:latest
```

### Security Scanning

All images are scanned for vulnerabilities using:
- **Trivy** - During GitHub Actions build

Security scan results are available in:
- GitHub Security tab (SARIF uploads)

## Local Development

### Building Images Locally

Each Docker image has a dedicated directory with a Dockerfile:

```bash
# Build specific tool image
cd docker/aws-sso-cred
docker build -t ghcr.io/my-ez-cli/aws-sso-cred:local .

# Build with specific platform
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/my-ez-cli/serverless:local .
```

### Testing Images Locally

Test the image before pushing:

```bash
# Run the image
docker run --rm ghcr.io/my-ez-cli/aws-sso-cred:local --help

# Or use the bin script with local image
IMAGE=ghcr.io/my-ez-cli/aws-sso-cred:local ./bin/aws-sso-cred
```

### Pushing to GitHub Container Registry

Manual push (requires ghcr.io login):

```bash
# Login to ghcr.io
echo $GHCR_TOKEN | docker login ghcr.io -u <your-github-username> --password-stdin

# Tag the image
docker tag local-image:tag ghcr.io/my-ez-cli/<tool>:<version>

# Push to ghcr.io
docker push ghcr.io/my-ez-cli/<tool>:<version>
```

## Maintenance

### Updating Base Images

Docker images should be updated periodically for security patches:

1. Update the base image version in `docker/{tool}/Dockerfile`
2. Test locally
3. Commit and push to trigger CI build
4. Verify successful build in GitHub Actions

### Pruning Old Tags

To clean up old package versions on ghcr.io:

1. Go to https://github.com/orgs/my-ez-cli/packages
2. Select the package (tool) to manage
3. Click on old SHA-based versions and delete them
4. Keep:
   - `latest` tag
   - Recent version tags
   - Last 5-10 SHA tags per tool

### Monitoring Image Sizes

Keep images small for faster pulls and reduced storage:

```bash
# Check image size
docker images ghcr.io/my-ez-cli

# Use multi-stage builds in Dockerfiles
# Use Alpine Linux when possible
# Remove unnecessary dependencies
```

## Troubleshooting

### Authentication Failed

**Error**: `Error: Cannot perform an interactive login from a non TTY device`

**Solution**: Ensure `GHCR_TOKEN` secret is correctly set in GitHub repository settings

### Build Fails with "manifest unknown"

**Error**: `manifest for ghcr.io/my-ez-cli/<tool>:latest not found`

**Solution**: The image hasn't been built yet. Trigger the workflow manually or push to main

### Pull Rate Limit

GitHub Container Registry (`ghcr.io`) has no pull rate limits for public images. If you encounter authentication errors when pulling, ensure you are either using a public image or are logged in:

```bash
echo $GHCR_TOKEN | docker login ghcr.io -u <your-github-username> --password-stdin
```

### Platform Mismatch

**Error**: `no matching manifest for linux/arm64 in the manifest list entries`

**Solution**: Ensure multi-platform build is configured in workflows:
```yaml
platforms: linux/amd64,linux/arm64
```

## Migration from Docker Hub

Previous setup used Docker Hub (`davidcardoso/my-ez-cli`). All images have been migrated to GitHub Container Registry.

### Old vs New Images

| Old (Docker Hub) | New (ghcr.io) |
|------------------|---------------|
| `davidcardoso/my-ez-cli:aws-sso-cred-latest` | `ghcr.io/my-ez-cli/aws-sso-cred:latest` |
| `davidcardoso/my-ez-cli:serverless-latest` | `ghcr.io/my-ez-cli/serverless:latest` |
| `davidcardoso/my-ez-cli:speedtest-latest` | `ghcr.io/my-ez-cli/speedtest:latest` |
| `davidcardoso/my-ez-cli:yarn-berry-latest` | `ghcr.io/my-ez-cli/yarn-berry:latest` |
| `davidcardoso/my-ez-cli:yarn-plus-latest` | `ghcr.io/my-ez-cli/yarn-plus:latest` |
| `davidcardoso/my-ez-cli:dashboard-latest` | `ghcr.io/my-ez-cli/dashboard:latest` |
| `davidcardoso/my-ez-cli:config-service-latest` | `ghcr.io/my-ez-cli/config-service:latest` |
| `davidcardoso/my-ez-cli:ai-service-latest` | `ghcr.io/my-ez-cli/ai-service:latest` |
| `davidcardoso/my-ez-cli:claude-latest` | `ghcr.io/my-ez-cli/claude:latest` |
| `davidcardoso/my-ez-cli:playwright-latest` | `ghcr.io/my-ez-cli/playwright:latest` |

**Note**: Old images on Docker Hub are deprecated and will not receive updates. Run `mec <tool> pull` or `docker pull ghcr.io/my-ez-cli/<tool>:latest` to update.

## Resources

- GitHub Container Registry: https://github.com/orgs/my-ez-cli/packages
- GitHub Actions: https://github.com/DavidCardoso/my-ez-cli/actions
- Docker Documentation: https://docs.docker.com/
- GitHub Actions Documentation: https://docs.github.com/en/actions
