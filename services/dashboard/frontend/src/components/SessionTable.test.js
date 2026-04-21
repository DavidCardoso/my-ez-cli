import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import SessionTable from './SessionTable.vue'

// Stub PrimeVue DataTable/Column/Tag with minimal HTML equivalents
vi.mock('primevue/datatable', () => ({
  default: {
    template: `
      <div class="p-datatable">
        <slot name="empty" v-if="!value || value.length === 0" />
        <table v-else>
          <tbody>
            <tr
              v-for="row in value"
              :key="row.session_id"
              class="data-row"
              @click="$emit('row-click', { data: row })"
            >
              <td class="col-timestamp">{{ row.timestamp }}</td>
              <td class="col-tool">{{ row.tool }}</td>
              <td class="col-exit">{{ row.exit_code }}</td>
              <td class="col-ai">{{ row.ai_status }}</td>
              <td class="col-session-id">{{ row.session_id }}</td>
            </tr>
          </tbody>
        </table>
      </div>`,
    props: ['value', 'loading', 'rows', 'rowsPerPageOptions', 'paginator', 'sortField', 'sortOrder', 'dataKey', 'rowHover'],
    emits: ['row-click'],
  },
}))
vi.mock('primevue/column', () => ({ default: { template: '<slot />' } }))
vi.mock('primevue/tag', () => ({
  default: { template: '<span class="p-tag">{{ value }}</span>', props: ['value', 'severity'] },
}))

const mockSessions = [
  { session_id: 'mec-node-001', tool: 'node', exit_code: 0, ai_status: 'done', timestamp: '2026-01-01T00:00:00Z' },
  { session_id: 'mec-npm-002', tool: 'npm', exit_code: 1, ai_status: 'pending', timestamp: '2026-01-01T00:01:00Z' },
]

describe('SessionTable', () => {
  it('renders the correct number of rows', () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions } })
    expect(wrapper.findAll('.data-row')).toHaveLength(2)
  })

  it('emits row-click with correct session_id on row click', async () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions } })
    await wrapper.findAll('.data-row')[0].trigger('click')
    expect(wrapper.emitted('row-click')).toBeTruthy()
    expect(wrapper.emitted('row-click')[0]).toEqual(['mec-node-001'])
  })

  it('shows session IDs in rows', () => {
    const wrapper = mount(SessionTable, { props: { sessions: mockSessions } })
    const ids = wrapper.findAll('.col-session-id').map((el) => el.text())
    expect(ids).toContain('mec-node-001')
    expect(ids).toContain('mec-npm-002')
  })

  it('shows empty slot when sessions is empty', () => {
    const wrapper = mount(SessionTable, { props: { sessions: [] } })
    expect(wrapper.find('.table-empty').exists()).toBe(true)
  })
})
