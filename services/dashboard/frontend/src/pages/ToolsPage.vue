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
          <Search class="search-icon" aria-hidden="true" />
          <UiInput
            v-model="search"
            placeholder="Search tools…"
            class="search-input"
          />
        </div>
        <UiSelect
          v-model="selectedCategory"
          :options="categoryOptions"
          optionLabel="label"
          optionValue="value"
          class="filter-select"
        />
      </div>

      <!-- Table -->
      <div class="table-wrapper">
        <UiDataTable
          :rows="filteredTools"
          :columns="columns"
          row-key="name"
          :loading="loading"
          sort-field="name"
          :sort-order="1"
          class="tools-table"
        >
          <template #empty>
            <div class="table-empty">
              <Search :size="24" style="color: var(--mec-text-faint);" aria-hidden="true" />
              <div style="color: var(--mec-text-dim); margin-top: 8px;">No tools match your search.</div>
            </div>
          </template>

          <template #cell-name="{ row }">
            <span class="tool-name mono">{{ row.name }}</span>
          </template>

          <template #cell-category="{ row }">
            <UiTag :value="row.category" :severity="categorySeverity(row.category)" class="category-tag" />
          </template>

          <template #cell-description="{ row }">
            <span class="tool-description">{{ row.description }}</span>
          </template>

          <template #cell-image="{ row }">
            <span class="tool-image mono">{{ row.image }}</span>
          </template>
        </UiDataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Search } from 'lucide-vue-next'
import UiInput from '../components/ui/UiInput.vue'
import UiSelect from '../components/ui/UiSelect.vue'
import UiTag from '../components/ui/UiTag.vue'
import UiDataTable from '../components/ui/UiDataTable.vue'
import { ref, computed, onMounted } from 'vue'

const tools = ref([])
const loading = ref(true)
const columns = [
  { field: 'name', header: 'Name', sortable: true, style: 'width: 150px;' },
  { field: 'category', header: 'Category', sortable: true, style: 'width: 120px;' },
  { field: 'description', header: 'Description' },
  { field: 'image', header: 'Image' },
]

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

.ui-input.search-input {
  width: 100%;
  padding-left: 30px;
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

.ui-tag.category-tag {
  font-size: 10px;
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
