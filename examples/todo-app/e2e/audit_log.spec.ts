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

test('role updates are recorded and visible in the audit log', async ({ browser }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()
  const domain = `audit-${runId}.example.com`

  const adminName = `PW Audit Admin ${runId}`
  const adminEmail = `pw-audit-admin-${runId}@${domain}`

  const userName = `PW Audit User ${runId}`
  const userEmail = `pw-audit-user-${runId}@${domain}`

  const adminContext = await browser.newContext()
  const adminPage = await adminContext.newPage()
  await login(adminPage, base, adminName, adminEmail)

  const userContext = await browser.newContext()
  const userPage = await userContext.newPage()
  await login(userPage, base, userName, userEmail)

  // Promote the user via the org admin UI (this should emit an audit log entry).
  await adminPage.goto(base + '/org')
  await expect(adminPage.getByTestId('members-title')).toBeVisible({ timeout: 20000 })

  const memberRow = adminPage
    .getByTestId('member-row')
    .filter({ hasText: userEmail })
    .first()

  await expect(memberRow).toBeVisible({ timeout: 20000 })
  await memberRow.getByTestId('member-role-select').selectOption('admin')
  await memberRow.getByTestId('btn-save-role').click()

  await expect(adminPage.getByTestId('flash-info')).toContainText(/role updated/i, { timeout: 20000 })

  // Verify the audit log page contains the new entry.
  await adminPage.goto(base + '/admin/audit')
  await waitForLiveViewConnected(adminPage)
  await expect(adminPage.getByTestId('audit-title')).toBeVisible({ timeout: 20000 })

  const matchingRow = adminPage
    .getByTestId('audit-row')
    .filter({ hasText: 'user.role_updated' })
    .filter({ hasText: userEmail })
    .first()

  await expect(matchingRow).toBeVisible({ timeout: 20000 })

  await userContext.close()
  await adminContext.close()
})

