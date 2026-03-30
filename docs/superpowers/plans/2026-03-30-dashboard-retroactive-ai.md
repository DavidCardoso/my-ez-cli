# Dashboard Retroactive AI Analysis Trigger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Run AI Analysis" button to the session detail page that triggers on-demand Claude analysis for sessions that have no AI result (`ai_status == "none"`).

**Architecture:** A new `POST /api/sessions/{session_id}/analyze` FastAPI endpoint reads the log file for the session, spawns `analyze_with_claude` via a subprocess shell call (reusing the exact same Docker pipeline already used by `exec_with_ai`), and immediately returns `202 Accepted`. The sidecar file is written asynchronously; the existing filesystem watcher detects the change and broadcasts a `refresh` event to all connected WebSocket clients, causing the Vue page to re-fetch and display the result automatically — no polling required.

**Tech Stack:** Python 3.12 + FastAPI (backend), Vue 3 + PrimeVue (frontend), existing `analyze_with_claude` shell function in `bin/utils/common.sh`, existing WebSocket + watchfiles broadcast pipeline.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `services/dashboard/src/api/sessions.py` | Modify | Add `POST /{session_id}/analyze` endpoint |
| `services/dashboard/src/sessions.py` | Modify | Add `trigger_analysis(data_root, session_id)` helper |
| `services/dashboard/frontend/src/pages/SessionDetailPage.vue` | Modify | Add "Run AI Analysis" button + loading state |
| `services/dashboard/tests/test_sessions.py` | Modify | Add tests for `trigger_analysis()` |
| `services/dashboard/tests/test_api_analyze.py` | Create | API-level tests for the new endpoint |

---

## Task 1: Add `trigger_analysis()` to `sessions.py`

**Files:**
- Modify: `services/dashboard/src/sessions.py`
- Test: `services/dashboard/tests/test_sessions.py`

The function finds the log file for a given session ID, then invokes `analyze_with_claude` via a subprocess shell that sources `common.sh`. It returns `True` if the subprocess was launched (fire-and-forget), `False` if the session was not found or the log file doesn't exist.

- [ ] **Step 1: Write the failing tests**

Add to `services/dashboard/tests/test_sessions.py`:

```python
import subprocess
from unittest.mock import MagicMock, patch

from src.sessions import trigger_analysis


class TestTriggerAnalysis:
    """Tests for trigger_analysis()."""

    def test_returns_false_when_session_not_found(self, data_root: Path) -> None:
        result = trigger_analysis(data_root, "mec-npm-nonexistent")
        assert result is False

    def test_returns_true_and_launches_subprocess_when_session_exists(
        self, data_root: Path
    ) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        with patch("src.sessions.subprocess.Popen") as mock_popen:
            mock_popen.return_value = MagicMock()
            result = trigger_analysis(data_root, "mec-npm-1")
        assert result is True
        mock_popen.assert_called_once()

    def test_subprocess_receives_log_file_path(self, data_root: Path) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        with patch("src.sessions.subprocess.Popen") as mock_popen:
            mock_popen.return_value = MagicMock()
            trigger_analysis(data_root, "mec-npm-1")
        call_args = mock_popen.call_args
        cmd = call_args[0][0]  # first positional arg is the command list/string
        assert "mec-npm-1" in cmd or str(data_root / "logs" / "npm" / "2026-03-25_12-00-00.json") in cmd

    def test_returns_false_when_log_file_missing(self, data_root: Path) -> None:
        # Write a log entry then delete the file
        log_path = _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        log_path.unlink()
        result = trigger_analysis(data_root, "mec-npm-1")
        assert result is False
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd services/dashboard
docker run --rm \
  --volume "$PWD:/app" \
  --workdir /app \
  python:3.12-slim \
  sh -c "pip install -q poetry && poetry install --no-interaction -q && poetry run pytest tests/test_sessions.py::TestTriggerAnalysis -v"
```

Expected: `ImportError: cannot import name 'trigger_analysis'`

- [ ] **Step 3: Implement `trigger_analysis()` in `sessions.py`**

Add the following **import** at the top of `services/dashboard/src/sessions.py` (after existing imports):

```python
import subprocess
```

Add the following **function** at the end of `services/dashboard/src/sessions.py`:

