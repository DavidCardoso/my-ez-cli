<template>
  <TooltipProvider :delay-duration="200">
    <TooltipRoot>
      <TooltipTrigger as-child>
        <slot />
      </TooltipTrigger>
      <TooltipPortal>
        <TooltipContent class="ui-tooltip" side="top" :side-offset="6">
          {{ text }}
          <TooltipArrow class="ui-tooltip__arrow" :width="10" :height="5" />
        </TooltipContent>
      </TooltipPortal>
    </TooltipRoot>
  </TooltipProvider>
</template>

<script setup>
import {
  TooltipArrow, TooltipContent, TooltipPortal, TooltipProvider, TooltipRoot, TooltipTrigger,
} from 'reka-ui'

defineProps({
  text: { type: String, required: true },
})
</script>

<style>
/* Unscoped: the content is teleported to <body>. */
.ui-tooltip {
  z-index: 1000;
  font-family: var(--font-ui);
  font-size: 12px;
  color: var(--mec-text);
  background: var(--mec-surface-3);
  border: 1px solid var(--mec-border);
  border-radius: 5px;
  padding: 4px 8px;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.35);
}

.ui-tooltip__arrow { fill: var(--mec-surface-3); }
</style>
