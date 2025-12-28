import { test, expect, type Page } from '@playwright/test'

async function waitForLiveViewConnected(page: Page) {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
}

test('two sessions receive live updates (PubSub)', async ({ page, context }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await waitForLiveViewConnected(page)

  const title = `E2E LiveUpdate ${Date.now()}`

  // Create a fresh todo to toggle
  await page.getByTestId('btn-new-todo').click()
  const form = page.locator('form[phx-submit="create_todo"]').first()
  await expect(form.getByTestId('input-title')).toBeVisible({ timeout: 15000 })
  await form.getByTestId('input-title').fill(title)
  await form.getByTestId('btn-create-todo').click()
  const heading1 = page.locator('h3', { hasText: title }).first()
  const card1 = heading1.locator('xpath=ancestor::*[@data-testid="todo-card"][1]')
  await expect(card1).toBeVisible({ timeout: 15000 })

  // Second session
  const page2 = await context.newPage()
  await page2.goto(base + '/todos')
  await waitForLiveViewConnected(page2)
  const heading2 = page2.locator('h3', { hasText: title }).first()
  const card2 = heading2.locator('xpath=ancestor::*[@data-testid="todo-card"][1]')
  await expect(card2).toBeVisible({ timeout: 15000 })

  // Toggle completion in session 1
  await card1.getByTestId('btn-toggle-todo').click()

  // Session 2 should reflect the update without reload (line-through title class)
  await expect.poll(
    async () => await card2.locator('h3').getAttribute('class'),
    { timeout: 15000 }
  ).toMatch(/line-through/)

  await page2.close()
})
