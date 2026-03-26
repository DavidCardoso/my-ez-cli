<template>
  <div class="tools-page">
    <div class="page-header">
      <div class="page-header-content">
        <div class="page-header-left">
          <h1 class="page-title">Tools</h1>
          <span v-if="!loading" class="tool-count">{{ filteredTools.length }} tool{{ filteredTools.length !== 1 ? 's' : '' }}</span>
        </div>
        <p class="page-subtitle">All available mec Docker tool wrappers</p>
      </div>
    </div>

    <div class="page-body">
      <!-- Search + filter toolbar -->
      <div class="toolbar">
        <div class="toolbar-search">
          <i class="pi pi-search search-icon"></i>
          <InputText
            v-model="search"
            placeholder="Search tools…"
            class="search-input"
          />
        </div>
        <Select
          v-model="selectedCategory"
          :options="categoryOptions"
          optionLabel="label"
          optionValue="value"
          class="filter-select"
        />
      </div>

      <!-- Table -->
      <div class="table-wrapper">
        <DataTable
          :value="filteredTools"
          :loading="loading"
          sortField="name"
          :sortOrder="1"
          class="tools-table"
        >
          <template #empty>
            <div class="table-empty">
              <i class="pi pi-search" style="font-size: 24px; color: var(--mec-text-faint);"></i>
              <div style="color: var(--mec-text-dim); margin-top: 8px;">No tools match your search.</div>
            </div>
          </template>

          <Column field="name" header="Name" sortable style="width: 150px;">
            <template #body="{ data }">
              <span class="tool-name mono">{{ data.name }}</span>
            </template>
          </Column>

          <Column field="category" header="Category" sortable style="width: 120px;">
            <template #body="{ data }">
              <Tag :value="data.category" :severity="categorySeverity(data.category)" class="category-tag" />
            </template>
          </Column>

          <Column field="description" header="Description">
            <template #body="{ data }">
              <span class="tool-description">{{ data.description }}</span>
            </template>
          </Column>

          <Column field="image" header="Image">
            <template #body="{ data }">
              <span class="tool-image mono">{{ data.image }}</span>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'

const tools = ref([])
const loading = ref(true)
const search = ref('')
const selectedCategory = ref('all')

const categoryOptions = [
  { label: 'All categories', value: 'all' },
  { label: 'Runtime', value: 'runtime' },
  { label: 'Cloud', value: 'cloud' },
  { label: 'Infra', value: 'infra' },
  { label: 'Testing', value: 'testing' },
  { label: 'AI', value: 'ai' },
]

const filteredTools = computed(() => {
  let result = tools.value
  if (selectedCategory.value !== 'all') {
    result = result.filter((t) => t.category === selectedCategory.value)
  }
  if (search.value.trim()) {
    const q = search.value.trim().toLowerCase()
    result = result.filter((t) =>
      t.name.toLowerCase().includes(q) || t.description.toLowerCase().includes(q)
    )
  }
  return result
})

function categorySeverity(cat) {
  const map = {
    runtime: 'info',
    cloud: 'warn',
    infra: 'secondary',
    testing: 'contrast',
    ai: 'success',
  }
  return map[cat] ?? 'secondary'
}

onMounted(async () => {
  try {
    const res = await fetch('/api/tools')
    if (res.ok) tools.value = await res.json()
  } catch { /* silently fail */ }
  finally { loading.value = false }
})
</script>

<style scoped>
.tools-page {
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
  margin-bottom: 4px;
}

.page-title {
  font-size: 22px;
  font-weight: 600;
  color: var(--mec-text);
  margin: 0;
  font-family: var(--font-ui);
  letter-spacing: -0.02em;
}

.tool-count {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--mec-text-faint);
}

.page-subtitle {
  font-size: 13px;
  color: var(--mec-text-dim);
  margin: 0;
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
}

.toolbar-search {
  position: relative;
  flex: 1;
  max-width: 400px;
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
  min-width: 150px;
}

.table-wrapper {
  border: 1px solid var(--mec-border);
  border-radius: 10px;
  overflow: hidden;
  background: var(--mec-surface-1);
}

.tool-name {
  font-size: 13px;
  font-weight: 500;
  color: var(--mec-accent-bright);
}

.tool-description {
  font-size: 13px;
  color: var(--mec-text-dim);
}

.tool-image {
  font-size: 11px;
  color: var(--mec-text-faint);
  word-break: break-all;
}

.category-tag {
  font-size: 10px !important;
}

.table-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px;
}

@media (max-width: 700px) {
  .page-body { padding: 16px; }
  .page-header { padding: 16px; }
}
</style>
