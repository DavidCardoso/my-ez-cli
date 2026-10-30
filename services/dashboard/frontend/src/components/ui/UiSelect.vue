<template>
  <SelectRoot v-model="model" :multiple="multiple">
    <SelectTrigger class="ui-select" :aria-label="ariaLabel || placeholder">
      <span class="ui-select__label" :class="{ 'ui-select__label--placeholder': isEmpty }">{{ displayLabel }}</span>
      <ChevronDown class="ui-select__chevron" aria-hidden="true" />
    </SelectTrigger>
    <SelectPortal>
      <SelectContent class="ui-select__content" position="popper" :side-offset="4">
        <SelectViewport class="ui-select__viewport">
          <SelectItem
            v-for="opt in normalized"
            :key="opt.value"
            :value="opt.value"
            class="ui-select__item"
          >
            <SelectItemIndicator class="ui-select__check"><Check aria-hidden="true" /></SelectItemIndicator>
            <SelectItemText>{{ opt.label }}</SelectItemText>
          </SelectItem>
        </SelectViewport>
      </SelectContent>
    </SelectPortal>
  </SelectRoot>
</template>

<script setup>
import { computed } from 'vue'
import {
  SelectContent, SelectItem, SelectItemIndicator, SelectItemText,
  SelectPortal, SelectRoot, SelectTrigger, SelectViewport,
} from 'reka-ui'
import { Check, ChevronDown } from 'lucide-vue-next'

const model = defineModel({ type: [String, Number, Array], default: undefined })

const props = defineProps({
  // Plain values (['node', 'npm']) or objects ([{ label, value }])
  options: { type: Array, default: () => [] },
  optionLabel: { type: String, default: 'label' },
  optionValue: { type: String, default: 'value' },
  placeholder: { type: String, default: 'Select' },
  multiple: { type: Boolean, default: false },
  // multiple only: beyond this many, show "N selected" instead of the names
  maxSelectedLabels: { type: Number, default: 3 },
  ariaLabel: { type: String, default: '' },
})

const normalized = computed(() =>
  props.options.map((o) =>
    typeof o === 'object' && o !== null
      ? { label: String(o[props.optionLabel]), value: o[props.optionValue] }
      : { label: String(o), value: o },
  ),
)

const isEmpty = computed(() =>
  props.multiple ? !model.value?.length : model.value === undefined || model.value === null,
)

const displayLabel = computed(() => {
  if (isEmpty.value) return props.placeholder
  const labelOf = (v) => normalized.value.find((o) => o.value === v)?.label ?? String(v)
  if (!props.multiple) return labelOf(model.value)
  if (model.value.length > props.maxSelectedLabels) return `${model.value.length} selected`
  return model.value.map(labelOf).join(', ')
})
</script>

<style>
/* Unscoped: the dropdown content is teleported to <body>. */
.ui-select {
  display: inline-flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  min-width: 140px;
  font-family: var(--font-ui);
  font-size: 13px;
  color: var(--mec-text);
  background: var(--mec-surface-2);
  border: 1px solid var(--mec-border);
  border-radius: 6px;
  padding: 7px 10px;
  cursor: pointer;
  transition: border-color 0.12s, box-shadow 0.12s;
}

.ui-select:focus-visible,
.ui-select[data-state='open'] {
  outline: none;
  border-color: var(--mec-accent);
  box-shadow: 0 0 0 2px var(--mec-accent-glow);
}

.ui-select__label { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ui-select__label--placeholder { color: var(--mec-text-dim); }
.ui-select__chevron { width: 16px; height: 16px; color: var(--mec-text-dim); flex-shrink: 0; }

.ui-select__content {
  z-index: 1000;
  min-width: var(--reka-select-trigger-width);
  max-height: var(--reka-select-content-available-height);
  background: var(--mec-surface-2);
  border: 1px solid var(--mec-border);
  border-radius: 6px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  overflow: hidden;
}

.ui-select__viewport { padding: 4px; }

.ui-select__item {
  position: relative;
  display: flex;
  align-items: center;
  font-size: 13px;
  color: var(--mec-text);
  border-radius: 4px;
  padding: 6px 10px 6px 28px;
  cursor: pointer;
  user-select: none;
  outline: none;
}

.ui-select__item[data-highlighted] { background: var(--mec-surface-3); }
.ui-select__item[data-state='checked'] { color: var(--mec-accent-bright); }

.ui-select__check {
  position: absolute;
  left: 8px;
  display: inline-flex;
}

.ui-select__check svg { width: 14px; height: 14px; }
</style>
