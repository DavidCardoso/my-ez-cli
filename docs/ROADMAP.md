# My Ez CLI — Roadmap

**Status:** v1.0.0 release candidate in progress
**Tracking:** [GitHub Issues](https://github.com/DavidCardoso/my-ez-cli/issues) · [v1.0.0 Milestone](https://github.com/DavidCardoso/my-ez-cli/milestone/1)
**Changelog:** [CHANGELOG.md](../CHANGELOG.md)

---

## Project Overview

My Ez CLI is a collection of Docker-based wrapper scripts providing sandboxed access to development tools (Node.js, AWS CLI, Terraform, Python, etc.) without local installation.

**Core mission:** Tooling platform, not an AI platform.

- **Primary function:** Sandboxed Docker tool wrappers
- **AI integration:** Claude Code CLI as the sole analysis engine
- **Lean middleware:** Rule-based pattern matching for token optimization
- **Separation of concerns:** AI infrastructure belongs in a separate "Local AI Stack" project

---

## Architecture

```
bin/* tool scripts  →  I/O Middleware (services/ai/)  →  Claude Code CLI
     (Docker)            (Python, filter-only)              (analysis)
                                                                 ↓
                                           ~/.my-ez-cli/ai-analyses/<tool>/<ts>.json
```

See [docs/AI_INTEGRATION.md](./AI_INTEGRATION.md) for full architecture details.

---

## v1.0.0 Status

**All major features are complete.** Remaining work is tracked in the [v1.0.0 milestone](https://github.com/DavidCardoso/my-ez-cli/milestone/1).

### Completed

| Area | Details |
|------|---------|
| Foundation | Path resolution, setup.sh, bats tests (73+), CI/CD, Docker Hub |
| AI Integration | Claude Code wrapper, I/O middleware, `mec ai` subcommands, `exec_with_ai()` |
| Immutable logs | AI sidecars in `ai-analyses/`, log files never mutated after finalization |
| Async analysis | Background Claude Code analysis, `mec ai last/show/logs` |
| Dashboard | FastAPI + Vue 3 at port 4242, session list/detail, WebSocket hot-reload |
| Health check | `mec doctor` with ✓/⚠/✗ output and scriptable exit code |
| Purge | `mec purge` subcommand |

See [CHANGELOG.md](../CHANGELOG.md) for the full implementation history.

### Open for v1.0.0

| Issue | Description |
|-------|-------------|
| [#74](https://github.com/DavidCardoso/my-ez-cli/issues/74) | `mec <tool>` subcommand dispatch for all tool wrappers |
| [#75](https://github.com/DavidCardoso/my-ez-cli/issues/75) | `mec logs` — add session ID column |
| [#76](https://github.com/DavidCardoso/my-ez-cli/issues/76) | `MEC_HOME` env var to replace hardcoded `~/.my-ez-cli/` |
| [#77](https://github.com/DavidCardoso/my-ez-cli/issues/77) | Dashboard — retroactive AI analysis trigger |
| [#78](https://github.com/DavidCardoso/my-ez-cli/issues/78) | `mec setup` output styling (colors, icons) |
| [#79](https://github.com/DavidCardoso/my-ez-cli/issues/79) | CI — evaluate integration tests on pull requests |
| [#80](https://github.com/DavidCardoso/my-ez-cli/issues/80) | Fix serverless container update check on every run |
| [#81](https://github.com/DavidCardoso/my-ez-cli/issues/81) | `add-mec-tool` Claude Code skill |
| [#82](https://github.com/DavidCardoso/my-ez-cli/issues/82) | Docs — checklist for adding new tools with custom Docker images |
| [#94](https://github.com/DavidCardoso/my-ez-cli/issues/94) | Display AI execution time + token usage in `mec` TUI and dashboard UI |

### Pre-release checklist

- [ ] Final verification testing passed
- [ ] Release notes written (`CHANGELOG.md` update)
- [ ] Migration guide for 0.x.y users

---

## Future (Post v1.0.0)

Tracked as GH issues with no milestone — picked up when v1.0.0 is stable.

| Issue | Description |
|-------|-------------|
| [#83](https://github.com/DavidCardoso/my-ez-cli/issues/83) | Shell completion (zsh/bash) |
| [#84](https://github.com/DavidCardoso/my-ez-cli/issues/84) | Decouple from Zsh — bash compatibility |
| [#85](https://github.com/DavidCardoso/my-ez-cli/issues/85) | `mec help <tool>` with examples |
| [#86](https://github.com/DavidCardoso/my-ez-cli/issues/86) | Homebrew formula |
| [#87](https://github.com/DavidCardoso/my-ez-cli/issues/87) | Claude Code MCP server for mec tools |
| [#88](https://github.com/DavidCardoso/my-ez-cli/issues/88) | PostgreSQL log storage (opt-in) |
| [#89](https://github.com/DavidCardoso/my-ez-cli/issues/89) | Custom image local fallback on pull failure |
| [#90](https://github.com/DavidCardoso/my-ez-cli/issues/90) | Prompt injection hardening |
| [#91](https://github.com/DavidCardoso/my-ez-cli/issues/91) | Multi-category tool tags in dashboard |
| [#92](https://github.com/DavidCardoso/my-ez-cli/issues/92) | Evaluate Docker Hub org naming (dedicated org vs personal account) |

---

*Last updated: 2026-03-27*
