# My Ez CLI - Source Code Organization

This directory contains the source code for advanced features implemented in higher-level languages (Node.js, Vue.js, Go, etc.).

## Directory Structure

```
src/
├── cli/          # Main CLI (mec command)
│   ├── src/      # TypeScript/JavaScript source
│   ├── package.json
│   └── README.md
├── api/          # Backend API (for Web UI and future services)
│   ├── src/      # Node.js/Express source
│   ├── package.json
│   └── README.md
├── web-ui/       # Web Dashboard
│   ├── src/      # Vue.js source
│   ├── package.json
│   └── README.md
└── README.md     # This file
```

## Principles

- **Separation of Concerns**: Each subdirectory is an independent project with its own dependencies
- **Bash stays in bin/**: All bash scripts remain in the `bin/` directory for consistency
- **Modular**: Each component can be developed, tested, and deployed independently
- **Tech Stack Flexibility**: Different technologies per component as needed

## Components

### cli/ (Phase 2)
Main CLI interface for My Ez CLI commands like:
- `mec help`
- `mec config`
- `mec status`
- `mec logs`
- `mec doctor`

**Technology**: Node.js + TypeScript

### api/ (Phase 4)
Backend API providing:
- Container monitoring endpoints
- Log retrieval and analysis
- Configuration management
- Metrics collection
- AI integration endpoints

**Technology**: Node.js + Express/Fastify

### web-ui/ (Phase 4)
Web-based dashboard providing:
- Visual container monitoring
- Log viewer with search/filter
- Tool management interface
- Configuration editor
- Real-time metrics

**Technology**: Vue.js + Vite

## Development Phases

- **Phase 1 (Current)**: Foundation - Bash scripts and utilities in `bin/`
- **Phase 2**: Distribution - NPM package, `mec` CLI (uses `cli/`)
- **Phase 3**: Enhanced Features - Log persistence, TUI dashboard
- **Phase 4**: Polish & Advanced - Web UI (uses `api/` and `web-ui/`)

## Notes

- This structure is prepared for future development
- Initial implementation remains in `bin/` (bash scripts)
- Components will be populated during their respective phases
