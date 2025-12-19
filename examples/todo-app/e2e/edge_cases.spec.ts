import { test, expect } from '@playwright/test'

test('edge: tag parsing trims and drops empty entries', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })

  const tagA = `tag-a-${Date.now()}`
  const tagB = `tag-b-${Date.now()}`
  const title = `TagParse ${Date.now()}`

  await page.getByTestId('btn-new-todo').click()
  const form = page.locator('form[phx-submit="create_todo"]').first()
  await expect(form).toBeVisible({ timeout: 20000 })
  await page.getByTestId('input-title').fill(title)
  await form.locator('input[name="tags"]').fill(`  ${tagA}  , ,  ${tagB} ,   ,`)
  await page.getByTestId('btn-create-todo').click()

  const card = page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: title }) }).first()
  await expect(card).toBeVisible({ timeout: 20000 })

  await expect(card.locator(`[data-testid="todo-tag"][data-tag="${tagA}"]`)).toBeVisible({ timeout: 20000 })
  await expect(card.locator(`[data-testid="todo-tag"][data-tag="${tagB}"]`)).toBeVisible({ timeout: 20000 })
  await expect(card.locator('[data-testid="todo-tag"][data-tag=""]')).toHaveCount(0)

  // Available tag chips are derived from current todos and should include trimmed tags.
  await expect(page.locator(`[data-testid="tag-chip"][data-tag="${tagA}"]`).first()).toBeVisible({ timeout: 20000 })
  await expect(page.locator(`[data-testid="tag-chip"][data-tag="${tagB}"]`).first()).toBeVisible({ timeout: 20000 })
})

test('edge: multi-tag selection uses OR semantics and composes with search', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })

  const tagA = `sel-a-${Date.now()}`
  const tagB = `sel-b-${Date.now()}`
  const tagC = `sel-c-${Date.now()}`
  const titleA = `SelA ${Date.now()}`
  const titleB = `SelB ${Date.now()}`
  const titleC = `SelC ${Date.now()}`

  const mk = async (title: string, tag: string) => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    await expect(form).toBeVisible({ timeout: 20000 })
    await page.getByTestId('input-title').fill(title)
    await form.locator('input[name="tags"]').fill(tag)
    await page.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"] h3', { hasText: title })).toBeVisible({ timeout: 20000 })
  }

  await mk(titleA, tagA)
  await mk(titleB, tagB)
  await mk(titleC, tagC)

  const chipA = page.locator(`[data-testid="tag-chip"][data-tag="${tagA}"]`).first()
  const chipB = page.locator(`[data-testid="tag-chip"][data-tag="${tagB}"]`).first()
  await expect(chipA).toBeVisible({ timeout: 20000 })
  await expect(chipB).toBeVisible({ timeout: 20000 })

  // Select A: only A visible (among our three)
  await chipA.click()
  await expect(page.locator('h3', { hasText: titleA })).toBeVisible({ timeout: 20000 })
  await expect(page.locator('h3', { hasText: titleB })).toHaveCount(0)
  await expect(page.locator('h3', { hasText: titleC })).toHaveCount(0)

  // Select B too: OR semantics → A and B visible, C hidden
  await chipB.click()
  await expect(page.locator('h3', { hasText: titleA })).toBeVisible({ timeout: 20000 })
  await expect(page.locator('h3', { hasText: titleB })).toBeVisible({ timeout: 20000 })
  await expect(page.locator('h3', { hasText: titleC })).toHaveCount(0)

  // Compose with search + tags: searching for tagC while only A/B are selected should show none.
  const search = page.getByPlaceholder('Search todos...')
  await search.fill(tagC)
  await expect(page.locator('h3', { hasText: titleA })).toHaveCount(0)
  await expect(page.locator('h3', { hasText: titleB })).toHaveCount(0)
  await expect(page.locator('h3', { hasText: titleC })).toHaveCount(0)

  // Selecting C should allow the C result to appear under the same search.
  const chipC = page.locator(`[data-testid="tag-chip"][data-tag="${tagC}"]`).first()
  await expect(chipC).toBeVisible({ timeout: 20000 })
  await chipC.click()
  await expect(page.locator('h3', { hasText: titleC })).toBeVisible({ timeout: 20000 })
})

