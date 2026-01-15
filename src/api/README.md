# My Ez CLI - Backend API

REST API for My Ez CLI web dashboard and future integrations.

## Overview

This component provides a backend API for:
- Container monitoring and metrics
- Log retrieval and analysis
- Configuration management
- Tool management
- AI integration endpoints

## Technology Stack

- **Language**: TypeScript/JavaScript
- **Framework**: Express or Fastify
- **Runtime**: Node.js 18+
- **Database**: File-based (JSON) initially, with pluggable storage

## Development Status

⏳ **Pending** - Will be implemented in Phase 4

## API Endpoints (Planned)

### Containers
- `GET /api/containers` - List running containers
- `GET /api/containers/:id` - Get container details
- `GET /api/containers/:id/logs` - Get container logs
- `GET /api/containers/:id/stats` - Get container stats

### Logs
- `GET /api/logs` - List available logs
- `GET /api/logs/:tool` - Get logs for a specific tool
- `GET /api/logs/:tool/:file` - Get specific log file
- `POST /api/logs/analyze` - Analyze logs with AI

### Configuration
- `GET /api/config` - Get all configuration
- `GET /api/config/:key` - Get specific config value
- `PUT /api/config/:key` - Set config value

### Tools
- `GET /api/tools` - List available tools
- `GET /api/tools/installed` - List installed tools
- `POST /api/tools/:name/install` - Install a tool
- `DELETE /api/tools/:name` - Uninstall a tool

### System
- `GET /api/system/status` - System health check
- `GET /api/system/version` - Get version info

## Future Structure

```
api/
├── src/
│   ├── index.ts          # Server entry point
│   ├── routes/
│   │   ├── containers.ts
│   │   ├── logs.ts
│   │   ├── config.ts
│   │   ├── tools.ts
│   │   └── system.ts
│   ├── services/
│   │   ├── docker.ts     # Docker integration
│   │   ├── logs.ts       # Log management
│   │   ├── config.ts     # Config management
│   │   └── metrics.ts    # Metrics collection
│   ├── middleware/
│   │   ├── auth.ts       # Authentication (future)
│   │   └── error.ts      # Error handling
│   └── utils/
│       └── validation.ts # Input validation
├── package.json
├── tsconfig.json
└── README.md             # This file
```

## Running (Future)

```bash
mec api start              # Start API server
mec api start --port 3000  # Custom port
mec api stop               # Stop server
```
