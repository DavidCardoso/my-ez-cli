# Configuration Guide

Last Updated: 2026-01-15

## Overview

My Ez CLI uses a git-style configuration system that stores settings in `~/.my-ez-cli/config.yaml`. This guide explains how to manage your configuration.

## Quick Start

```shell
# View current configuration
mec config list

# Get a specific value
mec config get telemetry.enabled

# Set a value
mec config set logs.enabled true

# Edit config file directly
mec config edit

# Reset to defaults
mec config reset
```

## Configuration File

### Location

Configuration file: `~/.my-ez-cli/config.yaml`

Default template: `<install-dir>/config/config.default.yaml`

### Structure

The configuration file uses YAML format with the following main sections:

- `telemetry`: Session telemetry settings (on by default — opt-out)
- `logs`: stdout/stderr capture and rotation settings (off by default — opt-in)
- `ai`: AI integration settings
- `tools`: Tool-specific configurations
- `performance`: Performance and caching settings
- `privacy`: Privacy and security settings
- `experimental`: Experimental features

## Commands

### Get Configuration Value

Retrieve a specific configuration value:

```shell
mec config get <key>

# Examples
mec config get telemetry.enabled
mec config get logs.enabled
mec config get ai.provider
mec config get tools.node.default_version
```

### Set Configuration Value

Update a configuration value:

```shell
mec config set <key> <value>

# Examples
mec config set telemetry.enabled false
mec config set logs.enabled true
mec config set logs.level debug
mec config set ai.provider anthropic
mec config set tools.node.default_version 24
```

### List Configuration

Display all configuration settings:

```shell
mec config list
```

### Edit Configuration

Open configuration file in your default editor:

```shell
mec config edit

# Uses $EDITOR environment variable (defaults to vi)
# Example: EDITOR=nano mec config edit
```

### Reset Configuration

Reset configuration to defaults:

```shell
mec config reset

# Your current config will be backed up before reset
```

### Other Commands

```shell
# Show config file path
mec config path

# Show config directory path
mec config dir

# Validate config file
mec config validate

# Export config as environment variables
eval $(mec config export)
```

## Configuration Sections

### Telemetry

Control session metadata recording (opt-out — enabled by default):

```yaml
telemetry:
  enabled: true                     # Enable/disable session telemetry (session_id, tool, exit_code, timing)
```

**Environment Variable Overrides:**
- `MEC_TELEMETRY_ENABLED=false` - Disable telemetry

### Logs

Control stdout/stderr capture and rotation (opt-in — disabled by default):

```yaml
logs:
  enabled: false                    # Enable/disable stdout/stderr capture
  level: info                       # Log level: debug, info, warn, error
  format: json                      # Log format: json, text

  rotation:
    strategy: daily                 # daily, weekly, size-based
    compress_after_days: 7
    retention_days: 30
    max_size_mb: 100
```

