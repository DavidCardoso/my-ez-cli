<template>
  <UiDataTable
    :rows="sessions"
    :columns="columns"
    row-key="session_id"
    :loading="loading"
    :rows-per-page="rows"
    :rows-per-page-options="[20, 50, 100]"
    paginator
    clickable
    sort-field="timestamp"
    :sort-order="-1"
    class="mec-table"
    @row-click="(row) => emit('row-click', row.session_id)"
  >
    <template #empty>
      <div class="table-empty">
        <Inbox class="table-empty-icon" aria-hidden="true" />
        <div style="color: var(--mec-text-dim); font-size: 13px;">No sessions found.</div>
        <div style="color: var(--mec-text-faint); font-size: 12px; margin-top: 4px;">
          Run a tool with <code class="inline-code">MEC_TELEMETRY_ENABLED=true</code>
        </div>
      </div>
    </template>
    <template #loading>
      <div class="table-loading">Loading sessions…</div>
    </template>

    <template #cell-timestamp="{ row }">
      <span class="mono" style="font-size: 12px; color: var(--mec-text-dim);">{{ fmtTs(row.timestamp) }}</span>
    </template>

    <template #cell-tool="{ row }">
      <UiTag :value="row.tool || '—'" class="tool-tag" />
    </template>

    <template #cell-exit_code="{ row }">
      <UiTag
        v-if="row.exit_code !== null && row.exit_code !== undefined"
        :value="String(row.exit_code)"
        :severity="row.exit_code === 0 ? 'success' : 'danger'"
        class="exit-tag"
      />
      <span v-else class="text-faint mono" style="font-size: 11px;">—</span>
    </template>

    <template #cell-log_status="{ row }">
      <UiTag :value="row.log_status" :severity="logSeverity(row.log_status)" class="log-tag" />
    </template>

    <template #cell-ai_status="{ row }">
      <UiTag :value="row.ai_status" :severity="aiSeverity(row.ai_status)" class="ai-tag" />
    </template>

    <template #cell-ai_execution_time_ms="{ row }">
      <span class="mono col-ai-time">
        {{ row.ai_execution_time_ms != null
           ? (row.ai_execution_time_ms / 1000).toFixed(1) + 's'
           : '—' }}
      </span>
    </template>

    <template #cell-session_id="{ row }">
      <span class="mono session-id">{{ row.session_id }}</span>
    </template>
  </UiDataTable>
</template>

<script setup>
import { Inbox } from 'lucide-vue-next'
import UiDataTable from './ui/UiDataTable.vue'
import UiTag from './ui/UiTag.vue'

const columns = [
  { field: 'timestamp', header: 'Timestamp (UTC)', sortable: true },
  { field: 'tool', header: 'Tool', sortable: true },
  { field: 'exit_code', header: 'Exit', sortable: true },
  { field: 'log_status', header: 'Logs', sortable: true },
  { field: 'ai_status', header: 'AI', sortable: true },
  { field: 'ai_execution_time_ms', header: 'AI Time', sortable: true },
  { field: 'session_id', header: 'Session ID' },
]

defineProps({
  sessions: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
  rows: { type: Number, default: 20 },
})

const emit = defineEmits(['row-click'])

function fmtTs(ts) {
  if (!ts) return '—'
  return ts.replace('T', ' ').replace(/\.\d+Z?$/, '').replace(/Z$/, '') + ' UTC'
}

function aiSeverity(status) {
  if (status === 'done') return 'success'
  if (status === 'pending') return 'warn'
  return 'secondary'
}

function logSeverity(status) {
  return status === 'captured' ? 'success' : 'secondary'
}
</script>

<style scoped>
.mec-table {
  width: 100%;
}

.table-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 48px 20px;
}

.table-loading {
  text-align: center;
  padding: 32px;
  color: var(--mec-text-dim);
  font-size: 13px;
}

.table-empty-icon {
  width: 28px;
  height: 28px;
  color: var(--mec-text-faint);
  margin-bottom: 10px;
}

.ui-tag.tool-tag {
  background: var(--mec-surface-3);
  color: var(--mec-accent-bright);
  border: 1px solid var(--mec-accent-dim);
}

.exit-tag {
  min-width: 32px;
  justify-content: center;
}

.ai-tag {
  min-width: 56px;
  justify-content: center;
}

.log-tag {
  min-width: 64px;
  justify-content: center;
}

.session-id {
  font-size: 11px;
  color: var(--mec-text-dim);
  letter-spacing: 0.02em;
}

.inline-code {
  font-family: var(--font-mono);
  font-size: 11px;
  background: var(--mec-surface-3);
  border: 1px solid var(--mec-border);
  border-radius: 3px;
  padding: 1px 5px;
  color: var(--mec-accent-bright);
}

.col-ai-time {
  text-align: right;
  font-family: var(--font-mono);
  font-size: 12px;
  white-space: nowrap;
  color: var(--mec-text-dim);
}
</style>
