import { test, expect } from '@playwright/test'

test.describe('mec dashboard', () => {
  test('home page loads with stat cards', async ({ page }) => {
    await page.goto('/')
    await expect(page.locator('.page-title')).toContainText('Overview')
    // Four stat cards should be present
    await expect(page.locator('.stat-card')).toHaveCount(4)
  })

  test('sessions page loads and shows table', async ({ page }) => {
    await page.goto('/sessions')
    await expect(page.locator('.page-title')).toContainText('Sessions')
    // Table wrapper should be present
    await expect(page.locator('.table-wrapper')).toBeVisible()
  })

  test('sessions page search input works', async ({ page }) => {
    await page.goto('/sessions')
    const search = page.locator('input[placeholder="Search sessions…"]')
    await expect(search).toBeVisible()
    await search.fill('mec-')
    // After typing, the filter is applied (table still rendered)
    await expect(page.locator('.table-wrapper')).toBeVisible()
  })

  test('sessions table sorts by column header', async ({ page }) => {
    await page.goto('/sessions')
    const toolHeader = page.locator('.table-wrapper th', { hasText: 'Tool' })
    await expect(toolHeader).toHaveAttribute('aria-sort', 'none')
    // Default sort is newest first
    await expect(page.locator('.table-wrapper th', { hasText: 'Timestamp' })).toHaveAttribute('aria-sort', 'descending')

    await toolHeader.getByRole('button').click()
    await expect(toolHeader).toHaveAttribute('aria-sort', 'ascending')
    await toolHeader.getByRole('button').click()
    await expect(toolHeader).toHaveAttribute('aria-sort', 'descending')
  })

  test('sessions tool filter narrows rows and can be cleared', async ({ page }) => {
    await page.goto('/sessions')
    await expect(page.locator('.ui-table__row').first()).toBeVisible()

    const toolFilter = page.getByRole('combobox', { name: 'All tools' })
    await toolFilter.click()
    await page.getByRole('option', { name: 'node' }).click()
    await page.keyboard.press('Escape')

    await expect(toolFilter).toContainText('node')
    const tools = await page.locator('.ui-table__row .tool-tag').allTextContents()
    expect(tools.length).toBeGreaterThan(0)
    expect(tools.every((t) => t.trim() === 'node')).toBe(true)

    await page.getByRole('button', { name: 'Clear' }).click()
    await expect(toolFilter).toContainText('All tools')
  })

  test('tools page loads with tool list', async ({ page }) => {
    await page.goto('/tools')
    await expect(page.locator('.page-title')).toContainText('Tools')
    await expect(page.locator('.table-wrapper')).toBeVisible()
  })

  test('nav links navigate correctly', async ({ page }) => {
    await page.goto('/')
    await page.click('a[href="/sessions"]')
    await expect(page).toHaveURL('/sessions')

    await page.click('a[href="/tools"]')
    await expect(page).toHaveURL('/tools')

    await page.click('a[href="/"]')
    await expect(page).toHaveURL('/')
  })

  test('deep link to session detail serves index.html (SPA fallback)', async ({ page }) => {
    // Even if session doesn't exist, the page should load (not 404)
    const res = await page.goto('/sessions/mec-nonexistent-000')
    expect(res.status()).toBe(200)
    // Vue app should have mounted (nav bar present)
    await expect(page.locator('.navbar')).toBeVisible()
  })

  test('WebSocket status indicator is visible', async ({ page }) => {
    await page.goto('/')
    await expect(page.locator('.ws-status')).toBeVisible()
  })
})
