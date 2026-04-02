<template>
  <div class="log-output">
    <div class="panel-header">
      <span class="panel-title">Raw Output</span>
      <span v-if="hasStderr" class="stderr-badge">stderr</span>
      <Button
        v-if="hasContent"
        icon="pi pi-copy"
        text
        rounded
        size="small"
        class="copy-btn"
        :class="{ copied }"
        v-tooltip="copied ? 'Copied!' : 'Copy'"
        @click="copyContent"
      />
    </div>

    <div class="panel-body">
      <template v-if="hasContent">
        <div v-if="stdout" class="output-block">
          <pre class="output-pre"><code>{{ stdout }}</code></pre>
        </div>
        <div v-if="hasStderr" class="stderr-divider">
          <span class="stderr-label">stderr</span>
        </div>
        <div v-if="stderr" class="output-block output-block--stderr">
          <pre class="output-pre output-pre--stderr"><code>{{ stderr }}</code></pre>
        </div>
      </template>
      <div v-else-if="captureDisabled" class="state-msg">
        <i class="pi pi-ban" style="font-size: 15px; opacity: 0.5;"></i>
        <span>Output capture disabled — run <code>mec logs output enable</code> to record stdout/stderr.</span>
      </div>
      <div v-else class="state-msg">
        <i class="pi pi-minus-circle" style="font-size: 15px; opacity: 0.4;"></i>
        <span>No output for this session.</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import Button from 'primevue/button'

const props = defineProps({
  stdout: { type: String, default: '' },
  stderr: { type: String, default: '' },
  captureDisabled: { type: Boolean, default: false },
})

const copied = ref(false)
const hasStderr = computed(() => !!props.stderr)
const hasContent = computed(() => !!(props.stdout || props.stderr))

async function copyContent() {
  const parts = [props.stdout, props.stderr ? `\n--- stderr ---\n${props.stderr}` : '']
  const text = parts.filter(Boolean).join('')
  try {
    await navigator.clipboard.writeText(text)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch {
    // clipboard not available — silently skip
  }
}
</script>

<style scoped>
.log-output {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 0;
}

.panel-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  border-bottom: 1px solid var(--mec-border);
  flex-shrink: 0;
}

.panel-title {
  font-family: var(--font-ui);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--mec-text-dim);
}

.stderr-badge {
  font-family: var(--font-mono);
  font-size: 10px;
  background: var(--mec-red-dim);
  color: var(--mec-red);
  border: 1px solid rgba(255, 107, 107, 0.2);
  border-radius: 3px;
  padding: 1px 6px;
}

.copy-btn {
  margin-left: auto;
  color: var(--mec-text-faint) !important;
  transition: color 0.15s !important;
}

.copy-btn:hover {
  color: var(--mec-accent-bright) !important;
}

.copy-btn.copied {
  color: var(--mec-green) !important;
}

.panel-body {
  flex: 1;
  overflow-y: auto;
  min-height: 0;
}

.output-block {
  padding: 0;
}

.output-pre {
  margin: 0;
  padding: 14px 16px;
  font-family: var(--font-mono);
  font-size: 12px;
  line-height: 1.65;
  color: var(--mec-text);
  background: transparent;
  white-space: pre-wrap;
  word-break: break-word;
  border: none;
}

.output-pre--stderr {
  color: var(--mec-red);
  background: rgba(255, 107, 107, 0.03);
}

.stderr-divider {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 16px;
  border-top: 1px dashed var(--mec-border);
  border-bottom: 1px dashed var(--mec-border);
}

.stderr-label {
  font-family: var(--font-mono);
  font-size: 10px;
  color: var(--mec-red);
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.state-msg {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 24px 16px;
  font-size: 13px;
  color: var(--mec-text-faint);
  font-family: var(--font-mono);
}
</style>
