import { config } from '@vue/test-utils'

// jsdom has no ResizeObserver; Reka UI uses it to size popovers and tooltips
globalThis.ResizeObserver ??= class {
  observe() {}
  unobserve() {}
  disconnect() {}
}

// Stub RouterLink globally so tests don't need a full router
config.global.stubs = {
  ...config.global.stubs,
  RouterLink: { template: '<a><slot /></a>' },
}

