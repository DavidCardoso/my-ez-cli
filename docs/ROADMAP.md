# My Ez CLI - v1.0.0 Roadmap

**Status:** Phase 3.5 In Progress - v1.0.0 Release Candidate
**Target:** First Stable Release (v1.0.0)
**Previous Versions:** 0.x.y (beta releases)
**Phase 1 Completed:** 2026-01-20
**Phase 2 Completed:** 2026-02-16
**Phase 2.9 Completed:** 2026-02-20
**Phase 3 Started:** 2026-03-24

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [v1.0.0 Status](#v10-status)
4. [Implementation Phases](#implementation-phases)
5. [Future Roadmap](#future-roadmap)
6. [Version Roadmap](#version-roadmap)
7. [Priority Matrix](#priority-matrix)
8. [Success Criteria](#success-criteria)

---

## Project Overview

My Ez CLI is a collection of Docker-based wrapper scripts providing sandboxed access to development tools (Node.js, AWS CLI, Terraform, Python, etc.) without local installation. Each tool runs in an isolated Docker container with appropriate volume mounts and environment configurations.

### Core Purpose

**My Ez CLI is a tooling platform, not an AI platform.**

- **Primary function:** Sandboxed Docker tool wrappers
- **AI integration:** Powered by Claude Code CLI for deep analysis
- **Lean middleware:** Rule-based pattern matching for automatic suggestions
- **Separation of concerns:** AI infrastructure belongs in separate "Local AI Stack" project

### Key Principles

- **Claude Code-first:** Use Claude Code CLI as the AI layer
- **No custom AI providers:** Claude Code manages model selection and authentication
- **BYOK via Claude Code:** Users authenticate via `~/.claude/` or `.claude/settings.local.json`
- **Claude Code as sole analysis engine:** All analysis goes through Claude Code
- **Opt-in AI:** Disabled by default, enabled via `mec ai enable`
- **Graceful degradation:** AI features are optional; tools work without them

---

## Architecture

### v1.0.0 Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│  bin/* tool scripts (node, aws, terraform, etc.)    │
│  Each tool: setup_logging → docker run → log output │
│  log file written once, immutable after finalize    │
└──────────┬──────────────────────────────────────────┘
           │ after execution
           ▼
┌─────────────────────────────────────────────────────┐
│  I/O Middleware (services/ai/)                       │
│  - Output filtering (reduce noise, token savings)    │
│  - parse-claude-response: parse + write AI sidecar   │
│  - Config-driven filter patterns                     │
└──────────┬──────────────────────────────────────────┘
           │ when MEC_AI_ENABLED=true + credential set
           ▼
┌─────────────────────────────────────────────────────┐
│  Claude Code CLI (bin/claude)                        │
│  - Automated analysis (exec_with_ai, mec ai analyze) │
│  - Interactive sessions (user invokes bin/claude)    │
│  - Model selection via Claude Code's own settings    │
│  - Auth: API key, OAuth token, or web login          │
└──────────┬──────────────────────────────────────────┘
           │ result written to parallel sidecar
           ▼
┌─────────────────────────────────────────────────────┐
│  ~/.my-ez-cli/ai-analyses/<tool>/<timestamp>.json   │
│  Mirrors logs/ tree — same filename, separate dir   │
└─────────────────────────────────────────────────────┘
```

### Input/Output Filtering (Token Optimization)

The lean Python layer applies filtering BEFORE sending context to Claude Code:

**Config YAML rules:**
```yaml
ai:
  filters:
    ignore_output:
      - "^npm warn"           # npm deprecation warnings
      - "^Downloading.*\\d+%" # download progress bars
      - "├──|└──|│"           # dependency tree formatting
    ignore_input:
      - "node_modules/"       # never send node_modules paths
      - "*.lock"              # lock file contents
```

### Project Structure

```
my-ez-cli/
├── bin/                    # Tool wrapper scripts
│   ├── aws, node, terraform, etc.
│   ├── claude              # Claude Code CLI wrapper
│   ├── mec                 # Main CLI entry point
│   └── utils/              # Shell utilities
│       ├── common.sh       # Core functions + exec_with_ai()
│       ├── config-manager.sh
│       └── log-manager.sh
├── services/ai/            # I/O middleware (Python 3.14, filter-only)
│   ├── src/
│   │   ├── claude_response.py  # Parse Claude JSON + write AI sidecar
│   │   ├── filters/            # I/O filtering engine
│   │   ├── utils/
│   │   └── main.py             # CLI dispatcher
│   ├── tests/
│   └── pyproject.toml
├── docker/                 # Custom Dockerfiles
│   ├── claude/             # Claude Code Docker image
│   ├── aws-sso-cred/
│   ├── serverless/
│   └── ...
├── tests/                  # Test suite (bats-core)
│   ├── unit/               # 65 unit tests
│   └── integration/        # 8 integration tests
├── config/
│   └── config.default.yaml # Default configuration
├── docs/
│   ├── ROADMAP.md          # This file
│   ├── AI_INTEGRATION.md   # AI architecture details
│   ├── CODE_STANDARDS.md   # Python standards
│   └── DOCKER_HUB.md       # Docker Hub setup
├── setup.sh                # Installation script
└── CLAUDE.md               # Project guidance for Claude Code
```

### Docker Hub Images

**Repository:** `davidcardoso/my-ez-cli`

**Images:**
- `davidcardoso/my-ez-cli:ai-service-latest` - Lean Python middleware
- `davidcardoso/my-ez-cli:claude-latest` - Claude Code CLI
- `davidcardoso/my-ez-cli:aws-sso-cred-latest`
- `davidcardoso/my-ez-cli:serverless-latest`
- `davidcardoso/my-ez-cli:speedtest-latest`
- `davidcardoso/my-ez-cli:yarn-berry-latest`

---

## v1.0.0 Status

### ✅ Completed Features

**Phase 1 - Foundation (Completed: 2026-01-20)**
- ✅ Path resolution fixes (`common.sh` with symlink-safe utilities)
- ✅ Multi-select installation in `setup.sh`
- ✅ Comprehensive test framework (73 tests: 65 unit, 8 integration)
- ✅ Docker Hub migration (from GitHub Container Registry)
- ✅ Enhanced documentation (SETUP.md, DOCKER_HUB.md, tests/README.md)
- ✅ GitHub Actions CI/CD with multi-platform builds (linux/amd64, linux/arm64)
- ✅ Container naming and labeling (`mec-{tool}-{timestamp}`)

**Phase 2 - AI Integration (Completed: 2026-02-16)**
- ✅ Claude Code as first-class tool (`bin/claude` + Docker image)
- ✅ I/O middleware (Python) for filtering and token optimization — no rule-based analyzers
- ✅ All analysis through Claude Code (rule-based analyzers later removed)
- ✅ `mec ai` CLI subcommands (status, enable, disable, test, analyze)
- ✅ All bin scripts wired to `exec_with_ai()` for automatic analysis
- ✅ Configuration system updated with AI filters and Claude Code settings
- ✅ Log persistence system with structured JSON format
- ✅ Terraform-style config precedence (env → user → defaults)

**Phase 2.9 - Immutable Logs + AI Sidecar (Completed: 2026-02-20)**
- ✅ Tool log files are immutable after finalization — never mutated by AI
- ✅ AI analyses written to parallel `~/.my-ez-cli/ai-analyses/<tool>/<timestamp>.json` sidecar
- ✅ `parse-claude-response` updated: `--ai-file`, `--log-file`, `--log-session-id` args
- ✅ `mec logs list/failures/stats` detect AI presence via sidecar file existence (no log parsing)
- ✅ Removed stripping block from `analyze_with_claude()` — log files are clean by design

### Usage Examples

```bash
# Enable AI features
mec ai enable

# Claude Code analysis runs automatically after tool execution (requires ANTHROPIC_API_KEY)
node app.js
# [mec-ai] Running analysis with Claude Code...
# [mec-ai] Claude Code analysis: (detailed suggestions)

# Interactive Claude Code session
claude

# Analyze a log file directly
mec ai analyze ~/.my-ez-cli/logs/node/2026-02-16.json

# Check AI status
mec ai status
# AI Status: enabled
# Claude Code: available (authenticated)
```

---

## Implementation Phases

### Phase 1: Foundation ✅

**Status:** Complete
**Priority:** P0 (Critical)
**Completed:** 2026-01-20
**Goal:** Fix critical issues, establish solid base

**Completed Tasks:**
- ✅ Fix bin/utils path resolution
- ✅ Create `src/utils/common.sh` with unified utilities
- ✅ Update all bin scripts to use common.sh
- ✅ Improve setup.sh with multi-select installation
- ✅ Add install/uninstall/status commands
- ✅ Create GitHub workflows for Docker builds
- ✅ Set up testing framework with bats-core
- ✅ Write unit and integration tests (73 tests total)
- ✅ Add CI testing with parallel execution and Docker caching
- ✅ Trim project (remove EOL Node versions, unused tools)
- ✅ Container naming and labeling conventions

**Deliverables:**
- All scripts work from any location (symlink-safe)
- Multi-select installation with interactive mode
- Automated Docker image builds with multi-platform support
- Comprehensive test coverage (73 tests passing)
- CI/CD optimized for speed (67% faster with caching)

---

### Phase 2: AI Integration ✅

**Status:** Complete
**Priority:** P0 (Critical)
**Completed:** 2026-02-16
**Goal:** AI-powered assistance with Claude Code as the sole analysis engine

**Language:** Python 3.14 (services/ai/) + Shell (bin/claude)
**Deployment:** Docker containers

**Architecture:** Single-path analysis via Claude Code
- **I/O middleware** (Python): Filtering and token optimization only — no rule-based analysis
- **Claude Code CLI:** All analysis (requires `ANTHROPIC_API_KEY` for automated use)

**Architectural Pivot:** Original provider-based architecture (Anthropic SDK, OpenAI, LiteLLM, Llama) replaced with Claude Code as the AI layer. Rule-based analyzers (port_detector, error_analyzer, env_suggester) were built initially and later removed — all analysis delegated to Claude Code. All custom AI provider code removed.

#### Phase 2.1: Foundation ✅
- ✅ Created `services/ai/` directory structure
- ✅ Wrote `Dockerfile` (python:3.14-alpine)
- ✅ Implemented base analyzer class (rule-based, no AI provider dependency)
- ✅ Implemented `src/utils/config.py` with Terraform-style precedence
- ✅ Created `src/main.py` CLI dispatcher
- ✅ Built and tested Docker image

#### Phase 2.2: Analyzers (Rule-Based) ✅ *(later removed in Phase 2.6)*
- ✅ Created `src/analyzers/port_detector.py` — port binding detection via regex
- ✅ Created `src/analyzers/error_analyzer.py` — error pattern detection
- ✅ Created `src/analyzers/env_suggester.py` — missing env var detection
- ✅ All analyzers use pure regex/rule-based detection (no AI API calls)
- ✅ Wrote comprehensive tests (88 tests, all passing)
- ✅ Structured JSON output format
- *(Note: All analyzer files later removed — analysis delegated entirely to Claude Code)*

#### Phase 2.3: I/O Filter Engine ✅
- ✅ Created `src/filters/engine.py` — pattern-based I/O filtering
- ✅ Configurable regex patterns from config YAML
- ✅ Default patterns for npm warnings, progress bars, tree formatting
- ✅ Wrote filter engine tests

#### Phase 2.4: Claude Code Integration ✅
- ✅ Created `docker/claude/Dockerfile` (node:20-slim + @anthropic-ai/claude-code)
- ✅ Created `bin/claude` wrapper script
- ✅ Mounted PWD as workspace, ~/.claude/ for auth persistence
- ✅ Pass ANTHROPIC_*, CLAUDE_*, MEC_* env vars
- ✅ Interactive and single-shot modes via TTY detection
- ✅ Added to `setup.sh` (install_claude/uninstall_claude)
- ✅ Wrote bats tests (20 tests, all passing)
- ✅ Conflict detection in `install_claude()`: detects Homebrew/Anthropic-script/unknown installs, presents side-by-side / replace / skip menu
- ✅ `mec claude` subcommand proxies to `bin/claude` regardless of symlink state
- ✅ `mec ai status` reports active Claude wrapper symlink name

#### Phase 2.5: Shell Integration ✅
- ✅ Refactored `exec_with_ai()` for single-path Claude Code analysis in `common.sh`
- *(Note: `analyze_with_rules()` was created initially and later removed)*
- *(Note: `MEC_AI_DEEP` env var was planned but later removed — Claude Code is the sole analysis path)*
- ✅ Wired all bin scripts to `exec_with_ai()`: node, npm, npx, yarn, yarn-berry, python, terraform, aws, gcloud, serverless, speedtest, playwright, promptfoo (cdktf removed — CDKTF discontinued)
- ✅ Used `[mec-ai]` prefix for suggestions
- ✅ Graceful error handling (silent if AI disabled/unavailable)
- ✅ Support jq for formatted output (fallback without jq)

#### Phase 2.6: Provider Code Removal ✅
- ✅ Deleted all provider files (anthropic.py, openai.py, litellm.py, llama.py, base.py)
- ✅ Removed AI SDK dependencies (anthropic, openai, ollama, litellm) from pyproject.toml
- ✅ Removed all provider tests
- ✅ Simplified exception hierarchy (removed provider exceptions)
- ✅ Docker image significantly smaller without AI SDK deps

#### Phase 2.7: Configuration & CLI ✅
- ✅ Updated `config/config.default.yaml` — model tiers, ai.filters, ai.claude sections
- ✅ Updated `config-manager.sh` fallback config and export
- ✅ Added `mec ai` subcommands: status, enable, disable, test, analyze
- ✅ Updated `mec help` with AI commands
- ✅ Rewrote `docs/AI_INTEGRATION.md` — new architecture
- ✅ Updated `CLAUDE.md` — Phase 2 complete status
- ✅ Updated `README.md` — Claude Code section, AI Features section

#### Phase 2.8: Hardening & UX ✅
- ✅ `bin/yarn-plus` wired to `exec_with_ai()` (was bare `eval`) — all bin scripts now fully wired
- ✅ Conflict detection for all CLI-name-sharing tools: `node`, `npm`, `npx`, `yarn`, `terraform`, `python`, `aws`, `gcloud`, `serverless`, `speedtest`, `playwright`, `promptfoo` — 3-option menu (side-by-side as `mec-<tool>`, replace, skip)
- ✅ `npx` special handling: checks for native Node.js first and warns before replacing system-managed npx
- ✅ All `uninstall_*` functions remove `mec-<tool>` side-by-side symlink
- ✅ `verify_installation()` accepts either primary symlink or `mec-<tool>` for all conflict-aware tools
- ✅ `mec setup` subcommand — opens interactive TUI
- ✅ `mec setup show` — shows installation status table
- ✅ `mec install <tool>` and `mec uninstall <tool>` as top-level `mec` subcommands
- ✅ Unit tests for `detect_existing_tool()`, `detect_existing_claude()`, `detect_claude_install_method()` in `test-setup.bats`
- ✅ Manual testing checklist added to `docs/SETUP.md`

**Deliverables:**
- I/O middleware (Python, filter-only — no rule-based analyzers)
- Claude Code as first-class Docker tool (bin/claude + Docker image)
- I/O filter engine for token optimization
- Single-path analysis via Claude Code (requires `ANTHROPIC_API_KEY`)
- `mec ai` CLI subcommands (status, enable, disable, test, analyze)
- All bin scripts wired to `exec_with_ai()`
- Terraform-style config precedence (env vars → user config → default)

---

### Phase 2.9: Immutable Logs + AI Sidecar ✅

**Status:** Complete
**Priority:** P0 (Critical)
**Completed:** 2026-02-20
**Goal:** Eliminate AI→log feedback loop; make tool log files immutable after finalization

**Changes:**
- ✅ `write_ai_analysis()` replaces `append_to_log()` — writes to sidecar, never touches log file
- ✅ `parse-claude-response` updated with `--ai-file`, `--log-file`, `--log-session-id` args
- ✅ `analyze_with_claude()` computes sidecar path, mounts log as `:ro`, removed stripping block
- ✅ `_ai_sidecar_exists()` helper in `bin/mec`; all four `ai_analyses` grep checks replaced
- ✅ `TestWriteAiAnalysis` replaces `TestAppendToLog` in test suite (7 tests)

**Deliverables:**
- Immutable tool log files (written once, never mutated)
- `~/.my-ez-cli/ai-analyses/` parallel directory mirrors `logs/` tree
- No token waste from prior AI output being re-analyzed
- `mec logs list/failures/stats` AI column works via filesystem check

---

### Phase 3: AI Performance + Dashboard ✅

**Status:** Complete
**Priority:** P0 (Critical)
**Started:** 2026-03-24
**Completed:** 2026-03-25
**Goal:** Eliminate AI analysis blocking delay and deliver an early Web UI for log + analysis review

#### Phase 3.1 — Async Analysis + mec ai last/logs ✅

- ✅ `analyze_with_claude()` fires in background — shell unblocks immediately after tool finishes
- ✅ Terminal prints session ID + dashboard URL on every run
- ✅ `mec ai last` — show most recent AI analysis (ad-hoc fallback)
- ✅ `mec ai show <session_id>` — show any session by ID
- ✅ `mec ai logs` — list recent sessions with status (pending/done)

**Deliverables:**
- Non-blocking AI analysis
- Session-aware terminal output with direct link to results
- `mec ai last`, `mec ai show`, `mec ai logs` subcommands

#### Phase 3.2 — Dashboard Daemon ✅

- ✅ `services/dashboard/` — Python/FastAPI server with `watchfiles` + WebSocket hot-reload
- ✅ `docker/dashboard/Dockerfile` — `python:3.12-alpine`, exposes port `4242`
- ✅ `mec dashboard start | stop | status | open` subcommands
- ✅ Web UI: session list + detail (raw log + AI analysis side-by-side), auto-refreshes when new analysis arrives
- ✅ `davidcardoso/my-ez-cli:dashboard-latest` Docker Hub image
- ✅ `ai.dashboard.port` config key (default: `4242`)

**Deliverables:**
- Long-running dashboard container managed by `mec dashboard`
- Hot-reload UI replaces terminal output as the primary analysis surface

---

### Phase 3.4: mec doctor ✅

**Status:** Complete
**Priority:** P1
**Completed:** 2026-03-26
**Goal:** Health-check subcommand for Docker, Zsh, AI, dashboard, data directory, and auth

- ✅ `mec doctor` prints ✓/⚠/✗ per check with summary line
- ✅ Exits 1 if any check fails (scriptable: `mec doctor && deploy`)
- ✅ Checks: Docker daemon, Zsh + Oh My Zsh, data dir, config file, logs, AI enabled/images/auth, dashboard image/running
- ✅ Unit tests in `tests/unit/test-doctor.bats` (14 tests)

**Deliverables:**
- Single `mec doctor` command for full environment health check
- Structured pass/warn/fail output with actionable hints

---

### Phase 3.5: Execution Metrics & Session Insight ⏳

**Status:** In Progress
**Priority:** P1 (High)
**Started:** 2026-03-26
**Goal:** Capture AI execution timing and token usage in sidecars; ship `mec purge`; improve dashboard UX; project documentation hygiene.

**Completed Tasks:**
- ✅ CHANGELOG backfill (Phase 3.1–3.4 + ad-hoc fixes)
- ✅ README status badges + Mermaid architecture diagram
- ✅ AI sidecar schema extended: `execution_time_ms`, `tokens.input`, `tokens.output`
- ✅ `mec purge` subcommand
- ✅ `mec dashboard rebuild` + `restart --rebuild`
- ✅ Session search extended to command + cwd
- ✅ NavBar status chips auto-refresh fix

**Deliverables:**
- *(to be confirmed on completion)*

---

## Future Ideas

Items below are not scheduled — they may become implementation phases once v1.0.0 is stable.

- Multi-category tools — `TOOL_REGISTRY` tools like `promptfoo` (ai + testing) and `serverless` (cloud + infra) belong to multiple categories; currently a single `category: str` field limits display on the Tools page to one tag per tool; change to `categories: list[str]` and update `ToolsPage.vue` to render multiple tags per row
- Shell completion (`mec` CLI, zsh/bash)
- Decouple from Zsh — make mec compatible with other shells (bash as default/fallback); currently requires Zsh + Oh My Zsh
- `mec help <tool>` — tool-specific help with examples
- Homebrew formula (`brew install my-ez-cli`)
- Claude Code MCP server for my-ez-cli tools
- Better error messages and onboarding
- PostgreSQL log storage (opt-in)
- Full configuration editor UI
- Log encryption (AES-256-GCM, opt-in)
- Custom image local fallback — when a custom Docker image pull fails (e.g. speedtest, serverless), fall back to locally-built image if available rather than failing with "image not found"
- Prompt injection hardening — tool output passed to Claude as inline prompt content could contain adversarial instructions; sanitization beyond control-char stripping (e.g. delimiters, input validation, output sandboxing)
- CVE / security advisory scanning — cross-reference tool execution logs and AI analysis results against known CVE databases (NVD, OSV, GitHub Advisory) and security issue DBs; flag vulnerable package versions, deprecated images, or insecure patterns detected at runtime (needs proper planning: data sources, update cadence, false-positive rate, opt-in UX)
- Elasticsearch + Kibana integration
- NPM publishing (`@my-ez-cli/core`)
- Remote execution (curl install script)
- Local AI Stack integration (separate project)

**Cut from scope:**
- Docker Compose generation (users can create compose files directly)
- Warp workflow integration (terminal-specific, low priority)
- Unity Catalog integration (belongs in "Local AI Stack" project)
- Debian packages (low ROI)

---

## Priority Matrix

| Item | Phase | Priority | Impact | Effort | Status |
|------|-------|----------|--------|--------|--------|
| Path resolution | 1 | P0 | High | Low | ✅ Complete |
| Setup improvements | 1 | P0 | High | Medium | ✅ Complete |
| GitHub workflows | 1 | P0 | High | Low | ✅ Complete |
| Testing | 1 | P0 | High | Medium | ✅ Complete |
| Project trimming | 1 | P0 | Medium | Low | ✅ Complete |
| Log persistence | 2 | P0 | High | Medium | ✅ Complete |
| Configuration system | 2 | P0 | High | Low | ✅ Complete |
| Rule-based analyzers | 2 | P0 | High | Medium | ✅ Complete |
| I/O filter engine | 2 | P0 | High | Medium | ✅ Complete |
| Claude Code integration | 2 | P0 | High | High | ✅ Complete |
| Shell integration | 2 | P0 | High | Medium | ✅ Complete |
| Provider removal | 2 | P0 | High | Low | ✅ Complete |
| Async AI analysis | 3.1 | P0 | High | Low | ✅ Complete |
| mec ai last/logs/show | 3.1 | P0 | High | Low | ✅ Complete |
| Dashboard daemon | 3.2 | P0 | High | High | ✅ Complete |
| Dashboard Web UI | 3.2 | P0 | High | High | ✅ Complete |
| Shell completion | Future | P1 | Medium | Low | 💡 Future |
| `mec doctor` | 3.4 | P1 | High | Medium | ✅ Complete |
| Homebrew formula | Future | P1 | Medium | Medium | 💡 Future |
| PostgreSQL logs | Future | P2 | Low | Medium | 💡 Future |
| Log encryption | Future | P2 | Medium | Medium | 💡 Future |
| Prompt injection hardening | Future | P2 | High | Medium | 💡 Future |
| CVE / security advisory scanning | Future | P2 | High | High | 💡 Future |
| Elasticsearch | Future | P3 | Low | High | 💡 Future |

---

## Success Criteria

### v1.0.0 is ready when:

- ✅ All Phase 1 tasks complete (path resolution, setup, workflows, tests)
- ✅ All Phase 2 tasks complete (Claude Code, I/O middleware, config)
- ✅ All Phase 2.8 tasks complete (hardening, conflict detection, mec subcommands)
- ✅ All Phase 2.9 tasks complete (immutable logs, AI sidecar directory)
- ✅ All existing tools work with new structure
- ✅ Documentation updated (ROADMAP.md, AI_INTEGRATION.md, CLAUDE.md, README.md)
- ✅ At least 70% test coverage achieved (currently 73 tests + 8 new conflict detection tests)
- [ ] Final verification testing passed
- [ ] Release notes written
- ✅ CHANGELOG.md updated
- ✅ Claude install conflict detection implemented
- ✅ Conflict detection for all CLI-name-sharing tools implemented

---

## Notes

### Core Principles

- **v1.0.0 is the first stable release** - Previous versions were 0.x.y (beta)
- **Claude Code-first architecture** - No custom AI providers
- **Lean Python middleware** - I/O filtering only, no AI SDK dependencies, no rule-based analyzers
- **Claude Code as sole analysis engine** - All analysis goes through Claude Code
- **Graceful degradation** - AI features are optional enhancements

### Architectural Decisions

- **Provider removal:** All custom AI provider code (Anthropic SDK, OpenAI, LiteLLM, Llama) was removed. Claude Code manages its own model selection and authentication.
- **I/O filtering:** Token optimization happens BEFORE sending context to Claude Code
- **Immutable logs:** Tool log files are written once and never mutated. AI analyses live in a parallel `ai-analyses/` directory (same filename, different root).
- **Authentication:** BYOK via Claude Code settings (`~/.claude/` or `.claude/settings.local.json`)
- **Model tiers:** Simple config (faster/smarter/advanced) mapped by Claude Code, not my-ez-cli

### Technology Choices

- **AI integration uses BYOK** - Users authenticate Claude Code via OAuth or API keys
- **Python 3.14** - Latest stable Python for services/ai/
- **Docker-based** - All tools and services run in containers
- **Shell utilities** - Bash scripts for bin/ wrappers

### Design for Future-Proofing

- **Modular log layers:** Application → Manager → Modules → Storage
- **Pluggable storage:** File (v1.0) → Database exporters (v1.4+)
- **Schema versioning:** Log entry schema v1 with version field
- **Backward compatibility:** Old logs readable, new features opt-in, no API breakage

### Trimmed Scope

**Cut from roadmap:**
- Docker Compose generation - users can create compose files directly
- Warp workflow integration - terminal-specific, low priority
- Unity Catalog integration - belongs in "Local AI Stack" project
- Debian packages - low ROI, focus on Homebrew and NPM

**Deferred to "Local AI Stack" project:**
- Multi-provider orchestration
- Custom routing logic
- Cost optimization across providers
- Prompt template systems

---

## Reminders

- [ ] **Update CHANGELOG.md** before v1.0.0 release
- [ ] **Write migration guide** for users upgrading from 0.x.y
- [ ] **Create release notes** summarizing v1.0.0 features
- [ ] **Announce release:** Blog post, Reddit, HN, Twitter
- [ ] **Gather feedback:** Create feedback form for v1.0.0 users
- [ ] **Create Homebrew tap** after v1.1.0 planning starts

---

*This roadmap is a living document. Update as implementation progresses.*

**Last updated:** 2026-03-25
