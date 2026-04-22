# Setup & Installation Guide

This guide covers how to install, manage, and verify `my-ez-cli` tools using the `mec` CLI.

---

## Quick Start

```bash
# 1. Run the bootstrap installer (first time only)
./setup.sh

# 2. Install tools interactively
mec setup

# 3. Or install specific tools directly
mec install node terraform python

# 4. Check what's installed
mec setup show
```

---

## Installing Tools

### Interactive TUI

```bash
mec setup
```

Shows a numbered list of all available tools with installation status. Select by number, `all`, or type `done` to exit.

```
Available tools:
--------------------------------------------------------------------------------
 1. [  ] aws                  - AWS CLI and SSO tools
 2. [  ] node                 - Node.js (v22, v24)
 3. [  ] npm                  - NPM package manager
...
--------------------------------------------------------------------------------

Your selection: 1 3 9
```

### Command-Line Install

```bash
mec install node terraform python     # install specific tools
mec install all                       # install all tools
mec uninstall node npm                # uninstall tools
mec setup show                        # show installation status
```

---

## Available Tools

| Tool | Description |
|------|-------------|
| aws | AWS CLI and SSO tools |
| node | Node.js (v22 default, v24 also available) |
| npm | NPM package manager |
| npx | NPX package runner |
| yarn | Yarn package manager |
| yarn-plus | Yarn + git/curl/jq tools |
| yarn-berry | Yarn Berry (v2+) |
| serverless | Serverless Framework |
| terraform | Terraform CLI |
| speedtest | Ookla Speedtest CLI |
| gcloud | Google Cloud CLI |
| playwright | Playwright testing |
| python | Python interpreter |
| promptfoo | Promptfoo evaluation |
| promptfoo-server | Promptfoo server |
| claude | Claude Code CLI |

---

## Installing Claude Code

The `claude` tool has conflict-detection logic because users may already have Claude Code installed via Homebrew or the Anthropic install script.

### Fresh install

Both `/usr/local/bin/claude` and `/usr/local/bin/mec-claude` are created as symlinks to `bin/claude`.

### Conflict detected

If a `claude` binary already exists in PATH that is not mec-managed, three options are presented:

```
Conflict detected: 'claude' already exists at: /opt/homebrew/bin/claude
Installed via:    Homebrew

Note: 'mec claude' is always available regardless of your choice.

How would you like to proceed?
  1) Side-by-side  — Install mec's wrapper as 'mec-claude' (native 'claude' untouched)
  2) Replace        — Uninstall existing 'claude', then install mec's wrapper as 'claude' + 'mec-claude'
  3) Skip           — Do not install any symlink
```

| Option | Result |
|--------|--------|
| Side-by-side | Installs `/usr/local/bin/mec-claude` only; native `claude` untouched |
| Replace | Detects install method, asks for confirmation, uninstalls native, installs both symlinks |
| Skip | No symlinks created; use `mec claude` or `bin/claude` directly |

### Supported native install methods

| Method | Detected by | Uninstall action |
|--------|-------------|-----------------|
| Homebrew | Path under `brew --prefix` | `brew uninstall claude` |
| Anthropic script | `~/.claude/local/claude` or `~/.local/bin/claude` | `rm -f <path>` |
| Unknown | Any other path | Prints manual removal instructions; falls back to side-by-side |

### Always available

`mec claude` is always available as a direct proxy to `bin/claude`, regardless of which symlink option was chosen:

```bash
mec claude --version
mec claude "Explain this error..."
```

### Uninstalling

```bash
mec uninstall claude
# Removes /usr/local/bin/claude and /usr/local/bin/mec-claude
```

---

## AI Analysis

Enable AI-powered analysis of tool executions:

```bash
mec logs enable         # logging must be enabled first
mec ai enable           # enable AI analysis
mec ai status           # verify configuration
```

Run any tool — analysis appears automatically in the background:

```bash
node server.js          # [mec-ai] analysis prints after execution
```

Review analyses:

```bash
mec ai last             # most recent analysis
mec ai logs             # list all sessions with AI status
mec ai logs --last 5    # last 5 sessions
mec ai show <session>   # show specific session
```

Requirements (one of):

- `ANTHROPIC_API_KEY` — Anthropic API key
- `CLAUDE_CODE_OAUTH_TOKEN` — Long-lived OAuth token

