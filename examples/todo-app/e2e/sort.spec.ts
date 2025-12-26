import { test, expect } from '@playwright/test'

test('sort by priority reorders list', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  const group = `grp-${Date.now()}`

  const mk = async (title: string, priority: 'low' | 'medium' | 'high') => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    try {
      await expect(form).toBeVisible({ timeout: 20000 })
    } catch {
      await page.getByTestId('btn-new-todo').click()
      await expect(form).toBeVisible({ timeout: 15000 })
    }
    const titleInput = page.getByTestId('input-title')
    await expect(titleInput).toBeVisible({ timeout: 15000 })
    await titleInput.fill(title)
    // Set priority
    await page.selectOption('select[name="priority"]', priority)
    // Stamp with a unique tag to scope assertions
    await page.locator('input[name="tags"]').fill(group)
    await page.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"]', { hasText: group }).locator('h3', { hasText: title })).toBeVisible({ timeout: 20000 })
  }

  const tHigh = `High ${Date.now()}`
  const tMed = `Medium ${Date.now()}`
  const tLow = `Low ${Date.now()}`
  await mk(tHigh, 'high')
  await mk(tMed, 'medium')
  await mk(tLow, 'low')

  // Change sort to Priority and ensure a fresh render
  await page.selectOption('select[name="sort_by"]', 'priority')
  await page.waitForFunction(() => document.querySelector('select[name="sort_by"]').value === 'priority')

  // Expect priority descending: high → medium → low
  await expect.poll(async () => {
    const cards = page.locator('[data-testid="todo-card"]').filter({ hasText: group })
    const priorities = await cards.locator('span').allTextContents()
    const ranks = priorities
      .filter(t => /Priority:/i.test(t))
      .map(t => t.toLowerCase().includes('high') ? 0 : t.toLowerCase().includes('medium') ? 1 : 2)
    // We created exactly three with the same stamp; ensure we have 3 readings
    if (ranks.length < 3) return false
    return ranks[0] <= ranks[1] && ranks[1] <= ranks[2]
  }, { timeout: 20000 }).toBe(true)
})
