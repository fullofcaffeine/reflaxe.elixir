import { test, expect } from '@playwright/test'

test('home + todos render', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/')
  await expect(page).toHaveTitle(/Todo/i)
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await expect(page.locator('body')).toContainText(/Todo/i)
  // DOM shape: list container exists
  await expect(page.locator('#todo-list')).toHaveCount(1)
  // Guard: no escaped HTML should be visible as text
  const bodyText = await page.locator('body').innerText()
  expect(bodyText).not.toMatch(/<\/?(div|span|button|h[1-6]|p|ul|li)(\s|>)/i)
})
