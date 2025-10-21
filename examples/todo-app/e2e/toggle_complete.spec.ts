import { test, expect } from '@playwright/test'

test('toggle todo completed state', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForSelector('body.phx-connected', { timeout: 10000 })

  // Create a dedicated todo to toggle
  await page.getByRole('button', { name: /Add New Todo/i }).click()
  const title = `Toggle ${Date.now()}`
  await page.getByPlaceholder('What needs to be done?').fill(title)
  await page.getByRole('button', { name: /Create Todo/i }).click()
  await expect(page.locator('h3', { hasText: title })).toBeVisible()
  const heading = page.locator('h3', { hasText: title }).first()
  const card = heading.locator('xpath=ancestor::div[contains(@class, "rounded-xl")][1]')
  const toggleBtn = card.locator('button[phx-click="toggle_todo"]').first()
  await expect(toggleBtn).toBeVisible()
  await toggleBtn.click()
  // After toggle, the title should gain line-through decoration
  await expect(heading).toHaveClass(/line-through/, { timeout: 10000 })
  await toggleBtn.click()
  await expect(heading).not.toHaveClass(/line-through/, { timeout: 10000 })
})
