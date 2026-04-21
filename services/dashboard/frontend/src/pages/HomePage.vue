<template>
  <div class="home-page">
    <div class="page-header">
      <div class="page-header-content">
        <h1 class="page-title">Overview</h1>
        <p class="page-subtitle">Activity stats and recent trends across all mec sessions</p>
      </div>
    </div>

    <div class="page-body">
      <!-- Stat cards -->
      <div class="stat-grid">
        <div class="stat-card" v-for="card in statCards" :key="card.label">
          <template v-if="loading">
            <div class="stat-skeleton skeleton-pulse"></div>
          </template>
          <template v-else>
            <div class="stat-value" :style="{ color: card.color }">{{ card.value }}</div>
            <div class="stat-label">{{ card.label }}</div>
            <div v-if="card.sub" class="stat-sub">{{ card.sub }}</div>
          </template>
        </div>
      </div>

      <!-- Tool stats table -->
      <div class="tool-stats-card">
        <div class="tool-stats-header">Tool Stats</div>
        <template v-if="loading">
          <div class="tool-stats-skeleton skeleton-pulse"></div>
        </template>
        <table v-else-if="toolStatsRows.length" class="tool-stats-table">
          <thead>
            <tr>
              <th>Tool</th>
              <th class="col-num">Sessions</th>
              <th class="col-num">Success</th>
              <th class="col-num">AI Analyzed</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in toolStatsRows" :key="row.tool">
              <td class="col-tool">{{ row.tool }}</td>
              <td class="col-num">{{ row.sessions }}</td>
              <td class="col-num" :style="{ color: row.successColor }">{{ row.successRate }}</td>
              <td class="col-num" :style="{ color: row.aiColor }">{{ row.aiRate }}</td>
            </tr>
          </tbody>
        </table>
        <div v-else class="tool-stats-empty">No data</div>
      </div>

      <!-- Charts row -->
      <div class="charts-grid">
        <!-- Sessions per tool (Bar) -->
        <div class="chart-card">
          <div class="chart-card-header">Sessions by Tool</div>
          <div class="chart-card-body">
            <template v-if="loading">
              <div class="chart-skeleton skeleton-pulse"></div>
            </template>
            <Chart
              v-else-if="toolBarData.labels.length"
              type="bar"
              :data="toolBarData"
              :options="barOptions"
              class="chart"
            />
            <div v-else class="chart-empty">No data</div>
          </div>
        </div>

        <!-- Exit code distribution (Doughnut) -->
        <div class="chart-card chart-card--sm">
          <div class="chart-card-header">Exit Codes</div>
          <div class="chart-card-body chart-card-body--center">
            <template v-if="loading">
              <div class="chart-skeleton skeleton-pulse"></div>
            </template>
            <Chart
              v-else-if="stats && stats.total_sessions > 0"
              type="doughnut"
              :data="exitDonutData"
              :options="donutOptions"
              class="chart chart--donut"
            />
            <div v-else class="chart-empty">No data</div>
          </div>
        </div>

        <!-- Last 7 days (Line) -->
        <div class="chart-card chart-card--sm">
          <div class="chart-card-header">Last 7 Days</div>
          <div class="chart-card-body">
            <template v-if="loading">
              <div class="chart-skeleton skeleton-pulse"></div>
            </template>
            <Chart
              v-else-if="stats"
              type="line"
              :data="lineData"
              :options="lineOptions"
              class="chart"
            />
            <div v-else class="chart-empty">No data</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import Chart from 'primevue/chart'
import { useWebSocket } from '../composables/useWebSocket.js'

const stats = ref(null)
const loading = ref(true)
const { onRefresh } = useWebSocket()

async function fetchStats() {
  try {
    const res = await fetch('/api/stats')
    if (res.ok) stats.value = await res.json()
  } catch {
    // silently fail
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchStats()
  const cleanup = onRefresh(fetchStats)
  onUnmounted(cleanup)
})

