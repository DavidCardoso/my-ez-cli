<template>
  <div class="feature-status" :class="{ enabled }" :title="enabled ? 'Logging enabled — mec logs disable to turn off' : 'Logging disabled — run: mec logs enable'">
    <span class="feature-dot"></span>
    <span class="feature-label">{{ enabled ? 'logs on' : 'logs off' }}</span>
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
  color: var(--mec-blue);
}

.feature-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--mec-text-faint);
  flex-shrink: 0;
}

.feature-status.enabled .feature-dot {
  background: var(--mec-blue);
}
</style>
