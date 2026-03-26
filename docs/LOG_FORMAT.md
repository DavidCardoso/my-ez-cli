# Log Format Specification

Status: Draft
Last Updated: 2026-02-20

## Overview

My Ez CLI uses a structured JSON log format for all tool executions. This format enables:
- Machine-readable logs for AI processing
- Consistent structure across all tools
- Easy filtering and querying
- Log rotation and compression
- Database export capabilities (future)

## JSON Log Entry Schema

### Base Structure

```json
{
  "version": "1.0",
  "timestamp": "2026-01-15T10:30:45.123Z",
  "session_id": "mec-node-1705318245",
  "tool": "node",
  "image": "node:24-alpine",
  "command": "node server.js",
  "cwd": "/Users/username/project",
  "environment": {
    "MEC_BIND_PORTS": "8080:80",
    "NODE_ENV": "development"
  },
  "execution": {
    "start_time": "2026-01-15T10:30:45.123Z",
    "end_time": "2026-01-15T10:30:47.456Z",
    "duration_ms": 2333,
    "exit_code": 0
  },
  "output": {
    "stdout": "Server listening on port 8080\n",
    "stderr": "",
    "filtered": false,
    "filter_rules": []
  },
  "metadata": {
    "mec_version": "1.0.0-rc",
    "user": "username",
    "hostname": "macbook-pro.local",
    "platform": "darwin",
    "container_name": "mec-node-1705318245"
  }
}
```

### Field Descriptions

#### Top-Level Fields

- `version` (string): Log format version (semver)
- `timestamp` (string): ISO 8601 timestamp when log entry was created
- `session_id` (string): Unique identifier for this execution (same as container name)
- `tool` (string): Tool name (node, terraform, aws, etc.)
- `image` (string): Docker image used
- `command` (string): Full command executed
- `cwd` (string): Working directory where command was executed

#### environment (object)

Environment variables passed to the container. Only includes:
- MEC_* variables
- Tool-specific variables (NODE_ENV, AWS_PROFILE, TF_VAR_*, etc.)
- Excludes sensitive data (tokens, passwords, keys)

#### execution (object)

- `start_time` (string): ISO 8601 timestamp when execution started
- `end_time` (string): ISO 8601 timestamp when execution ended
- `duration_ms` (number): Execution duration in milliseconds
- `exit_code` (number): Command exit code

#### output (object)

- `stdout` (string): Standard output (may be filtered)
- `stderr` (string): Standard error (may be filtered)
- `filtered` (boolean): Whether output was filtered
- `filter_rules` (array): List of filter rule names applied

#### metadata (object)

- `mec_version` (string): My Ez CLI version
- `user` (string): System username
- `hostname` (string): System hostname
- `platform` (string): OS platform (darwin, linux)
- `container_name` (string): Docker container name

## Log Files

### Directory Structure

```
$HOME/.my-ez-cli/
├── logs/                          ← tool execution logs (immutable after finalization)
│   ├── node/
│   │   ├── 2026-01-15_10-30-45.json
│   │   ├── 2026-01-15_10-30-45.raw.log
│   │   └── ...
│   ├── terraform/
│   │   └── ...
│   └── aws/
│       └── ...
├── ai-analyses/                   ← AI analysis sidecars (created only if AI runs)
│   ├── node/
│   │   ├── 2026-01-15_10-30-45.json   ← same filename as log
│   │   └── ...
│   ├── terraform/
│   │   └── ...
│   └── aws/
│       └── ...
└── config.yaml
```

Tool log files are **written once and never mutated**. AI analyses go into the parallel `ai-analyses/` tree — the filename is the link between a log and its sidecar.

### File Types

1. **JSON Logs** (`.json` under `logs/`): Structured log entries following the schema above
2. **Raw Logs** (`.raw.log` under `logs/`): Unfiltered stdout/stderr for debugging
3. **AI Sidecar** (`.json` under `ai-analyses/`): AI analysis results — see schema below

### Naming Convention

