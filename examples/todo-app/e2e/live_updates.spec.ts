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

  // Edit in session A and expect session B to receive the updated title
  const edited = `LiveEdited ${Date.now()}`
  await cardA.getByTestId('btn-edit-todo').click()
  const editFormA = pageA.locator('form[phx-submit="save_todo"]').first()
  await expect(editFormA).toBeVisible({ timeout: 20000 })
  const editTitleInput = editFormA.getByTestId('input-title').first()
  await editTitleInput.evaluate((el, val) => {
    const input = el as HTMLInputElement
    input.removeAttribute('readonly')
    input.value = val as string
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }, edited)
  await editFormA.getByRole('button', { name: /Save/i }).click()

  await expect(pageA.locator('h3', { hasText: edited })).toBeVisible({ timeout: 20000 })
  await expect(pageB.locator('h3', { hasText: edited })).toBeVisible({ timeout: 20000 })
  await expect(pageB.locator('h3', { hasText: title })).toHaveCount(0)

  // Delete in session A and expect session B to remove it too
  const editedCardA = pageA.locator('[data-testid="todo-card"]', { has: pageA.locator('h3', { hasText: edited }) }).first()
  const editedCardB = pageB.locator('[data-testid="todo-card"]', { has: pageB.locator('h3', { hasText: edited }) }).first()
  await expect(editedCardA).toBeVisible({ timeout: 20000 })
  await expect(editedCardB).toBeVisible({ timeout: 20000 })

  pageA.once('dialog', d => d.accept())
  await editedCardA.getByTestId('btn-delete-todo').click()

  await expect(pageA.locator('h3', { hasText: edited })).toHaveCount(0, { timeout: 20000 })
  await expect(pageB.locator('h3', { hasText: edited })).toHaveCount(0, { timeout: 20000 })

  await ctxA.close()
  await ctxB.close()
})
