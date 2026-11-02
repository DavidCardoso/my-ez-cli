import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SessionTable from './SessionTable.vue'

const mockSessions = [
  { session_id: 'mec-node-001', tool: 'node', exit_code: 0, ai_status: 'done', log_status: 'captured', timestamp: '2026-01-01T00:00:00Z' },
  { session_id: 'mec-npm-002', tool: 'npm', exit_code: 1, ai_status: 'pending', log_status: 'none', timestamp: '2026-01-01T00:01:00Z' },
]

const rows = (w) => w.findAll('.ui-table__row')

describe('SessionTable', () => {
  it('renders the correct number of rows', () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions } })
    expect(rows(wrapper)).toHaveLength(2)
  })

  it('sorts newest first by default', () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions } })
    expect(rows(wrapper)[0].find('.session-id').text()).toBe('mec-npm-002')
  })

  it('emits row-click with correct session_id on row click', async () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions } })
    await rows(wrapper)[1].trigger('click')
    expect(wrapper.emitted('row-click')).toBeTruthy()
    expect(wrapper.emitted('row-click')[0]).toEqual(['mec-node-001'])
  })

  it('shows session IDs in rows', () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions } })
    const ids = wrapper.findAll('.session-id').map((el) => el.text())
    expect(ids).toContain('mec-node-001')
    expect(ids).toContain('mec-npm-002')
  })

  it('renders exit codes with success/danger severity', () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions } })
    const tags = wrapper.findAll('.exit-tag')
    expect(tags.map((t) => t.text())).toEqual(['1', '0'])
    expect(tags[0].classes()).toContain('ui-tag--danger')
    expect(tags[1].classes()).toContain('ui-tag--success')
  })

  it('shows the empty state when there are no sessions', () => {
    const wrapper = mount(SessionTable, { props: { sessions: [] } })
    expect(wrapper.text()).toContain('No sessions found.')
  })

  it('shows the loading state while loading', () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions, loading: true } })
    expect(wrapper.text()).toContain('Loading sessions…')
    expect(rows(wrapper)).toHaveLength(0)
  })
})
