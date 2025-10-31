import { test, expect } from '@playwright/test'

test('sort by due date orders earliest first', async ({ page }) => {
  const base = process.env.BASE_URL || 'http://localhost:4001'
  await page.goto(base + '/todos')
  await page.waitForFunction('window.liveSocket && window.liveSocket.isConnected()', { timeout: 15000 })

  const mk = async (title: string, due: string) => {
    await page.getByTestId('btn-new-todo').click()
    const form = page.locator('form[phx-submit="create_todo"]').first()
    await expect(form).toBeVisible()
    await page.getByTestId('input-title').fill(title)
    // Set due date (scoped to the create form) using fill for better compatibility
    const dueInput = form.locator('input[name="due_date"]').first()
    await dueInput.evaluate((el, val) => {
      const input = el as HTMLInputElement
      input.setAttribute('value', val as string)
      ;(input as any).defaultValue = val
      input.value = val as string
      input.dispatchEvent(new Event('input', { bubbles: true }))
      input.dispatchEvent(new Event('change', { bubbles: true }))
    }, due)
    await page.getByTestId('btn-create-todo').click()
    await expect.poll(async () => await page.locator('[data-testid="todo-card"] h3', { hasText: title }).count(), { timeout: 20000 }).toBeGreaterThan(0)
  }

  const tEarly = `DueEarly ${Date.now()}`
  const tLate = `DueLate ${Date.now()}`
  const today = new Date()
  const pad = (n: number) => n.toString().padStart(2, '0')
  const y = today.getFullYear()
  const m = pad(today.getMonth() + 1)
  const d = pad(today.getDate())
  const tomorrow = new Date(today.getTime() + 86400000)
  const y2 = tomorrow.getFullYear()
  const m2 = pad(tomorrow.getMonth() + 1)
  const d2 = pad(tomorrow.getDate())
  await mk(tLate, `${y2}-${m2}-${d2}`)
  await mk(tEarly, `${y}-${m}-${d}`)

  await page.selectOption('select[name="sort_by"]', 'due_date')
  await page.waitForTimeout(300)

  const titles = await page.locator('[data-testid="todo-card"] h3').allTextContents()
  const iEarly = titles.findIndex(t => t.includes(tEarly))
  const iLate = titles.findIndex(t => t.includes(tLate))
  expect(iEarly).toBeGreaterThanOrEqual(0)
  expect(iLate).toBeGreaterThanOrEqual(0)
  // Earliest first → tEarly before tLate
  expect(iEarly).toBeLessThan(iLate)
})