test('edge: validation failures show flash and do not apply changes', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })

  // Invalid create (empty title): bypass HTML required and assert flash error.
  await page.getByTestId('btn-new-todo').click()
  const createForm = page.locator('form[phx-submit="create_todo"]').first()
  await expect(createForm).toBeVisible({ timeout: 20000 })
  const titleInput = createForm.getByTestId('input-title').first()
  await titleInput.evaluate((el) => {
    const input = el as HTMLInputElement
    input.removeAttribute('required')
    input.value = ''
    input.dispatchEvent(new Event('input', { bubbles: true }))
  })
  await page.getByTestId('btn-create-todo').click()
  await expect(page.getByTestId('flash-error')).toContainText(/Failed to create todo/i, { timeout: 20000 })

  // Valid create so we can test invalid edit.
  const title = `Valid ${Date.now()}`
  await titleInput.evaluate((el, val) => {
    const input = el as HTMLInputElement
    input.setAttribute('required', 'required')
    input.value = val as string
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }, title)
  await page.getByTestId('btn-create-todo').click()
  const card = page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: title }) }).first()
  await expect(card).toBeVisible({ timeout: 20000 })

  // Invalid edit (empty title): bypass required and assert flash error.
  await card.getByTestId('btn-edit-todo').click()
  const editForm = page.locator('form[phx-submit="save_todo"]').first()
  await expect(editForm).toBeVisible({ timeout: 20000 })
  const editTitle = editForm.getByTestId('input-title').first()
  await editTitle.evaluate((el) => {
    const input = el as HTMLInputElement
    input.removeAttribute('required')
    input.value = ''
    input.dispatchEvent(new Event('input', { bubbles: true }))
  })
  await editForm.getByRole('button', { name: /Save/i }).click()
  await expect(page.getByTestId('flash-error')).toContainText(/Failed to update todo/i, { timeout: 20000 })
})

test('edge: cancel edit discards changes', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })

  const original = `CancelEdit ${Date.now()}`
  const edited = `ShouldNotPersist ${Date.now()}`

  // Create a fresh todo
  await page.getByTestId('btn-new-todo').click()
  const createForm = page.locator('form[phx-submit="create_todo"]').first()
  await expect(createForm).toBeVisible({ timeout: 20000 })
  await createForm.getByTestId('input-title').fill(original)
  await page.getByTestId('btn-create-todo').click()
  const card = page.locator('[data-testid="todo-card"]', { has: page.locator('h3', { hasText: original }) }).first()
  await expect(card).toBeVisible({ timeout: 20000 })

  // Enter edit mode, change title, then cancel
  await card.getByTestId('btn-edit-todo').click()
  const editForm = page.locator('form[phx-submit="save_todo"]').first()
  await expect(editForm).toBeVisible({ timeout: 20000 })
  const editTitle = editForm.getByTestId('input-title').first()
  await editTitle.evaluate((el, val) => {
    const input = el as HTMLInputElement
    input.removeAttribute('readonly')
    input.value = val as string
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }, edited)
  await editForm.getByRole('button', { name: /Cancel/i }).click()

  // Should still show original title and not the edited value
  await expect(page.locator('h3', { hasText: original })).toBeVisible({ timeout: 20000 })
  await expect(page.locator('h3', { hasText: edited })).toHaveCount(0)
})

test('edge: bulk actions show info flash', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })

  // Ensure at least one active todo
  const title = `BulkInfo ${Date.now()}`
  await page.getByTestId('btn-new-todo').click()
  const createForm = page.locator('form[phx-submit="create_todo"]').first()
  await expect(createForm).toBeVisible({ timeout: 20000 })
  await createForm.getByTestId('input-title').fill(title)
  await page.getByTestId('btn-create-todo').click()
  await expect(page.locator('h3', { hasText: title })).toBeVisible({ timeout: 20000 })

  // Complete all and expect info flash
  await page.getByRole('button', { name: /Complete All/i }).click()
  await expect(page.getByTestId('flash-info')).toContainText(/All todos marked as completed!/i, { timeout: 20000 })

  // Delete completed and expect info flash
  page.once('dialog', d => d.accept())
  await page.getByRole('button', { name: /Delete Completed/i }).click()
  await expect(page.getByTestId('flash-info')).toContainText(/Completed todos deleted!/i, { timeout: 20000 })
})

test('edge: search matches description case-insensitively and clearing restores list', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })

  const marker = `DescMarker-${Date.now()}`
  const title = `DescSearch ${Date.now()}`

  await page.getByTestId('btn-new-todo').click()
  const form = page.locator('form[phx-submit="create_todo"]').first()
  await expect(form).toBeVisible({ timeout: 20000 })
  await form.getByTestId('input-title').fill(title)
  await form.locator('textarea[name="description"]').fill(`Some ${marker} text`)
  await page.getByTestId('btn-create-todo').click()
  await expect(page.locator('h3', { hasText: title })).toBeVisible({ timeout: 20000 })

  const cards = page.locator('[data-testid="todo-card"]')
  const baseline = await cards.count()
  expect(baseline).toBeGreaterThan(0)

  const search = page.getByPlaceholder('Search todos...')
  await search.fill(marker.toLowerCase())
  await expect(page.locator('h3', { hasText: title })).toBeVisible({ timeout: 20000 })
  await expect.poll(async () => await cards.count(), { timeout: 10000 }).toBeLessThanOrEqual(baseline)

  // Clear search → list should restore (at least baseline or higher, since other tests may have added rows)
  await search.fill('')
  await expect(page.locator('h3', { hasText: title })).toBeVisible({ timeout: 20000 })
  await expect.poll(async () => await cards.count(), { timeout: 10000 }).toBeGreaterThanOrEqual(baseline)
})
