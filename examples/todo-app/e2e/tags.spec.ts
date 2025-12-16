import { test, expect } from '@playwright/test'

test('clicking a tag chip filters by tags', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  const tagA = `tag-a-${Date.now()}`
  const tagB = `tag-b-${Date.now()}`

  const mk = async (title: string, tag: string) => {
    await page.getByTestId('btn-new-todo').click()
    const titleInput = page.getByTestId('input-title')
    await expect(titleInput).toBeVisible({ timeout: 20000 })
    await titleInput.fill(title)
    await page.locator('input[name="tags"]').fill(tag)
    await page.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"] h3', { hasText: title })).toBeVisible({ timeout: 20000 })
  }

  const titleA = `Tag A ${Date.now()}`
  const titleB = `Tag B ${Date.now()}`
  await mk(titleA, tagA)
  await mk(titleB, tagB)

  // Capture initial total text
  const stats = page.locator('.bg-white >> text=Showing')
  await expect(stats).toBeVisible()
  const beforeText = await stats.first().innerText()

  // Click tag chip in the tag row (dynamic, derived from todos)
  const chip = page.locator(`[data-testid="tag-chip"][data-tag="${tagA}"]`).first()
  await expect(chip).toBeVisible({ timeout: 20000 })
  await chip.click()

  // Confirm filtering: tagA todo visible, tagB todo hidden
  await expect(page.locator('h3', { hasText: titleA })).toBeVisible({ timeout: 20000 })
  await expect(page.locator('h3', { hasText: titleB })).toHaveCount(0)

  // Counter should change as a result of filtering
  await expect.poll(async () => await stats.first().innerText(), { timeout: 5000 }).not.toBe(beforeText)
})