```python
def trigger_analysis(data_root: Path, session_id: str) -> bool:
    """Launch a background AI analysis for the given session.

    Finds the log file for session_id, then fires analyze_with_claude via
    a subprocess shell. Returns True if the subprocess was launched, False
    if the session was not found or its log file is missing.

    Args:
        data_root: Path to the mec data directory (e.g. ~/.my-ez-cli).
        session_id: The mec session ID to analyze.

    Returns:
        True if analysis was triggered, False if session not found.
    """
    log_path: Path | None = None
    for candidate in _log_files(data_root):
        data = _read_json(candidate)
        if str(data.get("session_id", "")) == session_id:
            log_path = candidate
            break

    if log_path is None or not log_path.exists():
        return False

    # Resolve common.sh relative to this file's location in the repo.
    # Inside the Docker container the repo is mounted at /app.
    common_sh = Path(__file__).parent.parent.parent.parent / "bin" / "utils" / "common.sh"

    script = (
        f'source "{common_sh}" 2>/dev/null && '
        f'MEC_AI_ENABLED=true analyze_with_claude "{log_path}"'
    )
    subprocess.Popen(
        ["bash", "-c", script],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    return True
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd services/dashboard
docker run --rm \
  --volume "$PWD:/app" \
  --workdir /app \
  python:3.12-slim \
  sh -c "pip install -q poetry && poetry install --no-interaction -q && poetry run pytest tests/test_sessions.py::TestTriggerAnalysis -v"
```

Expected: 4 tests PASS

- [ ] **Step 5: Commit**

```bash
git add services/dashboard/src/sessions.py services/dashboard/tests/test_sessions.py
git commit -m "feat: add trigger_analysis() helper to sessions module (#77)"
```

---

## Task 2: Add `POST /api/sessions/{session_id}/analyze` endpoint

**Files:**
- Modify: `services/dashboard/src/api/sessions.py`
- Create: `services/dashboard/tests/test_api_analyze.py`

The endpoint returns `202 Accepted` immediately when analysis is triggered, `404` if session not found, and `409 Conflict` if the session already has AI analysis (to prevent duplicate runs).

- [ ] **Step 1: Write the failing API tests**

Create `services/dashboard/tests/test_api_analyze.py`:

```python
"""Tests for POST /api/sessions/{session_id}/analyze endpoint."""

from __future__ import annotations

import json
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from src.main import create_app
from tests.test_sessions import _write_log, _write_sidecar


@pytest.fixture()
def data_root(tmp_path: Path) -> Path:
    (tmp_path / "logs").mkdir()
    (tmp_path / "ai-analyses").mkdir()
    return tmp_path


@pytest.fixture()
def client(data_root: Path) -> TestClient:
    app = create_app(data_root=data_root)
    return TestClient(app)


class TestAnalyzeEndpoint:
    """Tests for POST /api/sessions/{session_id}/analyze."""

    def test_returns_404_when_session_not_found(self, client: TestClient) -> None:
        res = client.post("/api/sessions/mec-npm-nonexistent/analyze")
        assert res.status_code == 404

    def test_returns_202_when_analysis_triggered(
        self, client: TestClient, data_root: Path
    ) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        with patch("src.api.sessions.trigger_analysis", return_value=True):
            res = client.post("/api/sessions/mec-npm-1/analyze")
        assert res.status_code == 202
        assert res.json() == {"status": "triggered", "session_id": "mec-npm-1"}

    def test_returns_409_when_ai_already_done(
        self, client: TestClient, data_root: Path
    ) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        _write_sidecar(data_root, "npm", "2026-03-25_12-00-00", result="Already analyzed.")
        with patch("src.api.sessions.trigger_analysis", return_value=True):
            res = client.post("/api/sessions/mec-npm-1/analyze")
        assert res.status_code == 409
        assert "already" in res.json()["detail"].lower()

    def test_returns_409_when_ai_pending(
        self, client: TestClient, data_root: Path
    ) -> None:
        _write_log(data_root, "npm", "2026-03-25_12-00-00", "mec-npm-1")
        _write_sidecar(data_root, "npm", "2026-03-25_12-00-00", result="")
        with patch("src.api.sessions.trigger_analysis", return_value=True):
            res = client.post("/api/sessions/mec-npm-1/analyze")
        assert res.status_code == 409
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd services/dashboard
docker run --rm \
  --volume "$PWD:/app" \
  --workdir /app \
  python:3.12-slim \
  sh -c "pip install -q poetry && poetry install --no-interaction -q && poetry run pytest tests/test_api_analyze.py -v"
```

Expected: `ImportError` or `404` route not found errors.

- [ ] **Step 3: Add the endpoint to `sessions.py` API router**

Add to the **imports** at the top of `services/dashboard/src/api/sessions.py`:

```python
from src.sessions import get_session, list_sessions, trigger_analysis
```

Add the following endpoint **after** the existing `session_detail` route in `services/dashboard/src/api/sessions.py`:

