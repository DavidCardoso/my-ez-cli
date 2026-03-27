# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0-rc] - WIP

First release candidate for v1.0.0. Combines Phase 1 (Docker tooling foundation) and Phase 2 (AI integration via Claude Code).

> **Note:** All prior releases were 0.x.y pre-release/beta.

### Added

#### Phase 1 — Foundation
- `bin/utils/common.sh` with shared utilities: `get_container_name()`, `get_container_labels()`, `exec_with_ai()`
- `bin/utils/docker.sh` with TTY detection via `get_tty_flag()`
- Multi-select interactive installation in `setup.sh` (terminal-based, no ncurses)
- Command-line mode for `setup.sh`: `install`, `uninstall`, `status`, `list`, `help`
- Installation tracking via `$HOME/.my-ez-cli/installed`
- Comprehensive test framework using `bats-core` (73 tests: 65 unit, 8 integration)
- Docker Hub migration: all custom images moved to `davidcardoso/my-ez-cli` repository
- Container naming (`mec-{tool}-{timestamp}`) and labeling (`com.my-ez-cli.*`) across all bin scripts
- GitHub Actions CI/CD workflows for multi-platform Docker image builds
- Documentation: `docs/SETUP.md`, `docs/DOCKER_HUB.md`, `tests/README.md`

#### Phase 2 — AI Integration
- `bin/claude` wrapper script + `docker/claude/Dockerfile` (Claude Code CLI in Docker)
- `docker/claude/init-firewall.sh` for network isolation in Claude Code container
- I/O middleware service (`services/ai/`, Python 3.14) for output filtering and token optimization
- `mec ai` subcommands: `status`, `enable`, `disable`, `test`, `analyze`
- `exec_with_ai()` in `bin/utils/common.sh` for automatic Claude Code analysis on tool output
- All bin scripts wired to `exec_with_ai()` (triggered when `MEC_AI_ENABLED=true` and `ANTHROPIC_API_KEY` is set)
- `bin/yarn-plus` wrapper: Yarn with git, curl, and jq pre-installed (useful for Projen workflows)
- `davidcardoso/my-ez-cli:yarn-plus-latest` Docker image
- Conflict detection in `setup.sh` when installing Claude Code (`install_claude()`):
  - Detects pre-existing `claude` in PATH and whether it is mec-managed or external
  - Presents a 3-option interactive menu: side-by-side (`mec-claude`), replace (with guided uninstall), or skip
  - Helper functions: `detect_existing_claude()`, `detect_claude_install_method()`, `uninstall_native_claude()`
  - Supports Homebrew (`brew uninstall`), Anthropic install script (`rm`), and unknown installations (manual instructions)
  - Fresh installs now create both `/usr/local/bin/claude` and `/usr/local/bin/mec-claude` symlinks
- `mec claude` subcommand in `bin/mec` — proxies to `bin/claude` regardless of symlink state
- `mec ai status` now shows which symlink name the Claude Docker wrapper is accessible under (`claude` or `mec-claude`)

