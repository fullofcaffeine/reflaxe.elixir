import { test, expect } from '@playwright/test'

const baseUrl = () => process.env.BASE_URL || 'http://localhost:4001'

test('Haxe-authored React insights drive the typed LiveView filter event', async ({ page }) => {
  await page.goto(baseUrl() + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  const nativeFallback = page.getByTestId('todo-insights-native-fallback')
  const reactIsland = page.getByTestId('todo-insights')

  await expect(nativeFallback).toContainText('LiveView summary:')
  await expect(reactIsland).toHaveAttribute('data-active-filter', 'all')

  await page.getByTestId('insights-filter-completed').click()

  await expect(reactIsland).toHaveAttribute('data-active-filter', 'completed')
  await expect(page.locator("button[phx-click='filter_todos'][phx-value-filter='completed']")).toHaveClass(/todo-filter-btn-active/)
  await expect(nativeFallback).toBeVisible()
})

test('native LiveView summary stays useful when browser JavaScript is disabled', async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false })
  const page = await context.newPage()

  try {
    await page.goto(baseUrl() + '/todos')

    await expect(page.getByTestId('todo-insights-native-fallback')).toContainText('LiveView summary:')
    await expect(page.locator('#todo-list')).toHaveCount(1)
    await expect(page.getByTestId('todo-insights')).toHaveCount(0)
  } finally {
    await context.close()
  }
})
