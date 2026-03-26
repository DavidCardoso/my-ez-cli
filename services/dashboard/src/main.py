"""FastAPI application entry point for the mec-dashboard service."""

from __future__ import annotations

import asyncio
import logging
import os
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager, suppress
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from src.api.sessions import router as sessions_router
from src.api.stats import router as stats_router
from src.api.ws import router as ws_router
from src.watcher import watch_data_dir

logging.basicConfig(level=logging.WARNING, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

DATA_ROOT_ENV = "MEC_DATA_ROOT"
DEFAULT_DATA_ROOT = Path.home() / ".my-ez-cli"
STATIC_DIR = Path(__file__).parent / "static"


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Start the filesystem watcher on startup; cancel on shutdown."""
    data_root: Path = app.state.data_root
    data_root.mkdir(parents=True, exist_ok=True)
    task = asyncio.create_task(watch_data_dir(data_root))
    logger.debug("Dashboard started, watching %s", data_root)
    yield
    task.cancel()
    with suppress(asyncio.CancelledError):
        await task


def create_app(data_root: Path | None = None) -> FastAPI:
    """Create and configure the FastAPI application."""
    if data_root is None:
        data_root = Path(os.environ.get(DATA_ROOT_ENV, str(DEFAULT_DATA_ROOT)))

    app = FastAPI(
        title="mec-dashboard",
        description="My Ez CLI — log and AI analysis viewer",
        version="1.0.0-rc",
        lifespan=lifespan,
    )
    app.state.data_root = data_root

    app.include_router(sessions_router)
    app.include_router(ws_router)
    app.include_router(stats_router)
    assets_dir = STATIC_DIR / "assets"
    if assets_dir.exists():
        app.mount("/assets", StaticFiles(directory=str(assets_dir)), name="assets")

    @app.get("/{full_path:path}")
    async def spa_fallback(full_path: str) -> FileResponse:
        """Serve index.html for all non-API, non-assets paths (Vue Router SPA)."""
        if full_path.startswith(("api/", "assets/")):
            raise HTTPException(status_code=404)
        return FileResponse(str(STATIC_DIR / "index.html"))

    return app


app = create_app()
