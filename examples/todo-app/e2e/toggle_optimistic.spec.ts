import { test, expect } from '@playwright/test'

test('optimistic toggle flips immediately and persists after reload', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')

  const card = page.locator('[data-testid="todo-card"]').first()
  await expect(card).toBeVisible()

  const before = await card.getAttribute('data-completed')
  const expected = before === 'true' ? 'false' : 'true'

  const toggleBtn = card.getByTestId('btn-toggle-todo').first()
  await toggleBtn.click()

  // Expect flip quickly (optimistic assign-first)
  await expect(card).toHaveAttribute('data-completed', expected, { timeout: 1500 })

  // Reload to confirm DB persistence
  await page.reload()
  const cardAfter = page.locator('[data-testid="todo-card"]').first()
  await expect(cardAfter).toHaveAttribute('data-completed', expected, { timeout: 3000 })
})
