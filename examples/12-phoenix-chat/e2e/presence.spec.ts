import { test, expect } from '@playwright/test'

test('presence online count updates across sessions', async ({ browser }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'

  const ctxA = await browser.newContext()
  const ctxB = await browser.newContext()

  const pageA = await ctxA.newPage()
  const pageB = await ctxB.newPage()

  await pageA.goto(base + '/')
  await expect(pageA.getByTestId('online-count')).toHaveText('1', { timeout: 15000 })

  await pageB.goto(base + '/')
  await expect(pageB.getByTestId('online-count')).toHaveText('2', { timeout: 15000 })
  await expect(pageA.getByTestId('online-count')).toHaveText('2', { timeout: 15000 })

  await ctxA.close()
  await ctxB.close()
})

test('React island sends one typed event and native fallback remains useful', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'

  await page.goto(base + '/')
  await expect(page.getByTestId('preference-studio')).toBeVisible()

  await page.getByRole('button', { name: /Dense/ }).click()
  await page.getByRole('button', { name: 'Apply dense' }).click()
  await expect(page.getByTestId('preference-status')).toHaveText('Density synchronized: Dense.')

  await page.getByTestId('preference-fallback').getByText('Native LiveView controls').click()
  await page.getByRole('button', { name: 'Use Calm native mode' }).click()
  await expect(page.getByTestId('preference-status')).toHaveText('Density synchronized: Calm.')
})
