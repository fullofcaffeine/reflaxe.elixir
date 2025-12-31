import { test, expect, type Page } from '@playwright/test'

async function waitForLiveViewConnected(page: Page) {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })
}

async function login(page: Page, base: string, name: string, email: string) {
  await page.goto(base + '/login')
  await expect(page.locator('h1')).toContainText('Sign in')

  const loginForm = page.locator('form[action="/auth/login"]').filter({
    has: page.locator('input[name="name"][type="text"]'),
  }).first()

  await loginForm.locator('input[name="name"][type="text"]').fill(name)
  await loginForm.locator('input[name="email"][type="email"]').fill(email)
  await loginForm.getByRole('button', { name: /continue/i }).click()

  await page.waitForURL('**/todos', { timeout: 15000 })
  await waitForLiveViewConnected(page)
}

test('optional login + profile edit', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()
  const name = `PW User ${runId}`
  const email = `pw-${runId}@example.com`

  await login(page, base, name, email)
  await expect(page.locator('body')).toContainText(`Welcome, ${name}!`)
  await expect(page.getByTestId('nav-profile-avatar')).toBeVisible()

  await page.getByTestId('nav-profile').click()
  await page.waitForURL('**/profile', { timeout: 10000 })

  await expect(page.getByTestId('profile-avatar')).toBeVisible()
  await page.getByTestId('btn-copy-email').click()
  await expect(page.getByTestId('flash-info')).toContainText(/email copied/i)

  const profileForm = page.locator('form[phx-submit="save_profile"]').first()

  await expect(profileForm.locator('input[name="name"][type="text"]')).toHaveValue(name)
  await expect(profileForm.locator('input[name="email"][type="email"]')).toHaveValue(email)

  const updatedName = `PW User Updated ${runId}`
  await profileForm.locator('input[name="name"][type="text"]').fill(updatedName)
  await profileForm.getByRole('button', { name: /^save$/i }).click()
  await expect(page.getByTestId('flash-info')).toContainText(/profile updated/i)

  await page.getByRole('link', { name: /back to todos/i }).click()
  await page.waitForURL('**/todos', { timeout: 10000 })
  await expect(page.locator('body')).toContainText(`Welcome, ${updatedName}!`)

  await page.getByTestId('nav-sign-out').click()
  await page.waitForURL('**/', { timeout: 10000 })
  await expect(page.locator('body')).toContainText(/demo mode/i)
})
