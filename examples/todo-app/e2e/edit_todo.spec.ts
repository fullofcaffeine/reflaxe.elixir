import { test, expect } from '@playwright/test'

test('edit todo updates title', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  // Create a fresh todo to edit
  await page.getByTestId('btn-new-todo').click()
  const original = `Edit Me ${Date.now()}`
  const titleInput = page.getByTestId('input-title')
  await expect(titleInput).toBeVisible({ timeout: 15000 })
  await titleInput.fill(original)
  await page.getByTestId('btn-create-todo').click()
  const heading = page.locator('h3', { hasText: original }).first()
  const card = heading.locator('xpath=ancestor::*[@data-testid="todo-card"][1]')

  // Open edit form
  await card.getByTestId('btn-edit-todo').click()
  // Wait for the edit form to appear inside the card
  await expect(card.locator('form[phx-submit="save_todo"]').first()).toBeVisible({ timeout: 15000 })

  const updated = `Edited ${Date.now()}`
  // Edit form now exposes data-testid on the title input
  const editInput = card.getByTestId('input-title').first()
  await expect(editInput).toBeVisible({ timeout: 15000 })
  await editInput.fill(updated)
  await card.getByRole('button', { name: /Save/i }).click()

  // Assert the updated title is visible
  await expect(page.locator('h3', { hasText: updated })).toBeVisible({ timeout: 15000 })
})
