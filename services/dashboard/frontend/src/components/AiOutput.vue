<template>
  <div class="ai-output">
    <div class="panel-header">
      <span class="panel-title">AI Analysis</span>
      <Tag v-if="status" :value="status" :severity="aiSeverity(status)" style="font-size: 10px;" />
      <Button
        v-if="status === 'done' && content"
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
      <div v-if="status === 'done' && content" class="prose" v-html="renderedMarkdown"></div>
      <div v-else-if="status === 'pending'" class="state-msg state-msg--pending">
        <i class="pi pi-spin pi-spinner" style="font-size: 15px;"></i>
        <span>Analysis running in background — page updates automatically.</span>
      </div>
      <div v-else class="state-msg state-msg--none">
        <i class="pi pi-ban" style="font-size: 15px; opacity: 0.5;"></i>
        <span>No AI analysis for this session.</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { marked } from 'marked'
import Tag from 'primevue/tag'
import Button from 'primevue/button'

const props = defineProps({
  content: { type: String, default: '' },
  status: { type: String, default: 'none' }, // 'done' | 'pending' | 'none'
})

const copied = ref(false)

const renderedMarkdown = computed(() => {
  if (!props.content) return ''
  return marked.parse(props.content, { breaks: true, gfm: true })
})

function aiSeverity(status) {
  if (status === 'done') return 'success'
  if (status === 'pending') return 'warn'
  return 'secondary'
}

async function copyContent() {
  try {
    await navigator.clipboard.writeText(props.content)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch {
    // clipboard not available in non-secure context — silently skip
  }
}
</script>

<style scoped>
.ai-output {
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
  padding: 16px;
  min-height: 0;
}

.state-msg {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 24px 0;
  font-size: 13px;
}

.state-msg--pending {
  color: var(--mec-yellow);
}

.state-msg--none {
  color: var(--mec-text-faint);
}
</style>
