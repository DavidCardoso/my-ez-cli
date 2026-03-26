import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30000,
  retries: 1,
  workers: 1,

  use: {
    baseURL: 'http://localhost:4242',
    headless: true,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // Start FastAPI backend before running e2e tests (in CI, the server is started externally)
  // For local dev: `mec dashboard start` or `uvicorn src.main:app --port 4242` from services/dashboard/
  webServer: process.env.CI
    ? undefined
    : {
        command: 'cd ../.. && uvicorn src.main:app --host 0.0.0.0 --port 4242',
        url: 'http://localhost:4242',
        reuseExistingServer: true,
        timeout: 10000,
      },
})
