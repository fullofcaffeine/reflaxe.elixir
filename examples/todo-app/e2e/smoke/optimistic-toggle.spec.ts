import { test, expect } from '@playwright/test'

test('optimistic toggle flips immediately', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  // Create a unique todo to act upon
  const title = `E2E Toggle ${Date.now()}`
  await page.getByTestId('btn-new-todo').click()
  const form = page.locator('form[phx-submit="create_todo"]').first()
  await expect(form).toBeVisible({ timeout: 15000 })
  await page.getByTestId('input-title').fill(title)
  await page.getByTestId('btn-create-todo').click()
  const card = page.locator('[data-testid="todo-card"]').filter({ has: page.getByRole('heading', { name: title }) })
  await expect(card).toBeVisible({ timeout: 15000 })

  // Assert initial state is incomplete
  await expect(card).toHaveAttribute('data-completed', 'false')

  // Click toggle and expect immediate flip (optimistic UI)
  await card.getByTestId('btn-toggle-todo').click()
  const checkbox = card.getByTestId('btn-toggle-todo')
  await expect.poll(async () => await checkbox.innerText(), { timeout: 2000 }).toContain('✓')
  await expect(card).toHaveAttribute('data-completed', 'true', { timeout: 2500 })
})