Format: `YYYY-MM-DD_HH-MM-SS.{json|raw.log}`

Example: `2026-01-15_10-30-45.json`

### AI Sidecar Schema

When `MEC_AI_ENABLED=true` and Claude Code runs after a tool execution, an AI sidecar is created at the corresponding path under `ai-analyses/`:

```json
{
  "log_session_id": "mec-node-1705318245",
  "log_file": "/Users/username/.my-ez-cli/logs/node/2026-01-15_10-30-45.json",
  "analyses": {
    "<claude_session_id>": {
      "timestamp": "2026-03-26T14:30:45.123456+00:00",
      "result": "Analysis text…",
      "execution_time_ms": 12450,
      "tokens": {
        "input": 3200,
        "output": 512
      }
    }
  }
}
```

- `log_session_id`: tool session ID (matches the log file's `session_id`)
- `log_file`: absolute path to the corresponding tool log file
- `analyses`: dict keyed by Claude session ID — allows re-analysis without overwriting
- `execution_time_ms` — wall-clock milliseconds from start to end of Claude Code analysis
- `tokens.input` — input token count from Claude's `usage` response field
- `tokens.output` — output token count from Claude's `usage` response field

`mec logs list` and `mec logs stats` report the `AI` column by checking for the sidecar file — the tool log is never read for this purpose.

## Filtering and Guardrails

### Purpose

Filter out noise and unnecessary output to optimize AI context usage:
- Dependency installation verbose output
- Progress indicators and spinners
- Repetitive debug messages
- ANSI color codes

### Filter Rules by Tool

#### NPM/Yarn
- Package installation progress
- Deprecated package warnings (configurable)
- Peer dependency warnings (configurable)
- Audit warnings (keep security issues)

#### Terraform
- Resource refresh progress
- Plan output formatting (keep summary)
- Provider download progress

#### Node.js
- Module resolution debug output
- Experimental feature warnings (configurable)

#### Python
- pip installation progress
- Deprecation warnings (configurable)

#### AWS CLI
- Pagination indicators
- Progress bars for uploads/downloads

### Configuration

Filter rules are configurable via `~/.my-ez-cli/config.yaml`:

```yaml
logs:
  enabled: true
  level: info
  format: json
  filters:
    npm:
      - suppress_deprecation_warnings: false
      - suppress_peer_warnings: true
      - suppress_audit_info: true
    terraform:
      - suppress_refresh_progress: true
      - keep_plan_summary: true
```

## Log Rotation

### Strategy

- **Time-based rotation**: Daily rotation by default
- **Size-based rotation**: When log directory exceeds threshold
- **Compression**: Gzip compression for logs older than 7 days
- **Retention**: Keep logs for 30 days by default (configurable)

### Configuration

```yaml
logs:
  rotation:
    strategy: daily  # daily, weekly, size-based
    compress_after_days: 7
    retention_days: 30
    max_size_mb: 100  # for size-based rotation
```

## Privacy and Security

### Sensitive Data Handling

The log system automatically redacts:
- API keys (AWS_ACCESS_KEY_ID, ANTHROPIC_API_KEY, etc.)
- Tokens (NPM_TOKEN, GITHUB_TOKEN, etc.)
- Passwords and credentials
- SSH keys
- Private keys

### Redaction Pattern

Sensitive values are replaced with: `[REDACTED]`

Example:
```json
{
  "environment": {
    "AWS_ACCESS_KEY_ID": "[REDACTED]",
    "AWS_PROFILE": "production"
  }
}
```

## Future Enhancements

- Database export (SQLite, PostgreSQL)
- Log streaming to remote endpoints
- Real-time log analysis
- Performance metrics and aggregation
- Log query language
- Integration with observability platforms

## Change History

- **2026-02-20**: AI sidecar directory; immutable log files
  - Tool log files are immutable after finalization
  - AI analyses written to parallel `ai-analyses/` directory tree
  - Added AI Sidecar Schema section
- **2026-01-15**: Initial specification
