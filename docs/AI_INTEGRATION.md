# AI Integration Guide

**Last Updated:** 2026-02-20
**Status:** v1.0.0 — Claude Code as AI layer + I/O middleware

This document describes the AI integration architecture for My Ez CLI.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [I/O Middleware](#io-middleware)
4. [Claude Code Integration](#claude-code-integration)
5. [I/O Filtering](#io-filtering)
6. [Configuration](#configuration)
7. [Testing](#testing)

---

## Overview

My Ez CLI uses Claude Code for all AI-powered analysis. The Python middleware (`services/ai/`) acts as a pure I/O layer: filtering, security, and future encryption. No rule-based analysis is performed.

### Key Principles

- **No rule-based analyzers** — all analysis goes through Claude Code
- **API key or OAuth token required** for automated analysis (`exec_with_ai`, `mec ai analyze`) — see [authentication methods](../docker/claude/README.md#authentication)
- **Graceful degradation** — if no credential is set, analysis is skipped silently (or with debug message when `MEC_DEBUG=1`)
- **Token optimization** — I/O filtering reduces noise before sending context to Claude Code

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  bin/* tool scripts (node, aws, terraform, etc.)    │
│  Each tool: setup_logging → docker run → log output │
│  Uses exec_with_ai() for automatic analysis         │
└──────────┬──────────────────────────────────────────┘
           │ after execution
           ▼
┌─────────────────────────────────────────────────────┐
│  I/O Middleware (services/ai/)                       │
│  - Output filtering (reduce noise, token savings)    │
│  - Security layer (future: redaction, encryption)    │
│  - Config-driven filter patterns                     │
└──────────┬──────────────────────────────────────────┘
           │ when MEC_AI_ENABLED=true + ANTHROPIC_API_KEY set
           ▼
┌─────────────────────────────────────────────────────┐
│  Claude Code CLI (bin/claude)                        │
│  - Automated analysis (exec_with_ai, mec ai analyze) │
│  - Interactive sessions (user invokes bin/claude)    │
│  - Model selection via Claude Code's own settings    │
│  - Auth: API key, OAuth token, or web login          │
└─────────────────────────────────────────────────────┘
```

### Directory Structure

```
services/ai/
├── src/
│   ├── main.py              # CLI entry point
│   ├── claude_response.py   # Parse Claude JSON + write AI sidecar
│   ├── filters/             # I/O filtering engine
│   │   └── engine.py        # Pattern-based filtering
│   ├── utils/
│   │   ├── config.py        # Configuration loader
│   │   └── logger.py        # Logger setup
│   ├── types.py             # Shared type definitions
│   └── exceptions.py        # Custom exceptions
├── tests/                   # Test suite
└── pyproject.toml           # Dependencies (pyyaml, pytest only)

docker/ai-service/
├── Dockerfile               # AI service Docker image (python:3.14-alpine)
└── build                    # Build script

docker/claude/
├── Dockerfile               # Claude Code Docker image (node:20-slim)
└── build                    # Build script

bin/claude                   # Claude Code wrapper script
```

---

## I/O Middleware

The Python middleware (`services/ai/`) is a lean filtering and security layer. It does not perform any AI analysis or make API calls.

### Filter Command

```bash
# Filter output via CLI
echo "npm warn deprecated package" | docker run --rm -i \
  ghcr.io/my-ez-cli/ai-service:latest \
  filter -

# Filter inline text
docker run --rm \
  ghcr.io/my-ez-cli/ai-service:latest \
  filter "noisy output text"
```

### Available Commands

```
filter <text|->                  Filter output using configured patterns
parse-claude-response            Parse Claude Code JSON from stdin, print result
  [--ai-file <path>]             Write analysis to sidecar file
  [--log-file <path>]            Original log path (stored as metadata in sidecar)
  [--log-session-id <id>]        Tool session ID (stored in sidecar)
--help, -h                       Show help
--version, -v                    Show version
```

---

## Claude Code Integration

Claude Code is the sole AI analysis engine in My Ez CLI.

### Docker Image

```dockerfile
FROM node:20-slim
RUN npm install -g @anthropic-ai/claude-code@latest
ENTRYPOINT ["claude"]
```

Image: `ghcr.io/my-ez-cli/claude:latest`

### Usage

**Interactive mode (OAuth):**
```bash
claude                    # Opens interactive Claude Code session
claude -p "help me debug" # Single-shot prompt
```

**Automated analysis:**
```bash
# Requires ANTHROPIC_API_KEY
mec ai analyze /path/to/log.json
mec ai test                        # Test Claude Code availability
mec ai status                      # Show AI integration status
```

**Log monitoring:**
```bash
mec logs list                      # Table of recent executions
mec logs list --tool node --last 5 # Filter by tool, limit results
mec logs failures                  # Only failed executions
mec logs stats                     # Aggregate stats per tool
```

### Authentication

Three auth methods are supported. See [docker/claude/README.md](../docker/claude/README.md#authentication) for full details.

| Method | Credential | Use case |
|--------|-----------|----------|
| API key | `ANTHROPIC_API_KEY` | Automated analysis (`exec_with_ai`, `mec ai analyze`) |
| OAuth long-lived token | `CLAUDE_CODE_OAUTH_TOKEN` | Automated use with Claude.ai subscription (no API credits) |
| OAuth web login | `~/.claude/` session | Interactive `bin/claude` sessions |

### Analysis Flow

When `MEC_AI_ENABLED=true` and a valid credential (`ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`) is set, `exec_with_ai()`:

1. Runs the tool command and captures output
2. If the command fails (non-zero exit), prints `[mec] Command failed (exit code N)` to stderr
3. Finalizes the log session (JSON file) — **the log file is never modified after this point**
4. Computes the sidecar path from the log path (`logs/` → `ai-analyses/`, same filename)
5. Invokes Claude Code in single-shot mode (`--output-format json`, `--max-turns 1`) with the log content
6. Pipes the Claude JSON response to `ai-service parse-claude-response`, which writes the result to the sidecar file
7. Displays the analysis text to stderr under `[mec-ai] Claude Code analysis:`
8. Prints a resume hint: `[mec-ai] To follow up: claude --resume <session-id> "your question here"`

If no credential is set, analysis is skipped. Set `MEC_DEBUG=1` to see the skip message.

### Sidecar Files (AI Analyses)

Tool log files are **immutable after finalization**. AI analyses are written to a parallel directory tree that mirrors `logs/` — the filename is the link between a log and its analysis.

```
~/.my-ez-cli/
├── logs/
│   └── node/
│       └── 2026-01-15_10-30-45.json    ← written once, never mutated
└── ai-analyses/
    └── node/
        └── 2026-01-15_10-30-45.json    ← created only if AI runs
```

**Sidecar schema:**

```json
{
  "log_session_id": "mec-node-1705318245",
  "log_file": "/abs/path/to/logs/node/2026-01-15_10-30-45.json",
  "analyses": {
    "abc-123-def": {
      "timestamp": "2026-02-19T20:00:00Z",
      "result": "This execution completed successfully..."
    }
  }
}
```

`mec logs list` and `mec logs stats` report the `AI` column by checking for the sidecar file — no log file parsing needed.

---

## Dashboard

The mec dashboard is a local web UI (Vue 3 + FastAPI) that visualises all session logs and AI analysis results in real time.

### Commands

```shell
mec dashboard start    # Start the container (API + UI on same port)
mec dashboard stop     # Stop and remove the container
mec dashboard restart  # Restart the container
mec dashboard status   # Show running state and URL
mec dashboard open     # Open in default browser
```

### Pages

| Page | URL | What |
|------|-----|------|
| Home | `/` | Stat cards (total sessions, success rate, AI rate, tools used) + 3 charts (sessions by tool, exit code distribution, last 7 days) |
| Sessions | `/sessions` | Paginated session list with search and filters (tool, AI status, exit code) |
| Session Detail | `/sessions/<id>` | Meta bar, command, log output, and AI analysis (markdown rendered). Shows **Resume AI** row with `claude --resume <id>` command when an AI analysis exists. |
| Tools | `/tools` | Read-only registry of all mec Docker tool wrappers |

### Architecture

The dashboard is a single Docker container (`ghcr.io/my-ez-cli/dashboard:latest`) built from a multi-stage Dockerfile:

- **Stage 1** (`node:22-alpine`): builds the Vue 3 + Vite + PrimeVue frontend into `/frontend/dist/`
- **Stage 2** (`python:3.12-alpine`): runs FastAPI + uvicorn; serves the built Vue assets from `/assets` and the REST API from `/api`

The frontend connects to a WebSocket (`/ws`) for live updates whenever new sessions are written to `~/.my-ez-cli/`.

### Configuration

```shell
# Change the default port (4242)
mec config set ai.dashboard.port <port>
mec dashboard restart
```

### Development (frontend)

When working on the Vue frontend, run the Vite dev server alongside the API container:

```shell
mec dashboard start   # start the API container on :4242

# in services/dashboard/frontend/:
MEC_BIND_PORTS="5173:5173" npm run dev -- --host 0.0.0.0 --port 5173
```

The Vite dev server auto-detects when it runs inside Docker (via `/.dockerenv`) and proxies `/api` and `/ws` to `host.docker.internal:4242` instead of `localhost:4242`.

---

## I/O Filtering

The filter engine reduces noise in tool output before sending to Claude Code, optimizing token usage. `ai.filters` is the **single filtering layer** — tool-specific noise patterns (npm, yarn, terraform, python, aws) are all expressed here as regex patterns.

### Configuration

In `config/config.default.yaml`:

```yaml
ai:
  filters:
    ignore_output:
      # npm / yarn noise
      - "^npm warn"
      - "^npm WARN"
      - "^npm notice"
      - "^yarn warning"
      # peer warnings
      - "^npm warn peer"
      - "^warning.*peer"
      # install progress
      - "^Downloading.*\\d+%"
      - "^added \\d+ packages"
      # terraform progress
      - "^.*: Refreshing state\\.\\.\\."
      - "Downloading registry\\."
      - "Installing provider"
      # python pip progress
      - "^Collecting "
      - "^Installing collected packages"
      # aws progress bars
      - "\\[[-=>#]+"
      - "^Completed \\d+"
      # general noise
      - "├──|└──|│"
      - "^\\s*$"
    ignore_input:
      - "node_modules/"
      - "*.lock"
      - ".git/"
```

To customize patterns, copy `config/config.default.yaml` to `~/.my-ez-cli/config.yaml` and edit `ai.filters.ignore_output`.

---

## Configuration

### Environment Variables

- `MEC_AI_ENABLED` — enable/disable AI analysis (`true`/`false`)
- `ANTHROPIC_API_KEY` — required for automated Claude Code analysis
- `MEC_DEBUG` — show debug messages including skip reasons (`1`/`0`)
- `MEC_LOG_LEVEL` — log verbosity

### Configuration Files

1. **Environment variables** (highest priority)
2. **User config** (`~/.my-ez-cli/config.yaml`) — overrides defaults
3. **Default config** (`config/config.default.yaml`) — safe to commit

### Example Configuration

```yaml
ai:
  enabled: true

  # ai.filters is the single filtering layer for all tools
  filters:
    ignore_output:
      - "^npm warn"
      - "^npm WARN"
      - "^Downloading.*\\d+%"
      - "├──|└──|│"
      - "^\\s*$"
    ignore_input:
      - "node_modules/"

  claude:
    image: "ghcr.io/my-ez-cli/claude:latest"
    max_turns: 1
    output_format: json
```

---

## Testing

### Running Tests

```bash
# All tests
docker run --rm --entrypoint python \
  ghcr.io/my-ez-cli/ai-service:latest \
  -m pytest tests/ -v

# Claude response parser + sidecar writer tests
docker run --rm --entrypoint python \
  ghcr.io/my-ez-cli/ai-service:latest \
  -m pytest tests/test_claude_response.py -v

# Filter engine tests
docker run --rm --entrypoint python \
  ghcr.io/my-ez-cli/ai-service:latest \
  -m pytest tests/test_filter_engine.py -v

# Test filter command works
echo "npm warn deprecated" | docker run --rm -i \
  ghcr.io/my-ez-cli/ai-service:latest filter -

# Test Claude Code auth
ANTHROPIC_API_KEY=your-key mec ai test
```

### Test Standards

- Use pytest framework
- Mock external dependencies
- Minimum 80% coverage

See [`CODE_STANDARDS.md`](./CODE_STANDARDS.md) for detailed guidelines.

---

## Resources

- **Code Standards:** [`CODE_STANDARDS.md`](./CODE_STANDARDS.md)
- **ROADMAP:** [`ROADMAP.md`](./ROADMAP.md)
- **Main Guide:** [`../CLAUDE.md`](../CLAUDE.md)

---

## Change History

- **2026-02-20**: Parallel AI-analyses directory (immutable log files)
  - Tool log files are now immutable after finalization — never mutated by AI
  - AI analyses written to `~/.my-ez-cli/ai-analyses/<tool>/<timestamp>.json` (sidecar)
  - `parse-claude-response` updated: `--ai-file`, `--log-file`, `--log-session-id` args
  - `mec logs list/failures/stats` detect AI presence via sidecar file existence
  - Removed stripping block from `analyze_with_claude()` — no longer needed
- **2026-02-17**: Remove rule-based analyzers; pivot middleware to I/O-only
  - Deleted all rule-based analyzers (port detector, error analyzer, env suggester)
  - Python middleware is now a pure I/O filter/security layer
  - All analysis now goes through Claude Code
  - API key or OAuth token required for automated analysis; web OAuth for interactive use
  - Removed `MEC_AI_DEEP` — analysis runs whenever `MEC_AI_ENABLED=true` and API key is set
- **2026-02-16**: Architecture pivot to Claude Code + rule-based middleware
  - Removed all AI provider code (Anthropic SDK, OpenAI, LiteLLM, Llama)
  - Analyzers refactored to pure rule-based pattern matching
  - Added I/O filter engine for token optimization
  - Added Claude Code as first-class tool (bin/claude + Docker image)
  - Added `mec ai` CLI subcommands
- **2026-01-20**: Initial AI integration documentation
