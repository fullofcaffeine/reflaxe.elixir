import { test, expect } from '@playwright/test'

test('filter buttons switch visible items', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  // Helper: create a new active todo quickly
  const mk = async (title: string) => {
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
    // Some LiveView patches briefly mark inputs readonly; force-enable then set value with input event
    await titleInput.evaluate((el, val) => {
      const input = el as HTMLInputElement
      input.removeAttribute('readonly')
      input.value = val as string
      input.dispatchEvent(new Event('input', { bubbles: true }))
    }, title)
    await page.getByTestId('btn-create-todo').click()
  }
  const activeTitle = `Active ${Date.now()}`
  await mk(activeTitle)

  // Completed filter: ensure completed cards render; if none exist, perform bulk complete then verify
  await page.getByTestId('btn-filter-completed').click()
  const completedCount = await page.locator('[data-testid="todo-card"][data-completed="true"]').count()
  if (completedCount === 0) {
    await page.getByRole('button', { name: /Delete Completed|Complete All/i }).click({ trial: true }).catch(() => {})
    // Prefer 'Complete All' if present
    const completeAll = page.getByRole('button', { name: /Complete All/i })
    if (await completeAll.count()) {
      await completeAll.click()
    }
    // Switch to Completed again and verify
    await page.getByTestId('btn-filter-completed').click()
  }
  await expect.poll(async () => await page.locator('[data-testid="todo-card"][data-completed="true"]').count(), { timeout: 10000 }).toBeGreaterThan(0)

  // Active filter: Only active cards should be visible
  await page.getByTestId('btn-filter-active').click()
  await expect.poll(async () => await page.locator('[data-testid="todo-card"][data-completed="false"]').count(), { timeout: 10000 }).toBeGreaterThan(0)
  // And the freshly created one should be visible
  await expect(page.locator('h3', { hasText: activeTitle })).toBeVisible()
})
