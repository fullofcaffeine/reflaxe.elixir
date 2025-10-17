const { chromium } = require('playwright');
(async () => {
  const port = process.env.PORT || '4001';
  const base = `http://localhost:${port}`;
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  try {
    await page.goto(`${base}/todos`, { waitUntil: 'domcontentloaded' });
    // Open form
    await page.locator('button[phx-click="toggle_form"]').first().click();
    const title = `E2E Todo ${Date.now()}`;
    await page.fill('form[phx-submit="create_todo"] input[name="title"]', title);
    await page.click('form[phx-submit="create_todo"] button[type="submit"]');
    await page.waitForSelector(`text=${title}`, { timeout: 5000 });
    // Delete it: click delete within the container that has the title
    const item = page.locator('div', { hasText: title }).last();
    await item.locator('button[phx-click="delete_todo"]').click();
    // Ensure it disappears
    await page.waitForTimeout(600);
    const stillVisible = await page.isVisible(`text=${title}`);
    if (stillVisible) throw new Error('Todo still visible after delete');
    console.log('[E2E] Delete scenario passed');
    process.exit(0);
  } catch (err) {
    console.error('[E2E] Failure:', err && err.message ? err.message : err);
    await page.screenshot({ path: '/tmp/e2e-delete-failure.png' }).catch(() => {});
    process.exit(2);
  } finally {
    await page.close().catch(() => {});
    await browser.close().catch(() => {});
  }
})();
