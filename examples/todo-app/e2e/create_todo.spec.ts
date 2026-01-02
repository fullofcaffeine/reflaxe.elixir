import { test, expect } from '@playwright/test'

test('create todo appears in list and counters update', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  // Record baseline list size from h3 headings
  const headings = page.locator('h3')
  const beforeCount = await headings.count()

  // Open form deterministically
  const newTodoButton = page.getByTestId('btn-new-todo')
  await expect(newTodoButton).toHaveAttribute('phx-click', 'toggle_form')
  await newTodoButton.click()
  const form = page.locator('form[phx-submit="create_todo"]').first()
  await expect(form).toBeVisible({ timeout: 15000 })
  const titleInput = page.getByTestId('input-title')
  await expect(titleInput).toBeVisible({ timeout: 15000 })

  const title = `E2E New ${Date.now()}`
  await titleInput.fill(title)
  await page.getByTestId('btn-create-todo').click()

  // Expect the new item to appear and the count to increase by 1
  await expect(page.locator('h3', { hasText: title })).toBeVisible({ timeout: 15000 })
  const afterCount = await headings.count()
  expect(afterCount).toBeGreaterThanOrEqual(beforeCount + 1)
})
