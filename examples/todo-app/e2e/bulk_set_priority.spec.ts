import { test, expect } from '@playwright/test'

test('bulk set priority applies to visible todos only and persists', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  const mk = async (title: string, priority: 'low' | 'medium' | 'high') => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    await expect(form).toBeVisible({ timeout: 15000 })
    await form.getByTestId('input-title').fill(title)
    await form.locator('select[name="priority"]').selectOption(priority)
    await form.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"] h3', { hasText: title })).toBeVisible({ timeout: 15000 })
  }

  const runId = Date.now()
  const aTitle = `BSP-A ${runId}`
  const bTitle = `BSP-B ${runId}`

  await mk(aTitle, 'low')
  await mk(bTitle, 'medium')

  const search = page.getByPlaceholder('Search todos...')
  await search.fill(aTitle)

  const aCard = page.getByTestId('todo-card').filter({ hasText: aTitle }).first()
  await expect(aCard).toBeVisible({ timeout: 15000 })
  await expect(aCard).toContainText(/Priority:\s*low/i)

  await page.getByTestId('btn-bulk-priority-high').click()
  await expect(aCard).toContainText(/Priority:\s*high/i, { timeout: 20000 })

  await search.fill('')
  const bCard = page.getByTestId('todo-card').filter({ hasText: bTitle }).first()
  await expect(bCard).toBeVisible({ timeout: 15000 })
  await expect(bCard).toContainText(/Priority:\s*medium/i)

  await page.reload({ waitUntil: 'networkidle' })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  const aCardAfter = page.getByTestId('todo-card').filter({ hasText: aTitle }).first()
  const bCardAfter = page.getByTestId('todo-card').filter({ hasText: bTitle }).first()
  await expect(aCardAfter).toContainText(/Priority:\s*high/i)
  await expect(bCardAfter).toContainText(/Priority:\s*medium/i)
})

