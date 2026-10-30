import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import UiDataTable from './UiDataTable.vue'

const columns = [
  { field: 'name', header: 'Name', sortable: true },
  { field: 'size', header: 'Size', sortable: true },
  { field: 'note', header: 'Note' },
]

const rows = [
  { id: 'a', name: 'beta', size: 2, note: 'x' },
  { id: 'b', name: 'alpha', size: 10, note: 'y' },
  { id: 'c', name: 'gamma', size: null, note: 'z' },
]

function mountTable(props = {}, slots = {}) {
  return mount(UiDataTable, { props: { columns, rows, rowKey: 'id', ...props }, slots })
}

const names = (w) => w.findAll('tbody tr').map((tr) => tr.find('td').text())

describe('UiDataTable', () => {
  it('renders rows in given order without a sort field', () => {
    expect(names(mountTable())).toEqual(['beta', 'alpha', 'gamma'])
  })

  it('applies the default sort field and order', () => {
    expect(names(mountTable({ sortField: 'name', sortOrder: -1 }))).toEqual(['gamma', 'beta', 'alpha'])
  })

  it('sorts numerically and keeps missing values last in both directions', async () => {
    const w = mountTable()
    const sizeHeader = () => w.findAll('th')[1]
    await sizeHeader().find('button').trigger('click')
    expect(names(w)).toEqual(['beta', 'alpha', 'gamma']) // 2, 10, null
    expect(sizeHeader().attributes('aria-sort')).toBe('ascending')
    await sizeHeader().find('button').trigger('click')
    expect(names(w)).toEqual(['alpha', 'beta', 'gamma']) // 10, 2, null
    expect(sizeHeader().attributes('aria-sort')).toBe('descending')
  })

  it('marks only sortable columns with aria-sort', () => {
    const ths = mountTable().findAll('th')
    expect(ths[0].attributes('aria-sort')).toBe('none')
    expect(ths[2].attributes('aria-sort')).toBeUndefined()
    expect(ths[2].find('button').exists()).toBe(false)
  })

  it('renders cells through #cell-<field> slots', () => {
    const w = mountTable({}, { 'cell-note': '<em class="note">{{ params.row.note.toUpperCase() }}</em>' })
    expect(w.findAll('.note').map((e) => e.text())).toEqual(['X', 'Y', 'Z'])
  })

  it('shows the empty slot when there are no rows', () => {
    const w = mountTable({ rows: [] }, { empty: '<p class="nothing">No data</p>' })
    expect(w.find('.nothing').exists()).toBe(true)
  })

  it('shows the loading slot instead of rows while loading', () => {
    const w = mountTable({ loading: true }, { loading: '<p class="busy">Loading</p>' })
    expect(w.find('.busy').exists()).toBe(true)
    expect(w.findAll('.ui-table__row')).toHaveLength(0)
  })

  it('emits row-click on click and Enter only when clickable', async () => {
    const plain = mountTable()
    await plain.find('.ui-table__row').trigger('click')
    expect(plain.emitted('row-click')).toBeUndefined()

    const w = mountTable({ clickable: true })
    await w.findAll('.ui-table__row')[1].trigger('click')
    await w.findAll('.ui-table__row')[2].trigger('keydown', { key: 'Enter' })
    expect(w.emitted('row-click').map(([r]) => r.id)).toEqual(['b', 'c'])
    expect(w.find('.ui-table__row').attributes('tabindex')).toBe('0')
  })

  it('paginates rows and resets to page 1 when rows change', async () => {
    const many = Array.from({ length: 45 }, (_, i) => ({ id: `r${i}`, name: `n${String(i).padStart(2, '0')}`, size: i, note: '' }))
    const w = mountTable({ rows: many, paginator: true, rowsPerPage: 20 })
    expect(w.findAll('.ui-table__row')).toHaveLength(20)
    expect(names(w)[0]).toBe('n00')

    await w.find('[aria-label="Next page"]').trigger('click')
    expect(names(w)[0]).toBe('n20')

    await w.setProps({ rows: many.slice(0, 30) })
    expect(names(w)[0]).toBe('n00')
  })

  it('hides the paginator when disabled or empty', () => {
    expect(mountTable().find('.ui-table__paginator').exists()).toBe(false)
    expect(mountTable({ paginator: true, rows: [] }).find('.ui-table__paginator').exists()).toBe(false)
  })
})
