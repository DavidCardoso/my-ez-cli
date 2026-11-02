<template>
  <span class="ui-tag" :class="severity && `ui-tag--${severity}`">{{ value }}</span>
</template>

<script setup>
defineProps({
  value: { type: [String, Number], default: '' },
  // success | danger | warn | info | secondary — omitted = accent
  severity: { type: String, default: '' },
})
</script>

<style scoped>
.ui-tag {
  display: inline-flex;
  align-items: center;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 500;
  line-height: 1.5;
  letter-spacing: 0.02em;
  border-radius: 4px;
  padding: 2px 8px;
  white-space: nowrap;
  color: var(--mec-accent-bright);
  background: var(--mec-accent-glow);
}

.ui-tag--success { color: var(--mec-green); background: var(--mec-green-dim); }
.ui-tag--danger { color: var(--mec-red); background: var(--mec-red-dim); }
.ui-tag--warn { color: var(--mec-orange); background: var(--mec-orange-dim); }
.ui-tag--info { color: var(--mec-blue); background: var(--mec-blue-dim); }
.ui-tag--secondary { color: var(--mec-text-dim); background: var(--mec-surface-3); }
</style>