> **Note:** Tool output filtering is configured under `ai.filters`, not `logs`. See [AI Integration](#ai-integration) below.

**Environment Variable Overrides:**
- `MEC_LOGS_ENABLED=true` - Enable stdout/stderr capture
- `MEC_LOG_LEVEL=debug` - Set log level
- `MEC_LOG_DIR=/path/to/logs` - Custom log directory

### AI Integration

Configure AI-powered analysis via Claude Code. `ai.filters` is the single filtering layer — tool-specific noise patterns (npm, terraform, python, aws) are all expressed here as regex patterns applied before output is sent to Claude Code.

```yaml
ai:
  enabled: false                    # Enable/disable AI features

  filters:
    ignore_output:                  # Regex patterns to suppress from tool output
      - "^npm warn"
      - "^npm WARN"
      - "^Downloading.*\\d+%"
      - "├──|└──|│"
      - "^\\s*$"
    ignore_input:                   # Patterns to exclude from input context
      - "node_modules/"
      - "*.lock"
      - ".git/"

  claude:
    image: "ghcr.io/my-ez-cli/claude:latest"
    max_turns: 1
    output_format: text
```

**Required Environment Variables:**
- `ANTHROPIC_API_KEY` - Required for automated analysis (`exec_with_ai`, `mec ai analyze`)
- `CLAUDE_CODE_OAUTH_TOKEN` - Alternative: OAuth token for Claude.ai subscribers

See [AI_INTEGRATION.md](./AI_INTEGRATION.md) for full details.

### Tool-Specific Settings

> **Note:** These settings are defined but not yet implemented. Keys in this section are not read at runtime.

Customize behavior for specific tools:

```yaml
tools:
  node:
    default_version: 24             # Default Node version (22, 24)
    auto_bind_ports: false          # Auto-bind ports

  terraform:
    auto_load_env: true             # Auto-load .env files
    # default_workspace: default

  aws:
    # default_profile: default
    # default_region: us-east-1

  python:
    # default_version: 3.12
```

### Performance

> **Note:** These settings are defined but not yet implemented. Keys in this section are not read at runtime.

Control caching and cleanup:

```yaml
performance:
  cache:
    enabled: true                   # Enable image caching
    auto_pull: false                # Auto-pull on install

  cleanup:
    auto_remove: true               # Auto-remove containers
    cleanup_after_days: 7           # Cleanup interval
```

### Privacy

> **Note:** These settings are defined but not yet implemented. Keys in this section are not read at runtime.

Privacy and security settings:

```yaml
privacy:
  telemetry:
    enabled: false                  # Telemetry (not implemented)

  redaction:
    redact_api_keys: true          # Redact keys in logs
    redact_tokens: true            # Redact tokens in logs
    redact_credentials: true       # Redact credentials in logs
```

## Environment Variables

Configuration values can be overridden with environment variables:

### Telemetry
- `MEC_TELEMETRY_ENABLED` - Enable/disable session telemetry (true/false, default: true)

### Logs
- `MEC_LOGS_ENABLED` - Enable stdout/stderr capture (true/false, default: false)
- `MEC_LOG_LEVEL` - Log level (debug/info/warn/error)
- `MEC_LOG_FORMAT` - Log format (json/text)
- `MEC_LOG_DIR` - Custom log directory
- `MEC_SAVE_LOGS` - Legacy: Enable telemetry (1/0)

### AI
- `MEC_AI_ENABLED` - Enable AI features (true/false)
- `ANTHROPIC_API_KEY` - Anthropic API key (required for automated analysis)
- `CLAUDE_CODE_OAUTH_TOKEN` - OAuth token alternative for Claude.ai subscribers

### General
- `MEC_DEBUG` - Enable debug mode (1/0)
- `MEC_VERSION` - My Ez CLI version (read-only)

## Examples

### Enable Output Capture

```shell
# Enable stdout/stderr capture (telemetry is on by default)
mec logs enable
# or: mec config set logs.enabled true

# Or use environment variable for a single run
MEC_LOGS_ENABLED=true node server.js

# View logs
ls ~/.my-ez-cli/logs/node/
```

### Configure AI Integration

```shell
# Enable AI analysis
mec config set ai.enabled true

# Set API key (use environment variable, not config file)
export ANTHROPIC_API_KEY="your-key-here"

# Test Claude Code connectivity
mec ai test

# Check status
mec ai status
```

### Customize Tool Defaults

```shell
# Set default Node version
mec config set tools.node.default_version 22

# Enable auto-port binding for Node
mec config set tools.node.auto_bind_ports true

# Set default AWS profile
mec config set tools.aws.default_profile production
```

### Customize Output Filtering

```shell
# Edit config to customize AI filter patterns
mec config edit

# Then modify the ai.filters section:
# ai:
#   filters:
#     ignore_output:
#       - "^npm warn"
#       - "^my custom pattern"
```

## Migration from v0.x

### Legacy Environment Variables

The following legacy variables are still supported:

- `MEC_SAVE_LOGS=1` equivalent to `MEC_TELEMETRY_ENABLED=true`

### Upgrading Configuration

If you're upgrading from v0.x, your configuration will be automatically migrated on first use. The new system is backward compatible with environment variables.

## Troubleshooting

### Config File Not Found

If config file is missing, initialize it:

```shell
mec config init
```

### Invalid Configuration

Validate your config file:

```shell
mec config validate
```

### Reset to Defaults

If config is corrupted, reset to defaults:

```shell
mec config reset
```

Your old config will be backed up to:
`~/.my-ez-cli/config.yaml.backup.YYYYMMDD_HHMMSS`

### Check Current Settings

View all current settings:

```shell
mec config list
```

## Best Practices

1. **Use Environment Variables for Secrets**: Never store API keys or tokens in config.yaml. Use environment variables instead.

2. **Version Control**: Add `~/.my-ez-cli/config.yaml` to your global `.gitignore` to avoid committing sensitive settings.

3. **Backup Before Reset**: The system automatically backs up your config before resetting, but you can manually backup with:
   ```shell
   cp ~/.my-ez-cli/config.yaml ~/.my-ez-cli/config.yaml.backup
   ```

4. **Test Changes**: After modifying config, test with a simple command:
   ```shell
   node --version
   ```

5. **Check Logs**: When troubleshooting, check log files:
   ```shell
   ls -la ~/.my-ez-cli/logs/
   ```

## Related Documentation

- [Log Format Specification](./LOG_FORMAT.md) - Detailed log format documentation
- [AI Integration Guide](./AI_INTEGRATION.md) - AI features documentation (coming soon)
- [README](../README.md) - Main project documentation

## Docker Container Management

All My Ez CLI containers use consistent naming and labeling for easy management.

**Naming pattern:** `mec-{tool}-{timestamp}` (e.g., `mec-node-1700000000`)

**Labels applied to every container:**
- `com.my-ez-cli.project=my-ez-cli` — project identifier
- `com.my-ez-cli.tool={tool}` — tool name
- `com.my-ez-cli.image={image}` — source Docker image

**Useful commands:**
```shell
# List all My Ez CLI containers
docker ps -a --filter "name=mec-"

# List by label
docker ps -a --filter "label=com.my-ez-cli.project=my-ez-cli"

# Remove stopped My Ez CLI containers
docker container prune --filter "label=com.my-ez-cli.project=my-ez-cli"

# List all My Ez CLI images
docker images --filter "label=com.my-ez-cli.project=my-ez-cli"
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/DavidCardoso/my-ez-cli/issues
- Documentation: https://github.com/DavidCardoso/my-ez-cli

---

Last updated: 2026-03-26
Version: 1.0.0-rc