#### Phase 2.8 — Hardening & UX
- `mec setup` subcommand — opens interactive TUI (`./setup.sh` with no args)
- `mec setup show` — shows installation status table (proxies to `./setup.sh status`)
- `mec install <tool>` and `mec uninstall <tool>` as top-level `mec` subcommands
- Conflict detection for all tools sharing a CLI name with widely-used tools: `node`, `npm`, `npx`, `yarn`, `terraform`, `python`, `aws`, `gcloud`, `serverless`, `speedtest`, `playwright`, `promptfoo` — 3-option menu (side-by-side as `mec-<tool>`, replace, skip)
- `npx` conflict detection: checks for native Node.js first; warns that replacing npx may break native node functionality; falls back to side-by-side (`mec-npx`)
- Unit tests for `detect_existing_tool()`, `detect_existing_claude()`, `detect_claude_install_method()` in `tests/unit/test-setup.bats`
- `bin/utils/common.sh` now auto-reads `ai.enabled` and `logging.enabled` from `~/.my-ez-cli/config.yaml` at source time — no manual env vars needed after `mec ai enable` / `mec logging enable`
- `mec logging` subcommand with `status`, `enable`, `disable`, and `help` commands — parallel to `mec ai` for discoverability
- `mec ai status` now shows logging state with a hint when logging is disabled (AI analysis requires logging)
- `mec logging` renamed to `mec logs` (cleaner notation; `logging` dispatch removed)
- `analyze_with_claude()` switched to `--output-format json`; Claude analysis written to sidecar file under `ai-analyses/` (see Phase 2.9)
- Resume hint printed after analysis: `[mec-ai] To follow up: claude --resume <session-id> "..."`
- `exec_with_ai()` prints `[mec] Command failed (exit code N)` banner on non-zero exits
- `mec logs list [--tool <name>] [--last N]`, `mec logs failures [--last N]`, and `mec logs stats` monitoring subcommands

#### Phase 2.9 — Immutable Logs + AI Sidecar
- Tool log files are now immutable after finalization — never mutated after `log_session_finalize` runs
- AI analyses written to a parallel `~/.my-ez-cli/ai-analyses/<tool>/<timestamp>.json` sidecar (same filename as the log, different root directory)
- `services/ai/src/claude_response.py`: replaced `append_to_log()` with `write_ai_analysis()` — writes sidecar schema `{log_session_id, log_file, analyses: {<claude_session_id>: {timestamp, result}}}`
- `parse-claude-response` command updated: `--log-file` is now metadata-only; new `--ai-file` and `--log-session-id` args control sidecar write
- `analyze_with_claude()` in `bin/utils/common.sh`: computes sidecar path from log path, mounts log as read-only, removed the `ai_analyses` stripping block (no longer needed)
- `bin/mec`: added `_ai_sidecar_exists()` helper; replaced all four `ai_analyses` grep/python checks with sidecar file existence checks
- `TestWriteAiAnalysis` replaces `TestAppendToLog` in `services/ai/tests/test_claude_response.py`

#### Phase 3.1–3.3 — Dashboard & Web UI

- `mec dashboard` subcommand: `start`, `stop`, `restart`, `status`, `open`, `help`
- FastAPI + Vue 3 dashboard at `http://localhost:4242` (multi-stage Docker build)
- `/api/sessions` — list sessions (limit=50, newest-first), returns `{sessions, total}`
- `/api/sessions/{id}` — session detail view
- `/api/stats` — aggregate stats: total_sessions, sessions_by_tool, tool_stats, exit_code_distribution, ai_analysis_rate, last_7_days, logs_enabled, ai_enabled
- WebSocket `/ws` — file-system-change hot reload
- Home page: stat cards, tool stats table, bar/donut/line charts
- Sessions page: session list with tool/AI/exit-code filters + session ID search
- Session detail modal: command, cwd, stdout/stderr, AI analysis result
- NavBar: `LogsStatus` and `AIStatus` chips (reads config), WebSocket live indicator
- `tool_stats` per-tool breakdown in `/api/stats` (sessions, success, ai_done)
- `logs_enabled` / `ai_enabled` flags in `/api/stats` (reads `~/.my-ez-cli/config.yaml`)
- ANSI/control-char stripping in `_read_json()` — recovers corrupted log files
- Session total fix: `total` counts only valid JSON sessions, not raw file count
- Tool filter sourced from `/api/stats` (all-time) not just the current fetch window

#### Phase 3.4 — Health Check

- `mec doctor` subcommand: full environment health check (Docker, images, config, credentials, dashboard)
- Exit code 0 = healthy, non-zero = one or more checks failed

#### Phase 3.5 — Execution Metrics, Purge & UX

