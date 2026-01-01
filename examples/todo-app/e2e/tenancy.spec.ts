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

test('todos are isolated per organization', async ({ browser }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()

  const orgDomainA = `tenant-a-${runId}.example.com`
  const orgDomainB = `tenant-b-${runId}.example.com`

  const ctxA = await browser.newContext()
  const pageA = await ctxA.newPage()
  const nameA = `PW Tenant A ${runId}`
  const emailA = `pw-tenant-a-${runId}@${orgDomainA}`
  await login(pageA, base, nameA, emailA)

  const title = `E2E Tenancy ${runId}`
  await pageA.getByTestId('btn-new-todo').click()
  const formA = pageA.locator('form[phx-submit="create_todo"]').first()
  await expect(formA.getByTestId('input-title')).toBeVisible({ timeout: 20000 })
  await formA.getByTestId('input-title').fill(title)
  await formA.getByTestId('btn-create-todo').click()
  await expect(pageA.locator('h3', { hasText: title }).first()).toBeVisible({ timeout: 20000 })

  const ctxB = await browser.newContext()
  const pageB = await ctxB.newPage()
  const nameB = `PW Tenant B ${runId}`
  const emailB = `pw-tenant-b-${runId}@${orgDomainB}`
  await login(pageB, base, nameB, emailB)

  await expect(pageB.locator('h3', { hasText: title })).toHaveCount(0, { timeout: 20000 })

  await ctxA.close()
  await ctxB.close()
})

