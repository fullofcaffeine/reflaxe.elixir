import { test, expect } from '@playwright/test'

test('toggling a todo reflects immediately in UI', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')

  // Find first todo card and its toggle button
  const card = page.locator('[data-testid="todo-card"]').first()
  await expect(card).toBeVisible()

  // Read initial completed state
  const beforeCompleted = await card.getAttribute('data-completed')

  // Click the toggle button on the first card
  const toggleBtn = card.locator('button[phx-click="toggle_todo"]')
  await toggleBtn.click()

  // UI should reflect change quickly (optimistic assign)
  await expect(card).toHaveAttribute('data-completed', beforeCompleted === 'true' ? 'false' : 'true')
})

