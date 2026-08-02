import {expect, test} from "@playwright/test"

test("plain TypeScript LiveReact sends typed events and keeps a native fallback", async ({page}) => {
  const base = process.env.BASE_URL || "http://localhost:4018"
  page.on("console", (message) => console.log(`[browser:${message.type()}] ${message.text()}`))
  page.on("pageerror", (error) => console.log(`[browser:pageerror] ${error.message}`))

  await page.goto(base + "/")
  await expect(page.getByRole("heading", {name: "Signal console"})).toBeVisible()
  await expect(page.getByTestId("pulse-count")).toHaveText("00")

  await page.getByTestId("transmit-pulse").click()
  await expect(page.getByTestId("pulse-count")).toHaveText("01")
  await expect(page.getByTestId("server-status")).toHaveText("Server received ALPHA pulse 01.")

  await page.getByTestId("cycle-channel").click()
  await expect(page.getByTestId("cycle-channel")).toContainText("BETA")
  await page.getByTestId("transmit-pulse").click()
  await expect(page.getByTestId("pulse-count")).toHaveText("02")
  await expect(page.getByTestId("server-status")).toHaveText("Server received BETA pulse 02.")

  await page.getByTestId("native-fallback").getByText("Native LiveView fallback").click()
  await page.getByTestId("native-transmit-pulse").click()
  await expect(page.getByTestId("pulse-count")).toHaveText("03")
  await expect(page.getByTestId("server-status")).toHaveText("Server received BETA pulse 03.")
})
