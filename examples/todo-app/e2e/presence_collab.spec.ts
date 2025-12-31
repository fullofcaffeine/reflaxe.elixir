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
  await expect(page.locator('body')).toContainText(`Welcome, ${name}!`, { timeout: 15000 })
}

test('presence shows online users and editing badges', async ({ browser }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const runId = Date.now()

  const ctxA = await browser.newContext()
  const pageA = await ctxA.newPage()
  const nameA = `PW A ${runId}`
  const emailA = `pw-a-${runId}@example.com`
  await login(pageA, base, nameA, emailA)

  const ctxB = await browser.newContext()
  const pageB = await ctxB.newPage()
  const nameB = `PW B ${runId}`
  const emailB = `pw-b-${runId}@example.com`
  await login(pageB, base, nameB, emailB)

  // Both sessions should see both users online
  await expect(pageA.getByTestId('online-count')).toContainText('2', { timeout: 20000 })
  await expect(pageB.getByTestId('online-count')).toContainText('2', { timeout: 20000 })

  const title = `E2E Presence Collab ${runId}`

  // Create a todo in session A and assert it appears in session B without reload
  await pageA.getByTestId('btn-new-todo').click()
  const formA = pageA.locator('form[phx-submit="create_todo"]').first()
  await expect(formA.getByTestId('input-title')).toBeVisible({ timeout: 20000 })
  await formA.getByTestId('input-title').fill(title)
  await formA.getByTestId('btn-create-todo').click()

  const headingA = pageA.locator('h3', { hasText: title }).first()
  const cardA = headingA.locator('xpath=ancestor::*[@data-testid="todo-card"][1]')
  await expect(cardA).toBeVisible({ timeout: 20000 })

  const headingB = pageB.locator('h3', { hasText: title }).first()
  const cardB = headingB.locator('xpath=ancestor::*[@data-testid="todo-card"][1]')
  await expect(cardB).toBeVisible({ timeout: 20000 })

  // Start editing in session A; session B should show an editing badge with A's name.
  await cardA.getByTestId('btn-edit-todo').click()
  await expect(cardB.getByTestId('editing-badge')).toContainText(nameA, { timeout: 20000 })

  await ctxA.close()
  await ctxB.close()
})
