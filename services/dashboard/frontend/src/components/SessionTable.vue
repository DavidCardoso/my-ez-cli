<template>
  <DataTable
    :value="sessions"
    :loading="loading"
    :rows="rows"
    :rowsPerPageOptions="[20, 50, 100]"
    paginator
    paginatorTemplate="RowsPerPageDropdown FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink"
    sortField="timestamp"
    :sortOrder="-1"
    dataKey="session_id"
    :rowHover="true"
    class="mec-table"
    @row-click="(e) => emit('row-click', e.data.session_id)"
  >
    <template #empty>
      <div class="table-empty">
        <i class="pi pi-inbox" style="font-size: 28px; color: var(--mec-text-faint); margin-bottom: 10px;"></i>
        <div style="color: var(--mec-text-dim); font-size: 13px;">No sessions found.</div>
        <div style="color: var(--mec-text-faint); font-size: 12px; margin-top: 4px;">
          Run a tool with <code class="inline-code">MEC_TELEMETRY_ENABLED=true</code>
        </div>
      </div>
    </template>
    <template #loading>
      <div class="table-loading">Loading sessions…</div>
    </template>

    <Column field="timestamp" header="Timestamp (UTC)" sortable>
      <template #body="{ data }">
        <span class="mono" style="font-size: 12px; color: var(--mec-text-dim);">{{ fmtTs(data.timestamp) }}</span>
      </template>
    </Column>

    <Column field="tool" header="Tool" sortable>
      <template #body="{ data }">
        <Tag :value="data.tool || '—'" class="tool-tag" />
      </template>
    </Column>

    <Column field="exit_code" header="Exit" sortable>
      <template #body="{ data }">
        <Tag
          v-if="data.exit_code !== null && data.exit_code !== undefined"
          :value="String(data.exit_code)"
          :severity="data.exit_code === 0 ? 'success' : 'danger'"
          class="exit-tag"
        />
        <span v-else class="text-faint mono" style="font-size: 11px;">—</span>
      </template>
    </Column>

    <Column field="ai_status" header="AI" sortable>
      <template #body="{ data }">
        <Tag
          :value="data.ai_status"
          :severity="aiSeverity(data.ai_status)"
          class="ai-tag"
        />
      </template>
    </Column>

    <Column field="log_status" header="Logs" sortable>
      <template #body="{ data }">
        <Tag
          :value="data.log_status"
          :severity="logSeverity(data.log_status)"
          class="log-tag"
        />
      </template>
    </Column>

    <Column field="ai_execution_time_ms" header="AI Time" sortable>
      <template #body="{ data }">
        <span class="mono col-ai-time">
          {{ data.ai_execution_time_ms != null
             ? (data.ai_execution_time_ms / 1000).toFixed(1) + 's'
             : '—' }}
        </span>
      </template>
    </Column>

    <Column field="session_id" header="Session ID">
      <template #body="{ data }">
        <span class="mono session-id">{{ data.session_id }}</span>
      </template>
    </Column>
  </DataTable>
</template>

<script setup>
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'

const props = defineProps({
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

.tool-tag {
  background: var(--mec-surface-3) !important;
  color: var(--mec-accent-bright) !important;
  border: 1px solid var(--mec-accent-dim) !important;
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
