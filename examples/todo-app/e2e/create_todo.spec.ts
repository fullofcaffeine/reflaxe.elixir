import { test, expect } from '@playwright/test'

test('create todo appears in list and counters update', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')

  // Record baseline list size from h3 headings
  const headings = page.locator('h3')
  const beforeCount = await headings.count()

  // Open form
  await page.getByRole('button', { name: /Add New Todo/i }).click()

  const title = `E2E New ${Date.now()}`
  await page.getByPlaceholder('What needs to be done?').fill(title)
  await page.getByRole('button', { name: /Create Todo/i }).click()

  // Expect the new item to appear and the count to increase by 1
  await expect(page.locator('h3', { hasText: title })).toBeVisible()
  const afterCount = await headings.count()
  expect(afterCount).toBeGreaterThanOrEqual(beforeCount + 1)
})

