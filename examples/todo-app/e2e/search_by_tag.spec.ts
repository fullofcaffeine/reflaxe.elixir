import { test, expect } from '@playwright/test'

test('search matches tags', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  const tag = `e2e-tag-${Date.now()}`
  const otherTag = `other-tag-${Date.now()}`
  const titleTagged = `Tagged ${Date.now()}`
  const titleOther = `Other ${Date.now()}`

  const mk = async (title: string, tags: string) => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    await expect(form).toBeVisible({ timeout: 20000 })
    await page.getByTestId('input-title').fill(title)
    await page.locator('input[name="tags"]').fill(tags)
    await page.getByTestId('btn-create-todo').click()
    await expect(page.locator('[data-testid="todo-card"] h3', { hasText: title })).toBeVisible({ timeout: 20000 })
  }

  await mk(titleTagged, tag)
  await mk(titleOther, otherTag)

  const search = page.getByPlaceholder('Search todos...')
  await search.fill(tag)

  await expect(page.locator('h3', { hasText: titleTagged })).toBeVisible({ timeout: 20000 })
  await expect(page.locator('h3', { hasText: titleOther })).toHaveCount(0)
})
