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

