import { test, expect } from '@playwright/test'

test('clicking a tag filters list and updates counter', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')

  // Ensure at least one todo with tags is visible
  const firstTagBtn = page.locator('button[phx-click="search_todos"]').first()
  await expect(firstTagBtn).toBeVisible()

  // Capture initial total text
  const stats = page.locator('.bg-white >> text=Showing')
  await expect(stats).toBeVisible()
  const beforeText = await stats.first().innerText()

  // Click a tag and expect fewer items (or equal if single tag matches all)
  await firstTagBtn.click()

  // Wait for list to update
  const list = page.locator('#todo-list')
  await expect(list).toBeVisible()

  await expect.poll(async () => await stats.first().innerText(), { timeout: 5000 }).not.toBe(beforeText)
})