```python
@router.post("/{session_id}/analyze", status_code=202)
def session_analyze(session_id: str, request: Request) -> dict[str, str]:
    """Trigger a retroactive AI analysis for a session with no existing analysis.

    Returns 202 Accepted immediately; analysis runs in background.
    Returns 404 if session not found.
    Returns 409 Conflict if analysis is already done or pending.
    """
    data_root = _data_root(request)
    detail = get_session(data_root, session_id)
    if detail is None:
        raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")
    if detail.ai_status in ("done", "pending"):
        raise HTTPException(
            status_code=409,
            detail=f"AI analysis already {detail.ai_status} for session: {session_id}",
        )
    triggered = trigger_analysis(data_root, session_id)
    if not triggered:
        raise HTTPException(status_code=404, detail=f"Log file not found for session: {session_id}")
    return {"status": "triggered", "session_id": session_id}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd services/dashboard
docker run --rm \
  --volume "$PWD:/app" \
  --workdir /app \
  python:3.12-slim \
  sh -c "pip install -q poetry && poetry install --no-interaction -q && poetry run pytest tests/test_api_analyze.py -v"
```

Expected: 4 tests PASS

- [ ] **Step 5: Run full test suite to confirm no regressions**

```bash
cd services/dashboard
docker run --rm \
  --volume "$PWD:/app" \
  --workdir /app \
  python:3.12-slim \
  sh -c "pip install -q poetry && poetry install --no-interaction -q && poetry run pytest -v"
```

Expected: all existing tests still PASS

- [ ] **Step 6: Commit**

```bash
git add services/dashboard/src/api/sessions.py services/dashboard/tests/test_api_analyze.py
git commit -m "feat: add POST /api/sessions/{id}/analyze endpoint (#77)"
```

---

## Task 3: Add "Run AI Analysis" button to `SessionDetailPage.vue`

**Files:**
- Modify: `services/dashboard/frontend/src/pages/SessionDetailPage.vue`

The button appears in the `meta-bar` only when `session.ai_status === 'none'`. Clicking it calls `POST /api/sessions/{id}/analyze`, sets a local `analyzing` ref to `true`, and disables the button while awaiting the response. On `202`, the status tag updates optimistically to `pending` and the existing WebSocket refresh handles the final update. On error, a brief error message is shown.

- [ ] **Step 1: Add `analyzing`, `analyzeError`, and `runAnalysis()` to the script block**

In `services/dashboard/frontend/src/pages/SessionDetailPage.vue`, replace the `<script setup>` block with:

```vue
<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import Tag from 'primevue/tag'
import Button from 'primevue/button'
import LogOutput from '../components/LogOutput.vue'
import AiOutput from '../components/AiOutput.vue'
import { useWebSocket } from '../composables/useWebSocket.js'

const route = useRoute()
const sessionId = route.params.sessionId
const session = ref(null)
const notFound = ref(false)
const copiedId = ref(false)
const copiedResume = ref(false)
const analyzing = ref(false)
const analyzeError = ref('')
const { onRefresh } = useWebSocket()

async function fetchSession() {
  try {
    const res = await fetch(`/api/sessions/${sessionId}`)
    if (res.status === 404) {
      notFound.value = true
      return
    }
    if (res.ok) {
      session.value = await res.json()
      document.title = `mec — ${sessionId}`
    }
  } catch {
    // silently fail
  }
}

async function runAnalysis() {
  analyzing.value = true
  analyzeError.value = ''
  try {
    const res = await fetch(`/api/sessions/${sessionId}/analyze`, { method: 'POST' })
    if (res.ok) {
      // Optimistically update status to 'pending' — WS will deliver final result
      if (session.value) session.value.ai_status = 'pending'
    } else {
      const body = await res.json().catch(() => ({}))
      analyzeError.value = body.detail || `Error ${res.status}`
    }
  } catch {
    analyzeError.value = 'Request failed'
  } finally {
    analyzing.value = false
  }
}

onMounted(() => {
  fetchSession()
  const cleanup = onRefresh(fetchSession)
  onUnmounted(cleanup)
})

function fmtTs(ts) {
  if (!ts) return '—'
  return ts.replace('T', ' ').replace(/\.\d+Z?$/, '').replace('Z', '')
}

function aiSeverity(status) {
  if (status === 'done') return 'success'
  if (status === 'pending') return 'warn'
  return 'secondary'
}

async function copyId() {
  try {
    await navigator.clipboard.writeText(sessionId)
    copiedId.value = true
    setTimeout(() => { copiedId.value = false }, 2000)
  } catch { /* noop */ }
}

async function copyResume() {
  try {
    await navigator.clipboard.writeText(`claude --resume ${session.value?.claude_session_id}`)
    copiedResume.value = true
    setTimeout(() => { copiedResume.value = false }, 2000)
  } catch { /* noop */ }
}
</script>
```

- [ ] **Step 2: Add the "Run AI Analysis" button and error message to the template**

