<template>
  <div class="feature-status" :class="{ enabled }" :title="enabled ? 'AI analysis enabled — mec ai disable to turn off' : 'AI analysis disabled — run: mec ai enable'">
    <span class="feature-dot"></span>
    <span class="feature-label">{{ enabled ? 'AI on' : 'AI off' }}</span>
  </div>
</template>

<script setup>
defineProps({
  enabled: { type: Boolean, default: false },
})
</script>

<style scoped>
.feature-status {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--mec-text-faint);
  letter-spacing: 0.04em;
  cursor: default;
}

.feature-status.enabled {
  color: var(--mec-accent-bright);
}

.feature-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--mec-text-faint);
  flex-shrink: 0;
}

.feature-status.enabled .feature-dot {
  background: var(--mec-accent-bright);
}
</style>
