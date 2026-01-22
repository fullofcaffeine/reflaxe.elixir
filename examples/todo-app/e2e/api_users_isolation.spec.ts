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

test('api users are isolated per organization', async ({ browser }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()

  const domainA = `api-users-org-a-${runId}.example.com`
  const domainB = `api-users-org-b-${runId}.example.com`

  const ctxA = await browser.newContext()
  const pageA = await ctxA.newPage()
  const adminAEmail = `pw-admin-a-${runId}@${domainA}`
  await login(pageA, base, `PW Admin A ${runId}`, adminAEmail)

  const ctxB = await browser.newContext()
  const pageB = await ctxB.newPage()
  const adminBEmail = `pw-admin-b-${runId}@${domainB}`
  await login(pageB, base, `PW Admin B ${runId}`, adminBEmail)

  const orgBUserEmail = `pw-user-b-${runId}@${domainB}`
  const createRes = await pageB.request.post(base + '/api/users', {
    headers: { accept: 'application/json' },
    data: { name: `PW OrgB User ${runId}`, email: orgBUserEmail },
  })
  expect(createRes.status()).toBe(201)
  const createBody = (await createRes.json()) as { user: { id: number; email: string } }
  expect(createBody.user.email).toBe(orgBUserEmail)

  const listRes = await pageA.request.get(base + '/api/users', { headers: { accept: 'application/json' } })
  expect(listRes.status()).toBe(200)
  const listBody = (await listRes.json()) as { users: Array<{ email: string }> }
  const emails = listBody.users.map((u) => u.email)
  expect(emails).toContain(adminAEmail)
  expect(emails).not.toContain(orgBUserEmail)

  const showRes = await pageA.request.get(base + `/api/users/${createBody.user.id}`, {
    headers: { accept: 'application/json' },
  })
  expect(showRes.status()).toBe(404)

  const updateRes = await pageA.request.put(base + `/api/users/${createBody.user.id}`, {
    headers: { accept: 'application/json' },
    data: { name: `HACKED ${runId}` },
  })
  expect(updateRes.status()).toBe(404)

  await ctxA.close()
  await ctxB.close()
})

