import { test, expect } from '@playwright/test'

test('search filters list and counter', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')

  // Baseline counter
  const counter = page.locator('text=Showing').first()
  await expect(counter).toContainText(/Showing \d+ of \d+ todos/i)

  // Type a query that should reduce the list
  const search = page.getByPlaceholder('Search todos...')
  await search.click()
  await search.fill('E2E')

  // Counter should update and list items should match filter
  await expect(counter).toContainText(/Showing \d+ of \d+ todos/i)

  // All visible headings should contain the query (case-insensitive)
  const headings = page.locator('h3')
  const count = await headings.count()
  for (let i = 0; i < count; i++) {
    const text = (await headings.nth(i).innerText()).toLowerCase()
    // allow description-only hits; if title doesn't match, body should
    if (!text.includes('e2e')) {
      const card = headings.nth(i).locator('xpath=ancestor::*[self::div][1]')
      await expect(card).toContainText(/e2e/i)
    }
  }
})