In `services/dashboard/frontend/src/pages/SessionDetailPage.vue`, replace the `AI Status` meta-item block:

```vue
        <div class="meta-item">
          <span class="meta-label">AI Status</span>
          <Tag :value="session.ai_status" :severity="aiSeverity(session.ai_status)" />
        </div>
```

with:

```vue
        <div class="meta-item">
          <span class="meta-label">AI Status</span>
          <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
            <Tag :value="analyzing ? 'triggering…' : session.ai_status" :severity="aiSeverity(session.ai_status)" />
            <Button
              v-if="session.ai_status === 'none'"
              label="Run AI Analysis"
              icon="pi pi-play"
              size="small"
              :loading="analyzing"
              :disabled="analyzing"
              style="font-size: 11px; padding: 4px 10px;"
              @click="runAnalysis"
            />
            <span v-if="analyzeError" style="font-size: 11px; color: var(--mec-red);">{{ analyzeError }}</span>
          </div>
        </div>
```

- [ ] **Step 3: Build the frontend to verify no compile errors**

```bash
cd services/dashboard/frontend
npm run build
```

Expected: build succeeds with no errors.

- [ ] **Step 4: Commit**

```bash
git add services/dashboard/frontend/src/pages/SessionDetailPage.vue
git commit -m "feat: add Run AI Analysis button to session detail page (#77)"
```

---

## Task 4: Smoke test end-to-end and create PR

- [ ] **Step 1: Run full backend test suite one final time**

```bash
cd services/dashboard
docker run --rm \
  --volume "$PWD:/app" \
  --workdir /app \
  python:3.12-slim \
  sh -c "pip install -q poetry && poetry install --no-interaction -q && poetry run pytest -v --tb=short"
```

Expected: all tests PASS, including the new `TestTriggerAnalysis` and `TestAnalyzeEndpoint` classes.

- [ ] **Step 2: Verify frontend build is clean**

```bash
cd services/dashboard/frontend && npm run build 2>&1 | tail -5
```

Expected: `built in X.Xs` with no errors or warnings.

- [ ] **Step 3: Create branch and push**

```bash
git checkout -b feat/77/dashboard-retroactive-ai
git push origin feat/77/dashboard-retroactive-ai
```

- [ ] **Step 4: Open PR**

```bash
gh pr create \
  --title "feat: dashboard retroactive AI analysis trigger (#77)" \
  --body "$(cat <<'EOF'
## Summary

- Adds `POST /api/sessions/{session_id}/analyze` endpoint (202 Accepted, 404 if not found, 409 if already done/pending)
- Adds `trigger_analysis()` helper in `sessions.py` that fires `analyze_with_claude` via subprocess (fire-and-forget)
- Adds "Run AI Analysis" button to session detail page — only visible when `ai_status === 'none'`
- Existing WebSocket → watchfiles pipeline delivers the result automatically; no polling

## Test plan

- [ ] Backend unit tests: `pytest tests/test_sessions.py::TestTriggerAnalysis`
- [ ] API tests: `pytest tests/test_api_analyze.py`
- [ ] Manual: open a session with `ai_status: none`, click button, status tag changes to `pending`, AI panel updates when analysis completes
- [ ] Manual: verify button is hidden for sessions with `ai_status: done` or `pending`

Closes #77
EOF
)" \
  --label "enhancement" \
  --milestone "v1.0.0"
```

- [ ] **Step 5: Add PR to GH project**

```bash
PR_ID=$(gh pr view --json id -q '.id')
gh api graphql -f query="mutation { addProjectV2ItemById(input: { projectId: \"PVT_kwHOANNfSs4BTAfg\", contentId: \"$PR_ID\" }) { item { id } } }"
```

---

## Self-Review Checklist

**Spec coverage:**
- ✅ `POST /api/sessions/{id}/analyze` endpoint → Task 2
- ✅ Button only shown when `ai_status === 'none'` → Task 3 Step 2
- ✅ 404 when session not found → Task 2 test + endpoint
- ✅ 409 when already done or pending → Task 2 test + endpoint
- ✅ Fire-and-forget (202 Accepted) → Task 1 + 2
- ✅ WebSocket auto-refresh delivers result → existing pipeline, no new code needed
- ✅ Optimistic `pending` state while waiting → Task 3 Step 1 `runAnalysis()`
- ✅ Error feedback in UI → Task 3 Step 2 `analyzeError`
- ✅ Tests for all backend paths → Tasks 1 + 2

**No placeholders:** All code blocks are complete and self-contained.

**Type consistency:** `trigger_analysis(data_root: Path, session_id: str) -> bool` is consistent across `sessions.py` definition and `api/sessions.py` import.
