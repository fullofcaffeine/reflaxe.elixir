import { test, expect } from '@playwright/test'

test('delete todo removes it from list', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForSelector('body.phx-connected', { timeout: 10000 })

  // Create a fresh todo to delete
  await page.getByRole('button', { name: /Add New Todo/i }).click()
  const title = `Delete Me ${Date.now()}`
  await page.getByPlaceholder('What needs to be done?').fill(title)
  await page.getByRole('button', { name: /Create Todo/i }).click()
  const card = page.locator('h3', { hasText: title }).first()
    .locator('xpath=ancestor::div[contains(@class, "rounded-xl")][1]')

  // Accept the browser confirm dialog when deleting
  page.on('dialog', async (dialog) => { await dialog.accept() })
  await card.locator('button[phx-click="delete_todo"]').click()

  // Assert it is gone
  await expect(page.locator('h3', { hasText: title })).toHaveCount(0, { timeout: 10000 })
})
