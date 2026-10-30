<template>
  <button
    type="button"
    class="ui-button"
    :class="{ 'ui-button--text': text, 'ui-button--rounded': rounded, 'ui-button--small': size === 'small' }"
  >
    <component :is="icon" v-if="icon" class="ui-button__icon" aria-hidden="true" />
    <span v-if="label">{{ label }}</span>
    <slot />
  </button>
</template>

<script setup>
defineProps({
  label: { type: String, default: '' },
  // A lucide-vue-next icon component, e.g. :icon="Copy"
  icon: { type: [Object, Function], default: null },
  text: { type: Boolean, default: false },
  rounded: { type: Boolean, default: false },
  size: { type: String, default: '' },
})
</script>

<style scoped>
.ui-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-family: var(--font-ui);
  font-size: 13px;
  color: #fff;
  background: var(--mec-accent);
  border: 1px solid transparent;
  border-radius: 6px;
  padding: 7px 12px;
  cursor: pointer;
  transition: background 0.12s, color 0.12s;
}

.ui-button:hover { background: var(--mec-accent-bright); }

.ui-button:focus-visible {
  outline: 2px solid var(--mec-accent);
  outline-offset: 2px;
}

.ui-button--text {
  color: var(--mec-text-dim);
  background: transparent;
}

.ui-button--text:hover {
  color: var(--mec-text);
  background: var(--mec-surface-3);
}

.ui-button--small { font-size: 12px; padding: 5px 9px; }
.ui-button--rounded { border-radius: 999px; }
.ui-button--rounded.ui-button--small:not(:has(span)) { padding: 6px; }

.ui-button__icon { width: 1.1em; height: 1.1em; flex-shrink: 0; }
</style>
