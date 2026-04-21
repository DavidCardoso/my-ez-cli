import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import SessionDetailPage from './SessionDetailPage.vue'

// Stub child components and dependencies
vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { sessionId: 'mec-node-test-1234' } }),
  RouterLink: { template: '<a><slot /></a>' },
}))
vi.mock('../composables/useWebSocket.js', () => ({
  useWebSocket: () => ({ onRefresh: () => () => {} }),
}))
vi.mock('../components/LogOutput.vue', () => ({
  default: { template: '<div class="log-output-stub" />' },
}))
vi.mock('../components/AiOutput.vue', () => ({
  default: { template: '<div class="ai-output-stub" />', props: ['content', 'status'] },
}))
vi.mock('primevue/tag', () => ({
  default: { template: '<span class="tag-stub">{{ value }}</span>', props: ['value', 'severity'] },
}))
vi.mock('primevue/button', () => ({
  default: {
    template: '<button class="btn-stub" @click="$emit(\'click\')"><slot /></button>',
    emits: ['click'],
    props: ['icon', 'text', 'rounded', 'size'],
  },
}))

function makeSession(overrides = {}) {
  return {
    session_id: 'mec-node-test-1234',
    tool: 'node',
    timestamp: '2026-01-15T10:00:00.000Z',
    exit_code: 0,
    ai_status: 'done',
    command: 'node --version',
    cwd: '/tmp',
    stdout: 'v24.0.0',
    stderr: '',
    ai_result: 'Analysis complete.',
    claude_session_id: '',
    ai_execution_time_ms: null,
    ai_tokens_input: null,
    ai_tokens_output: null,
    ...overrides,
  }
}

async function mountWithSession(session) {
  global.fetch = vi.fn().mockResolvedValue({
    ok: true,
    status: 200,
    json: async () => session,
  })
  const wrapper = mount(SessionDetailPage, {
    attachTo: document.body,
  })
  // Wait for fetch + reactivity
  await new Promise((r) => setTimeout(r, 10))
  await wrapper.vm.$nextTick()
  return wrapper
}

describe('SessionDetailPage — AI Time and Tokens meta-bar', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows AI time when ai_execution_time_ms is present', async () => {
    const wrapper = await mountWithSession(makeSession({ ai_execution_time_ms: 5000 }))
    expect(wrapper.text()).toContain('AI Time')
    expect(wrapper.text()).toContain('5.0s')
  })

  it('hides AI time when ai_execution_time_ms is null', async () => {
    const wrapper = await mountWithSession(makeSession({ ai_execution_time_ms: null }))
    expect(wrapper.text()).not.toContain('AI Time')
  })

  it('formats AI time correctly for sub-second values', async () => {
    const wrapper = await mountWithSession(makeSession({ ai_execution_time_ms: 450 }))
    expect(wrapper.text()).toContain('0.5s')
  })

  it('shows token counts when both are present', async () => {
    const wrapper = await mountWithSession(
      makeSession({ ai_tokens_input: 100, ai_tokens_output: 50 }),
    )
    expect(wrapper.text()).toContain('Tokens')
    expect(wrapper.text()).toContain('in=100')
    expect(wrapper.text()).toContain('out=50')
  })

  it('hides Tokens when both are null', async () => {
    const wrapper = await mountWithSession(
      makeSession({ ai_tokens_input: null, ai_tokens_output: null }),
    )
    expect(wrapper.text()).not.toContain('Tokens')
  })

  it('shows Tokens section when only input is present', async () => {
    const wrapper = await mountWithSession(
      makeSession({ ai_tokens_input: 200, ai_tokens_output: null }),
    )
    expect(wrapper.text()).toContain('Tokens')
    expect(wrapper.text()).toContain('in=200')
  })
})

describe('SessionDetailPage — Working Dir copy button', () => {
  it('shows copy button next to cwd when cwd is present', async () => {
    const wrapper = await mountWithSession(makeSession({ cwd: '/home/user/myproject' }))
    expect(wrapper.text()).toContain('Working Dir')
    expect(wrapper.text()).toContain('/home/user/myproject')
    // Should have a copy button in the cwd row
    const buttons = wrapper.findAll('.btn-stub')
    expect(buttons.length).toBeGreaterThan(0)
  })
})
