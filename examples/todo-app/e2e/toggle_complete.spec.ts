import { test, expect } from '@playwright/test'

test('toggle todo completed state', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  // Create a dedicated todo to toggle
  await page.getByTestId('btn-new-todo').click()
  await expect(page.locator('form[phx-submit="create_todo"]').first()).toBeVisible({ timeout: 15000 })
  const title = `Toggle ${Date.now()}`
  const titleInput = page.getByTestId('input-title')
  await expect(titleInput).toBeVisible({ timeout: 15000 })
  await titleInput.fill(title)
  await page.getByTestId('btn-create-todo').click()
  await expect(page.locator('h3', { hasText: title })).toBeVisible()
  const heading = page.locator('h3', { hasText: title }).first()
  const card = heading.locator('xpath=ancestor::div[contains(@class, "rounded-xl")][1]')
  const toggleBtn = card.getByTestId('btn-toggle-todo').first()
  await expect(toggleBtn).toBeVisible()
  await toggleBtn.click()
  // Reload to verify persisted completion state deterministically
  await page.reload()
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await page.waitForFunction(
    (text) => !!Array.from(document.querySelectorAll('h3'))
      .find(h => h.textContent?.includes(text) && h.className.includes('line-through')),
    title,
    { timeout: 15000 }
  )

  // Toggle back and verify cleared completion styles after reload
  await page.locator('h3', { hasText: title }).first().locator('xpath=ancestor::div[contains(@class, "rounded-xl")][1]').getByTestId('btn-toggle-todo').first().click()
  await page.reload()
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await page.waitForFunction(
    (text) => !!Array.from(document.querySelectorAll('h3'))
      .find(h => h.textContent?.includes(text) && !h.className.includes('line-through')),
    title,
    { timeout: 15000 }
  )
})
