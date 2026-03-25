import { defineConfig } from 'vite'
import { existsSync } from 'fs'
import vue from '@vitejs/plugin-vue'

// When running inside Docker (mec npm wrapper), localhost refers to the container.
// Use host.docker.internal to reach the host machine's FastAPI server instead.
const inDocker = existsSync('/.dockerenv')
const apiHost = inDocker ? 'host.docker.internal' : 'localhost'

export default defineConfig({
  plugins: [vue()],
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
  server: {
    proxy: {
      '/api': `http://${apiHost}:4242`,
      '/ws': {
        target: `ws://${apiHost}:4242`,
        ws: true,
      },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    include: ['src/**/*.test.js'],
    exclude: ['tests/e2e/**', 'node_modules/**'],
  },
})
