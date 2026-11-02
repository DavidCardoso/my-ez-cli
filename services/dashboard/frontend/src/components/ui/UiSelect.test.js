import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import UiSelect from './UiSelect.vue'

const objectOptions = [
  { label: 'All AI statuses', value: 'all' },
  { label: 'Done', value: 'done' },
]

const label = (w) => w.find('.ui-select__label')

describe('UiSelect', () => {
  it('shows the label of the selected object option', () => {
    const w = mount(UiSelect, { props: { options: objectOptions, modelValue: 'done' } })
    expect(label(w).text()).toBe('Done')
  })

  it('supports custom optionLabel / optionValue keys', () => {
    const w = mount(UiSelect, {
      props: { options: [{ name: 'Cloud', key: 'cloud' }], optionLabel: 'name', optionValue: 'key', modelValue: 'cloud' },
    })
    expect(label(w).text()).toBe('Cloud')
  })

  it('shows the placeholder when nothing is selected', () => {
    const w = mount(UiSelect, { props: { options: ['node'], multiple: true, modelValue: [], placeholder: 'All tools' } })
    expect(label(w).text()).toBe('All tools')
    expect(label(w).classes()).toContain('ui-select__label--placeholder')
  })

  it('lists selected values for multiple up to maxSelectedLabels', () => {
    const w = mount(UiSelect, {
      props: { options: ['node', 'npm', 'aws'], multiple: true, maxSelectedLabels: 2, modelValue: ['node', 'npm'] },
    })
    expect(label(w).text()).toBe('node, npm')
  })

  it('collapses to a count beyond maxSelectedLabels', () => {
    const w = mount(UiSelect, {
      props: { options: ['node', 'npm', 'aws'], multiple: true, maxSelectedLabels: 2, modelValue: ['node', 'npm', 'aws'] },
    })
    expect(label(w).text()).toBe('3 selected')
  })

  it('uses the placeholder as the accessible name by default', () => {
    const w = mount(UiSelect, { props: { options: ['node'], placeholder: 'All tools' } })
    expect(w.find('.ui-select').attributes('aria-label')).toBe('All tools')
  })
})
