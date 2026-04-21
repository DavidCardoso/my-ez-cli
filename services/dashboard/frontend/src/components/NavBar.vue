<template>
  <nav class="navbar">
    <div class="navbar-inner">
      <RouterLink to="/" class="navbar-brand">
        <span class="navbar-brand-prefix">mec</span>
        <span class="navbar-brand-suffix">dashboard</span>
      </RouterLink>

      <div class="navbar-links">
        <RouterLink to="/" class="nav-link" :class="{ active: route.path === '/' }">
          <i class="pi pi-home nav-icon"></i>
          <span>Home</span>
        </RouterLink>
        <RouterLink to="/sessions" class="nav-link" :class="{ active: route.path.startsWith('/sessions') }">
          <i class="pi pi-list nav-icon"></i>
          <span>Sessions</span>
        </RouterLink>
        <RouterLink to="/tools" class="nav-link" :class="{ active: route.path === '/tools' }">
          <i class="pi pi-box nav-icon"></i>
          <span>Tools</span>
        </RouterLink>
      </div>

      <div class="navbar-right">
        <LogsStatus :enabled="logsEnabled" />
        <span class="navbar-sep"></span>
        <AIStatus :enabled="aiEnabled" />
        <span class="navbar-sep"></span>
        <WsStatus />
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import WsStatus from './WsStatus.vue'
import LogsStatus from './LogsStatus.vue'
import AIStatus from './AIStatus.vue'
import { useWebSocket } from '../composables/useWebSocket.js'

const route = useRoute()
const { onRefresh } = useWebSocket()

const logsEnabled = ref(false)
const aiEnabled = ref(false)

async function fetchFeatureFlags() {
  try {
    const res = await fetch('/api/stats')
    if (res.ok) {
      const stats = await res.json()
      logsEnabled.value = stats.logs_enabled ?? false
      aiEnabled.value = stats.ai_enabled ?? false
    }
  } catch (_) { /* silently fail */ }
}

let pollTimer = null
onMounted(() => {
  fetchFeatureFlags()
  pollTimer = setInterval(fetchFeatureFlags, 30_000)
})
const cleanupRefresh = onRefresh(fetchFeatureFlags)
onUnmounted(() => {
  cleanupRefresh()
  if (pollTimer) clearInterval(pollTimer)
})
</script>

<style scoped>
.navbar {
  background: var(--mec-surface-1);
  border-bottom: 1px solid var(--mec-border);
  position: sticky;
  top: 0;
  z-index: 100;
  backdrop-filter: blur(12px);
}

.navbar-inner {
  display: flex;
  align-items: center;
  gap: 0;
  padding: 0 24px;
  height: 52px;
  max-width: 1400px;
  margin: 0 auto;
}

.navbar-brand {
  display: flex;
  align-items: center;
  gap: 0;
  text-decoration: none;
  font-family: var(--font-mono);
  font-size: 14px;
  font-weight: 600;
  margin-right: 32px;
  letter-spacing: -0.02em;
}

.navbar-brand-prefix {
  color: var(--mec-accent-bright);
}

.navbar-brand-suffix {
  color: var(--mec-text-dim);
}

.navbar-brand:hover .navbar-brand-prefix {
  color: var(--mec-accent-bright);
}

.navbar-links {
  display: flex;
  align-items: center;
  gap: 2px;
  flex: 1;
}

.nav-link {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 6px 12px;
  text-decoration: none;
  color: var(--mec-text-dim);
  font-size: 13px;
  font-weight: 500;
  border-radius: 6px;
  transition: color 0.12s, background 0.12s;
  font-family: var(--font-ui);
}

.nav-link:hover {
  color: var(--mec-text);
  background: var(--mec-surface-3);
}

.nav-link.active {
  color: var(--mec-accent-bright);
  background: var(--mec-accent-glow);
}

.nav-icon {
  font-size: 13px;
  opacity: 0.8;
}

.navbar-right {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 4px;
}

.navbar-sep {
  width: 1px;
  height: 14px;
  background: var(--mec-border);
  margin: 0 6px;
}
</style>
