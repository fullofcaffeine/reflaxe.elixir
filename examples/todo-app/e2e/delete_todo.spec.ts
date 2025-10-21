import { test, expect } from '@playwright/test'

test('delete todo removes it from list', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  // Create a fresh todo to delete
  await page.getByTestId('btn-new-todo').click()
  await expect(page.locator('form[phx-submit="create_todo"]').first()).toBeVisible({ timeout: 15000 })
  const title = `Delete Me ${Date.now()}`
  const titleInput = page.getByTestId('input-title')
  await expect(titleInput).toBeVisible({ timeout: 15000 })
  await titleInput.fill(title)
  await page.getByTestId('btn-create-todo').click()
  const card = page.locator('h3', { hasText: title }).first()
    .locator('xpath=ancestor::div[contains(@class, "rounded-xl")][1]')

  // Accept the browser confirm dialog when deleting (single-use)
  page.once('dialog', async (dialog) => { await dialog.accept() })
  await card.getByTestId('btn-delete-todo').click()

  // Assert it is gone (robust wait)
  await page.waitForFunction(
    (text) => !Array.from(document.querySelectorAll('h3')).some(h => h.textContent?.includes(text)),
    title,
    { timeout: 15000 }
  )
})
