<template>
  <div class="sessions-page">
    <div class="page-header">
      <div class="page-header-content">
        <div class="page-header-left">
          <h1 class="page-title">Sessions</h1>
          <span v-if="!loading" class="session-count">
            {{ filteredSessions.length }} session{{ filteredSessions.length !== 1 ? 's' : '' }}
            <template v-if="totalSessions > sessions.length"> of {{ totalSessions }} total</template>
          </span>
        </div>
      </div>
    </div>

    <div class="page-body">
      <!-- Filters toolbar -->
      <div class="toolbar">
        <div class="toolbar-search">
          <i class="pi pi-search search-icon"></i>
          <InputText
            v-model="search"
            placeholder="Search session ID…"
            class="search-input"
          />
        </div>

        <MultiSelect
          v-model="selectedTools"
          :options="availableTools"
          placeholder="All tools"
          :maxSelectedLabels="2"
          class="filter-select"
        />

        <Select
          v-model="selectedAiStatus"
          :options="aiStatusOptions"
          optionLabel="label"
          optionValue="value"
          class="filter-select"
        />

        <Select
          v-model="selectedExitCode"
          :options="exitCodeOptions"
          optionLabel="label"
          optionValue="value"
          class="filter-select"
        />

        <Button
          v-if="hasActiveFilters"
          icon="pi pi-times"
          label="Clear"
          text
          size="small"
          class="clear-btn"
          @click="clearFilters"
        />
      </div>

      <!-- Table -->
      <div class="table-wrapper">
        <SessionTable
          :sessions="filteredSessions"
          :loading="loading"
          @row-click="(id) => router.push(`/sessions/${id}`)"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import InputText from 'primevue/inputtext'
import MultiSelect from 'primevue/multiselect'
import Select from 'primevue/select'
import Button from 'primevue/button'
import SessionTable from '../components/SessionTable.vue'
import { useSessions } from '../composables/useSessions.js'
import { useWebSocket } from '../composables/useWebSocket.js'

const router = useRouter()
const { sessions, totalSessions, loading, fetchSessions, makeFiltered } = useSessions()
const { onRefresh } = useWebSocket()

const search = ref('')
const selectedTools = ref([])
const selectedAiStatus = ref('all')
const selectedExitCode = ref('all')
const allToolNames = ref([])

const aiStatusOptions = [
  { label: 'All AI statuses', value: 'all' },
  { label: 'Done', value: 'done' },
  { label: 'Pending', value: 'pending' },
  { label: 'None', value: 'none' },
]

const exitCodeOptions = [
  { label: 'All exit codes', value: 'all' },
  { label: 'Success (0)', value: 'success' },
  { label: 'Failure (≠0)', value: 'failure' },
]

// Use the full tool list from stats (covers all tools ever used, not just the fetched window)
const availableTools = computed(() => {
  if (allToolNames.value.length > 0) return allToolNames.value
  const tools = new Set(sessions.value.map((s) => s.tool).filter(Boolean))
  return [...tools].sort()
})

const hasActiveFilters = computed(() =>
  search.value || selectedTools.value.length > 0 ||
  selectedAiStatus.value !== 'all' || selectedExitCode.value !== 'all'
)

// Build reactive filtered view — makeFiltered returns a computed that reads the refs
const filteredSessions = makeFiltered({
  get tools() { return selectedTools.value },
  get aiStatus() { return selectedAiStatus.value },
  get exitCode() { return selectedExitCode.value },
  get search() { return search.value },
})

function clearFilters() {
  search.value = ''
  selectedTools.value = []
  selectedAiStatus.value = 'all'
  selectedExitCode.value = 'all'
}

onMounted(async () => {
  fetchSessions({ limit: 100 })
  // Fetch stats to get the full list of tools (not limited by the sessions fetch window)
  try {
    const res = await fetch('/api/stats')
    if (res.ok) {
      const stats = await res.json()
      allToolNames.value = Object.keys(stats.sessions_by_tool || {}).sort()
    }
  } catch (_) { /* fallback to session-derived list */ }
  const cleanup = onRefresh(() => fetchSessions({ limit: 100 }))
  onUnmounted(cleanup)
})
</script>

<style scoped>
.sessions-page {
  flex: 1;
}

.page-header {
  border-bottom: 1px solid var(--mec-border-subtle);
  padding: 28px 32px 20px;
}

.page-header-content {
  max-width: 1400px;
  margin: 0 auto;
}

.page-header-left {
  display: flex;
  align-items: baseline;
  gap: 12px;
}

.page-title {
  font-size: 22px;
  font-weight: 600;
  color: var(--mec-text);
  margin: 0;
  font-family: var(--font-ui);
  letter-spacing: -0.02em;
}

.session-count {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--mec-text-faint);
}

.page-body {
  padding: 24px 32px;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
}

.toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.toolbar-search {
  position: relative;
  flex: 1;
  min-width: 200px;
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--mec-text-faint);
  font-size: 12px;
  pointer-events: none;
  z-index: 1;
}

.search-input {
  width: 100%;
  padding-left: 30px !important;
}

.filter-select {
  min-width: 140px;
  flex-shrink: 0;
}

.clear-btn {
  color: var(--mec-text-faint) !important;
  flex-shrink: 0;
}

.table-wrapper {
  border: 1px solid var(--mec-border);
  border-radius: 10px;
  overflow: hidden;
  background: var(--mec-surface-1);
}

@media (max-width: 700px) {
  .page-body { padding: 16px; }
  .page-header { padding: 16px; }
  .toolbar { gap: 8px; }
  .filter-select { min-width: 110px; }
}
</style>
