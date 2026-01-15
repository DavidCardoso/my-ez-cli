# My Ez CLI - Main CLI

Main command-line interface for My Ez CLI (`mec` command).

## Overview

This component provides the `mec` command for managing My Ez CLI:

```bash
mec help                    # Show help
mec config get logs.enabled # Get configuration value
mec config set logs.enabled true # Set configuration value
mec status                  # Show installation status
mec logs node --last 10     # View logs
mec doctor                  # Run health checks
mec update                  # Update My Ez CLI
```

## Technology Stack

- **Language**: TypeScript
- **Runtime**: Node.js 18+
- **CLI Framework**: Commander.js
- **Configuration**: YAML (via js-yaml)

## Development Status

⏳ **Pending** - Will be implemented in Phase 2

## Planned Features (Phase 2)

- Git-style configuration system (`mec config`)
- Health check command (`mec doctor`)
- Update mechanism (`mec update`)
- Help system (`mec help`)
- Log management (`mec logs`)
- Status command (`mec status`)

## Future Structure

```
cli/
├── src/
│   ├── index.ts          # Main entry point
│   ├── commands/
│   │   ├── config.ts     # Config commands
│   │   ├── doctor.ts     # Health checks
│   │   ├── help.ts       # Help system
│   │   ├── logs.ts       # Log management
│   │   ├── status.ts     # Status display
│   │   └── update.ts     # Update mechanism
│   ├── lib/
│   │   ├── config.ts     # Configuration manager
│   │   └── docker.ts     # Docker utilities
│   └── utils/
│       └── formatting.ts # Output formatting
├── package.json
├── tsconfig.json
└── README.md             # This file
```

## Installation (Future)

```bash
npm install -g @my-ez-cli/core
mec help
```
