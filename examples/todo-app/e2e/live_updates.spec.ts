import { test, expect, type Page } from '@playwright/test'

async function waitForLiveViewConnected(page: Page) {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
}

test('two sessions receive live updates (PubSub)', async ({ page, context }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await waitForLiveViewConnected(page)

  // Second session
  const page2 = await context.newPage()
  await page2.goto(base + '/todos')
  await waitForLiveViewConnected(page2)

  const title = `E2E LiveUpdate ${Date.now()}`

  // Create in session 1 and assert session 2 receives without reload
  await page.getByTestId('btn-new-todo').click()
  const form = page.locator('form[phx-submit="create_todo"]').first()
  await expect(form.getByTestId('input-title')).toBeVisible({ timeout: 15000 })
  await form.getByTestId('input-title').fill(title)
  await form.getByTestId('btn-create-todo').click()

  const heading1 = page.locator('h3', { hasText: title }).first()
  const card1 = heading1.locator('xpath=ancestor::*[@data-testid="todo-card"][1]')
  await expect(card1).toBeVisible({ timeout: 15000 })

  const heading2 = page2.locator('h3', { hasText: title }).first()
  const card2 = heading2.locator('xpath=ancestor::*[@data-testid="todo-card"][1]')
  await expect(card2).toBeVisible({ timeout: 15000 })

  // Toggle completion in session 1
  await card1.getByTestId('btn-toggle-todo').click()

  // Session 2 should reflect the update without reload (line-through title class)
  await expect.poll(
    async () => await card2.locator('h3').getAttribute('class'),
    { timeout: 15000 }
  ).toMatch(/line-through/)

  // Edit in session 1 and assert session 2 updates the heading
  await card1.getByTestId('btn-edit-todo').click()
  const editForm = page.locator('form[phx-submit="save_todo"]').first()
  await expect(editForm).toBeVisible({ timeout: 20000 })
  const editCard = editForm.locator('xpath=ancestor::*[@data-testid="todo-card"][1]')
  const updated = `E2E LiveUpdate Edited ${Date.now()}`
  const editInput = editCard.getByTestId('input-title').first()
  await expect(editInput).toBeVisible({ timeout: 20000 })
  await page.waitForFunction(() => {
    const el = document.querySelector('[data-testid="input-title"]') as HTMLInputElement | null
    return !!el && !el.hasAttribute('readonly')
  }, { timeout: 20000 })
  await editInput.evaluate((el, val) => {
    const input = el as HTMLInputElement
    input.removeAttribute('readonly')
    input.value = val as string
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }, updated)
  await editCard.locator('textarea[name="description"]').first().fill('')
  await editCard.getByRole('button', { name: /Save/i }).click()

  await expect(page2.locator('h3', { hasText: updated })).toBeVisible({ timeout: 20000 })

  // Delete in session 1 and assert session 2 removes without reload
  page.once('dialog', async (dialog) => { await dialog.accept() })
  await page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: updated }) }).first().getByTestId('btn-delete-todo').click()
  await expect(page2.locator('h3', { hasText: updated })).toHaveCount(0, { timeout: 20000 })

  await page2.close()
})
