---
name: Tools page multi-category support
description: TOOL_REGISTRY tools should support multiple categories; deferred to a future PR after Phase 3.3
type: project
---

Tools like `promptfoo` (ai + testing) and `serverless` (cloud + infra) belong to multiple categories, but the current `TOOL_REGISTRY` in `sessions.py` uses a single `category` string per tool. The Tools page is read-only and displays a single Category tag per row.

**Why:** User flagged this during Phase 3.3 testing; deferred to keep the PR focused.
**How to apply:** When addressing this, change `category: str` to `categories: list[str]` in `TOOL_REGISTRY`, update `get_tools()` return type, and update `ToolsPage.vue` to render multiple `Tag` components per row. Also update `test_stats.py` assertions.
