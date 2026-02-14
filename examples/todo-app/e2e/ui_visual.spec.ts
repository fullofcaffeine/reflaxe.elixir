import { test, expect, type Page } from '@playwright/test'

const BASE_URL = process.env.BASE_URL || 'http://localhost:4001'

async function waitForLiveView(page: Page): Promise<void> {
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
}

async function login(page: Page, base: string, name: string, email: string): Promise<void> {
  await page.goto(base + '/login')
  await waitForLiveView(page)

  const loginForm = page.locator('form[action="/auth/login"]').filter({
    has: page.locator('input[name="name"][type="text"]'),
  }).first()

  await loginForm.locator('input[name="name"][type="text"]').fill(name)
  await loginForm.locator('input[name="email"][type="email"]').fill(email)
  await loginForm.getByRole('button', { name: /continue/i }).click()

  await page.waitForURL('**/todos', { timeout: 15000 })
  await waitForLiveView(page)
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
    const visualDomain = 'visual-auth-row.example.com'
    const adminName = 'Visual Admin'
    const adminEmail = `admin@${visualDomain}`
    const memberName = 'Visual Member'
    const memberEmail = `member@${visualDomain}`

    await page.addInitScript(() => {
      window.localStorage.setItem('todo_app_theme', 'light')
    })

    // Ensure deterministic signed-in state for auth-row screenshots:
    // first user in org becomes admin; second user stays regular (no Admin pill in auth row).
    await login(page, BASE_URL, adminName, adminEmail)
    await page.getByTestId('nav-sign-out').click()
    await page.waitForURL('**/', { timeout: 10000 })
    await login(page, BASE_URL, memberName, memberEmail)

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

    await expect(authRow).toHaveScreenshot('todo-nav-auth-row.signed-in.light.png', {
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

    await expect(authRow).toHaveScreenshot('todo-nav-auth-row.signed-in.dark.png', {
      animations: 'disabled',
      caret: 'hide',
      maxDiffPixelRatio: 0.001,
      scale: 'css',
    })
  })
})
