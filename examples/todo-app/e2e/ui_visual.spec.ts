import { test, expect, type Page } from '@playwright/test'

const BASE_URL = process.env.BASE_URL || 'http://localhost:4001'

async function waitForLiveView(page: Page): Promise<void> {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
}

async function disableMotion(page: Page): Promise<void> {
  await page.addStyleTag({
    content: `
      *,
      *::before,
      *::after {
        animation: none !important;
        transition: none !important;
      }
    `,
  })
}

test.describe('visual regression: todo ui key regions', () => {
  test.use({ viewport: { width: 1365, height: 768 } })

  test('controls row + auth row visuals remain stable in light/dark themes', async ({ page }) => {
    await page.addInitScript(() => {
      window.localStorage.setItem('todo_app_theme', 'light')
    })

    await page.goto(BASE_URL + '/todos')
    await waitForLiveView(page)
    await disableMotion(page)

    const controlsRow = page.getByTestId('todo-controls-row')
    const authRow = page.getByTestId('todo-nav-auth-row')
    await expect(controlsRow).toBeVisible()
    await expect(authRow).toBeVisible()

    await expect(controlsRow).toHaveScreenshot('todo-controls-row.light.png', {
      animations: 'disabled',
      caret: 'hide',
      maxDiffPixelRatio: 0.001,
      scale: 'css',
    })

    await page.getByTestId('nav-theme-toggle').click()
    await page.waitForFunction(() => document.documentElement.classList.contains('dark'), { timeout: 5000 })

    await expect(controlsRow).toHaveScreenshot('todo-controls-row.dark.png', {
      animations: 'disabled',
      caret: 'hide',
      maxDiffPixelRatio: 0.001,
      scale: 'css',
    })

    await expect(authRow).toHaveScreenshot('todo-nav-auth-row.dark.png', {
      animations: 'disabled',
      caret: 'hide',
      maxDiffPixelRatio: 0.001,
      scale: 'css',
    })
  })
})
