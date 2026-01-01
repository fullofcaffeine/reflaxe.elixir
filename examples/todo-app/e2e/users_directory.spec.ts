import { test, expect, type Page } from '@playwright/test'

async function waitForLiveViewConnected(page: Page) {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })
}

async function login(page: Page, base: string, name: string, email: string) {
  await page.goto(base + '/login')
  await expect(page.locator('h1')).toContainText('Sign in')

  const loginForm = page
    .locator('form[action="/auth/login"]')
    .filter({
      has: page.locator('input[name="name"][type="text"]'),
    })
    .first()

  await loginForm.locator('input[name="name"][type="text"]').fill(name)
  await loginForm.locator('input[name="email"][type="email"]').fill(email)
  await loginForm.getByRole('button', { name: /continue/i }).click()

  await page.waitForURL('**/todos', { timeout: 15000 })
  await waitForLiveViewConnected(page)
}

test('users directory search + toggle active', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()
  const domain = `users-${runId}.example.com`
  const name = `PW Directory ${runId}`
  const email = `pw-dir-${runId}@${domain}`

  await login(page, base, name, email)

  await page.getByTestId('nav-users').click()
  await page.waitForURL('**/users', { timeout: 10000 })

  await expect(page.locator('h1')).toContainText('Users')

  await page.getByTestId('users-search').fill(email)
  await expect(page.locator('[data-testid="users-row"]')).toHaveCount(1, { timeout: 20000 })
  await expect(page.locator('[data-testid="users-row"]')).toContainText(email)
  await expect(page.locator('[data-testid="user-avatar"]')).toHaveCount(1, { timeout: 20000 })

  await page.getByTestId('users-toggle-active').first().click()
  await expect(page.getByTestId('flash-info')).toBeVisible({ timeout: 20000 })

  await page.getByTestId('users-status').selectOption('inactive')
  await expect(page.locator('[data-testid="users-row"]')).toHaveCount(1, { timeout: 20000 })
  await expect(page.locator('[data-testid="users-row"]')).toContainText(email)
})
