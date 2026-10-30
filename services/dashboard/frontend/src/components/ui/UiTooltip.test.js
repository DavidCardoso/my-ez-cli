import { describe, it, expect } from 'vitest'
import { defineComponent, nextTick, ref } from 'vue'
import { mount } from '@vue/test-utils'
import { TooltipProvider } from 'reka-ui'
import UiTooltip from './UiTooltip.vue'

function mountWithText(initial) {
  const text = ref(initial)
  const Host = defineComponent({
    components: { TooltipProvider, UiTooltip },
    setup: () => ({ text }),
    template: '<TooltipProvider><UiTooltip :text="text"><button class="trigger">copy</button></UiTooltip></TooltipProvider>',
  })
  return { wrapper: mount(Host, { attachTo: document.body }), text }
}

const tooltipText = () => document.querySelector('.ui-tooltip')?.textContent.trim()

describe('UiTooltip', () => {
  it('shows on keyboard focus and follows text changes', async () => {
    const { wrapper, text } = mountWithText('Copy ID')
    expect(tooltipText()).toBeUndefined()

    await wrapper.find('.trigger').trigger('focus')
    await nextTick()
    expect(tooltipText()).toContain('Copy ID')

    text.value = 'Copied!'
    await nextTick()
    expect(tooltipText()).toContain('Copied!')
    wrapper.unmount()
  })

  it('renders the trigger element itself (as-child, no wrapper)', () => {
    const { wrapper } = mountWithText('Copy')
    expect(wrapper.find('button.trigger').exists()).toBe(true)
    expect(wrapper.find('button.trigger').attributes('data-state')).toBe('closed')
    wrapper.unmount()
  })
})
