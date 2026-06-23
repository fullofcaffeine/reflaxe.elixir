import { expect, test } from '@playwright/test'

test('opens the RailsHx-inspired PhoenixHx todo board and persists LiveView changes', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4017'

  await page.goto(base + '/todos')
  await expect(page.getByText('Same todo room, Phoenix rules.')).toBeVisible()
  await page.getByRole('button', { name: 'Continue as guest' }).click()

  await expect(page.getByText('Typed Phoenix, live BEAM state.')).toBeVisible()
  await expect(page.locator('[data-testid="todo-item"]')).toHaveCount(3)

  await page.getByPlaceholder('Write the Phoenix LiveView port').fill('Keep the RailsHx UX')
  await page.getByPlaceholder('Add a short implementation note').fill('But use LiveView events')
  await page.getByRole('button', { name: 'Add task' }).click()

  await expect(page.locator('[data-testid="todo-item"]')).toHaveCount(4)
  await expect(page.locator('[data-testid="todo-item"]').first()).toContainText('Keep the RailsHx UX')

  await page.locator('[data-testid="todo-item"]').first().getByRole('button', { name: 'Done' }).click()
  await expect(page.locator('[data-testid="todo-item"]').first()).toHaveClass(/is-complete/)

  await page.locator('[data-testid="todo-item"]').first().getByRole('button', { name: 'Delete' }).click()
  await expect(page.locator('[data-testid="todo-item"]')).toHaveCount(3)
  await expect(page.getByText('The Rails API is not being emulated.')).toBeVisible()
})
