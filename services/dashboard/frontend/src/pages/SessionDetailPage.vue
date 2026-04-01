<template>
  <div class="detail-page">
    <!-- Header -->
    <div class="detail-header">
      <div class="detail-header-inner">
        <RouterLink to="/sessions" class="back-link">
          <i class="pi pi-arrow-left"></i> Sessions
        </RouterLink>
        <div v-if="session" class="detail-title">
          <span class="detail-tool">{{ session.tool }}</span>
          <span class="detail-sep">/</span>
          <span class="detail-session-id mono">{{ session.session_id }}</span>
        </div>
        <div v-else-if="notFound" class="detail-title">Session not found</div>
        <div v-else class="detail-title text-faint">Loading…</div>
      </div>
    </div>

    <div v-if="session" class="detail-body">
      <!-- Meta bar -->
      <div class="meta-bar">
        <div class="meta-item">
          <span class="meta-label">Tool</span>
          <Tag :value="session.tool" class="tool-tag" />
        </div>
        <div class="meta-item">
          <span class="meta-label">Timestamp</span>
          <span class="meta-value mono">{{ fmtTs(session.timestamp) }}</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Exit Code</span>
          <Tag
            v-if="session.exit_code !== null && session.exit_code !== undefined"
            :value="String(session.exit_code)"
            :severity="session.exit_code === 0 ? 'success' : 'danger'"
          />
          <span v-else class="meta-value text-faint">—</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">AI Status</span>
          <Tag :value="session.ai_status" :severity="aiSeverity(session.ai_status)" />
        </div>
        <div v-if="session.ai_execution_time_ms != null" class="meta-item">
          <span class="meta-label">AI Time</span>
          <span class="meta-value mono">{{ (session.ai_execution_time_ms / 1000).toFixed(1) }}s</span>
        </div>
        <div v-if="session.ai_tokens_input != null || session.ai_tokens_output != null" class="meta-item">
          <span class="meta-label">Tokens</span>
          <span class="meta-value mono">in={{ session.ai_tokens_input ?? '—' }} • out={{ session.ai_tokens_output ?? '—' }}</span>
        </div>
        <div v-if="session.ai_status === 'none'" class="meta-item meta-item--wide">
          <span class="meta-label">Run AI Analysis</span>
          <div class="session-id-row">
            <span class="meta-value mono" style="font-size: 11px;">mec ai analyze {{ session.session_id }}</span>
            <Button
              icon="pi pi-copy"
              text
              rounded
              size="small"
              style="color: var(--mec-text-faint); width: 24px; height: 24px;"
              v-tooltip="copiedAnalyze ? 'Copied!' : 'Copy command'"
              @click="copyAnalyze"
            />
          </div>
        </div>
        <div class="meta-item meta-item--id">
          <span class="meta-label">Session ID</span>
          <div class="session-id-row">
            <span class="meta-value mono" style="font-size: 12px;">{{ session.session_id }}</span>
            <Button
              icon="pi pi-copy"
              text
              rounded
              size="small"
              style="color: var(--mec-text-faint); width: 24px; height: 24px;"
              v-tooltip="copiedId ? 'Copied!' : 'Copy ID'"
              @click="copyId"
            />
          </div>
        </div>
        <div v-if="session.cwd" class="meta-item meta-item--wide">
          <span class="meta-label">Working Dir</span>
          <span class="meta-value mono" style="font-size: 11px; color: var(--mec-text-dim);">{{ session.cwd }}</span>
        </div>
        <div v-if="session.claude_session_id" class="meta-item meta-item--wide">
          <span class="meta-label">Resume AI</span>
          <div class="session-id-row">
            <span class="meta-value mono" style="font-size: 11px;">claude --resume {{ session.claude_session_id }}</span>
            <Button
              icon="pi pi-copy"
              text
              rounded
              size="small"
              style="color: var(--mec-text-faint); width: 24px; height: 24px;"
              v-tooltip="copiedResume ? 'Copied!' : 'Copy command'"
              @click="copyResume"
            />
          </div>
        </div>
      </div>

      <!-- Command bar -->
      <div v-if="session.command" class="command-bar">
        <span class="command-prompt">$</span>
        <span class="command-text">{{ session.command }}</span>
      </div>

      <!-- Two-panel layout -->
      <div class="panels">
        <div class="panel">
          <LogOutput :stdout="session.stdout" :stderr="session.stderr" />
        </div>
        <div class="panel">
          <AiOutput :content="session.ai_result" :status="session.ai_status" />
        </div>
      </div>
    </div>

    <div v-else-if="notFound" class="not-found">
      <i class="pi pi-exclamation-triangle" style="font-size: 28px; color: var(--mec-yellow);"></i>
      <div style="color: var(--mec-text-dim); margin-top: 12px;">Session <span class="mono">{{ sessionId }}</span> not found.</div>
      <RouterLink to="/sessions" class="back-link" style="margin-top: 16px;">← Back to sessions</RouterLink>
    </div>
  </div>