// --- Stat cards ---
const statCards = computed(() => {
  if (!stats.value) return Array(4).fill({ label: '', value: '—' })
  const s = stats.value
  const total = s.total_sessions
  const success = s.exit_code_distribution?.success ?? 0
  const successRate = total ? Math.round((success / total) * 100) : 0
  const aiDone = s.ai_analysis_rate?.done ?? 0
  const aiRate = total ? Math.round((aiDone / total) * 100) : 0
  const toolCount = Object.keys(s.sessions_by_tool ?? {}).length

  return [
    { label: 'Total Sessions', value: total.toLocaleString(), color: 'var(--mec-text)', sub: null },
    { label: 'Success Rate', value: `${successRate}%`, color: successRate >= 80 ? 'var(--mec-green)' : successRate >= 50 ? 'var(--mec-yellow)' : 'var(--mec-red)', sub: `${success} of ${total}` },
    { label: 'AI Analyzed', value: `${aiRate}%`, color: 'var(--mec-accent-bright)', sub: `${aiDone} sessions` },
    { label: 'Tools Used', value: toolCount.toString(), color: 'var(--mec-blue)', sub: 'unique tools' },
  ]
})

// --- Tool stats table ---
const toolStatsRows = computed(() => {
  if (!stats.value) return []
  const ts = stats.value.tool_stats ?? {}
  return Object.entries(ts)
    .sort(([, a], [, b]) => b.sessions - a.sessions)
    .map(([tool, d]) => {
      const successPct = d.sessions ? Math.round((d.success / d.sessions) * 100) : 0
      const aiPct = d.sessions ? Math.round((d.ai_done / d.sessions) * 100) : 0
      return {
        tool,
        sessions: d.sessions,
        successRate: `${successPct}%`,
        aiRate: `${aiPct}%`,
        successColor: successPct >= 80 ? 'var(--mec-green)' : successPct >= 50 ? 'var(--mec-yellow)' : 'var(--mec-red)',
        aiColor: aiPct >= 50 ? 'var(--mec-accent-bright)' : 'var(--mec-text-faint)',
      }
    })
})

// --- Chart data ---
const toolBarData = computed(() => {
  if (!stats.value) return { labels: [], datasets: [] }
  const byTool = stats.value.sessions_by_tool ?? {}
  const sorted = Object.entries(byTool)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 10)
  return {
    labels: sorted.map(([name]) => name),
    datasets: [{
      label: 'Sessions',
      data: sorted.map(([, count]) => count),
      backgroundColor: 'rgba(124, 106, 247, 0.6)',
      borderColor: 'rgba(124, 106, 247, 0.9)',
      borderWidth: 1,
      borderRadius: 4,
    }],
  }
})

const exitDonutData = computed(() => {
  if (!stats.value) return { labels: [], datasets: [] }
  const dist = stats.value.exit_code_distribution ?? {}
  return {
    labels: ['Success', 'Failure'],
    datasets: [{
      data: [dist.success ?? 0, dist.failure ?? 0],
      backgroundColor: ['rgba(61, 220, 132, 0.7)', 'rgba(255, 107, 107, 0.7)'],
      borderColor: ['rgba(61, 220, 132, 0.9)', 'rgba(255, 107, 107, 0.9)'],
      borderWidth: 1,
    }],
  }
})

const lineData = computed(() => {
  if (!stats.value) return { labels: [], datasets: [] }
  const days = stats.value.last_7_days ?? []
  return {
    labels: days.map((d) => d.date.slice(5)), // "MM-DD"
    datasets: [{
      label: 'Sessions',
      data: days.map((d) => d.count),
      borderColor: 'rgba(124, 106, 247, 0.9)',
      backgroundColor: 'rgba(124, 106, 247, 0.1)',
      pointBackgroundColor: 'rgba(124, 106, 247, 1)',
      pointRadius: 4,
      pointHoverRadius: 6,
      fill: true,
      tension: 0.3,
    }],
  }
})

// --- Chart options ---
const baseGridColor = 'rgba(35, 40, 67, 0.8)'
const baseTickColor = '#4a5270'
const baseFontFamily = "'Inter', sans-serif"

const barOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: { bodyFont: { family: baseFontFamily, size: 12 } },
  },
  scales: {
    x: {
      grid: { color: baseGridColor },
      ticks: { color: baseTickColor, font: { family: baseFontFamily, size: 11 } },
    },
    y: {
      grid: { color: baseGridColor },
      ticks: { color: baseTickColor, font: { family: baseFontFamily, size: 11 }, stepSize: 1 },
      beginAtZero: true,
    },
  },
}

const donutOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom',
      labels: { color: baseTickColor, font: { family: baseFontFamily, size: 11 }, padding: 12 },
    },
  },
  cutout: '65%',
}

const lineOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: { bodyFont: { family: baseFontFamily, size: 12 } },
  },
  scales: {
    x: {
      grid: { color: baseGridColor },
      ticks: { color: baseTickColor, font: { family: baseFontFamily, size: 11 } },
    },
    y: {
      grid: { color: baseGridColor },
      ticks: { color: baseTickColor, font: { family: baseFontFamily, size: 11 }, stepSize: 1 },
      beginAtZero: true,
    },
  },
}
</script>

<style scoped>
.home-page {
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

.page-title {
  font-size: 22px;
  font-weight: 600;
  color: var(--mec-text);
  margin: 0 0 4px;
  font-family: var(--font-ui);
  letter-spacing: -0.02em;
}

.page-subtitle {
  font-size: 13px;
  color: var(--mec-text-dim);
  margin: 0;
}

.page-body {
  padding: 28px 32px;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
}

/* Stat cards */
.stat-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 28px;
}

.stat-card {
  background: var(--mec-surface-1);
  border: 1px solid var(--mec-border);
  border-radius: 10px;
  padding: 20px 22px;
  min-height: 100px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  transition: border-color 0.15s;
}

.stat-card:hover {
  border-color: var(--mec-accent-dim);
}

.stat-value {
  font-family: var(--font-mono);
  font-size: 28px;
  font-weight: 600;
  line-height: 1;
  letter-spacing: -0.03em;
  margin-bottom: 6px;
}

.stat-label {
  font-size: 12px;
  color: var(--mec-text-dim);
  font-weight: 500;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.stat-sub {
  font-size: 11px;
  color: var(--mec-text-faint);
  margin-top: 3px;
  font-family: var(--font-mono);
}

.stat-skeleton {
  height: 60px;
  border-radius: 6px;
  background: var(--mec-surface-3);
}

/* Tool stats table */
.tool-stats-card {
  background: var(--mec-surface-1);
  border: 1px solid var(--mec-border);
  border-radius: 10px;
  overflow: hidden;
  margin-bottom: 28px;
}

.tool-stats-header {
  padding: 14px 18px 12px;
  border-bottom: 1px solid var(--mec-border-subtle);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--mec-text-dim);
}

.tool-stats-skeleton {
  height: 120px;
  margin: 16px;
  border-radius: 6px;
  background: var(--mec-surface-3);
}

.tool-stats-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
}

.tool-stats-table th {
  padding: 10px 18px;
  text-align: left;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--mec-text-faint);
  border-bottom: 1px solid var(--mec-border-subtle);
}

.tool-stats-table td {
  padding: 10px 18px;
  border-bottom: 1px solid var(--mec-border-subtle);
  color: var(--mec-text);
}

.tool-stats-table tbody tr:last-child td {
  border-bottom: none;
}

.tool-stats-table tbody tr:hover td {
  background: var(--mec-surface-2);
}

.col-tool {
  font-family: var(--font-mono);
  font-size: 12px;
}

.col-num {
  text-align: right !important;
  font-family: var(--font-mono);
  font-size: 12px;
  white-space: nowrap;
}

.tool-stats-empty {
  padding: 24px 18px;
  color: var(--mec-text-faint);
  font-size: 13px;
}

/* Charts */
.charts-grid {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 16px;
}

.chart-card {
  background: var(--mec-surface-1);
  border: 1px solid var(--mec-border);
  border-radius: 10px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.chart-card-header {
  padding: 14px 18px 12px;
  border-bottom: 1px solid var(--mec-border-subtle);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--mec-text-dim);
  flex-shrink: 0;
}

.chart-card-body {
  padding: 16px;
  flex: 1;
  min-height: 200px;
  display: flex;
  flex-direction: column;
}

.chart-card-body--center {
  align-items: center;
  justify-content: center;
}

.chart {
  width: 100% !important;
  height: 200px !important;
}

.chart--donut {
  max-width: 200px;
}

.chart-skeleton {
  flex: 1;
  min-height: 180px;
  border-radius: 6px;
  background: var(--mec-surface-3);
}

.chart-empty {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--mec-text-faint);
  font-size: 13px;
}

@media (max-width: 1100px) {
  .stat-grid { grid-template-columns: repeat(2, 1fr); }
  .charts-grid { grid-template-columns: 1fr; }
}

@media (max-width: 600px) {
  .stat-grid { grid-template-columns: 1fr; }
  .page-body { padding: 16px; }
  .page-header { padding: 16px; }
}
</style>
