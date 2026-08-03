import { test, expect } from '@playwright/test'

test('native LiveView preference controls work independently of the React island', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'

  await page.goto(base + '/')
  await expect(page.locator('[data-phx-main].phx-connected')).toBeVisible()
  await page.getByTestId('preference-fallback').getByText('Native LiveView controls').click()
  await page.getByRole('button', { name: 'Use Calm native mode' }).click()
  await expect(page.getByTestId('preference-status')).toHaveText('Density synchronized: Calm.')
})
