import { config } from '@vue/test-utils'

// Stub RouterLink globally so tests don't need a full router
config.global.stubs = {
  ...config.global.stubs,
  RouterLink: { template: '<a><slot /></a>' },
}

// Register v-tooltip as a no-op directive globally
config.global.directives = {
  ...config.global.directives,
  tooltip: {},
}
