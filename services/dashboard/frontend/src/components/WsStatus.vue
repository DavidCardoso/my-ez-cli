<template>
  <div class="ws-status" :class="{ connected }">
    <span class="ws-dot" :class="{ 'ws-dot--pulse': connected }"></span>
    <span class="ws-label">{{ connected ? 'live' : 'disconnected' }}</span>
  </div>
</template>

<script setup>
import { useWebSocket } from '../composables/useWebSocket.js'

const { connected } = useWebSocket()
</script>

<style scoped>
.ws-status {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--mec-text-faint);
  letter-spacing: 0.04em;
  transition: color 0.2s;
}

.ws-status.connected {
  color: var(--mec-green);
}

.ws-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--mec-text-faint);
  flex-shrink: 0;
  transition: background 0.2s;
}

.ws-status.connected .ws-dot {
  background: var(--mec-green);
}

.ws-dot--pulse {
  animation: wsPulse 2.5s ease-in-out infinite;
}

@keyframes wsPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(61, 220, 132, 0.4); }
  50% { box-shadow: 0 0 0 4px rgba(61, 220, 132, 0); }
}
</style>
