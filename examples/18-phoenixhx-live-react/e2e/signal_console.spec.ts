import {expect, test} from "@playwright/test"

test("Genes boots and the LiveReact island hydrates", async ({page}) => {
  const base = process.env.BASE_URL || "http://localhost:4018"

  await page.goto(base + "/")
  await expect(page.getByRole("heading", {name: "Signal console"})).toBeVisible()
  await expect(page.getByTestId("pulse-count")).toHaveText("00")
  await expect.poll(() => page.evaluate(() => Boolean((window as any).__PHOENIXHX_GENES_BOOTED__))).toBe(true)

  await page.getByTestId("transmit-pulse").click()
  await expect(page.getByTestId("pulse-count")).toHaveText("01")

  await page.getByTestId("cycle-channel").click()
  await expect(page.getByTestId("cycle-channel")).toContainText("BETA")
})
