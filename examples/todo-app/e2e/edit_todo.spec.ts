import { test, expect } from '@playwright/test'

test('edit todo updates title', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForSelector('body.phx-connected', { timeout: 10000 })

  // Create a fresh todo to edit
  await page.getByRole('button', { name: /Add New Todo/i }).click()
  const original = `Edit Me ${Date.now()}`
  await page.getByPlaceholder('What needs to be done?').fill(original)
  await page.getByRole('button', { name: /Create Todo/i }).click()
  const heading = page.locator('h3', { hasText: original }).first()
  const card = heading.locator('xpath=ancestor::div[contains(@class, "rounded-xl")][1]')

  // Open edit form
  await card.locator('button[phx-click="edit_todo"]').click()
  await expect(card.locator('form')).toBeVisible({ timeout: 10000 })

  const updated = `Edited ${Date.now()}`
  await card.locator('input[name="title"]').first().fill(updated)
  await card.getByRole('button', { name: /Save/i }).click()

  // Assert the updated title is visible
  await expect(page.locator('h3', { hasText: updated })).toBeVisible({ timeout: 10000 })
})
