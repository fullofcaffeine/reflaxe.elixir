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

test('invites can be created by an admin and are accepted on login', async ({ browser }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()

  const orgSlug = `invite-org-${runId}.example.com`
  const adminEmail = `pw-inviter-${runId}@${orgSlug}`

  const inviteeDomain = `invitee-domain-${runId}.example.com`
  const inviteeEmail = `pw-invitee-${runId}@${inviteeDomain}`

  const adminContext = await browser.newContext()
  const adminPage = await adminContext.newPage()

  await login(adminPage, base, `PW Inviter ${runId}`, adminEmail)
  await expect(adminPage.getByTestId('org-slug')).toHaveText(orgSlug, { timeout: 20000 })

  await adminPage.goto(base + '/org')
  await expect(adminPage.getByTestId('org-title')).toBeVisible({ timeout: 20000 })

  await expect(adminPage.getByTestId('invite-email')).toBeVisible({ timeout: 20000 })
  await adminPage.getByTestId('invite-email').fill(inviteeEmail)
  await adminPage.getByTestId('invite-role').selectOption('admin')
  await adminPage.getByTestId('btn-invite').click()

  await expect(adminPage.locator('body')).toContainText(inviteeEmail, { timeout: 20000 })

  const inviteeContext = await browser.newContext()
  const inviteePage = await inviteeContext.newPage()

  await login(inviteePage, base, `PW Invitee ${runId}`, inviteeEmail)

  // The invite should override the domain-derived organization assignment.
  await expect(inviteePage.getByTestId('org-slug')).toHaveText(orgSlug, { timeout: 20000 })

  await inviteePage.goto(base + '/org')
  await expect(inviteePage.getByTestId('org-current-slug')).toHaveText(orgSlug, { timeout: 20000 })

  // Invited as admin, so the invites section should be visible and show acceptance.
  await expect(inviteePage.getByTestId('invite-email')).toBeVisible({ timeout: 20000 })
  await expect(inviteePage.locator('body')).toContainText(inviteeEmail, { timeout: 20000 })
  await expect(inviteePage.locator('body')).toContainText('Accepted', { timeout: 20000 })

  await inviteeContext.close()
  await adminContext.close()
})
