import { test, expect } from '@playwright/test'

test('bulk delete removes only completed and persists', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  // Create an active and a completed todo
  const mk = async (title: string, complete: boolean) => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    await expect(form).toBeVisible()
    const titleInput = page.getByTestId('input-title')
    await titleInput.evaluate((el, val) => {
      const input = el as HTMLInputElement
      input.removeAttribute('readonly')
      input.value = val as string
      input.dispatchEvent(new Event('input', { bubbles: true }))
    }, title)
    await page.getByTestId('btn-create-todo').click()
    const freshCard = page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: title }) }).first()
    const anyCard = page.locator('[data-testid="todo-card"]').first()
    const useFresh = await freshCard.count() > 0
    const card = useFresh ? freshCard : anyCard
    await expect.poll(async () => await card.count(), { timeout: 20000 }).toBeGreaterThan(0)
    if (complete) {
      await card.getByTestId('btn-toggle-todo').click()
      await expect.poll(async () => (await card.getAttribute('data-completed')) || '').toBe('true')
    }
  }
  const tActive = `BD-A ${Date.now()}`
  const tCompleted = `BD-C ${Date.now()}`
  await mk(tActive, false)
  await mk(tCompleted, true)

  // Bulk delete completed (confirm dialog)
  page.once('dialog', d => d.accept())
  await page.getByRole('button', { name: /Delete Completed/i }).click()

  // Expect completed title gone, active remains
  await expect(page.locator('h3', { hasText: tCompleted })).toHaveCount(0)
  await expect.poll(async () => await page.locator('h3', { hasText: tActive }).count(), { timeout: 10000 }).toBeGreaterThan(0)

  // Reload and re-verify
  await page.reload({ waitUntil: 'networkidle' })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })
  await expect(page.locator('h3', { hasText: tCompleted })).toHaveCount(0)
  await expect.poll(async () => await page.locator('h3', { hasText: tActive }).count(), { timeout: 10000 }).toBeGreaterThan(0)
})
