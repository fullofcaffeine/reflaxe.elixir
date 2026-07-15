import AxeBuilder from '@axe-core/playwright'
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

test('Crema invitation preserves native form state and the closed React boundary', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'

  await page.goto(base + '/crema')
  await expect(page).toHaveTitle(/Morrow Field Office/)
  await expect(page.getByRole('heading', {name: /Build in company/i})).toBeVisible()
  await expect(page.getByTestId('preference-studio')).toBeVisible()

  await page.getByRole('button', {name: /Prepare my request/i}).click()
  await expect(page.getByTestId('crema-request-status')).toContainText('Add a name')

  await page.getByLabel('Your name').fill('Ada Lovelace')
  await page.getByLabel('Correspondence').fill('ada@example.test')
  await page
    .getByLabel('The question on your desk')
    .fill('I am building a calmer way for research teams to compare consequential ideas.')
  await page.getByRole('button', {name: /Prepare my request/i}).click()
  await expect(page.getByTestId('crema-request-status')).toContainText('ready for review')
  await expect(page.getByTestId('crema-request-status')).toContainText('before storage')

  await page.getByRole('button', {name: /Dense/}).click()
  await expect(page.getByTestId('preference-studio')).toHaveAttribute('data-density', 'dense')
  await page.getByRole('button', {name: 'Apply dense'}).click()
  await expect(page.getByTestId('crema-preference-status')).toHaveText('Working density set to Dense.')

  await page.getByTestId('crema-preference-fallback').getByText('Use native LiveView controls').click()
  await page.getByRole('button', {name: 'Use Calm native mode'}).click()
  await expect(page.getByTestId('crema-preference-status')).toHaveText('Working density set to Calm.')
})

test('Crema invitation has no automatically detectable accessibility violations', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'

  await page.goto(base + '/crema')
  await expect(page.getByTestId('preference-studio')).toBeVisible()
  const results = await new AxeBuilder({page}).analyze()
  expect(results.violations).toEqual([])
})

test('Crema invitation remains bounded and reviewable at three representative widths', async ({ page }, testInfo) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const viewports = [
    {name: 'mobile-390', width: 390, height: 844},
    {name: 'tablet-768', width: 768, height: 1024},
    {name: 'desktop-1440', width: 1440, height: 1000},
  ]

  for (const viewport of viewports) {
    await page.setViewportSize({width: viewport.width, height: viewport.height})
    await page.goto(base + '/crema')
    await expect(page.getByRole('heading', {name: /Build in company/i})).toBeVisible()
    const dimensions = await page.evaluate(() => ({
      body: document.body.scrollWidth,
      viewport: document.documentElement.clientWidth,
    }))
    expect(dimensions.body).toBeLessThanOrEqual(dimensions.viewport)
    await testInfo.attach(`crema-${viewport.name}`, {
      body: await page.screenshot({fullPage: true, animations: 'disabled'}),
      contentType: 'image/png',
    })
  }
})
