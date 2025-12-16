import { test, expect } from '@playwright/test'

test('live updates propagate across two sessions', async ({ browser }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'

  const ctxA = await browser.newContext()
  const ctxB = await browser.newContext()
  const pageA = await ctxA.newPage()
  const pageB = await ctxB.newPage()

  await pageA.goto(base + '/todos')
  await pageB.goto(base + '/todos')
  await pageA.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })
  await pageB.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })

  const title = `Live ${Date.now()}`
  const tag = `lv-${Date.now()}`

  // Create a todo in session A
  await pageA.getByTestId('btn-new-todo').click()
  const formA = pageA.locator('form[phx-submit="create_todo"]').first()
  await expect(formA).toBeVisible({ timeout: 20000 })
  await pageA.getByTestId('input-title').fill(title)
  await pageA.locator('input[name="tags"]').fill(tag)
  await pageA.getByTestId('btn-create-todo').click()

  const cardA = pageA.locator('[data-testid="todo-card"]', { has: pageA.locator('h3', { hasText: title }) }).first()
  await expect(cardA).toBeVisible({ timeout: 20000 })

  // Expect session B to receive the new todo without reload
  const cardB = pageB.locator('[data-testid="todo-card"]', { has: pageB.locator('h3', { hasText: title }) }).first()
  await expect(cardB).toBeVisible({ timeout: 20000 })

  // Toggle completion in session A and expect session B to reflect it
  const before = (await cardA.getAttribute('data-completed')) || 'false'
  const expected = before === 'true' ? 'false' : 'true'
  await cardA.getByTestId('btn-toggle-todo').first().click()

  await expect.poll(async () => (await cardB.getAttribute('data-completed')) || '', { timeout: 20000 }).toBe(expected)

  await ctxA.close()
  await ctxB.close()
})

