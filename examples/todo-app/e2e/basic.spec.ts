import { test, expect } from '@playwright/test'

test('home + todos render', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/')
  await expect(page).toHaveTitle(/Todo/i)
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await expect(page.locator('body')).toContainText(/Todo/i)
})
