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

test('admin dashboard is restricted to admins', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()

  const adminName = `PW Admin ${runId}`
  const adminEmail = `pw-admin-${runId}@example.com`

  await login(page, base, adminName, adminEmail)

  // First created user becomes admin (server-side rule in Accounts).
  await page.getByTestId('nav-admin').click()
  await page.waitForURL('**/admin', { timeout: 15000 })
  await waitForLiveViewConnected(page)
  await expect(page.getByTestId('admin-title')).toContainText(/admin dashboard/i)
  await expect(page.getByTestId('admin-stat-total-users')).toContainText('1')
  await expect(page.locator('[data-testid="admin-user-role"]').first()).toContainText('admin')

  await page.getByTestId('admin-sign-out').click()
  await page.waitForURL('**/', { timeout: 10000 })

  const userName = `PW User ${runId}`
  const userEmail = `pw-user-${runId}@example.com`
  await login(page, base, userName, userEmail)

  // Non-admins should be redirected away.
  await page.goto(base + '/admin')
  await page.waitForURL('**/todos', { timeout: 15000 })
  await expect(page.getByTestId('flash-error')).toContainText(/admins only/i)
  await expect(page.getByTestId('nav-admin')).toHaveCount(0)
})

