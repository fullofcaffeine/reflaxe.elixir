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

async function createTodo(page: Page, title: string) {
  await page.getByTestId('btn-new-todo').click()
  const form = page.locator('form[phx-submit="create_todo"]').first()
  await expect(form.getByTestId('input-title')).toBeVisible({ timeout: 20000 })
  await form.getByTestId('input-title').fill(title)
  await form.getByTestId('btn-create-todo').click()
  await expect(page.locator('h3', { hasText: title }).first()).toBeVisible({ timeout: 20000 })
}

async function switchOrg(page: Page, base: string, slug: string) {
  await page.goto(base + '/org')
  await expect(page.getByTestId('org-title')).toBeVisible({ timeout: 20000 })
  await page.getByTestId('org-input-slug').fill(slug)
  await page.getByTestId('btn-switch-org').click()
  await page.waitForURL('**/todos', { timeout: 20000 })
  await waitForLiveViewConnected(page)
}

test('a signed-in user can switch organizations and see isolated todos', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()

  const orgSlugA = `org-a-${runId}.example.com`
  const orgSlugB = `org-b-${runId}.example.com`

  await login(page, base, `PW Org Switch ${runId}`, `pw-org-switch-${runId}@${orgSlugA}`)

  await expect(page.getByTestId('org-slug')).toHaveText(orgSlugA, { timeout: 20000 })

  const titleA = `Org A Todo ${runId}`
  await createTodo(page, titleA)

  await switchOrg(page, base, orgSlugB)
  await expect(page.getByTestId('org-slug')).toHaveText(orgSlugB, { timeout: 20000 })
  await expect(page.locator('h3', { hasText: titleA })).toHaveCount(0, { timeout: 20000 })

  const titleB = `Org B Todo ${runId}`
  await createTodo(page, titleB)

  await switchOrg(page, base, orgSlugA)
  await expect(page.getByTestId('org-slug')).toHaveText(orgSlugA, { timeout: 20000 })
  await expect(page.locator('h3', { hasText: titleA }).first()).toBeVisible({ timeout: 20000 })
  await expect(page.locator('h3', { hasText: titleB })).toHaveCount(0, { timeout: 20000 })
})

