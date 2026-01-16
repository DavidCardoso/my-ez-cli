# My Ez CLI - Web Dashboard

Web-based dashboard for managing and monitoring My Ez CLI.

## Overview

This component provides a modern web interface for:
- Visual container monitoring with real-time metrics
- Advanced log viewer with search and filtering
- Tool management (install/uninstall)
- Configuration editor
- System health dashboard

## Technology Stack

- **Frontend Framework**: Vue.js 3
- **Build Tool**: Vite
- **UI Library**: TBD (Vuetify, Element Plus, or custom)
- **Charts**: Chart.js or ECharts
- **HTTP Client**: FetchAPI
- **State Management**: Pinia

## Development Status

⏳ **Pending** - Will be implemented in Phase 4

## Features (Planned)

### Dashboard
- System overview (Docker status, disk space, running containers)
- Quick stats (installed tools, recent activity)
- Recent logs preview
- System health indicators

### Container Monitor
- List of running containers
- Real-time CPU and memory usage graphs
- Container logs streaming
- Start/stop/restart controls

### Log Viewer
- Browse logs by tool
- Full-text search across all logs
- Syntax highlighting
- Download logs
- AI-powered analysis integration

### Tool Manager
- Grid view of all available tools
- One-click install/uninstall
- Version selection for multi-version tools
- Installation status indicators

### Configuration Editor
- Form-based configuration editing
- Real-time validation
- Import/export configuration
- Reset to defaults option

## Future Structure

```
web-ui/
├── src/
│   ├── main.ts                # App entry point
│   ├── App.vue                # Root component
│   ├── components/
│   │   ├── Dashboard.vue
│   │   ├── ContainerMonitor.vue
│   │   ├── LogViewer.vue
│   │   ├── ToolManager.vue
│   │   └── ConfigEditor.vue
│   ├── views/
│   │   ├── Home.vue
│   │   ├── Containers.vue
│   │   ├── Logs.vue
│   │   ├── Tools.vue
│   │   └── Settings.vue
│   ├── stores/
│   │   ├── containers.ts
│   │   ├── logs.ts
│   │   ├── tools.ts
│   │   └── config.ts
│   ├── api/
│   │   └── client.ts          # API client
│   ├── router/
│   │   └── index.ts           # Vue Router config
│   └── assets/
│       ├── styles/
│       └── images/
├── public/
│   └── index.html
├── package.json
├── vite.config.ts
├── tsconfig.json
└── README.md                  # This file
```

## Running (Future)

```bash
mec web-ui start               # Start web UI
mec web-ui start --port 8080   # Custom port
mec web-ui stop                # Stop server
mec web-ui build               # Build for production
```

## Access

Once running, access the dashboard at:
```
http://localhost:8080
```
