# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## v1.0.0 Upgrade Status

**All phases complete (1, 2, 2.8, 3).**: My Ez CLI v1.0.0 includes Docker tooling (Phase 1), AI integration (Phase 2), UX hardening (Phase 2.8), and AI performance + dashboard (Phase 3). See [ROADMAP.md](./docs/ROADMAP.md) for the complete plan.

### Completed (Phase 1 — Foundation)
- ✓ Path resolution fixes with `common.sh` utilities
- ✓ Multi-select installation in setup.sh
- ✓ Comprehensive test framework (bats-core)
- ✓ Docker Hub migration for custom images
- ✓ Enhanced documentation (SETUP.md, DOCKER_HUB.md, tests/README.md)
- ✓ GitHub Actions CI/CD with multi-platform builds
- ✓ Container naming and labeling for better management

### Completed (Phase 2 — AI Integration)
- ✓ Claude Code as first-class tool (`bin/claude` + Docker image)
- ✓ I/O middleware (Python) for filtering and token optimization
- ✓ All analysis through Claude Code (no rule-based analyzers)
- ✓ `mec ai` CLI subcommands (status, enable, disable, test, analyze)
- ✓ All bin scripts wired to `exec_with_ai()` for automatic analysis
- ✓ API key, OAuth long-lived token, or web login supported (see [docker/claude/README.md](./docker/claude/README.md#authentication))

### Completed (Phase 2.8 — Hardening & UX)
- ✓ `bin/yarn-plus` wired to `exec_with_ai()` (last remaining unwired script)
- ✓ Conflict detection for all CLI-sharing tools (node, npm, npx, yarn, terraform, python, aws, gcloud, serverless, speedtest, playwright, promptfoo) — 3-option menu: side-by-side as `mec-<tool>`, replace, skip
- ✓ `mec setup` / `mec install <tool>` / `mec uninstall <tool>` top-level subcommands
- ✓ Unit tests for conflict detection functions in `tests/unit/test-setup.bats`
- ✓ Manual testing checklist in `docs/SETUP.md`

### Completed (Phase 3 — AI Performance + Dashboard)
- ✓ `analyze_with_claude()` now runs in background (non-blocking)
- ✓ Terminal prints session ID + dashboard URL after each command
- ✓ `mec ai last` — show most recent AI analysis
- ✓ `mec ai show <session_id>` — look up any session by ID
- ✓ `mec ai logs` — list recent sessions with AI status
- ✓ Dashboard daemon (`mec dashboard start|stop|status|open`, Python/FastAPI, hot-reload Web UI)

### Future
- Shell completion, `mec doctor`, Homebrew formula
- PostgreSQL log storage, log encryption, Elasticsearch integration

Follow the roadmap phases when implementing changes.

## Project Overview

My Ez CLI is a collection of Docker-based wrapper scripts that provide access to various development tools (AWS CLI, Terraform, Node.js, Python, etc.) without requiring local installation. Each tool runs in an isolated Docker container with appropriate volume mounts and environment configurations.

## Core Architecture

### Script Pattern

All wrapper scripts in `bin/` follow a consistent pattern:

1. **Docker Image Selection**: Each script specifies a Docker image (e.g., `node:24-alpine`, `hashicorp/terraform:1.9.8`)
2. **Container Naming**: Uses `mec-{tool}-{timestamp}` format via `get_container_name()` helper
3. **Container Labels**: Applies `com.my-ez-cli.*` labels via `get_container_labels()` helper
4. **Volume Mounting**: Mounts current working directory or specific context into container
5. **Environment Variable Propagation**: Passes relevant env vars (API keys, credentials, profiles) into container
6. **Interactive Mode**: Uses `-it` flags for interactive terminal sessions
7. **Cleanup**: Uses `--rm` flag for automatic container cleanup

### Key Directories

- `bin/`: Contains all executable wrapper scripts
- `bin/utils/`: Shared utilities (e.g., `common.sh` for common functions, `docker.sh` for TTY detection)
- `docker/`: Custom Dockerfiles for tools requiring special builds (aws-sso-cred, serverless, speedtest, yarn-berry, claude)
- `config/`: Configuration examples and documentation (currently only AWS)
- `docs/`: Project documentation (see [CODE_STANDARDS.md](./docs/CODE_STANDARDS.md) and [AI_INTEGRATION.md](./docs/AI_INTEGRATION.md))
- `tests/`: Test framework using bats-core (73 tests: 65 unit, 8 integration)
- `setup.sh`: Installation script that creates symbolic links in `/usr/local/bin/` and aliases in `~/.zshrc`
- `services/ai/`: AI analysis service (Python 3.14) - See [AI_INTEGRATION.md](./docs/AI_INTEGRATION.md)

### Docker Hub Images

Custom Docker images are hosted on Docker Hub in a single repository with tool-specific tags:

**Repository**: `davidcardoso/my-ez-cli`

**Images**:
- `davidcardoso/my-ez-cli:ai-service-latest` - AI I/O middleware service
- `davidcardoso/my-ez-cli:aws-sso-cred-latest` - AWS SSO credential retrieval
- `davidcardoso/my-ez-cli:claude-latest` - Claude Code CLI
- `davidcardoso/my-ez-cli:serverless-latest` - Serverless Framework
- `davidcardoso/my-ez-cli:speedtest-latest` - Ookla Speedtest CLI
- `davidcardoso/my-ez-cli:yarn-berry-latest` - Yarn Berry (v2+)
- `davidcardoso/my-ez-cli:yarn-plus-latest` - Yarn with extra tools (git, curl, jq)

For detailed information about Docker Hub setup, GitHub Secrets, and CI/CD workflows, see [DOCKER_HUB.md](./docs/DOCKER_HUB.md).

### Installation System

The `setup.sh` script provides an interactive menu to install specific tools or all tools at once. Each install function creates:
- Symbolic links in `/usr/local/bin/` (requires sudo)
- Aliases in `~/.zshrc` (for tools that need shell integration)

## Common Development Commands

### Testing Individual Scripts

```shell
# Test a specific tool wrapper directly
./bin/node --version
./bin/terraform --version
./bin/aws --version

# Test with environment variables
MEC_BIND_PORTS="8080:80" ./bin/node
PYENV_VERSION=3.9.19 ./bin/python
CONTEXT=/path/to/context ./bin/terraform plan
```

### Testing Installation

```shell
# Run setup script interactively
./setup.sh

# Or test specific installation functions
bash -c "source ./setup.sh && install_node"
```

## Important Environment Variables

### Cross-Tool Variables

- `MEC_BIND_PORTS`: Port binding for Node.js tools (node, npm, npx, yarn)
  - Format: `"host:container host2:container2"`
  - Example: `MEC_BIND_PORTS="8080:80 9090:90" npm start`

### Node.js/NPM/Yarn

- `NPM_TOKEN`: Authentication token for private NPM registries
- `NPM_CACHE_FOLDER`: NPM cache location (default: `$HOME/.npm`)
- `IMAGE`: Override Docker image (e.g., `IMAGE=node:18-alpine npm install`)

### Python

- `PYENV_VERSION`: Python version to use (compatible with PyEnv convention)
  - Example: `PYENV_VERSION=3.9.19 python script.py`

### Terraform

- `CONTEXT`: Absolute path to mount on container (default: parent directory)
  - Used when Terraform modules are located outside current directory
- `DOTENV_FILE`: Path to .env file (default: `${PWD}/.env`)
- `TF_CREDENTIALS_FILE`: Terraform Cloud credentials (default: `$HOME/.terraformrc`)
- `AWS_CREDENTIALS_FOLDER`: AWS credentials folder (default: `$HOME/.aws`)
- `AWS_PROFILE`: AWS profile to use
- `GCLOUD_CREDENTIALS_FOLDER`: GCP credentials folder (default: `$HOME/.config/gcloud`)
- `GOOGLE_APPLICATION_CREDENTIALS`: GCP service account key path

### Promptfoo

- `PROMPTFOO_CONFIG_DIR`: Config and data folder (default: `./data`)
- `PROMPTFOO_REMOTE_API_BASE_URL`: Remote API URL (default: empty)
- `PROMPTFOO_REMOTE_APP_BASE_URL`: Remote UI URL (default: empty)
- `PROMPTFOO_API_PORT`: API/UI port (default: 3000 for CLI, 33333 for server)
- `PROMPTFOO_CONTAINER_SUFFIX`: Unique container identifier for server (default: timestamp)
- Model API keys: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `AZURE_API_KEY`, `LITELLM_API_KEY`
- `GITHUB_TOKEN`: GitHub token for accessing repos
- AWS credentials: `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`

## Tool Version Management

### Node.js Multi-Version Support

Scripts support multiple Node.js LTS versions through version-suffixed commands:
- `node`, `node22`: Node.js 22 (default/Active LTS)
- `node24`: Node.js 24 (LTS)
- `node20`: Node.js 20 (maintenance)

Same pattern applies to `npm`, `npx`, and `yarn` (e.g., `npm20`, `npm22`, `npx20`, `npx22`, `yarn20`, `yarn22`).

Each version-specific script (e.g., `bin/node22`) simply sets the `IMAGE` environment variable with `export` and sources the base script.

## Adding New Tools

To add a new tool wrapper:

1. Create script in `bin/` following the existing pattern:
   - Source `common.sh` for shared utilities
   - Set `IMAGE` variable to appropriate Docker image
   - Set `WORKDIR` for container working directory
   - Use `get_container_name()` and `get_container_labels()` for naming/labeling
   - Mount `$PWD` or relevant directories as volumes
   - Pass necessary environment variables with `--env`
   - Use `-it --rm` flags for interactive cleanup

2. Add installation function in `setup.sh`:
   - Create `install_<toolname>()` function
   - Add symbolic link: `sudo ln -sf ${BASEDIR}/bin/<toolname> /usr/local/bin/<toolname>`
   - Update `install_all()` function
   - Add to PS3 select menu

3. Update README.md with usage examples

4. If custom Docker image needed, add Dockerfile in `docker/<toolname>/` with proper labels:
   - `com.my-ez-cli.project="my-ez-cli"`
   - `com.my-ez-cli.tool="{toolname}"`
   - OCI standard labels (`org.opencontainers.image.*`)

## Container Naming and Labeling

All containers follow consistent naming and labeling conventions for easy management:

**Helper Functions** (in `bin/utils/common.sh`):
```shell
CONTAINER_NAME=$(get_container_name "toolname")      # Returns: mec-toolname-{timestamp}
CONTAINER_LABELS=$(get_container_labels "toolname" "$IMAGE")  # Returns: --label flags
```

**Labels Applied**:
- `com.my-ez-cli.project=my-ez-cli` - Project identifier
- `com.my-ez-cli.tool={tool}` - Tool name
- `com.my-ez-cli.image={image}` - Source Docker image

**Management Commands**:
```shell
docker ps -a --filter "name=mec-"                                    # List all mec containers
docker ps -a --filter "label=com.my-ez-cli.project=my-ez-cli"        # List by label
docker container prune --filter "label=com.my-ez-cli.project=my-ez-cli"  # Remove stopped
```

## Script Utilities

### TTY Detection (`bin/utils/docker.sh`)

The `get_tty_flag()` function detects if running in a TTY and returns appropriate flag (`-t` or empty). Used in scripts that may run in non-interactive contexts (e.g., CI/CD):

```shell
. "$SCRIPT_DIR/utils/docker.sh"
docker run -i $(get_tty_flag) --rm ...
```

## Credential Handling

### AWS

- Credentials stored in `$HOME/.aws/` (credentials file and config file)
- Use `AWS_PROFILE` environment variable to specify profile
- Scripts `aws-get-session-token` and `aws-sso` help with MFA/SSO authentication
- Script `aws-sso-cred` retrieves current SSO credentials

### Terraform Cloud

- Credentials stored in `$HOME/.terraformrc`
- Automatically mounted in terraform container

### NPM Private Registries

- Token via `NPM_TOKEN` environment variable
- Or configure `$HOME/.npmrc` with registry auth settings

### GCP

- Use `gcloud-login` for interactive authentication
- Credentials stored in `$HOME/.config/gcloud/`
- Application default credentials at `application_default_credentials.json`

## AI Integration

My Ez CLI uses Claude Code for all AI-powered analysis. The Python middleware (`services/ai/`) is a pure I/O layer for filtering and token optimization — no rule-based analyzers.

### Documentation

**⭐ IMPORTANT:** Read these documents for AI work:
- [CODE_STANDARDS.md](./docs/CODE_STANDARDS.md) - Global code standards (logging, type hints, error handling)
- [AI_INTEGRATION.md](./docs/AI_INTEGRATION.md) - AI architecture, Claude Code integration, filtering

### Architecture

- **I/O middleware** (`services/ai/`): Python 3.14 service. Handles output filtering and token optimization only. No AI API calls, no rule-based analysis.
- **Claude Code** (`bin/claude`): First-class tool running in Docker (node:20-slim). Sole analysis engine. Requires an API key or OAuth token for automated use.
- **Single-path flow**: `exec_with_ai()` in `bin/utils/common.sh` invokes Claude Code when `MEC_AI_ENABLED=true` and a valid credential is set.

### Key Information

- **I/O middleware:** Python 3.14, Docker container (`davidcardoso/my-ez-cli:ai-service-latest`) — filter only
- **Claude Code:** Docker container (`davidcardoso/my-ez-cli:claude-latest`) — all analysis
- **Auth:** API key, OAuth long-lived token, or web login — see [docker/claude/README.md](./docker/claude/README.md#authentication)
- **CLI commands:** `mec ai status`, `mec ai enable`, `mec ai test`, `mec ai analyze <log>`

### Code Standards (Key Points)

From [CODE_STANDARDS.md](./docs/CODE_STANDARDS.md):

1. **Logging:** Minimize noise - most logs should be `logger.debug()`, not `logger.info()`
2. **Error Handling:** Always log → custom exception → chain with `from e`
3. **Testing:** 80% coverage minimum, use mocks for external dependencies

### Working with AI Service

1. **Before coding:** Read [CODE_STANDARDS.md](./docs/CODE_STANDARDS.md) and [AI_INTEGRATION.md](./docs/AI_INTEGRATION.md)
2. **The middleware is filter-only** — do not add analyzers; all analysis goes through Claude Code
3. **Test thoroughly:** Write comprehensive tests for filter engine changes
4. **Build and test:**

```bash
# Build AI service
cd docker/ai-service && ./build

# Run all tests (filter engine only)
docker run --rm --entrypoint python \
  davidcardoso/my-ez-cli:ai-service-latest \
  -m pytest tests/ -v

# Test Claude Code
mec ai test
```

## Contributing

- Branch naming: `<feat|fix>/<issue-id>/<issue-title>`
- All PRs must target `main` branch
- CI workflow must pass before merge
- Follow existing script patterns and conventions
