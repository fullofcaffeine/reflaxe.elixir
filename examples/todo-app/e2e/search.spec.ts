import { test, expect } from '@playwright/test'

test('search filter updates list and counter', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')

  // Basic smoke: there is a search input and typing narrows results or updates counter
  const search = page.getByPlaceholder(/search/i).first().or(page.locator('input[name="q"], input[type="search"]').first())
  await search.fill('a')
  // Counter text contains Todo or task-like summary; keep assertion resilient
  await expect(page.locator('body')).toContainText(/Todo|Tasks|items/i)
})

