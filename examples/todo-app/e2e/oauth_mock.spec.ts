import { test, expect, type Page } from '@playwright/test'

async function waitForLiveViewConnected(page: Page) {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })
}

test('mock OAuth sign-in (deterministic)', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'

  await page.goto(base + '/login')
  await expect(page.locator('h1')).toContainText('Sign in')

  await expect(page.getByTestId('btn-mock-oauth')).toBeVisible()
  await page.getByTestId('btn-mock-oauth').click()

  await page.waitForURL('**/todos', { timeout: 15000 })
  await waitForLiveViewConnected(page)

  await expect(page.locator('body')).toContainText(/welcome,\s*mock oauth user/i)

  await page.getByTestId('nav-sign-out').click()
  await page.waitForURL('**/', { timeout: 10000 })
  await expect(page.locator('body')).toContainText(/demo mode/i)
})