---

## Dashboard

View logs and AI analyses in a web UI:

```bash
mec dashboard start     # start at http://localhost:4242
mec dashboard status    # check if running
mec dashboard open      # open in browser
mec dashboard stop      # stop the dashboard
```

Change the port:

```bash
mec config set ai.dashboard.port 8080
mec dashboard restart
```

---

## Technical Details

- Tracking file: `$HOME/.my-ez-cli/installed`
- Config file: `$HOME/.my-ez-cli/config.yaml`
- Logs: `$HOME/.my-ez-cli/logs/`
- AI analyses: `$HOME/.my-ez-cli/ai-analyses/`
- Symlinks created in `/usr/local/bin/`

---

## Manual Testing Checklist

Use this checklist to verify the v1.0.0 release.

### Setup & Installation

- [x] `mec setup` — opens interactive TUI
- [x] `mec setup show` — shows status table
- [x] `mec install node` — installs node, symlink created at `/usr/local/bin/node`
- [x] `mec uninstall node` — removes node symlink(s)
- [x] `mec install terraform` (with existing terraform in PATH) — shows 3-option conflict menu

### Claude

- [x] `mec install claude` (no prior claude) — both `/usr/local/bin/claude` and `/usr/local/bin/mec-claude` created
- [x] `mec uninstall claude` — both symlinks removed
- [x] `mec claude --version` — runs Docker wrapper, prints version
- [x] `mec ai status` — shows correct wrapper name (`claude` or `mec-claude`)

### Conflict Detection

- [x] `mec install npm` (with native npm in PATH) — shows 3-option conflict menu
- [x] Option 1 (side-by-side) — creates `/usr/local/bin/mec-npm`, existing npm untouched
- [ ] Option 2 (replace) — shows confirmation, overwrites existing symlink (tracked in #157)
- [x] Option 3 (skip) — no symlinks created, shows direct-run hint
- [x] `mec uninstall npm` — removes both `/usr/local/bin/npm` and `/usr/local/bin/mec-npm`
- [ ] `mec install npx` (with native node+npx) — shows native node warning before conflict menu (tracked in #158)

### AI Integration

- [x] `mec ai status` — shows enabled/disabled, middleware, Claude image, wrapper, auth
- [x] `mec ai enable` + `mec ai status` — shows `AI enabled: true`
- [x] `mec ai disable` + `mec ai status` — shows `AI enabled: false`
- [x] `mec ai test` — Docker image check (pass or expected fail if not pulled)
- [x] `mec ai enable` + `mec logs enable`, then `node --version` → triggers `[mec-ai]` output

### Logging

- [x] `mec logs status` — shows enabled/disabled, log directory, file count
- [x] `mec logs enable` — enables logging, confirms log directory path
- [x] `mec logs disable` — disables logging
- [x] `mec logs help` — prints usage
- [x] `mec ai status` (logging disabled) — shows hint "run 'mec logs enable'"
- [x] `mec ai status` (logging enabled) — shows `Logging: enabled`

### Dashboard

- [x] `mec dashboard start` — starts container, prints URL
- [x] `mec dashboard status` — shows running/stopped state
- [x] `mec dashboard open` — opens browser (or prints URL if no browser)
- [x] `mec dashboard stop` — stops and removes container
- [x] `mec dashboard restart` — stop + start
- [x] `mec dashboard rebuild` — builds image from docker/dashboard/Dockerfile
- [x] `mec dashboard restart --rebuild` — rebuild then restart

### Purge

- [x] `mec purge help` — prints usage with FLAGS section
- [x] `mec purge data --dry-run` — lists files, no deletion
- [x] `mec purge data -y` — deletes files without prompt
- [x] `mec purge data --only-logs -y` — deletes only log files
- [x] `mec purge data --tool node -y` — deletes only node files

### Tools Spot Check

- [x] `node --version` — Node v22 from Docker
- [x] `yarn-plus --version` — Yarn version
- [x] `terraform --version` — Terraform version from Docker

### Health Check

- [x] `mec doctor` — prints structured health report
- [x] `mec doctor && echo "healthy"` — exits 0 when all checks pass

---

*Last updated: 2026-04-22*
*Version: 1.0.0*
