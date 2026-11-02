<template>
  <input v-model="model" class="ui-input" type="text" />
</template>

<script setup>
const model = defineModel({ type: String, default: '' })
</script>

<style scoped>
.ui-input {
  width: 100%;
  font-family: var(--font-ui);
  font-size: 13px;
  color: var(--mec-text);
  background: var(--mec-surface-2);
  border: 1px solid var(--mec-border);
  border-radius: 6px;
  padding: 7px 10px;
  transition: border-color 0.12s, box-shadow 0.12s;
}

.ui-input::placeholder { color: var(--mec-text-faint); }

.ui-input:focus {
  outline: none;
  border-color: var(--mec-accent);
  box-shadow: 0 0 0 2px var(--mec-accent-glow);
}
</style>