</template>

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
const copiedAnalyze = ref(false)
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

async function copyAnalyze() {
  try {
    await navigator.clipboard.writeText(`mec ai analyze ${session.value?.session_id}`)
    copiedAnalyze.value = true
    setTimeout(() => { copiedAnalyze.value = false }, 2000)
  } catch { /* noop */ }
}
</script>

<style scoped>
.detail-page {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.detail-header {
  border-bottom: 1px solid var(--mec-border-subtle);
  padding: 16px 32px;
}

.detail-header-inner {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  gap: 16px;
}

.back-link {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--mec-text-dim);
  text-decoration: none;
  font-size: 13px;
  transition: color 0.12s;
  flex-shrink: 0;
}

.back-link:hover {
  color: var(--mec-accent-bright);
}

.detail-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 500;
  overflow: hidden;
}

.detail-tool {
  color: var(--mec-accent-bright);
  font-family: var(--font-mono);
}

.detail-sep {
  color: var(--mec-text-faint);
}

.detail-session-id {
  color: var(--mec-text-dim);
  font-size: 12px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.detail-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 20px 32px 24px;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
  min-height: 0;
}

/* Meta bar */
.meta-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 0;
  background: var(--mec-surface-1);
  border: 1px solid var(--mec-border);
  border-radius: 10px;
  padding: 14px 20px;
  margin-bottom: 14px;
  align-items: flex-start;
  row-gap: 12px;
  column-gap: 28px;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.meta-item--wide {
  flex: 1;
  min-width: 200px;
}

.meta-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  color: var(--mec-text-faint);
}

.meta-value {
  font-size: 13px;
  color: var(--mec-text);
}

.session-id-row {
  display: flex;
  align-items: center;
  gap: 4px;
}

.tool-tag {
  background: var(--mec-surface-3) !important;
  color: var(--mec-accent-bright) !important;
  border: 1px solid var(--mec-accent-dim) !important;
}

/* Command bar */
.command-bar {
  background: var(--mec-surface-2);
  border: 1px solid var(--mec-border);
  border-radius: 8px;
  padding: 10px 14px;
  margin-bottom: 14px;
  display: flex;
  align-items: center;
  gap: 10px;
  font-family: var(--font-mono);
  font-size: 12px;
}

.command-prompt {
  color: var(--mec-accent);
  flex-shrink: 0;
}

.command-text {
  color: var(--mec-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Two-panel layout */
.panels {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  flex: 1;
  min-height: 400px;
}

.panel {
  background: var(--mec-surface-1);
  border: 1px solid var(--mec-border);
  border-radius: 10px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 400px;
  max-height: calc(100vh - 300px);
}

/* Not found */
.not-found {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px;
  text-align: center;
}

@media (max-width: 900px) {
  .panels { grid-template-columns: 1fr; }
  .detail-body { padding: 16px; }
  .detail-header { padding: 12px 16px; }
}
</style>
