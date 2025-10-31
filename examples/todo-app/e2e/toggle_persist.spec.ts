import { test, expect } from '@playwright/test'

test('toggle completion persists across reload', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  // Create a fresh todo
  await page.getByTestId('btn-new-todo').click()
  const title = `Persist ${Date.now()}`
  const titleInput = page.getByTestId('input-title')
  await expect(titleInput).toBeVisible({ timeout: 15000 })
  await titleInput.fill(title)
  await page.getByTestId('btn-create-todo').click()

  const card = page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: title }) }).first()
  await expect(card).toBeVisible({ timeout: 20000 })

  // Toggle to completed and verify
  await card.getByTestId('btn-toggle-todo').first().click()
  await expect.poll(async () => (await card.getAttribute('data-completed')) || '').toBe('true')

  // Reload page and verify completion persisted
  await page.reload({ waitUntil: 'networkidle' })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })
  const cardAfter = page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: title }) }).first()
  await expect(cardAfter).toBeVisible({ timeout: 20000 })
  await expect.poll(async () => (await cardAfter.getAttribute('data-completed')) || '').toBe('true')

  // Toggle back to active, reload, and verify persistence again
  await cardAfter.getByTestId('btn-toggle-todo').first().click()
  await expect.poll(async () => (await cardAfter.getAttribute('data-completed')) || '').toBe('false')
  await page.reload({ waitUntil: 'networkidle' })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })
  const cardFinal = page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: title }) }).first()
  await expect(cardFinal).toBeVisible({ timeout: 20000 })
  await expect.poll(async () => (await cardFinal.getAttribute('data-completed')) || '').toBe('false')
})

