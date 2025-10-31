import { test, expect } from '@playwright/test'

test('sort by created shows newest first', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  const mk = async (title: string) => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    await expect(form).toBeVisible()
    await page.getByTestId('input-title').fill(title)
    await page.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"] h3', { hasText: title })).toBeVisible()
  }

  const t1 = `CR1 ${Date.now()}`
  await mk(t1)
  // Small delay to ensure distinct timestamps
  await page.waitForTimeout(50)
  const t2 = `CR2 ${Date.now()}`
  await mk(t2)

  // Ensure sort is set to created
  await page.selectOption('select[name="sort_by"]', 'created')
  await page.reload({ waitUntil: 'networkidle' })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  const titles = await page.locator('[data-testid="todo-card"] h3').allTextContents()
  const i1 = titles.findIndex(t => t.includes(t1))
  const i2 = titles.findIndex(t => t.includes(t2))
  expect(i1).toBeGreaterThanOrEqual(0)
  expect(i2).toBeGreaterThanOrEqual(0)
  // Newest first → t2 before t1
  expect(i2).toBeLessThan(i1)
})

