import { test, expect } from '@playwright/test'

test('theme toggle persists via localStorage', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'

  // Ensure deterministic start state regardless of OS theme.
  await page.addInitScript(() => {
    if (window.localStorage.getItem('todo_app_theme') == null) {
      window.localStorage.setItem('todo_app_theme', 'light')
    }
  })

  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  await expect(page.getByTestId('nav-theme-toggle').locator('[data-theme-label]')).toHaveText('Light')
  await page.waitForFunction(() => !document.documentElement.classList.contains('dark'), { timeout: 5000 })

  await page.getByTestId('nav-theme-toggle').click()

  await expect(page.getByTestId('nav-theme-toggle').locator('[data-theme-label]')).toHaveText('Dark')
  await page.waitForFunction(() => window.localStorage.getItem('todo_app_theme') === 'dark', { timeout: 5000 })
  await page.waitForFunction(() => document.documentElement.classList.contains('dark'), { timeout: 5000 })

  await page.reload()
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  await page.waitForFunction(() => window.localStorage.getItem('todo_app_theme') === 'dark', { timeout: 5000 })
  await page.waitForFunction(() => document.documentElement.classList.contains('dark'), { timeout: 5000 })
})
