import { test, expect } from '@playwright/test'

test('filter buttons switch visible items', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  // Ensure at least one active and one completed todo
  const mk = async (title: string, complete: boolean) => {
    // Use deterministic test ids for creation flow; wait on title input (most stable)
    await page.getByTestId('btn-new-todo').click()
    // Wait for the form to appear (primary guard that event fired). Retry once if needed.
    const createForm = page.locator('form[phx-submit="create_todo"]').first()
    try {
      await expect(createForm).toBeVisible({ timeout: 20000 })
    } catch (e) {
      await page.getByTestId('btn-new-todo').click()
      await expect(createForm).toBeVisible({ timeout: 15000 })
    }
    // Optional: assert button label toggled
    await expect(page.getByTestId('btn-new-todo')).toContainText(/Cancel|✖/i, { timeout: 20000 })
    const titleInput = page.getByTestId('input-title')
    await expect(titleInput).toBeVisible({ timeout: 20000 })
    await page.waitForFunction(() => {
      const el = document.querySelector('[data-testid="input-title"]') as HTMLInputElement | null
      return !!el && !el.hasAttribute('readonly')
    }, { timeout: 20000 })
    await titleInput.fill(title)
    await page.getByTestId('btn-create-todo').click()
    const heading = page.locator('h3', { hasText: title }).first()
    const card = heading.locator('xpath=ancestor::div[contains(@class, "rounded-xl")][1]')
    if (complete) {
      const toggleBtn = card.getByTestId('btn-toggle-todo').first()
      await expect(toggleBtn).toBeVisible({ timeout: 10000 })
      await toggleBtn.click()
      await page.waitForFunction(
        (text) => !!Array.from(document.querySelectorAll('h3'))
          .find(h => h.textContent?.includes(text) && h.className.includes('line-through')),
        title,
        { timeout: 15000 }
      )
    }
  }
  const activeTitle = `Active ${Date.now()}`
  const completedTitle = `Completed ${Date.now()}`
  await mk(activeTitle, false)
  await mk(completedTitle, true)

  // Completed filter should hide the active title and show completed
  await page.getByTestId('btn-filter-completed').click()
  await expect(page.locator('h3', { hasText: activeTitle })).toHaveCount(0)
  await expect(page.locator('h3', { hasText: completedTitle })).toBeVisible()

  // Active filter should hide completed and show active
  await page.getByTestId('btn-filter-active').click()
  await expect(page.locator('h3', { hasText: completedTitle })).toHaveCount(0)
  await expect(page.locator('h3', { hasText: activeTitle })).toBeVisible()
})
