import { test, expect, type Page } from '@playwright/test'

async function waitForLiveViewConnected(page: Page) {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
}

test('tags filter + search-by-tag + sort works', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await waitForLiveViewConnected(page)

  const runId = Date.now().toString()
  const tagWork = `work-${runId}`
  const tagHome = `home-${runId}`

  const createTodo = async (title: string, opts: { tags: string[]; dueDate: string; priority: string }) => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    await expect(form).toBeVisible({ timeout: 15000 })
    await form.getByTestId('input-title').fill(title)
    await form.locator('select[name="priority"]').selectOption(opts.priority)
    await form.locator('input[name="due_date"]').fill(opts.dueDate)
    await form.locator('input[name="tags"]').fill(opts.tags.join(', '))
    await form.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"] h3', { hasText: title })).toBeVisible({ timeout: 15000 })
  }

  const aTitle = `E2E TagsSort A ${runId}`
  const bTitle = `E2E TagsSort B ${runId}`

  await createTodo(aTitle, { tags: [tagWork], dueDate: '2024-12-31', priority: 'low' })
  await createTodo(bTitle, { tags: [tagHome], dueDate: '2025-01-01', priority: 'high' })

  // Available tag chips should include our tags (dynamic, not hard-coded)
  const tagsRegion = page.getByTestId('available-tags')
  await expect(tagsRegion.locator(`[data-testid="tag-chip"][data-tag="${tagWork}"]`)).toBeVisible({ timeout: 15000 })
  await expect(tagsRegion.locator(`[data-testid="tag-chip"][data-tag="${tagHome}"]`)).toBeVisible({ timeout: 15000 })

  // Search should match tags as well as titles/descriptions
  const search = page.getByPlaceholder('Search todos...')
  await search.fill(tagWork)
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: aTitle })).toBeVisible({ timeout: 15000 })
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: bTitle })).toHaveCount(0)

  // Clear search; filter via tag chip
  await search.fill('')
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: bTitle })).toBeVisible({ timeout: 15000 })

  const workChip = tagsRegion.locator(`[data-testid="tag-chip"][data-tag="${tagWork}"]`).first()
  await workChip.click()
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: aTitle })).toBeVisible({ timeout: 15000 })
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: bTitle })).toHaveCount(0)

  // Clicking a tag on the todo card should also toggle the filter
  await workChip.click()
  const bCard = page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: bTitle }) }).first()
  await bCard.locator(`[data-testid="todo-tag"][data-tag="${tagHome}"]`).click()
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: bTitle })).toBeVisible({ timeout: 15000 })
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: aTitle })).toHaveCount(0)

  // Reset filters and scope list down to our items for stable sort assertions
  await bCard.locator(`[data-testid="todo-tag"][data-tag="${tagHome}"]`).click()
  await search.fill(runId)
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: aTitle })).toBeVisible({ timeout: 15000 })
  await expect(page.locator('[data-testid="todo-card"] h3', { hasText: bTitle })).toBeVisible({ timeout: 15000 })

  // Sort by due date should be chronological (2024-12-31 before 2025-01-01)
  const sortSelect = page.locator('select[name="sort_by"]').first()
  await sortSelect.selectOption('due_date')
  const titles = page.locator('[data-testid="todo-card"] h3')
  await expect(titles.first()).toHaveText(aTitle, { timeout: 15000 })

  // Sort by priority should put high before low
  await sortSelect.selectOption('priority')
  await expect(titles.first()).toHaveText(bTitle, { timeout: 15000 })
})
