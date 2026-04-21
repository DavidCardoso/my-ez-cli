# Claude Code CLI via Docker

Docker image providing [Claude Code](https://claude.ai/code) — Anthropic's official CLI for Claude — packaged for use as a My Ez CLI tool.

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Anthropic API](https://console.anthropic.com/)

## Docker Image

**Registry:** `ghcr.io/my-ez-cli`
**Image:** `ghcr.io/my-ez-cli/claude:latest`
**Base Image:** `node:24-slim`
**Extra tools:** `git`, `gh`, `jq`, `fzf`, `zsh`, `neovim`
**Platforms:** linux/amd64, linux/arm64

## Building the Docker Image

### Using the build script

```bash
cd docker/claude

# Build with default settings (IMAGE_TAG=latest, CLAUDE_CODE_VERSION=latest)
./build

# Build with custom tag
IMAGE_TAG=1.0.0 ./build

# Pin a specific Claude Code version
CLAUDE_CODE_VERSION=1.0.0 ./build

# Build for specific platform
PLATFORM=linux/amd64 ./build

# Build with a custom timezone
TZ=America/New_York ./build
```

### Manual Docker build

```bash
cd docker/claude

# Single platform (local use)
docker buildx build --platform linux/amd64 \
  --build-arg CLAUDE_CODE_VERSION=latest \
  --tag ghcr.io/my-ez-cli/claude:latest \
  --load .

# Multi-platform (push to registry)
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg CLAUDE_CODE_VERSION=latest \
  --tag ghcr.io/my-ez-cli/claude:latest \
  --push .
```

## Build Arguments

| Argument              | Description                                                                                   | Default            |
| --------------------- | --------------------------------------------------------------------------------------------- | ------------------ |
| `CLAUDE_CODE_VERSION` | Claude Code binary version (`latest`, `stable`, or a specific version e.g. `1.2.3`)          | `latest`           |
| `TZ`                  | Container timezone                                                                            | `Europe/Amsterdam` |

## Authentication

Claude Code supports two authentication methods:

### API Key

> Uses Anthropic API credits.

Set `ANTHROPIC_API_KEY` in your environment. This is the only method supported by `exec_with_ai()` and `mec ai analyze`:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
mec ai analyze /path/to/log.json
```

### OAuth via long-lived token

> Uses Claude.ai subscription.

```bash
# Using Claude subscription but bypassing web login
# Add the `"hasCompletedOnboarding": true` flag to your ~/.claude.json config file
# Generate a long-lived auth token
claude setup-token
# set the env var or add it to your profile (e.g., ~/.zshrc)
export CLAUDE_CODE_OAUTH_TOKEN=sk-...
# check the status
claude auth status
# if loggedIn = true
# call claude in the standalone mode
claude --print "help me debug this error"
# or start an interactive session
claude "help with debug this error"
```

### OAuth via web browser login

> Uses Claude.ai subscription.

When you run Claude Code CLI for the first time, an onboarding will start to ask some preferences and the login method.

Select the Claude.ai subscription option to start the web-basde login.

As this project runs `claude` over docker, a web browser is not available but you can copy/paste the auth URL and the auth token back into the terminal.

```bash
# Authenticate via web login

claude auth login
# or
claude
# and follow the onboarding steps
# or use /login slash command
```

## Usage Examples

### Interactive mode

```bash
# Open an interactive Claude Code session in the current directory
claude

# Ask a single question and exit
claude -p "explain this codebase"

# With API key (no OAuth needed)
ANTHROPIC_API_KEY=sk-ant-... claude -p "review my code"
```

### Automated analysis via mec

```bash
# Show AI integration status
mec ai status

# Test Claude Code is available
mec ai test

# Analyze a log file
ANTHROPIC_API_KEY=sk-ant-... mec ai analyze ~/.my-ez-cli/logs/node/2024-01-01.json

# Enable automatic analysis after every tool run
mec ai enable
export ANTHROPIC_API_KEY=sk-ant-...
node server.js   # Claude Code runs automatically if there are issues
```

### Direct Docker usage

```bash
# Interactive session (mount current directory)
docker run --rm -it \
  --volume $PWD:/workspace \
  --volume $HOME/.claude:/home/node/.claude \
  ghcr.io/my-ez-cli/claude:latest

# Single-shot prompt with API key
docker run --rm \
  --env ANTHROPIC_API_KEY \
  ghcr.io/my-ez-cli/claude:latest \
  -p "what does this project do?" \
  --output-format text \
  --max-turns 1
```

## Environment Variables

| Variable                  | Description                           | Required for                      |
| ------------------------- | ------------------------------------- | --------------------------------- |
| `ANTHROPIC_API_KEY`       | Anthropic API key (Console credits)   | Automated analysis (API method)   |
| `CLAUDE_CODE_OAUTH_TOKEN` | Long-lived OAuth token (subscription) | Automated analysis (OAuth method) |
| `TZ`                      | Timezone inside container             | No (cosmetic)                     |

## CI/CD Integration

The Docker image is automatically built and published via GitHub Actions:

- **Trigger:** Push to main, pull requests, releases, manual dispatch
- **Platforms:** linux/amd64, linux/arm64
- **Registry:** Docker Hub (`ghcr.io/my-ez-cli/claude:latest`)
- **Workflow:** `.github/workflows/docker-build-claude.yml`

## Troubleshooting

### Auth errors in automated mode

```bash
# Ensure ANTHROPIC_API_KEY is set
echo $ANTHROPIC_API_KEY

# Test with mec ai test
mec ai test
```

### Interactive session not connecting

```bash
# Re-authenticate on the host
claude  # follow the browser OAuth flow

# Verify ~/.claude/ exists
ls ~/.claude/
```

## Related Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [AI Integration Guide](../../docs/AI_INTEGRATION.md)
- [My Ez CLI Documentation](../../README.md)
