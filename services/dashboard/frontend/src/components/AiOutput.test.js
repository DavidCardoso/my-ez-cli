import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import AiOutput from './AiOutput.vue'

// Stub PrimeVue components used in AiOutput
vi.mock('primevue/tag', () => ({
  default: { template: '<span><slot /></span>' },
}))
vi.mock('primevue/button', () => ({
  default: { template: '<button @click="$emit(\'click\')"><slot /></button>', emits: ['click'] },
}))

describe('AiOutput', () => {
  it('renders markdown content when status is "done"', () => {
    const wrapper = mount(AiOutput, {
      props: { content: '**Bold text**', status: 'done' },
    })
    expect(wrapper.find('.prose').exists()).toBe(true)
    expect(wrapper.find('.prose').html()).toContain('strong')
  })

  it('shows pending message when status is "pending"', () => {
    const wrapper = mount(AiOutput, {
      props: { content: '', status: 'pending' },
    })
    expect(wrapper.find('.state-msg--pending').exists()).toBe(true)
    expect(wrapper.find('.state-msg--pending').text()).toContain('Analysis running')
  })

  it('shows no-analysis message when status is "none"', () => {
    const wrapper = mount(AiOutput, {
      props: { content: '', status: 'none' },
    })
    expect(wrapper.find('.state-msg--none').exists()).toBe(true)
    expect(wrapper.find('.state-msg--none').text()).toContain('No AI analysis')
  })

  it('shows copy button only when status is "done" and content is present', () => {
    const donWrapper = mount(AiOutput, { props: { content: 'some content', status: 'done' } })
    expect(donWrapper.find('.copy-btn').exists()).toBe(true)

    const pendingWrapper = mount(AiOutput, { props: { content: '', status: 'pending' } })
    expect(pendingWrapper.find('.copy-btn').exists()).toBe(false)
  })

  it('calls clipboard writeText on copy button click', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    vi.stubGlobal('navigator', { clipboard: { writeText } })

    const wrapper = mount(AiOutput, {
      props: { content: 'copy me', status: 'done' },
    })
    await wrapper.find('.copy-btn').trigger('click')
    expect(writeText).toHaveBeenCalledWith('copy me')

    vi.unstubAllGlobals()
  })
})
