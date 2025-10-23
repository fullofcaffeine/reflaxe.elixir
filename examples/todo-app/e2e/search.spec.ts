import { test, expect } from '@playwright/test'

function parseCounter(text: string): { shown: number; total: number } | null {
  const m = text.match(/Showing\s+(\d+)\s+of\s+(\d+)\s+todos/i)
  return m ? { shown: parseInt(m[1], 10), total: parseInt(m[2], 10) } : null
}

test('search filters list and counter', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  const counter = page.locator('text=Showing').first()
  await expect(counter).toContainText(/Showing \d+ of \d+ todos/i)

  // Capture baseline counts
  const baselineText = await counter.innerText()
  const baseline = parseCounter(baselineText)
  expect(baseline).not.toBeNull()
  const cards = page.locator('[data-testid="todo-card"]')
  const baselineItems = await cards.count()

  // Type a query that should reduce the list
  const search = page.getByPlaceholder('Search todos...')
  await search.click()
  await search.fill('E2E')

  // Wait for counter to change or for list to shrink (stabilize list)
  await expect(counter).toContainText(/Showing \d+ of \d+ todos/i)
  await expect.poll(async () => await cards.count(), { timeout: 5000 }).toBeLessThanOrEqual(baselineItems)
  const afterText = await counter.innerText()
  const after = parseCounter(afterText)
  expect(after).not.toBeNull()

  const afterItems = await cards.count()
  // Expect reduced or equal shown count, but prefer a reduction for a selective query
  expect(after!.shown).toBeLessThanOrEqual(baseline!.shown)
  expect(afterItems).toBeLessThanOrEqual(baselineItems)

  // All visible cards should include the query in title or body
  for (let i = 0; i < afterItems; i++) {
    const card = cards.nth(i)
    await expect(card).toBeVisible()
    await expect(card).toContainText(/e2e/i)
  }
})
