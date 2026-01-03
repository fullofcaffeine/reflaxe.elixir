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

test('creating an invite delivers an email (mailbox preview)', async ({ browser }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()

  const orgSlug = `mailbox-org-${runId}.example.com`
  const adminEmail = `pw-mailbox-admin-${runId}@${orgSlug}`
  const inviteeEmail = `pw-mailbox-invitee-${runId}@invitee-${runId}.example.com`

  const ctx = await browser.newContext()
  const page = await ctx.newPage()

  await login(page, base, `PW Mailbox Admin ${runId}`, adminEmail)

  await page.goto(base + '/org')
  await expect(page.getByTestId('org-title')).toBeVisible({ timeout: 20000 })

  await page.getByTestId('invite-email').fill(inviteeEmail)
  await page.getByTestId('invite-role').selectOption('user')
  await page.getByTestId('btn-invite').click()

  await expect(page.getByTestId('flash-info')).toContainText(/email sent/i, { timeout: 20000 })

  await page.goto(base + '/dev/mailbox')
  await expect(page.locator('body')).toContainText(inviteeEmail, { timeout: 20000 })

  await ctx.close()
})

