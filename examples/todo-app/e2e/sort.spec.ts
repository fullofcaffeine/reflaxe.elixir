import { test, expect } from '@playwright/test'

test('sort by priority reorders list', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

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
    await page.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"] h3', { hasText: title })).toBeVisible({ timeout: 20000 })
  }

  const tHigh = `High ${Date.now()}`
  const tMed = `Medium ${Date.now()}`
  const tLow = `Low ${Date.now()}`
  await mk(tHigh, 'high')
  await mk(tMed, 'medium')
  await mk(tLow, 'low')

  // Change sort to Priority and ensure a fresh render
  await page.selectOption('select[name="sort_by"]', 'priority')
  await page.waitForTimeout(300)

  // Expect relative ordering: High appears before Medium, which appears before Low
  await page.waitForTimeout(250); // brief settle for LiveView patch
  const titles = await page.locator('[data-testid="todo-card"] h3').allTextContents()
  console.log('TITLES:', titles)
  const iHigh = titles.findIndex(t => t.includes(tHigh))
  const iMed = titles.findIndex(t => t.includes(tMed))
  const iLow = titles.findIndex(t => t.includes(tLow))
  expect(iHigh).toBeGreaterThanOrEqual(0)
  expect(iMed).toBeGreaterThanOrEqual(0)
  expect(iLow).toBeGreaterThanOrEqual(0)
  expect(iHigh).toBeLessThan(iMed)
  expect(iMed).toBeLessThan(iLow)
})
