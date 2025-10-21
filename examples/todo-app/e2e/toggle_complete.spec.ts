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
  const card = page.locator('[data-testid="todo-card"]', { has: heading }).first()
  const toggleBtn = card.getByTestId('btn-toggle-todo').first()
  await expect(toggleBtn).toBeVisible()
  await toggleBtn.click()
  // Reload to verify persisted completion state deterministically
  await page.reload()
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  // Prefer robust data attribute; fallback to class-based
  await page.waitForFunction(
    (t) => {
      const card = Array.from(document.querySelectorAll('[data-testid="todo-card"]')).find(c => c.querySelector('h3')?.textContent?.includes(t))
      if (!card) return false
      if ((card as HTMLElement).getAttribute('data-completed') === 'true') return true
      const h = card.querySelector('h3')
      return (h && h.className.includes('line-through')) || card.className.includes('opacity-60')
    },
    title,
    { timeout: 15000 }
  )

  // Toggle back and verify cleared completion styles after reload
  await page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: title }) }).first().getByTestId('btn-toggle-todo').first().click()
  await page.reload()
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await page.waitForFunction(
    (t) => {
      const card = Array.from(document.querySelectorAll('[data-testid="todo-card"]')).find(c => c.querySelector('h3')?.textContent?.includes(t))
      if (!card) return false
      if ((card as HTMLElement).getAttribute('data-completed') === 'false') return true
      const h = card.querySelector('h3')
      return (h && !h.className.includes('line-through')) && !card.className.includes('opacity-60')
    },
    title,
    { timeout: 15000 }
  )
})
