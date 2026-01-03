import { test, expect, type Page } from '@playwright/test'

async function waitForLiveViewConnected(page: Page) {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })
}

async function login(page: Page, base: string, name: string, email: string) {
  await page.goto(base + '/login')
  await expect(page.locator('h1')).toContainText('Sign in')

  const loginForm = page
    .locator('form[action=\"/auth/login\"]')
    .filter({
      has: page.locator('input[name=\"name\"][type=\"text\"]'),
    })
    .first()

  await loginForm.locator('input[name=\"name\"][type=\"text\"]').fill(name)
  await loginForm.locator('input[name=\"email\"][type=\"email\"]').fill(email)
  await loginForm.getByRole('button', { name: /continue/i }).click()

  await page.waitForURL('**/todos', { timeout: 15000 })
  await waitForLiveViewConnected(page)
}

async function switchOrg(page: Page, base: string, slug: string) {
  await page.goto(base + '/org')
  await expect(page.getByTestId('org-title')).toBeVisible({ timeout: 20000 })
  await page.getByTestId('org-input-slug').fill(slug)
  await page.getByTestId('btn-switch-org').click()
  await page.waitForURL('**/todos', { timeout: 20000 })
  await waitForLiveViewConnected(page)
}

test('org members UI disables demotion of the last admin', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()
  const loginDomain = `login-last-admin-${runId}.example.com`
  const slug = `org-last-admin-${runId}.example.com`
  const name = `PW Last Admin ${runId}`
  const email = `pw-last-admin-${runId}@${loginDomain}`

  await login(page, base, name, email)
  await switchOrg(page, base, slug)

  await page.goto(base + '/org')
  await expect(page.getByTestId('members-title')).toBeVisible({ timeout: 20000 })

  const memberRow = page.getByTestId('member-row').filter({ hasText: email }).first()
  await expect(memberRow).toBeVisible({ timeout: 20000 })
  await expect(memberRow.getByTestId('last-admin-badge')).toBeVisible()

  await expect(memberRow.getByTestId('member-role-select')).toBeDisabled()
  await expect(memberRow.getByTestId('btn-save-role')).toBeDisabled()
})
