import { test, expect } from '@playwright/test'

test('typed phoenix channel ping/pong works', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 20000 })

  await expect
    .poll(async () => await page.evaluate(() => (window as any).__typed_channel_last_pong || null), { timeout: 15000 })
    .not.toBeNull()
})

