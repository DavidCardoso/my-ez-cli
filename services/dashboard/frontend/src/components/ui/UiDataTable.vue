<template>
  <div class="ui-table">
    <table>
      <thead>
        <tr>
          <th
            v-for="col in columns"
            :key="col.field"
            :style="col.style"
            :aria-sort="col.sortable ? ariaSort(col.field) : undefined"
          >
            <button v-if="col.sortable" type="button" class="ui-table__sort" @click="toggleSort(col.field)">
              {{ col.header }}
              <component :is="sortIcon(col.field)" class="ui-table__sort-icon" aria-hidden="true" />
            </button>
            <template v-else>{{ col.header }}</template>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="loading">
          <td :colspan="columns.length"><slot name="loading">Loading…</slot></td>
        </tr>
        <tr v-else-if="!pageRows.length">
          <td :colspan="columns.length"><slot name="empty" /></td>
        </tr>
        <template v-else>
          <tr
            v-for="row in pageRows"
            :key="row[rowKey]"
            class="ui-table__row"
            :class="{ 'ui-table__row--clickable': clickable }"
            :tabindex="clickable ? 0 : undefined"
            @click="clickable && emit('row-click', row)"
            @keydown.enter="clickable && emit('row-click', row)"
          >
            <td v-for="col in columns" :key="col.field" :style="col.style">
              <slot :name="`cell-${col.field}`" :row="row">{{ row[col.field] }}</slot>
            </td>
          </tr>
        </template>
      </tbody>
    </table>

    <div v-if="paginator && !loading && sortedRows.length" class="ui-table__paginator">
      <UiSelect v-model="perPage" :options="rowsPerPageOptions" aria-label="Rows per page" class="ui-table__per-page" />
      <PaginationRoot v-model:page="page" :total="sortedRows.length" :items-per-page="perPage" :sibling-count="1" show-edges>
        <PaginationList v-slot="{ items }" class="ui-table__pages">
          <PaginationFirst class="ui-table__page-btn" aria-label="First page"><ChevronsLeft /></PaginationFirst>
          <PaginationPrev class="ui-table__page-btn" aria-label="Previous page"><ChevronLeft /></PaginationPrev>
          <template v-for="(item, i) in items" :key="i">
            <PaginationListItem v-if="item.type === 'page'" :value="item.value" class="ui-table__page-btn">
              {{ item.value }}
            </PaginationListItem>
            <PaginationEllipsis v-else :index="i" class="ui-table__ellipsis">…</PaginationEllipsis>
          </template>
          <PaginationNext class="ui-table__page-btn" aria-label="Next page"><ChevronRight /></PaginationNext>
          <PaginationLast class="ui-table__page-btn" aria-label="Last page"><ChevronsRight /></PaginationLast>
        </PaginationList>
      </PaginationRoot>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import {
  PaginationEllipsis, PaginationFirst, PaginationLast, PaginationList,
  PaginationListItem, PaginationNext, PaginationPrev, PaginationRoot,
} from 'reka-ui'
import {
  ArrowDown, ArrowUp, ArrowUpDown, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight,
} from 'lucide-vue-next'
import UiSelect from './UiSelect.vue'

const props = defineProps({
  rows: { type: Array, default: () => [] },
  // [{ field, header, sortable?, style? }] — render cells via the #cell-<field>="{ row }" slot
  columns: { type: Array, required: true },
  rowKey: { type: String, required: true },
  loading: { type: Boolean, default: false },
  clickable: { type: Boolean, default: false },
  paginator: { type: Boolean, default: false },
  rowsPerPage: { type: Number, default: 20 },
  rowsPerPageOptions: { type: Array, default: () => [20, 50, 100] },
  sortField: { type: String, default: '' },
  sortOrder: { type: Number, default: 1 }, // 1 = ascending, -1 = descending
})

const emit = defineEmits(['row-click'])

const sort = ref({ field: props.sortField, order: props.sortOrder })
const page = ref(1)
const perPage = ref(props.rowsPerPage)

function compare(a, b) {
  // Missing values always sort last, regardless of direction
  if (a == null) return b == null ? 0 : 1
  if (b == null) return -1
  if (typeof a === 'number' && typeof b === 'number') return a - b
  return String(a).localeCompare(String(b), undefined, { numeric: true })
}

const sortedRows = computed(() => {
  const { field, order } = sort.value
  if (!field) return props.rows
  return [...props.rows].sort((x, y) => {
    const a = x[field]
    const b = y[field]
    if (a == null || b == null) return compare(a, b)
    return compare(a, b) * order
  })
})

const pageRows = computed(() => {
  if (!props.paginator) return sortedRows.value
  const start = (page.value - 1) * perPage.value
  return sortedRows.value.slice(start, start + perPage.value)
})

// Back to page 1 whenever the visible set changes shape
watch([() => props.rows, sort, perPage], () => { page.value = 1 }, { deep: true })

function toggleSort(field) {
  sort.value = sort.value.field === field
    ? { field, order: -sort.value.order }
    : { field, order: 1 }
}

function ariaSort(field) {
  if (sort.value.field !== field) return 'none'
  return sort.value.order === 1 ? 'ascending' : 'descending'
}

function sortIcon(field) {
  if (sort.value.field !== field) return ArrowUpDown
  return sort.value.order === 1 ? ArrowUp : ArrowDown
}
</script>

<style scoped>
.ui-table { width: 100%; }

table {
  width: 100%;
  border-collapse: collapse;
}

th {
  text-align: left;
  font-family: var(--font-ui);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--mec-text-dim);
  background: var(--mec-surface-2);
  border-bottom: 1px solid var(--mec-border);
  padding: 10px 14px;
  white-space: nowrap;
}

td {
  border-bottom: 1px solid var(--mec-border-subtle);
  padding: 9px 14px;
}

.ui-table__sort {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font: inherit;
  letter-spacing: inherit;
  text-transform: inherit;
  color: inherit;
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
}

.ui-table__sort:hover,
th[aria-sort='ascending'] .ui-table__sort,
th[aria-sort='descending'] .ui-table__sort { color: var(--mec-text); }

.ui-table__sort:focus-visible { outline: 2px solid var(--mec-accent); outline-offset: 2px; }
.ui-table__sort-icon { width: 13px; height: 13px; }

.ui-table__row { transition: background 0.12s; }
.ui-table__row--clickable { cursor: pointer; }
.ui-table__row:hover { background: var(--mec-surface-2); }
.ui-table__row:focus-visible { outline: 2px solid var(--mec-accent); outline-offset: -2px; }

.ui-table__paginator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 10px;
  background: var(--mec-surface-1);
}

.ui-table__per-page { min-width: 72px; }

.ui-table__pages {
  display: flex;
  align-items: center;
  gap: 4px;
}

.ui-table__page-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 32px;
  height: 32px;
  font-family: var(--font-ui);
  font-size: 13px;
  color: var(--mec-text-dim);
  background: none;
  border: none;
  border-radius: 999px;
  cursor: pointer;
}

.ui-table__page-btn svg { width: 16px; height: 16px; }
.ui-table__page-btn:hover:not(:disabled) { color: var(--mec-text); background: var(--mec-surface-3); }
.ui-table__page-btn:disabled { opacity: 0.35; cursor: default; }
.ui-table__page-btn[data-selected] { color: var(--mec-text); background: var(--mec-accent-dim); }
.ui-table__page-btn:focus-visible { outline: 2px solid var(--mec-accent); outline-offset: 1px; }
.ui-table__ellipsis { color: var(--mec-text-faint); padding: 0 4px; }
</style>
