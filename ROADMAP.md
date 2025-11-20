# My Ez CLI - v1.0.0 Upgrade Roadmap

**Status:** Phase 1 Complete - Proceeding to Phase 2
**Target:** First Stable Release (v1.0.0)
**Previous Versions:** 0.x.y (beta releases)
**Phase 1 Completed:** 2025-01-20

---

## Table of Contents

1. [Installation Process Improvements](#1-installation-process-improvements)
2. [AI Integration Architecture](#2-ai-integration-architecture)
3. [Warp Workflow Integration](#3-warp-workflow-integration)
4. [GitHub Workflows for Docker Builds](#4-github-workflows-for-docker-builds)
5. [Testing Strategy](#5-testing-strategy)
6. [bin/utils Path Resolution Fixes](#6-binutils-path-resolution-fixes)
7. [Remote Execution from GitHub](#7-remote-execution-from-github)
8. [Package Publishing Strategy](#8-package-publishing-strategy)
9. [Log Persistence System](#9-log-persistence-system)
10. [UI/Dashboard Features](#10-uidashboard-features)
11. [Docker Compose Generation](#11-docker-compose-generation)
12. [Overall UX Improvements](#12-overall-ux-improvements)

---

## Project Structure Reorganization

**Current structure:**
```
my-ez-cli/
├── bin/              # Tool wrapper scripts
├── bin/utils/        # Utilities (docker.sh)
├── docker/           # Custom Dockerfiles
└── setup.sh          # Installation script
```

**New structure for v1.0.0:**
```
my-ez-cli/
├── bin/              # Tool wrapper scripts ONLY
│   ├── aws
│   ├── node
│   ├── terraform
│   └── internals/    # Internal tools if needed (TBD)
├── src/              # My-ez-cli internal code
│   ├── ai/           # AI integration
│   ├── cli/          # Main CLI (mec command)
│   ├── dashboard/    # TUI dashboard
│   ├── web-ui/       # Web UI (Node + Vue)
│   ├── lib/          # Shared libraries
│   └── utils/        # Moved from bin/utils/
├── docker/           # Custom Dockerfiles
├── tests/            # Test suite
├── .warp/            # Warp workflows
├── package.json      # NPM package config
├── setup.sh          # Installation script
├── ROADMAP.md        # This file
└── CLAUDE.md         # Project guidance for Claude Code
```

---

## 1. Installation Process Improvements

**Status:** ✅ Complete
**Priority:** P0 (Critical)
**Phase:** 1
**Completed:** 2025-01-20

### Current Issues
- Single-selection menu (breaks after one choice)
- No ability to check installed tools
- No uninstall capability
- No validation of successful installation

### Implementation Plan

#### 1.1 Multi-Select Installation
- Replace `PS3 select` with `whiptail/dialog` checkbox interface
- Support both interactive and CLI arguments: `./setup.sh install node terraform`
- Add `list_installed()` function to check `/usr/local/bin` symlinks
- Create `.my-ez-cli-installed` tracking file

#### 1.2 Uninstall Capability
- Add `uninstall_<tool>()` functions for each tool
- Remove symlinks from `/usr/local/bin`
- Remove aliases from `~/.zshrc`
- Update tracking file

#### 1.3 Installation Verification
- Check symlink creation success
- Test command execution (`node --version`)
- Report success/failure status
- Add `./setup.sh status` to show installed vs available tools

#### 1.4 Update Capability
- Refresh symlinks without reinstalling
- Check for new tools available

### Files to Create/Modify
- `src/lib/install-manager.sh` - Reusable install/uninstall/check functions
- `setup.sh` - Enhanced with multi-select and new commands
- `.my-ez-cli-installed` - Track installed tools

---

## 2. AI Integration Architecture

**Status:** ⏳ Pending
**Priority:** P2 (High)
**Phase:** 3

### Key Principles
- **BYOK (Bring Your Own Key):** Users provide their own API keys (OpenAI, Anthropic, etc.)
- **Independent from Warp:** AI integration is standalone, Warp is optional
- **Opt-in:** Disabled by default, enabled via config or env var

### Use Cases
1. Auto-detect missing port bindings
2. Suggest missing environment variables
3. Analyze error outputs and suggest fixes
4. Validate configurations pre-execution

### Architecture

```
src/ai/
├── agent.sh              # Main AI agent orchestrator
├── providers/
│   ├── openai.sh         # OpenAI API integration
│   ├── anthropic.sh      # Anthropic API integration
│   └── ollama.sh         # Local Ollama integration
├── analyzers/
│   ├── port-detector.sh  # Analyze port binding mismatches
│   ├── env-suggester.sh  # Suggest missing environment variables
│   └── error-analyzer.sh # Parse errors and suggest fixes
└── config.yaml           # AI configuration
```

### Configuration
```yaml
# ~/.my-ez-cli/ai-config.yaml
enabled: false
provider: openai  # openai, anthropic, ollama
api_key_env: OPENAI_API_KEY  # Environment variable name
model: gpt-4-turbo
features:
  port_detection: true
  env_suggestions: true
  error_analysis: true
```

### Usage Examples
```bash
# Enable AI for single command
MEC_AI_ENABLED=1 node app.js

# Configure globally
mec config set ai.enabled true
mec config set ai.provider anthropic
export ANTHROPIC_API_KEY=sk-ant-...

# AI detects and suggests
$ node app.js
# Output: Server listening on port 3000
# [AI] Detected server on port 3000 but no port binding found.
# [AI] Suggestion: Run with MEC_BIND_PORTS='3000:3000' node app.js
# Apply suggestion? [y/N]
```

### Implementation
- Lightweight wrappers around API calls
- Parse tool outputs for patterns
- Store suggestions in `.my-ez-cli/suggestions.log`
- Interactive prompts for applying suggestions
- Log analysis uses filtered logs (see #9)

---

## 3. Warp Workflow Integration

**Status:** ⏳ Pending
**Priority:** P3 (Low)
**Phase:** 3

### Goal
Provide ready-to-use Warp workflows for common tasks

### Implementation
Create `.warp/workflows/` directory with YAML templates:

```yaml
# .warp/workflows/mec-node.yaml
name: "Run Node.js with my-ez-cli"
command: "node {{file}}"
tags: ["nodejs", "my-ez-cli"]
description: "Run Node.js app in Docker container"
arguments:
  - name: file
    description: "JavaScript file to execute"
    default_value: "index.js"
source_url: "https://github.com/DavidCardoso/my-ez-cli"
author: "David Cardoso"
author_url: "https://github.com/DavidCardoso"
```

### Workflows to Create
- `mec-node.yaml` - Run Node.js apps
- `mec-node-ports.yaml` - Run Node.js with port binding
- `mec-terraform-aws.yaml` - Terraform with AWS
- `mec-terraform-gcp.yaml` - Terraform with GCP
- `mec-npm-install.yaml` - NPM install with token
- `mec-python.yaml` - Run Python scripts

### Documentation
- README section on installing workflows
- Copy `.warp/workflows/` to `~/.warp/workflows/`

**Note:** Warp support is a bonus feature. Other terminal integrations may be added later.

---

## 4. GitHub Workflows for Docker Builds

**Status:** ✅ Complete
**Priority:** P0 (Critical)
**Phase:** 1
**Completed:** 2025-01-20

### Custom Images to Build
- `serverless` (bin/serverless)
- `cdktf` (bin/cdktf)
- `aws-sso-cred` (bin/aws-sso-cred)
- `yarn-berry` (bin/yarn-berry)
- `speedtest` (bin/speedtest)

### Workflow Structure
```
.github/workflows/
├── docker-build-serverless.yml
├── docker-build-cdktf.yml
├── docker-build-aws-sso-cred.yml
├── docker-build-yarn-berry.yml
├── docker-build-speedtest.yml
└── docker-build-all.yml         # Orchestrator
```

### Features (Implemented)
- **Triggers:** Push to main, PR, manual dispatch, tag creation, weekly schedule
- **Multi-platform:** `linux/amd64`, `linux/arm64` (M1/M2 Macs)
- **Registry:** Docker Hub (`davidcardoso/my-ez-cli`) - migrated from GitHub Container Registry
- **Versioning:** Tool-specific tags (`aws-sso-cred-latest`, `cdktf-sha-abc123`, etc.)
- **Security:** Trivy vulnerability scanning integrated
- **Automation:** GitHub Secrets for Docker Hub authentication
- **Documentation:** See [DOCKER_HUB.md](./DOCKER_HUB.md) for complete setup guide

### Trivy Security Scanning (Implemented)
**Trivy is free for open source projects** - Apache 2.0 license, no cost concerns.

All custom Docker images are scanned for vulnerabilities. Example implementation:

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: davidcardoso/my-ez-cli:serverless-latest
    format: 'sarif'
    output: 'trivy-results-serverless.sarif'
- name: Upload Trivy results to GitHub Security tab
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results-serverless.sarif'
```

---

## 5. Testing Strategy

**Status:** ✅ Complete
**Priority:** P0 (Critical)
**Phase:** 1
**Completed:** 2025-01-20

### Test Structure
```
tests/
├── unit/                    # Test individual script functions
│   ├── test-node.sh
│   ├── test-terraform.sh
│   └── test-promptfoo.sh
├── integration/             # Test full workflows
│   ├── test-aws-terraform.sh
│   └── test-node-port-binding.sh
├── e2e/                     # End-to-end scenarios
│   └── test-full-setup.sh
├── helpers/
│   ├── test-framework.sh    # Assert functions, test runners
│   └── mock-docker.sh       # Mock docker for unit tests
└── fixtures/
    ├── sample-node-app/
    └── sample-terraform/
```

### Testing Framework
Use **bats-core** (Bash Automated Testing System)

```bash
# Example test
@test "node runs with default version 24" {
  run ./bin/node --version
  assert_output --partial "v24"
}

@test "node binds ports correctly" {
  MEC_BIND_PORTS="8080:80" ./bin/node server.js &
  sleep 2
  run curl http://localhost:8080
  assert_success
}
```

### CI Integration
```yaml
# .github/workflows/test.yml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - run: ./tests/run-all-tests.sh
```

---

## 6. bin/utils Path Resolution Fixes

**Status:** ✅ Complete
**Priority:** P0 (Critical)
**Phase:** 1
**Completed:** 2025-01-20

### Problem
`SCRIPT_DIR` resolution breaks when called via symlinks:
- `/usr/local/bin/node` → symlink to `/path/to/my-ez-cli/bin/node`
- `dirname "$0"` returns `/usr/local/bin` instead of actual script location
- Sourcing `utils/docker.sh` fails

### Solution

#### Create Unified Utils Wrapper
All common utilities abstracted into one file:

```bash
# src/utils/common.sh
#!/bin/sh
set -e

# Path resolution that works with symlinks
get_script_real_path() {
    SCRIPT="$0"
    # Follow symlink if exists
    if [ -L "$SCRIPT" ]; then
        SCRIPT=$(readlink "$SCRIPT")
    fi
    SCRIPT_DIR=$(cd "$(dirname "$SCRIPT")" && pwd)
    echo "$SCRIPT_DIR"
}

# TTY detection
get_tty_flag() {
    if [ -t 0 ]; then
        echo "-t"
    else
        echo ""
    fi
}

# Log configuration (see #9)
setup_logging() {
    # Implementation in #9
}

# Environment setup
setup_env() {
    # Common environment variable setup
}
```

#### Update All Scripts
```bash
#!/bin/sh
set -e

# Source common utilities FIRST
SCRIPT_DIR="$(cd "$(dirname "$([ -L "$0" ] && readlink "$0" || echo "$0")")" && pwd)"
. "${SCRIPT_DIR}/../src/utils/common.sh"

# Or if installed via NPM/symlink:
# . "$(get_utils_path)/common.sh"

# Rest of script...
```

### Migration Plan
1. Create `src/utils/common.sh` with all shared utilities
2. Move `bin/utils/docker.sh` → `src/utils/common.sh`
3. Update all 35+ bin scripts to source common.sh
4. Test with local execution and symlink execution
5. Remove old `bin/utils/` directory

---

## 7. Remote Execution from GitHub

**Status:** ⏳ Pending
**Priority:** P1 (High)
**Phase:** 2

### Goal
Run my-ez-cli without cloning the repository

### Approach: All Three Methods

#### Method 1: Direct curl (Shell-friendly)
```bash
# One-liner execution
curl -fsSL https://raw.githubusercontent.com/DavidCardoso/my-ez-cli/main/bin/node | sh -s -- --version

# With wrapper for better UX
curl -fsSL https://raw.githubusercontent.com/DavidCardoso/my-ez-cli/main/scripts/remote-exec.sh | sh -s -- node --version
```

**Implementation:**
- Create `scripts/remote-exec.sh` wrapper
- Fetches bin script from GitHub
- Executes with passed arguments
- Caches in `/tmp/my-ez-cli-cache/` for session

#### Method 2: Install Script
```bash
# One-time setup
curl -fsSL https://my-ez-cli.io/install.sh | bash

# Creates:
# ~/.my-ez-cli/bin/       # Cached scripts
# ~/.my-ez-cli/version    # Current version

# Update via:
mec update
```

**Implementation:**
- Create `scripts/install.sh`
- Downloads latest release tarball
- Extracts to `~/.my-ez-cli/`
- Adds to PATH
- Self-update capability

#### Method 3: NPX (Easiest for npm users)
```bash
# No installation needed
npx @my-ez-cli/runner node --version
npx @my-ez-cli/runner terraform plan

# Or with alias
npx mec node --version
```

**Implementation:**
- NPM package (see #8)
- Package downloads/executes scripts
- Caches in `~/.my-ez-cli-cache/`
- Version pinning: `npx @my-ez-cli/runner@1.0.0 node --version`

### Priority
1. **NPX** - Easiest to implement alongside npm publishing
2. **Install script** - Good for non-npm users
3. **Direct curl** - Fallback for minimal environments

---

## 8. Package Publishing Strategy

**Status:** ⏳ Pending
**Priority:** P1 (High)
**Phase:** 2

### Release Plan
- **v1.0.0:** NPM package with npx support
- **v1.1.0:** Homebrew formula
- **v1.2.0:** Debian packages via GitHub Releases

### Phase 1: NPM Package (v1.0.0)

#### Naming Strategy: Direct Names + `mec-*` Alternatives

**PRIMARY:** Direct tool names (current behavior)
```bash
node                 # Node.js wrapper (default)
terraform            # Terraform wrapper (default)
aws                  # AWS CLI wrapper (default)
npm                  # NPM wrapper (default)
# ... etc for all tools
```

**ALTERNATIVE:** `mec-*` prefix (optional, user choice)
```bash
mec                  # Main CLI (help, config, status, etc.)
mec-node             # Alternative to 'node'
mec-terraform        # Alternative to 'terraform'
mec-aws              # Alternative to 'aws'
mec-npm              # Alternative to 'npm'
# ... etc for all tools
```

**Philosophy:**
- Keep current behavior: users call tools by direct name (node, terraform, npm)
- `mec-*` prefix is an ALTERNATIVE for users who:
  - Have native tools installed and want to avoid conflicts
  - Prefer explicit namespacing
  - Want to clearly distinguish mec tools from native tools
- User chooses installation mode: direct names, mec-only, or both
- Increases adoption by being flexible

#### package.json
```json
{
  "name": "@my-ez-cli/core",
  "version": "1.0.0",
  "description": "Docker-based CLI tool wrappers with no installation",
  "keywords": ["docker", "cli", "devtools", "terraform", "node", "aws"],
  "author": "David Cardoso",
  "license": "MIT",
  "repository": "github:DavidCardoso/my-ez-cli",
  "bin": {
    "mec": "./src/cli/index.js",

    "node": "./wrappers/node.js",
    "mec-node": "./wrappers/node.js",
    "node14": "./wrappers/node14.js",
    "mec-node14": "./wrappers/node14.js",
    "node16": "./wrappers/node16.js",
    "mec-node16": "./wrappers/node16.js",
    "node18": "./wrappers/node18.js",
    "mec-node18": "./wrappers/node18.js",
    "node20": "./wrappers/node20.js",
    "mec-node20": "./wrappers/node20.js",
    "node22": "./wrappers/node22.js",
    "mec-node22": "./wrappers/node22.js",
    "node24": "./wrappers/node24.js",
    "mec-node24": "./wrappers/node24.js",

    "npm": "./wrappers/npm.js",
    "mec-npm": "./wrappers/npm.js",
    "npx": "./wrappers/npx.js",
    "mec-npx": "./wrappers/npx.js",
    "yarn": "./wrappers/yarn.js",
    "mec-yarn": "./wrappers/yarn.js",

    "terraform": "./wrappers/terraform.js",
    "mec-terraform": "./wrappers/terraform.js",
    "aws": "./wrappers/aws.js",
    "mec-aws": "./wrappers/aws.js",
    "python": "./wrappers/python.js",
    "mec-python": "./wrappers/python.js",
    "serverless": "./wrappers/serverless.js",
    "mec-serverless": "./wrappers/serverless.js",
    "gcloud": "./wrappers/gcloud.js",
    "mec-gcloud": "./wrappers/gcloud.js",
    "cdktf": "./wrappers/cdktf.js",
    "mec-cdktf": "./wrappers/cdktf.js",
    "playwright": "./wrappers/playwright.js",
    "mec-playwright": "./wrappers/playwright.js",
    "promptfoo": "./wrappers/promptfoo.js",
    "mec-promptfoo": "./wrappers/promptfoo.js"
  },
  "scripts": {
    "postinstall": "node scripts/setup.js",
    "test": "npm run test:unit && npm run test:integration",
    "test:unit": "./tests/unit/run.sh",
    "test:integration": "./tests/integration/run.sh"
  },
  "engines": {
    "node": ">=14.0.0"
  },
  "dependencies": {
    "chalk": "^5.0.0",
    "commander": "^11.0.0",
    "inquirer": "^9.0.0"
  },
  "devDependencies": {
    "jest": "^29.0.0"
  }
}
```

#### Wrapper Files
Node.js wrapper scripts that call the shell scripts:

```javascript
// wrappers/node.js
#!/usr/bin/env node
const { execSync } = require('child_process');
const path = require('path');

const binScript = path.join(__dirname, '../bin/node');
const args = process.argv.slice(2).join(' ');

try {
  execSync(`${binScript} ${args}`, { stdio: 'inherit' });
} catch (error) {
  process.exit(error.status || 1);
}
```

#### Installation Modes

Users choose how to install tools during setup:

**Mode 1: Direct Names Only (Default)**
```bash
./setup.sh
# Installs: node, terraform, npm, aws, etc.
# User calls: node --version, terraform plan
```

**Mode 2: mec-* Prefix Only**
```bash
./setup.sh --mec-only
# Installs: mec-node, mec-terraform, mec-npm, mec-aws, etc.
# User calls: mec-node --version, mec-terraform plan
```

**Mode 3: Both (Dual Mode)**
```bash
./setup.sh --dual
# Installs: both direct names AND mec-* prefixes
# User calls: node --version OR mec-node --version
```

**Per-Tool Choice:**
```bash
./setup.sh interactive
# During setup, for each tool:
#
# ┌─────────── Install Node.js ───────────┐
# │ Native 'node' command detected!       │
# │                                        │
# │ How would you like to install?        │
# │ ( ) Replace native (install as 'node')│
# │ (•) Use prefix (install as 'mec-node')│
# │ ( ) Both (install both)               │
# │ ( ) Skip                               │
# └────────────────────────────────────────┘
```

**Conflict Detection:**
When native tools exist, setup script:
1. Detects existing installation (`which node`, `which terraform`)
2. Warns user about potential conflicts
3. Offers choices: replace, use prefix, both, or skip
4. Stores user preference in `~/.my-ez-cli/config.yaml`

**Configuration:**
```yaml
# ~/.my-ez-cli/config.yaml
installation:
  mode: dual  # direct, mec-only, or dual
  tools:
    node:
      installed_as: [direct, mec]  # User chose both
    npm:
      installed_as: [mec]           # User has native npm, chose prefix
    terraform:
      installed_as: [direct]        # No conflict, chose direct
```

#### Usage Examples
```bash
# Global install
npm install -g @my-ez-cli/core
mec help                    # My Ez CLI commands
node --version              # Direct name (if chosen)
mec-node --version          # mec prefix (always available)

# NPX (no install)
npx @my-ez-cli/core help
npx node --version          # If tool supports it
npx mec-node --version

# Local project
npm install --save-dev @my-ez-cli/core
npx terraform plan          # Direct name
npx mec-terraform plan      # mec prefix
```

### Phase 2: Homebrew (v1.1.0)

**REMINDER: Create Homebrew tap repository later**

```ruby
# davidcardoso/homebrew-my-ez-cli/Formula/my-ez-cli.rb
class MyEzCli < Formula
  desc "Docker-based CLI tool wrappers with no installation"
  homepage "https://github.com/DavidCardoso/my-ez-cli"
  url "https://github.com/DavidCardoso/my-ez-cli/archive/v1.1.0.tar.gz"
  sha256 "..."
  license "MIT"

  depends_on "docker"

  def install
    bin.install Dir["bin/*"]
    prefix.install "setup.sh"
    prefix.install "src"
  end

  def caveats
    <<~EOS
      Run setup: #{prefix}/setup.sh
      Or use commands directly: mec-node, mec-terraform, etc.
    EOS
  end

  test do
    system "#{bin}/mec-node", "--version"
  end
end
```

**Installation:**
```bash
brew tap davidcardoso/my-ez-cli
brew install my-ez-cli
```

### Phase 3: Debian/Ubuntu via GitHub Releases (v1.2.0)

**Use GitHub Releases instead of PPA**

Create `.deb` package and attach to GitHub releases:

```bash
# Package structure
my-ez-cli_1.2.0_amd64/
├── DEBIAN/
│   ├── control
│   ├── postinst
│   └── prerm
└── usr/
    ├── bin/
    │   ├── mec
    │   ├── mec-node
    │   └── ...
    └── share/
        └── my-ez-cli/
            ├── bin/
            ├── src/
            └── setup.sh
```

**Build in GitHub Actions:**
```yaml
# .github/workflows/release.yml
- name: Build .deb package
  run: ./scripts/build-deb.sh
- name: Upload to release
  uses: softprops/action-gh-release@v1
  with:
    files: my-ez-cli_*.deb
```

**Installation:**
```bash
# Download from releases
wget https://github.com/DavidCardoso/my-ez-cli/releases/download/v1.2.0/my-ez-cli_1.2.0_amd64.deb
sudo dpkg -i my-ez-cli_1.2.0_amd64.deb
```

### External Registry Configs
Save for last step after implementation:
- NPM publish workflow
- Homebrew tap creation
- Debian package building

---

## 9. Log Persistence System

**Status:** ⏳ Pending
**Priority:** P1 (High)
**Phase:** 3

### Goals
1. Save container logs for later analysis
2. Abstract log configuration into utilities
3. Filter/sanitize logs for AI consumption (reduce costs, disk usage)
4. User-extensible filtering rules
5. **Modular design** - Support future enhancements without breaking changes
6. **Structured logs** - Enable integration with external tools (Elasticsearch, Unity Catalog)

### Design Principles: Modularity & Future-Proofing

**Critical:** The log system must be modular to avoid breaking changes in future releases (stay within v1.x).

#### Modular Architecture Layers

```
┌─────────────────────────────────────────────┐
│  Application Layer (bin scripts)            │
│  - Calls log API: log_output()              │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  Log Manager (src/utils/log-manager.sh)     │
│  - Routing, configuration, API              │
└─────────────────┬───────────────────────────┘
                  │
      ┌───────────┼───────────┐
      │           │           │
┌─────▼─────┐ ┌──▼──────┐ ┌─▼────────┐
│ Formatter │ │ Filter  │ │ Encryptor│  ← Pluggable modules
│  Module   │ │ Module  │ │  Module  │
└─────┬─────┘ └──┬──────┘ └─┬────────┘
      │          │           │ (future)
      └──────────┼───────────┘
                 │
      ┌──────────▼──────────┐
      │  Storage Layer       │
      │  - File (current)    │
      │  - Database (future) │
      │  - Remote (future)   │
      └─────────────────────┘
```

#### Pluggable Modules

**Current (v1.0.0):**
- File storage (.log files)
- Text/JSON formatters
- Filter/guardrail system

**Future (v1.x - No Breaking Changes):**
- Encryption module (opt-in)
- Database exporters (Elasticsearch, Unity Catalog)
- Remote log shipping

**How it works:**
```bash
# Application calls unified API
log_output "node" "$output_data"

# Log manager routes through enabled modules:
# 1. Format (JSON or text)
# 2. Filter (apply guardrails)
# 3. Encrypt (if enabled) ← Future, opt-in
# 4. Store (file, DB, or remote) ← Future, pluggable
```

### Structured Log Format

**From Day 1:** All logs stored in structured format (JSON) to enable future integrations.

#### Log Entry Schema v1
```json
{
  "version": "1.0",
  "timestamp": "2025-01-19T14:30:45Z",
  "tool": "node",
  "command": "node app.js",
  "level": "info",
  "message": "Server listening on port 3000",
  "metadata": {
    "container_id": "abc123",
    "image": "node:24-alpine",
    "exit_code": 0,
    "duration_ms": 1234
  },
  "filtered": false,
  "encrypted": false
}
```

**Benefits:**
- Easy parsing by external tools
- Schema versioning (future changes backward compatible)
- AI models can easily consume structured data
- Database ingestion ready

#### Human-Readable Output
```bash
# CLI displays formatted output:
[2025-01-19 14:30:45] [node] Server listening on port 3000

# Raw JSON stored on disk:
~/.my-ez-cli/logs/node/2025-01-19_14-30-45.jsonl
```

### Future: Encryption Support (v1.3.0+)

**Use Case:** Logs may contain sensitive data (IPs, credentials, internal paths)

**Implementation:**
- **Opt-in:** Disabled by default, enabled via config
- **Pluggable:** Encryption module added without changing core log system
- **Transparent:** Logs encrypted at rest, decrypted on read
- **Standard:** AES-256-GCM encryption
- **Key management:** User-provided key or auto-generated

**Configuration:**
```yaml
# ~/.my-ez-cli/config.yaml
logs:
  encryption:
    enabled: false
    algorithm: aes-256-gcm
    key_file: ~/.my-ez-cli/secrets/log-key.enc
    encrypt_fields: [message, metadata.command]  # Selective encryption
```

**Usage:**
```bash
# Enable encryption
mec config set logs.encryption.enabled true
mec logs generate-key  # Creates encryption key

# Logs automatically encrypted
node app.js
# Stored: ~/.my-ez-cli/logs/node/2025-01-19.jsonl.enc

# View decrypted logs
mec logs view node --last 10  # Auto-decrypts with key
```

**Implementation Notes:**
- Add `src/utils/crypto.sh` module
- Encryption happens AFTER filtering (save space/time)
- Backward compatible: Unencrypted logs still readable
- No breaking changes to API

### Future: Log Database Support (v1.4.0+)

**Use Case:** Optimize log queries, enable advanced analytics, integrate with data platforms

**Supported Platforms:**
- **Elasticsearch** - Full-text search, analytics, visualization
- **Unity Catalog** - Data governance, lineage tracking
- **PostgreSQL** - Relational queries, long-term storage
- **ClickHouse** - High-performance analytics

**Implementation:**
- **Pluggable exporters:** Each platform has dedicated exporter module
- **Hybrid mode:** Store locally AND sync to database
- **Self-hosted:** Docker containers for Elasticsearch, PostgreSQL
- **Configuration-driven:** Enable via config, zero code changes

**Configuration:**
```yaml
# ~/.my-ez-cli/config.yaml
logs:
  storage:
    primary: file  # file, elasticsearch, postgres, clickhouse
    exporters:
      - type: elasticsearch
        enabled: true
        url: http://localhost:9200
        index_pattern: mec-logs-{tool}-{date}
        auth:
          username: elastic
          password_env: ELASTIC_PASSWORD
      - type: unity_catalog
        enabled: false
        url: http://localhost:8080
        catalog: mec_logs
        schema: tools
```

**Usage:**
```bash
# Start Elasticsearch container (provided by my-ez-cli)
mec logs database start elasticsearch

# Enable Elasticsearch exporter
mec config set logs.exporters.elasticsearch.enabled true

# Logs automatically indexed
node app.js
# Stored in: File + Elasticsearch

# Query via Elasticsearch
curl http://localhost:9200/mec-logs-node-*/_search?q=error

# Or use mec CLI
mec logs query --tool node --grep "error" --last 7d
# Uses Elasticsearch for fast queries

# Visualize in Kibana
mec logs dashboard
# Opens Kibana dashboard with mec logs
```

**Elasticsearch Example:**
```bash
# Start Elasticsearch + Kibana containers
mec logs database start elasticsearch

# Containers started:
# - elasticsearch:8.11.0 on port 9200
# - kibana:8.11.0 on port 5601

# Logs auto-indexed with schema:
PUT /mec-logs-node-2025-01-19
{
  "mappings": {
    "properties": {
      "timestamp": { "type": "date" },
      "tool": { "type": "keyword" },
      "level": { "type": "keyword" },
      "message": { "type": "text" },
      "metadata": { "type": "object" }
    }
  }
}
```

**Unity Catalog Example:**
```bash
# Start Unity Catalog server
mec logs database start unity-catalog

# Create catalog/schema
mec logs database init unity-catalog

# Logs exported as Delta tables:
# s3://my-ez-cli-logs/mec_logs/tools/node/
# Queryable via Spark, Databricks, etc.
```

**Implementation:**
- Add `src/exporters/` directory with platform-specific modules
- Each exporter implements standard interface:
  - `init()` - Initialize database/schema
  - `export(log_entry)` - Send log entry
  - `query(filters)` - Query logs
- Exporters run asynchronously (don't block tool execution)
- Batch uploads for performance
- Retry logic for failed exports
- Health checks for database connectivity

**Benefits:**
- **Performance:** Fast queries on large log volumes (Elasticsearch)
- **Analytics:** Complex aggregations, trends, anomaly detection
- **Integration:** Works with existing data platforms (Unity Catalog)
- **Governance:** Data lineage, access control, compliance
- **Visualization:** Dashboards, charts, real-time monitoring

### Architecture (v1.0.0 - File-Based)

```
~/.my-ez-cli/
├── logs/
│   ├── node/
│   │   ├── 2025-01-19_14-30-45.log
│   │   └── 2025-01-19_14-30-45.raw.log  # Optional: raw unfiltered
│   ├── terraform/
│   ├── aws/
│   └── npm/
├── config/
│   ├── logging.yaml
│   └── log-filters/        # Filter rules per tool
│       ├── node.yaml
│       ├── npm.yaml
│       ├── terraform.yaml
│       └── default.yaml
└── .gitignore
```

### Abstraction: Log Utility

Move log configuration to `src/utils/common.sh`:

```bash
# src/utils/common.sh (addition)

# Setup logging for a tool
# Usage: setup_logging "node"
setup_logging() {
    TOOL_NAME="$1"
    LOG_DIR="${MEC_LOG_DIR:-${HOME}/.my-ez-cli/logs}/${TOOL_NAME}"
    mkdir -p "$LOG_DIR"

    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    LOG_FILE="${LOG_DIR}/${TIMESTAMP}.log"
    RAW_LOG_FILE="${LOG_DIR}/${TIMESTAMP}.raw.log"

    # Check if logging is enabled
    if [ "$MEC_SAVE_LOGS" = "1" ] || [ "$(mec config get logs.enabled)" = "true" ]; then
        LOG_ENABLED=true
    else
        LOG_ENABLED=false
    fi

    # Export for use in scripts
    export LOG_ENABLED
    export LOG_FILE
    export RAW_LOG_FILE
}

# Apply log filters
# Usage: docker run ... | apply_log_filter "node"
apply_log_filter() {
    TOOL_NAME="$1"
    FILTER_FILE="${HOME}/.my-ez-cli/config/log-filters/${TOOL_NAME}.yaml"

    if [ -f "$FILTER_FILE" ]; then
        # Apply filters using grep/sed based on filter rules
        src/utils/log-filter.sh "$FILTER_FILE"
    else
        # No filter, pass through
        cat
    fi
}

# Execute with logging
# Usage: exec_with_logging "node" "docker run ..."
exec_with_logging() {
    TOOL_NAME="$1"
    shift
    COMMAND="$@"

    setup_logging "$TOOL_NAME"

    if [ "$LOG_ENABLED" = "true" ]; then
        # Save raw and filtered logs
        $COMMAND 2>&1 | tee "$RAW_LOG_FILE" | apply_log_filter "$TOOL_NAME" | tee "$LOG_FILE"
    else
        # No logging
        $COMMAND
    fi
}
```

### Updated Script Pattern

All scripts use the abstracted utility:

```bash
#!/bin/sh
set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "$([ -L "$0" ] && readlink "$0" || echo "$0")")" && pwd)"
. "${SCRIPT_DIR}/../src/utils/common.sh"

IMAGE=${IMAGE:-"node:24-alpine"}
WORKDIR=/app

# Setup logging
setup_logging "node"

# Port configuration
if [ ! -z "$MEC_BIND_PORTS" ]; then
    for PORT in $MEC_BIND_PORTS; do
        PORTS="$PORTS -p $PORT"
    done
fi

# Execute with logging
if [ "$LOG_ENABLED" = "true" ]; then
    docker run -it --rm \
        --volume $PWD:$WORKDIR \
        --workdir $WORKDIR \
        $PORTS \
        $IMAGE "${@}" 2>&1 | tee "$RAW_LOG_FILE" | apply_log_filter "node" | tee "$LOG_FILE"
else
    docker run -it --rm \
        --volume $PWD:$WORKDIR \
        --workdir $WORKDIR \
        $PORTS \
        $IMAGE "${@}"
fi
```

### Log Filtering: Guardrails for AI Context

**Semantic alignment:** Yes, log filtering for AI context is conceptually similar to **input guardrails** in LLM evaluation frameworks. We'll use terminology aligned with AI safety and evaluation:

- **Filter rules** = Input sanitization rules
- **Guardrails** = Rules preventing unwanted content from AI context
- **Allow/Block patterns** = Whitelisting/blacklisting patterns

### Filter Configuration Format

```yaml
# ~/.my-ez-cli/config/log-filters/npm.yaml
version: 1
tool: npm
description: "Filter npm/yarn output for AI analysis"

# Guardrails: What to keep for AI context
guardrails:
  # Strategy: keep (default), discard, or transform
  default_action: discard

  # Keep patterns (regex)
  keep:
    - pattern: "^(error|ERR!|warn|WARN|deprecated)"
      reason: "Errors and warnings are critical for analysis"
    - pattern: "^npm (ERR!|WARN)"
      reason: "npm-specific errors"
    - pattern: "vulnerability|security"
      case_insensitive: true
      reason: "Security issues"
    - pattern: "peer dep.*not compatible"
      reason: "Dependency conflicts"

  # Discard patterns (regex)
  discard:
    - pattern: "^(http|https)://.*"
      reason: "Package URLs - no analysis value"
    - pattern: "├──|└──"
      reason: "Dependency tree formatting"
    - pattern: "^added \d+ packages"
      reason: "Success messages"
    - pattern: "^found \d+ vulnerabilities \(0 "
      reason: "Zero vulnerabilities - success message"
    - pattern: "^up to date"
      reason: "Success message"
    - pattern: "^audited \d+ packages"
      reason: "Audit success message"

  # Transform patterns (optional)
  transform:
    - pattern: "(/[a-z0-9_-]+)+/node_modules"
      replace: "/node_modules"
      reason: "Normalize paths"

# Retention policy
retention:
  raw_logs: 7d      # Keep raw logs for 7 days
  filtered_logs: 30d # Keep filtered logs for 30 days
  compress_after: 1d # Gzip logs after 1 day

# Cost optimization
optimization:
  max_log_size: 10MB      # Rotate if exceeded
  summarize_repeats: true # "Error X repeated 50 times" instead of 50 lines
```

### Baseline Filter Rules

#### NPM/Yarn Filter
```yaml
# config/log-filters/npm.yaml
guardrails:
  keep:
    - pattern: "^(error|ERR!|warn|WARN|deprecated)"
    - pattern: "vulnerability|security"
    - pattern: "peer dep.*not compatible"
    - pattern: "ERESOLVE|ENOENT|EACCES"
  discard:
    - pattern: "^(http|https)://"
    - pattern: "├──|└──|│"
    - pattern: "^(added|removed|changed|audited|up to date)"
```

#### Terraform Filter
```yaml
# config/log-filters/terraform.yaml
guardrails:
  keep:
    - pattern: "^(Error:|Warning:)"
    - pattern: "╷|│|╵"  # Terraform error boxes
    - pattern: "Plan:|Changes:|Outputs:"
    - pattern: "will be (created|destroyed|updated)"
  discard:
    - pattern: "Terraform.*version"
    - pattern: "Initializing.*backend"
    - pattern: "Terraform has been successfully initialized"
```

#### Node.js Filter
```yaml
# config/log-filters/node.yaml
guardrails:
  keep:
    - pattern: "^(Error|Warning|Exception)"
    - pattern: "at .*:\\d+:\\d+"  # Stack traces
    - pattern: "listening on port"
    - pattern: "Server.*start"
  discard:
    - pattern: "webpack.*compiled"
    - pattern: "node_modules/"
```

#### Python Filter
```yaml
# config/log-filters/python.yaml
guardrails:
  keep:
    - pattern: "^(Error|Exception|Warning|Traceback)"
    - pattern: 'File ".*", line \d+'
    - pattern: "DEPRECAT"
  discard:
    - pattern: "^Successfully installed"
    - pattern: "^Requirement already satisfied"
```

#### AWS CLI Filter
```yaml
# config/log-filters/aws.yaml
guardrails:
  keep:
    - pattern: "^(Error|InvalidParameter|AccessDenied|Unauthorized)"
    - pattern: "does not exist|not found"
  discard:
    - pattern: "AWS CLI version"
```

### User Extensibility

Users can override or extend filters:

```bash
# Create custom filter
mec config filter create my-custom-node
# Opens editor with template based on node.yaml

# Edit existing filter
mec config filter edit npm

# Test filter without applying
mec logs filter-test npm logs/npm/2025-01-19.raw.log

# Apply filter to existing log
mec logs filter npm logs/npm/2025-01-19.raw.log > filtered.log
```

### Implementation Files

```
src/utils/
├── common.sh              # Log abstraction functions
├── log-filter.sh          # Filter engine (parses YAML, applies rules)
└── log-manager.sh         # Log rotation, compression, cleanup

config/log-filters/
├── default.yaml           # Default filter (catch-all)
├── npm.yaml
├── node.yaml
├── terraform.yaml
├── python.yaml
└── aws.yaml
```

### Features
- **Opt-in:** Disabled by default, enabled via `MEC_SAVE_LOGS=1` or `mec config set logs.enabled true`
- **Dual storage:** Raw logs (short retention) + Filtered logs (longer retention)
- **Automatic cleanup:** Delete logs older than retention period
- **Compression:** Gzip logs older than 1 day
- **AI-optimized:** Filtered logs ready for AI analysis (reduced tokens/cost)
- **User control:** Custom filters, filter testing, manual filtering

---

## 10. UI/Dashboard Features

**Status:** ⏳ Pending
**Priority:** P2 (High)
**Phase:** 3

### Hybrid Approach
- **TUI:** Quick checks, management tasks (stay in terminal)
- **Web UI:** Metrics, visualization, deep analysis (browser-based)

### File Organization

Keep separation of concerns:
- `bin/` - Tool wrapper scripts ONLY
- `src/` - Internal my-ez-cli code
- `src/dashboard/` - TUI implementation
- `src/web-ui/` - Web UI implementation

If internal tools need to be accessible like bin scripts:
- Consider `bin/internals/` or `bin/mec/` for namespace separation

### TUI Dashboard

**Technology:** whiptail/dialog (bash-native, no extra dependencies)

**Launch:** `mec dashboard` or `mec ui`

#### Screens

1. **Main Menu**
```
┌─────────────────── My Ez CLI Dashboard ───────────────────┐
│                                                            │
│  1. Tool Manager    - Install/uninstall/update tools      │
│  2. Running Containers - View active containers           │
│  3. Logs Viewer     - Browse recent logs                  │
│  4. Configuration   - Manage settings                     │
│  5. System Status   - Docker, tools, health check         │
│  6. AI Assistant    - Configure AI integration            │
│  7. Web UI          - Launch web dashboard                │
│  8. Help            - Documentation                       │
│  9. Exit                                                   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

2. **Tool Manager** (Checkbox interface)
```
┌──────────────── Install/Uninstall Tools ────────────────┐
│                                                          │
│  [x] node (v24)         Installed                       │
│  [ ] node14             Not installed                   │
│  [x] npm                Installed                       │
│  [x] terraform          Installed                       │
│  [ ] aws                Not installed                   │
│  [x] python             Installed                       │
│  [ ] serverless         Not installed                   │
│                                                          │
│  Space=Select  Enter=Apply  Tab=Mode                    │
└──────────────────────────────────────────────────────────┘

Mode: [Install] [Uninstall] [Update]
```

3. **Logs Viewer**
```
┌────────────────── Recent Logs ──────────────────┐
│                                                  │
│  node/2025-01-19_14-30-45.log      (2.3 MB)    │
│  terraform/2025-01-19_12-15-30.log (856 KB)    │
│  npm/2025-01-18_16-45-22.log       (1.1 MB)    │
│                                                  │
│  [View] [Delete] [Export] [AI Analyze]         │
└──────────────────────────────────────────────────┘
```

4. **Configuration Editor**
```
┌─────────────────── Configuration ───────────────────┐
│                                                      │
│  Logs                                                │
│    ├─ Enabled: [x] Yes [ ] No                       │
│    ├─ Retention: [30] days                          │
│    └─ Compression: [x] Yes [ ] No                   │
│                                                      │
│  AI Integration                                      │
│    ├─ Enabled: [ ] Yes [x] No                       │
│    ├─ Provider: [OpenAI ▼]                          │
│    └─ API Key: [********************]               │
│                                                      │
│  [Save] [Cancel] [Reset to Defaults]                │
└──────────────────────────────────────────────────────┘
```

#### Implementation
```bash
# src/dashboard/tui.sh
#!/bin/bash

show_main_menu() {
    CHOICE=$(whiptail --title "My Ez CLI Dashboard" --menu "Choose an option:" 20 70 10 \
        "1" "Tool Manager - Install/uninstall/update tools" \
        "2" "Running Containers - View active containers" \
        "3" "Logs Viewer - Browse recent logs" \
        "4" "Configuration - Manage settings" \
        "5" "System Status - Docker, tools, health check" \
        "6" "AI Assistant - Configure AI integration" \
        "7" "Web UI - Launch web dashboard" \
        "8" "Help - Documentation" \
        "9" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1) show_tool_manager ;;
        2) show_running_containers ;;
        3) show_logs_viewer ;;
        4) show_configuration ;;
        5) show_system_status ;;
        6) show_ai_assistant ;;
        7) launch_web_ui ;;
        8) show_help ;;
        9) exit 0 ;;
    esac
}

show_tool_manager() {
    # Build checklist from available tools
    TOOLS=$(whiptail --title "Tool Manager" --checklist \
        "Select tools to install (Space=select, Enter=confirm):" 20 70 10 \
        "node" "Node.js v24" $(is_installed "node" && echo "ON" || echo "OFF") \
        "npm" "NPM package manager" $(is_installed "npm" && echo "ON" || echo "OFF") \
        "terraform" "Terraform CLI" $(is_installed "terraform" && echo "ON" || echo "OFF") \
        # ... etc
        3>&1 1>&2 2>&3)

    # Apply changes
    apply_tool_changes "$TOOLS"
}
```

### Web UI

**Technology:** Node.js + Vue.js

**Launch:** `mec web-ui start` or via TUI dashboard

**Port:** Default 8080, configurable

#### Structure
```
src/web-ui/
├── backend/
│   ├── server.js          # Express/Fastify server
│   ├── api/
│   │   ├── containers.js  # Docker container API
│   │   ├── logs.js        # Log retrieval API
│   │   ├── config.js      # Configuration API
│   │   └── tools.js       # Tool management API
│   └── services/
│       ├── docker.js      # Docker integration
│       └── metrics.js     # Metrics collection
├── frontend/
│   ├── src/
│   │   ├── App.vue
│   │   ├── components/
│   │   │   ├── Dashboard.vue
│   │   │   ├── ContainerMonitor.vue
│   │   │   ├── LogViewer.vue
│   │   │   ├── ToolManager.vue
│   │   │   └── ConfigEditor.vue
│   │   └── main.js
│   ├── package.json
│   └── vite.config.js
└── package.json
```

#### Features

1. **Dashboard** - Overview of system status
   - Running containers with resource usage (CPU, memory)
   - Recent command history
   - Quick tool status (installed/not installed)
   - System health (Docker running, disk space, etc.)

2. **Container Monitor** - Real-time container metrics
   - List of running containers
   - Live resource graphs (Chart.js)
   - Container logs streaming
   - Start/stop/restart controls

3. **Log Viewer** - Advanced log browsing
   - Search/filter across all logs
   - Syntax highlighting
   - Download logs
   - AI analysis integration (send to AI, view suggestions)

4. **Tool Manager** - Visual tool installation
   - Grid view of all tools with status
   - One-click install/uninstall
   - Version selection for multi-version tools (node14, node18, etc.)

5. **Configuration** - Settings management
   - Form-based config editor
   - Real-time validation
   - Import/export configuration

#### API Examples

```javascript
// GET /api/containers
{
  "containers": [
    {
      "id": "abc123",
      "name": "terraform-cli",
      "image": "hashicorp/terraform:1.9.8",
      "status": "running",
      "cpu": 12.5,
      "memory": 256,
      "ports": []
    }
  ]
}

// GET /api/logs?tool=node&limit=10
{
  "logs": [
    {
      "file": "2025-01-19_14-30-45.log",
      "size": 2400000,
      "created": "2025-01-19T14:30:45Z",
      "filtered": true
    }
  ]
}

// GET /api/tools
{
  "tools": [
    {
      "name": "node",
      "installed": true,
      "version": "22",
      "variants": ["node14", "node16", "node18", "node20", "node22", "node24"]
    }
  ]
}
```

#### Implementation
```bash
# Launch web UI
mec web-ui start
# Starting My Ez CLI Web UI on http://localhost:8080
# Press Ctrl+C to stop

# Background mode
mec web-ui start --daemon

# Stop
mec web-ui stop
```

---

## 11. Docker Compose Generation

**Status:** ⏳ Pending
**Priority:** P2 (High)
**Phase:** 3

**Decision:** Skip OS service/daemon approach. Implement docker-compose generation instead.

### Use Case
User runs multiple containers that need to communicate (e.g., Node.js app + PostgreSQL + Redis)

### Implementation

#### Auto-Generate from Usage
```bash
# Analyze recent commands and generate docker-compose.yml
mec compose generate

# Output: docker-compose.yml created with services:
#   - node (based on: mec-node usage)
#   - postgres (detected from env vars or config)
#   - redis (detected from recent commands)
```

#### Manual Definition
```yaml
# ~/.my-ez-cli/services/my-app.yaml
name: my-app
services:
  web:
    tool: node
    command: ["npm", "start"]
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
    volumes:
      - ./:/app

  db:
    tool: custom
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - ./data:/var/lib/postgresql/data

  redis:
    tool: custom
    image: redis:7-alpine
    ports:
      - "6379:6379"

network:
  name: my-app-network
```

#### Generate and Run
```bash
# Generate docker-compose.yml from service definition
mec compose from-service my-app

# Or generate from scratch
mec compose init
# Interactive prompts:
#   - Which tools do you want to include? [x] node [ ] python
#   - Add database? [x] postgres [ ] mysql [ ] mongodb
#   - Add cache? [x] redis [ ] memcached

# Generated docker-compose.yml
mec compose up
mec compose down
mec compose logs web
```

#### Implementation

```bash
# src/lib/compose-generator.sh

generate_compose() {
    cat > docker-compose.yml <<EOF
version: '3.8'

services:
  web:
    image: node:24-alpine
    working_dir: /app
    volumes:
      - ./:/app
    ports:
      - "3000:3000"
    command: npm start
    networks:
      - my-ez-cli-network

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: \${DB_PASSWORD:-secret}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - my-ez-cli-network

networks:
  my-ez-cli-network:
    driver: bridge

volumes:
  postgres-data:
EOF

    echo "Generated docker-compose.yml"
    echo "Run: mec compose up"
}
```

### Features
- Auto-detect tools from recent usage
- Template library for common stacks (MERN, Django+Postgres, etc.)
- Service discovery (containers can reference each other by name)
- Simple and Docker-native (no custom daemon needed)
- User can extend/modify generated compose file

---

## 12. Overall UX Improvements

**Status:** ⏳ Pending
**Priority:** P1 (High)
**Phase:** All phases

### 12.1 Better Help System

```bash
mec help                    # Overview
mec help node               # Tool-specific help
mec help env node           # Shows all env vars for node
mec examples node           # Common usage examples
```

**Implementation:**
```bash
# src/cli/help.sh
show_help() {
    TOOL="$1"

    if [ -z "$TOOL" ]; then
        # General help
        cat <<EOF
My Ez CLI (mec) - Docker-based CLI tool wrappers

Usage:
  mec <command> [options]
  mec-<tool> [tool-args]

Commands:
  help [tool]          Show help for a tool
  config               Manage configuration
  dashboard            Launch TUI dashboard
  web-ui               Launch web dashboard
  logs                 View logs
  compose              Docker compose operations
  doctor               Run health checks
  update               Update my-ez-cli
  version              Show version

Tools:
  node, npm, npx, yarn, python, terraform, aws, gcloud,
  serverless, cdktf, playwright, promptfoo

Examples:
  mec help node           Show node help
  mec config list         Show configuration
  mec-node --version      Run Node.js
  mec logs node --last 5  View recent node logs

Documentation: https://github.com/DavidCardoso/my-ez-cli
EOF
    else
        # Tool-specific help
        show_tool_help "$TOOL"
    fi
}
```

### 12.2 Interactive Setup

```bash
./setup.sh interactive
# or
mec setup interactive

# Interactive wizard:
# ┌─────────────── My Ez CLI Setup ───────────────┐
# │ Welcome! Let's configure My Ez CLI.           │
# │                                                │
# │ 1. Which tools do you use?                    │
# │    [x] node    [ ] terraform  [x] aws         │
# │    [ ] python  [x] npm        [ ] gcloud      │
# │                                                │
# │ 2. Enable AI assistance?                      │
# │    ( ) Yes  (•) No                             │
# │                                                │
# │ 3. Save logs automatically?                   │
# │    (•) Yes  ( ) No                             │
# │                                                │
# │ 4. Install location                           │
# │    [/usr/local/bin]                            │
# │                                                │
# │        [Continue]  [Skip]  [Cancel]           │
# └────────────────────────────────────────────────┘
```

### 12.3 Health Checks

```bash
mec doctor

# Output:
# My Ez CLI Health Check
# ─────────────────────────
# ✓ Docker is running (v24.0.0)
# ✓ Docker Compose installed (v2.20.0)
# ✓ Zsh detected
# ✓ Installed tools:
#   ✓ node (v24)
#   ✓ npm (v10)
#   ✓ terraform (v1.9.8)
# ✗ Python image not found
#   → Pulling image python:3.12-alpine...
#   ✓ Image pulled successfully
# ✓ Environment:
#   ✓ AWS credentials configured
#   ✗ NPM_TOKEN not set (optional)
# ✓ Logs directory: ~/.my-ez-cli/logs (2.3 GB)
# ✓ Configuration valid
#
# Overall: ✓ Healthy
```

### 12.4 Version Management

```bash
mec version
# My Ez CLI v1.0.0

mec update --check
# Current version: v1.0.0
# Latest version: v1.1.0
# Update available! Run 'mec update' to upgrade.

mec update
# Updating My Ez CLI from v1.0.0 to v1.1.0...
# ✓ Downloaded release
# ✓ Verified checksum
# ✓ Installed new version
# ✓ Updated symlinks
# Successfully updated to v1.1.0!
```

### 12.5 Configuration System (Git-style)

```bash
# Set values
mec config set ai.enabled true
mec config set ai.provider anthropic
mec config set logs.retention-days 14
mec config set node.default-version 24

# Get values
mec config get ai.enabled
# true

# List all
mec config list
# ai.enabled=true
# ai.provider=anthropic
# ai.model=claude-3-sonnet-20240229
# logs.enabled=true
# logs.retention-days=14
# node.default-version=22

# Edit in editor
mec config edit

# Reset to defaults
mec config reset
```

**Configuration file:**
```yaml
# ~/.my-ez-cli/config.yaml
version: 1

ai:
  enabled: false
  provider: openai  # openai, anthropic, ollama
  model: gpt-4-turbo
  api_key_env: OPENAI_API_KEY

logs:
  enabled: false
  retention_days: 30
  compress_after_days: 1
  max_size_mb: 10

tools:
  node:
    default_version: 24
  terraform:
    default_context: parent

ui:
  web_port: 8080
  tui_theme: default
```

### 12.6 Shell Completion

```bash
# Install completion
mec completion install

# Or add to .zshrc:
source <(mec completion zsh)

# Usage:
mec <TAB>          # Shows: help, config, dashboard, logs, etc.
mec-node <TAB>     # Shows: --version, -e, -p, etc. (from Node.js)
mec config <TAB>   # Shows: get, set, list, edit, reset
```

**Implementation:**
```bash
# src/cli/completion.sh
generate_completion() {
    SHELL_TYPE="$1"

    if [ "$SHELL_TYPE" = "zsh" ]; then
        cat <<'EOF'
#compdef mec

_mec() {
    local -a commands
    commands=(
        'help:Show help'
        'config:Manage configuration'
        'dashboard:Launch TUI dashboard'
        'logs:View logs'
        'doctor:Run health checks'
    )
    _describe 'command' commands
}

_mec
EOF
    fi
}
```

### 12.7 Better Error Messages

**Before:**
```
docker: command not found
```

**After:**
```
[mec] ERROR: Docker is not running or not installed

Troubleshooting:
  1. Check if Docker is installed:
     docker --version

  2. Start Docker:
     macOS: open -a Docker
     Linux: sudo systemctl start docker

  3. Install Docker:
     https://docker.com/get-started

Need help? Run: mec doctor
```

### 12.8 Onboarding

**First-run experience:**
```bash
# After installation
mec

# Output:
# ┌──────────────────────────────────────────────────┐
# │      Welcome to My Ez CLI! 🚀                    │
# ├──────────────────────────────────────────────────┤
# │                                                  │
# │  My Ez CLI provides Docker-based wrappers for   │
# │  development tools with zero installation.      │
# │                                                  │
# │  Quick setup (2 minutes):                       │
# │    1. Select tools to install                   │
# │    2. Configure settings (optional)             │
# │                                                  │
# │  Start setup now? [Y/n]                         │
# │                                                  │
# │  Or skip: mec help                              │
# └──────────────────────────────────────────────────┘
```

### 12.9 Examples Library

```bash
mec examples node
# Node.js Examples
# ────────────────
#
# Run JavaScript file:
#   mec-node app.js
#
# Run with port binding:
#   MEC_BIND_PORTS="3000:3000" mec-node server.js
#
# Run REPL:
#   mec-node
#
# Execute code:
#   mec-node -e "console.log('Hello')"
#
# Use specific version:
#   mec-node18 app.js

mec examples terraform aws
# Terraform with AWS Examples
# ───────────────────────────
#
# Initialize:
#   mec-terraform init
#
# Plan with AWS profile:
#   AWS_PROFILE=my-profile mec-terraform plan
#
# Apply with custom context:
#   CONTEXT=/path/to/modules mec-terraform apply
```

### 12.10 Status Indicators

```bash
# Long-running command
mec-terraform apply

# Output:
# [mec] Running terraform in container terraform-cli-abc123
# [mec] Logs: ~/.my-ez-cli/logs/terraform/2025-01-19_15-30-00.log
# [mec] AI assistance: enabled
# [mec] Press Ctrl+C to stop (container will be removed)
#
# Terraform will perform the following actions:
# ...
```

---

## Implementation Phases

### Phase 1: Foundation (Priority P0)

**Goal:** Fix critical issues, establish solid base

**Tasks:**
- [ ] Fix bin/utils path resolution (#6)
- [ ] Create `src/utils/common.sh` with unified utilities
- [ ] Update all bin scripts to use common.sh
- [ ] Improve setup.sh with multi-select (#1)
- [ ] Add install/uninstall/status commands
- [ ] Create GitHub workflows for Docker builds (#4)
- [ ] Set up testing framework with bats-core (#5)
- [ ] Write unit tests for 5+ tools

**Deliverables:**
- All scripts work from any location (symlink-safe)
- Multi-select installation
- Automated Docker image builds
- Basic test coverage

**Duration:** High priority, implement ASAP

---

### Phase 2: Distribution (Priority P1)

**Goal:** Make my-ez-cli easily accessible

**Tasks:**
- [ ] Create NPM package structure (#8)
- [ ] Implement `mec` alias pattern (mec-node, mec-terraform, etc.)
- [ ] Create Node.js wrapper scripts (wrappers/*.js)
- [ ] Set up package.json with bin entries
- [ ] Implement npx support (#7)
- [ ] Create remote execution via curl (#7)
- [ ] Create install script (#7)
- [ ] Write npm publish GitHub workflow
- [ ] Publish v1.0.0 to npm

**Deliverables:**
- NPM package: @my-ez-cli/core
- npx support: `npx mec-node --version`
- Remote curl execution
- First stable release (v1.0.0)

**Duration:** After Phase 1

---

### Phase 3: Enhanced Features (Priority P1-P2)

**Goal:** Add advanced capabilities

**Tasks:**
- [ ] Implement log persistence system (#9)
- [ ] Create `src/utils/log-manager.sh`
- [ ] Abstract logging in common.sh
- [ ] Create baseline filter rules (npm, terraform, node, python, aws)
- [ ] Implement log filtering/guardrails
- [ ] Implement AI integration MVP (#2)
  - [ ] BYOK configuration
  - [ ] OpenAI provider
  - [ ] Anthropic provider
  - [ ] Port detection analyzer
  - [ ] Error analyzer
- [ ] Create TUI dashboard (#10)
  - [ ] Main menu (whiptail/dialog)
  - [ ] Tool manager screen
  - [ ] Log viewer screen
  - [ ] Configuration editor
- [ ] Create Warp workflows (#3)
- [ ] Implement docker-compose generation (#11)
- [ ] Implement config system (mec config get/set/list) (#12)

**Deliverables:**
- Log persistence with AI-optimized filtering
- AI assistance (BYOK)
- TUI dashboard
- Docker compose generation
- Warp workflows
- Git-style config system

**Duration:** After Phase 2

---

### Phase 4: Polish & Advanced (Priority P2-P3)

**Goal:** Complete UX improvements and advanced features

**Tasks:**
- [ ] Create Web UI (#10)
  - [ ] Backend API (Node.js + Express)
  - [ ] Frontend (Vue.js)
  - [ ] Container monitoring
  - [ ] Log viewer
  - [ ] Metrics visualization
- [ ] Implement help system (#12)
- [ ] Implement mec doctor (#12)
- [ ] Implement shell completion (#12)
- [ ] Implement examples library (#12)
- [ ] Improve error messages (#12)
- [ ] Create onboarding flow (#12)
- [ ] Expand AI capabilities (#2)
  - [ ] Environment variable suggester
  - [ ] Configuration validator
  - [ ] Ollama local support
- [ ] Write comprehensive documentation
- [ ] Create video tutorials

**Deliverables:**
- Web UI dashboard
- Complete help system
- Shell completion
- Enhanced error messages
- Onboarding experience
- Full AI integration

**Duration:** After Phase 3

---

### Phase 5: Security & Encryption (v1.3.0)

**Goal:** Add log encryption for sensitive data protection

**Tasks:**
- [ ] Design encryption module architecture (#9)
- [ ] Implement `src/utils/crypto.sh` encryption module
- [ ] Add AES-256-GCM encryption support
- [ ] Implement key management system
  - [ ] Key generation (`mec logs generate-key`)
  - [ ] Key storage (~/.my-ez-cli/secrets/)
  - [ ] Key rotation support
- [ ] Add selective field encryption
- [ ] Transparent encryption/decryption in log manager
- [ ] Update log schema to support encrypted fields
- [ ] Add encryption configuration to config.yaml
- [ ] Update log viewer to auto-decrypt
- [ ] Write tests for encryption module
- [ ] Security audit and hardening
- [ ] Documentation for encryption feature

**Deliverables:**
- Log encryption support (opt-in)
- Key management CLI
- Backward compatibility with unencrypted logs
- Security documentation

**Duration:** After Phase 4 (v1.2.0 release)

---

### Phase 6: Advanced Analytics & Log Database (v1.4.0)

**Goal:** Enable log database integrations for advanced querying and analytics

**Tasks:**
- [ ] Design exporter plugin architecture (#9)
- [ ] Create `src/exporters/` directory structure
- [ ] Implement Elasticsearch exporter
  - [ ] Docker container management
  - [ ] Index creation and mapping
  - [ ] Batch upload system
  - [ ] Query interface
- [ ] Implement Unity Catalog exporter
  - [ ] Delta table format
  - [ ] Catalog/schema management
  - [ ] Databricks integration
- [ ] Implement PostgreSQL exporter
  - [ ] Table schema creation
  - [ ] Connection pooling
  - [ ] SQL query interface
- [ ] Implement ClickHouse exporter
  - [ ] Time-series optimization
  - [ ] Analytics queries
- [ ] Create database management CLI
  - [ ] `mec logs database start <platform>`
  - [ ] `mec logs database init <platform>`
  - [ ] `mec logs database query <filters>`
- [ ] Add Kibana dashboard integration
- [ ] Implement async export (don't block tool execution)
- [ ] Add health checks and retry logic
- [ ] Configuration system for exporters
- [ ] Write tests for all exporters
- [ ] Documentation for each platform

**Deliverables:**
- Elasticsearch integration with Kibana
- Unity Catalog integration
- PostgreSQL and ClickHouse support
- Pluggable exporter architecture
- Advanced log querying capabilities
- Self-hosted database containers

**Duration:** After Phase 5 (v1.3.0 release)

---

### Phase 7: Alternative Distribution (Homebrew & Debian)

**Goal:** Expand distribution channels

**Note:** Homebrew formula included in v1.1.0 (Phase 3), Debian package in v1.2.0 (Phase 4)

**Tasks:**
- [ ] Create Homebrew tap repository (#8)
  - [ ] Create davidcardoso/homebrew-my-ez-cli repo
  - [ ] Write formula (Formula/my-ez-cli.rb)
  - [ ] Test installation
  - [ ] Include in v1.1.0 release
- [ ] Create Debian package (#8)
  - [ ] Create package structure
  - [ ] Write build script
  - [ ] Set up GitHub workflow
  - [ ] Publish to GitHub Releases
  - [ ] Include in v1.2.0 release

**Deliverables:**
- Homebrew formula (v1.1.0)
- Debian package (v1.2.0)

**Duration:** Homebrew in Phase 3, Debian in Phase 4

---

## Priority Matrix

| Item | Phase | Priority | Impact | Effort | Status |
|------|-------|----------|--------|--------|--------|
| #6 Path resolution | 1 | P0 | High | Low | ⏳ Pending |
| #1 Setup improvements | 1 | P0 | High | Medium | ⏳ Pending |
| #4 GitHub workflows | 1 | P0 | High | Low | ⏳ Pending |
| #5 Testing | 1 | P0 | High | Medium | ⏳ Pending |
| #8 NPM publish | 2 | P1 | High | Medium | ⏳ Pending |
| #7 Remote execution | 2 | P1 | Medium | Medium | ⏳ Pending |
| #9 Log persistence | 3 | P1 | Medium | Medium | ⏳ Pending |
| #12 UX improvements | 3-4 | P1 | High | High | ⏳ Pending |
| #2 AI integration | 3-4 | P2 | High | High | ⏳ Pending |
| #10 TUI dashboard | 3 | P2 | Medium | Medium | ⏳ Pending |
| #11 Compose generation | 3 | P2 | Medium | Low | ⏳ Pending |
| #3 Warp workflows | 3 | P3 | Low | Low | ⏳ Pending |
| #10 Web UI | 4 | P3 | Low | High | ⏳ Pending |
| #8 Homebrew | 3 | P3 | Medium | Medium | ⏳ Pending |
| #8 Debian | 4 | P3 | Medium | Medium | ⏳ Pending |
| #9 Log encryption | 5 | P4 | Medium | Medium | ⏳ Future |
| #9 Log database | 6 | P4 | Medium | High | ⏳ Future |

---

## Version Roadmap

### v1.0.0 - First Stable Release
**Target:** After Phase 2 completion

**Includes:**
- Fixed path resolution
- Multi-select installation
- GitHub workflows for Docker builds
- Basic test coverage
- NPM package with mec alias pattern
- npx support
- Remote execution (curl + install script)

### v1.1.0 - Enhanced Features
**Target:** After Phase 3 completion

**Includes:**
- Log persistence with filtering
- AI integration (BYOK)
- TUI dashboard
- Docker compose generation
- Config system
- Warp workflows
- Homebrew formula

### v1.2.0 - Complete Experience
**Target:** After Phase 4 completion

**Includes:**
- Web UI dashboard
- Full help system
- Shell completion
- Enhanced UX
- Full AI capabilities
- Debian package

### v1.3.0 - Security & Encryption
**Target:** After Phase 5 completion

**Includes:**
- Log encryption support (AES-256-GCM)
- Selective field encryption
- Key management
- Transparent encryption/decryption
- Security hardening

### v1.4.0 - Advanced Analytics
**Target:** After Phase 6 completion

**Includes:**
- Log database exporters (Elasticsearch, Unity Catalog, PostgreSQL, ClickHouse)
- Docker containers for self-hosted databases
- Advanced log querying
- Kibana dashboard integration
- Data governance features

---

## Reminders

- [ ] **Create Homebrew tap:** After v1.0.0 release, create `davidcardoso/homebrew-my-ez-cli` repository
- [ ] **Update documentation:** Keep README.md in sync with new features
- [ ] **Write migration guide:** For users upgrading from 0.x.y to 1.0.0
- [ ] **Announce release:** Blog post, Reddit, HN, Twitter
- [ ] **Gather feedback:** Create feedback form for v1.0.0 users

---

## Notes

### Core Principles
- **v1.0.0 is the first stable release** - Previous versions were 0.x.y (beta)
- **Direct names are PRIMARY** - Tool names (node, terraform, npm) are default; mec-* prefix is alternative
- **User choice for installation** - Support direct-only, mec-only, or both modes
- **Conflict detection** - Detect native tools, warn user, offer choices

### Distribution
- **All three remote execution methods will be implemented** - curl, install script, npx
- **External registry configs saved for last** - After implementation is complete
- **Homebrew and Debian packages come in later releases** - v1.1.0 and v1.2.0
- **Trivy is free and open source** - Apache 2.0 license, safe to use in CI

### Technology Choices
- **AI integration uses BYOK** - Users provide their own API keys (OpenAI, Anthropic, Ollama)
- **TUI uses whiptail/dialog** - Stay close to bash, no extra language dependencies
- **Web UI uses Node + Vue** - JavaScript ecosystem for consistency
- **Skip OS service/daemon** - Docker compose generation is simpler and sufficient

### Log System Architecture
- **Modular design from day 1** - Pluggable modules to avoid breaking changes
- **Structured logs (JSON)** - Enable future integrations with Elasticsearch, Unity Catalog, etc.
- **Logs use guardrail terminology** - Aligned with AI/LLM evaluation frameworks
- **Encryption is opt-in (v1.3.0+)** - AES-256-GCM, transparent, backward compatible
- **Database exporters are pluggable (v1.4.0+)** - Add without changing core system
- **No breaking changes in v1.x** - All enhancements backward compatible

### Design for Future-Proofing
- **Modular log layers:** Application → Manager → Modules (Formatter, Filter, Encryptor) → Storage
- **Pluggable storage:** File (v1.0) → Database exporters (v1.4+) → Remote shipping (future)
- **Schema versioning:** Log entry schema v1 with version field for future evolution
- **Backward compatibility:** Old logs readable, new features opt-in, no API breakage

---

## Success Criteria

**v1.0.0 is ready when:**
- [ ] All Phase 1 tasks complete (path resolution, setup, workflows, tests)
- [ ] All Phase 2 tasks complete (npm package, remote execution)
- [ ] Published to npm registry as @my-ez-cli/core
- [ ] All existing tools work with new structure
- [ ] Documentation updated
- [ ] Migration guide written
- [ ] At least 50% test coverage

---

*This roadmap is a living document. Update as implementation progresses.*

**Last updated:** 2025-01-19
