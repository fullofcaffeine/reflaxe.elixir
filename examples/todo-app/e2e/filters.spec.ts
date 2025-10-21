import { test, expect } from '@playwright/test'

test('filter buttons switch visible items', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForSelector('body.phx-connected', { timeout: 10000 })

  // Ensure at least one active and one completed todo
  const mk = async (title: string, complete: boolean) => {
    await page.getByRole('button', { name: /Add New Todo/i }).click()
    const titleInput = page.getByPlaceholder('What needs to be done?')
    await expect(titleInput).toBeVisible({ timeout: 10000 })
    await titleInput.fill(title)
    await page.getByRole('button', { name: /Create Todo/i }).click()
    const heading = page.locator('h3', { hasText: title }).first()
    const card = heading.locator('xpath=ancestor::div[contains(@class, "rounded-xl")][1]')
    if (complete) {
      const toggleBtn = card.locator('button[phx-click="toggle_todo"]').first()
      await expect(toggleBtn).toBeVisible()
      await toggleBtn.click()
      await expect(heading).toHaveClass(/line-through/)
    }
  }
  const activeTitle = `Active ${Date.now()}`
  const completedTitle = `Completed ${Date.now()}`
  await mk(activeTitle, false)
  await mk(completedTitle, true)

  // Completed filter should hide the active title and show completed
  await page.locator('button[phx-click="filter_todos"][phx-value-filter="completed"]').click()
  await expect(page.locator('h3', { hasText: activeTitle })).toHaveCount(0)
  await expect(page.locator('h3', { hasText: completedTitle })).toBeVisible()

  // Active filter should hide completed and show active
  await page.locator('button[phx-click="filter_todos"][phx-value-filter="active"]').click()
  await expect(page.locator('h3', { hasText: completedTitle })).toHaveCount(0)
  await expect(page.locator('h3', { hasText: activeTitle })).toBeVisible()
})
