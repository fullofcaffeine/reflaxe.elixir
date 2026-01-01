import { test, expect } from '@playwright/test'

test('profile updates broadcast to todos (name + bio)', async ({ page, context }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  const unique = Date.now()
  const email = `alice_profile_${unique}@example.com`
  const originalName = `Alice ${unique}`
  const updatedName = `Alice Updated ${unique}`
  const bio = `Hello from Haxe ${unique}`

  // Sign in via the demo login flow
  await page.goto(base + '/login')
  const loginForm = page.locator('form[action="/auth/login"]').filter({
    has: page.locator('input[name="name"][type="text"]'),
  }).first()
  await loginForm.locator('input[name="name"][type="text"]').fill(originalName)
  await loginForm.locator('input[name="email"][type="email"]').fill(email)
  await loginForm.getByRole('button', { name: /continue/i }).click()

  await page.waitForURL(/\/todos$/, { timeout: 15000 })
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })
  await expect(page.locator('body')).toContainText(`Welcome, ${originalName}!`)

  // Keep the todos LV connected while updating profile on a second page (same session cookie).
  const profilePage = await context.newPage()
  await profilePage.goto(base + '/profile')
  await profilePage.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 10000 })

  await profilePage.getByTestId('input-profile-name').fill(updatedName)
  await profilePage.getByTestId('input-profile-bio').fill(bio)
  await profilePage.getByTestId('btn-save-profile').click()

  await expect(profilePage.getByTestId('flash-info')).toContainText(/Profile updated/i)
  await expect(profilePage.locator('body')).toContainText(updatedName)
  await expect(profilePage.locator('body')).toContainText(bio)

  // Verify the running TodoLive receives the profile update via PubSub and refreshes UI.
  await expect(page.locator('body')).toContainText(`Welcome, ${updatedName}!`, { timeout: 15000 })
  await expect(page.locator('[data-testid="online-user"]').filter({ hasText: updatedName })).toBeVisible({ timeout: 15000 })
})
