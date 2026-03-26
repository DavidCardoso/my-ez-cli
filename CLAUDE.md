# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> See [docs/ROADMAP.md](./docs/ROADMAP.md) for current phase status and implementation plan.

## Project Overview

My Ez CLI is a collection of Docker-based wrapper scripts providing sandboxed access to development tools (AWS CLI, Terraform, Node.js, Python, etc.) without local installation. `mec` is the main CLI managing tools, configuration, AI analysis, logs, and the dashboard.

## Core Architecture

### Script Pattern

All wrapper scripts in `bin/` follow a consistent pattern:

1. **Docker Image Selection**: Each script specifies a Docker image (e.g., `node:24-alpine`)
2. **Container Naming**: Uses `mec-{tool}-{timestamp}` format via `get_container_name()` helper
3. **Container Labels**: Applies `com.my-ez-cli.*` labels via `get_container_labels()` helper
4. **Volume Mounting**: Mounts current working directory or specific context into container
5. **Environment Variable Propagation**: Passes relevant env vars (API keys, credentials, profiles)
6. **Interactive Mode**: Uses `-it` flags for interactive terminal sessions
7. **Cleanup**: Uses `--rm` flag for automatic container cleanup

### Key Directories

- `bin/`: Executable wrapper scripts
- `bin/utils/`: Shared utilities (`common.sh`, `config-manager.sh`, `log-manager.sh`, `docker.sh`)
- `docker/`: Custom Dockerfiles (aws-sso-cred, serverless, speedtest, yarn-berry, claude, dashboard)
- `config/`: Default configuration (`config.default.yaml`)
- `docs/`: Project documentation
- `services/ai/`: AI I/O middleware (Python 3.14, filter-only)
- `services/dashboard/`: Dashboard server (FastAPI + Vue 3)
- `tests/`: bats-core test suite (unit + integration)
- `setup.sh`: Bootstrap installer (use `mec` after initial setup)

### Container Naming and Labeling

```shell
CONTAINER_NAME=$(get_container_name "toolname")               # mec-toolname-{timestamp}
CONTAINER_LABELS=$(get_container_labels "toolname" "$IMAGE")  # --label flags
```

Labels applied to every container:
- `com.my-ez-cli.project=my-ez-cli`
- `com.my-ez-cli.tool={tool}`
- `com.my-ez-cli.image={image}`

## Adding New Tools

1. Create `bin/<toolname>` following the existing pattern (source `common.sh`, set `IMAGE`, use helpers)
2. Add `install_<toolname>()` in `setup.sh` with symlink to `/usr/local/bin/` (plus version variants and mec-prefixed aliases if applicable)
3. Add `uninstall_<toolname>()` in `setup.sh` — remove symlinks/aliases and call `track_uninstall "<toolname>"`
4. Update `README.md` with usage examples
5. If custom Docker image needed: add `docker/<toolname>/Dockerfile` with `com.my-ez-cli.*` labels

## AI Integration

- **I/O middleware** (`services/ai/`): Python 3.14, filter/token-optimization only — no analysis
- **Claude Code** (`bin/claude`): Docker container, sole analysis engine
- **Flow**: `exec_with_ai()` in `bin/utils/common.sh` fires background Claude analysis when `MEC_AI_ENABLED=true`

**⭐ Read before working on AI:** [docs/AI_INTEGRATION.md](./docs/AI_INTEGRATION.md) · [docs/CODE_STANDARDS.md](./docs/CODE_STANDARDS.md)

## Credential Handling

**AWS**: Credentials in `$HOME/.aws/`; use `AWS_PROFILE` env var; `aws-sso` / `aws-get-session-token` for auth.

**Terraform Cloud**: Credentials in `$HOME/.terraformrc`, auto-mounted in container.

**NPM Private Registries**: Token via `NPM_TOKEN` env var or `$HOME/.npmrc`.

**GCP**: `gcloud-login` for interactive auth; credentials in `$HOME/.config/gcloud/`.

## Contributing

- Branch naming: `<feat|fix|chore|docs|ci|test>/<short-description>` (include issue ID when applicable: `feat/123/short-description`)
- PRs target `rc-v1-alpha` — `main` is reserved for v1.0.0 stable release
- CI must pass before merge
- Follow existing script patterns and conventions
