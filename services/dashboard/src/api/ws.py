"""WebSocket endpoint — pushes 'refresh' events to the browser."""

from __future__ import annotations

import asyncio
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from src.watcher import manager

logger = logging.getLogger(__name__)
router = APIRouter()


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket) -> None:
    """Accept a WebSocket connection and relay broadcast messages."""
    await websocket.accept()
    q = manager.connect()
    try:
        while True:
            try:
                message = await asyncio.wait_for(q.get(), timeout=30)
                await websocket.send_text(message)
            except TimeoutError:
                # Send a ping to keep the connection alive
                await websocket.send_text("ping")
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(q)
