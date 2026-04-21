"""Filesystem watcher — broadcasts events to connected WebSocket clients."""

from __future__ import annotations

import asyncio
import logging
from pathlib import Path

from watchfiles import awatch

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages active WebSocket connections."""

    def __init__(self) -> None:
        self._connections: list[asyncio.Queue[str]] = []

    def connect(self) -> asyncio.Queue[str]:
        """Register a new client; return its message queue."""
        q: asyncio.Queue[str] = asyncio.Queue()
        self._connections.append(q)
        logger.debug("WS client connected (%d total)", len(self._connections))
        return q

    def disconnect(self, q: asyncio.Queue[str]) -> None:
        """Unregister a client."""
        self._connections.remove(q)
        logger.debug("WS client disconnected (%d total)", len(self._connections))

    async def broadcast(self, message: str) -> None:
        """Send a message to all connected clients."""
        for q in list(self._connections):
            await q.put(message)


manager = ConnectionManager()


async def watch_data_dir(data_root: Path) -> None:
    """Watch ~/.my-ez-cli for new/changed files and broadcast to WebSocket clients."""
    logger.debug("Watching %s for changes", data_root)
    try:
        async for changes in awatch(data_root):
            for _change_type, path in changes:
                if path.endswith(".json") and not path.endswith(".bak"):
                    await manager.broadcast("refresh")
                    break  # one broadcast per batch
    except Exception as exc:
        logger.error("Watcher error: %s", exc)