- AI sidecar extended with `execution_time_ms` and `tokens: {input, output}` fields — wall-clock timing captured around the Claude Code Docker pipeline; tokens extracted from `--output-format json` response (#65)
- Dashboard Sessions page: AI Time column shows analysis duration for each session (#65)
- `mec purge` subcommand: delete logs and/or AI analyses with `--tool`, `--older-than`, `--only-logs`, `--only-ai-analyses`, `--dry-run`, `-y` flags; interactive confirmation by default (#66)
- `mec dashboard rebuild` subcommand: builds dashboard Docker image locally from `docker/dashboard/Dockerfile`; `--rebuild` flag added to `mec dashboard restart` (#67)
- NavBar `LogsStatus`/`AIStatus` chips: fixed lifecycle bug (subscription leaked on mount); added 30s polling fallback so chips update without page reload (#67)
- Session search extended to match `command` and `cwd` fields in addition to `session_id` (#67)
- `mec` help output revamped: bold section headers (`USAGE`, `COMMANDS`, `FLAGS`, `EXAMPLES`), commands grouped by function (CORE / MANAGEMENT / AI & DASHBOARD / OTHER), `*` suffix signals subcommand groups (#71)
- `bin/playwright` now uses a custom Docker image with Chromium pre-installed at build time — single-command test flow without manual browser installation (#73)
- `docker/playwright/Dockerfile`: extends official Playwright image with `npx playwright install chromium` at build time (#73)
- `mec install playwright` builds the custom image as part of installation (#73)

### Changed

- `docs/SETUP.md` rewritten to document current `mec` CLI interface (AI, Dashboard, Purge, Health Check sections); removed v1.0.0-rc dev internals (#72)
- `docs/ROADMAP.md` refactored to a high-level overview; detailed tracking moved to GitHub Issues and the [v1.0.0 milestone](https://github.com/DavidCardoso/my-ez-cli/milestone/1) (#93)
- README node version example corrected: default is `node:22-alpine`, not `node24` (#69)
- `escape_json()` in `bin/utils/log-manager.sh` now strips ANSI escape sequences before writing stdout/stderr to log JSON
- `/api/sessions` response shape changed from plain array to `{"sessions": [...], "total": N}`
- All bin scripts use `get_container_name()` and `get_container_labels()` from `common.sh`
- Path resolution fixed across all scripts using `SCRIPT_DIR`-based sourcing
- `setup.sh` rewritten with full command-line and interactive multi-select support
- `uninstall_claude()` in `setup.sh` now also removes `/usr/local/bin/mec-claude`
- `verify_installation()` for `claude` now accepts either `/usr/local/bin/claude` or `/usr/local/bin/mec-claude` as valid
- `bin/yarn-plus` now calls `exec_with_ai()` (was bare `eval`) — fully wired for AI analysis
- All conflicting tool `uninstall_*` functions now also remove `/usr/local/bin/mec-<tool>`
- `verify_installation()` accepts either primary symlink or `mec-<tool>` for all conflict-aware tools: `node`, `npm`, `npx`, `yarn`, `terraform`, `python`, `aws`, `gcloud`, `serverless`, `speedtest`, `playwright`, `promptfoo`

### Removed

- `.raw.log` file creation from `log-manager.sh` — these files were always empty since AI analyses moved to `ai-analyses/`; removed `log_raw_output()` helper and `RAW_LOG_FILE` compat shim (#70)
- Logging-system internal env vars (`MEC_LOG_DIR`, `MEC_LOG_LEVEL`, etc.) filtered out of `get_log_environment()` — not useful context for AI analysis (#70)
- **CDKTF** (`bin/cdktf`, `docker/cdktf/`, `.github/workflows/docker-build-cdktf.yml`) — CDKTF was officially discontinued by HashiCorp
- Rule-based analyzers (`port_detector`, `error_analyzer`, `env_suggester`) from AI middleware — all analysis delegated to Claude Code
- Custom AI provider code (Anthropic SDK, OpenAI, LiteLLM, Llama) — replaced by Claude Code

---

*Prior to v1.0.0, releases were 0.x.y pre-release/beta with no formal changelog.*
