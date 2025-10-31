import { test, expect } from '@playwright/test'

test('bulk complete marks all as completed and persists', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  // Ensure at least two active todos
  const mk = async (title: string) => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    await expect(form).toBeVisible()
    await page.getByTestId('input-title').fill(title)
    await page.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"] h3', { hasText: title })).toBeVisible()
  }
  const t1 = `BC1 ${Date.now()}`
  const t2 = `BC2 ${Date.now()}`
  await mk(t1)
  await mk(t2)

  // Click Complete All
  await page.getByRole('button', { name: /Complete All/i }).click()

  // Assert all cards are completed
  const cards = page.locator('[data-testid="todo-card"]')
  await expect.poll(async () => await cards.count(), { timeout: 15000 }).toBeGreaterThan(0)
  await expect.poll(async () => {
    const vals = await cards.evaluateAll(nodes => nodes.map(n => n.getAttribute('data-completed')))
    return vals.length > 0 && vals.every(v => v === 'true')
  }, { timeout: 20000 }).toBeTruthy()

  // Reload and assert persistence
  await page.reload({ waitUntil: 'networkidle' })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })
  const cardsAfter = page.locator('[data-testid="todo-card"]')
  const allCompletedAfter = await cardsAfter.evaluateAll(nodes => nodes.every(n => n.getAttribute('data-completed') === 'true'))
  expect(allCompletedAfter).toBeTruthy()
})
