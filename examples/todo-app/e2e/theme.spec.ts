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

  // Signed-out nav chips must adopt dark palette and never stay in the light button color.
  const usersChip = page.getByTestId('nav-users')
  const signInChip = page.getByTestId('nav-sign-in')
  await expect(usersChip).toBeVisible()
  await expect(signInChip).toBeVisible()

  const usersBg = await usersChip.evaluate((el) => window.getComputedStyle(el).backgroundColor)
  const signInBg = await signInChip.evaluate((el) => window.getComputedStyle(el).backgroundColor)
  expect(usersBg).not.toBe('rgb(243, 244, 246)')
  expect(signInBg).not.toBe('rgb(243, 244, 246)')

  // Search/filter/sort controls should share one horizontal baseline and equal height.
  const searchInput = page.getByPlaceholder('Search todos...')
  const filterAll = page.getByTestId('btn-filter-all')
  const sortSelect = page.locator('select[name="sort_by"]').first()
  const searchBox = await searchInput.boundingBox()
  const filterBox = await filterAll.boundingBox()
  const sortBox = await sortSelect.boundingBox()
  expect(searchBox).not.toBeNull()
  expect(filterBox).not.toBeNull()
  expect(sortBox).not.toBeNull()
  expect(Math.abs(searchBox!.y - filterBox!.y)).toBeLessThanOrEqual(1.5)
  expect(Math.abs(searchBox!.y - sortBox!.y)).toBeLessThanOrEqual(1.5)
  expect(Math.abs(searchBox!.height - filterBox!.height)).toBeLessThanOrEqual(1.5)
  expect(Math.abs(searchBox!.height - sortBox!.height)).toBeLessThanOrEqual(1.5)

  await page.reload()
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  await page.waitForFunction(() => window.localStorage.getItem('todo_app_theme') === 'dark', { timeout: 5000 })
  await page.waitForFunction(() => document.documentElement.classList.contains('dark'), { timeout: 5000 })
})
