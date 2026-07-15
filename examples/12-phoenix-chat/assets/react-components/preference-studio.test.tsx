// @vitest-environment jsdom

import {cleanup, render, screen} from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import {afterEach, describe, expect, it, vi} from "vitest"
import {PreferenceStudioBoundary} from "./preference-studio-boundary"
import {PreferenceStudio} from "./preference-studio"

afterEach(cleanup)

describe("PreferenceStudio", () => {
  it("keeps draft state local until the user applies it", async () => {
    const user = userEvent.setup()
    const onPreferenceChanged = vi.fn()
    render(
      <PreferenceStudio title="Conversation density" density="focused" onPreferenceChanged={onPreferenceChanged} />,
    )

    expect(screen.getByTestId("preference-map").parentElement?.getAttribute("data-density")).toBe("focused")
    await user.click(screen.getByRole("button", {name: /Dense/}))
    expect(screen.getByTestId("preference-map").parentElement?.getAttribute("data-density")).toBe("dense")
    expect(onPreferenceChanged).not.toHaveBeenCalled()
    await user.click(screen.getByRole("button", {name: "Apply dense"}))
    expect(onPreferenceChanged).toHaveBeenCalledWith({density: "dense"})
  })

  it("narrows stock live_react to the exact event", async () => {
    const user = userEvent.setup()
    const pushEvent = vi.fn()
    render(<PreferenceStudioBoundary title="Conversation density" density="calm" pushEvent={pushEvent} />)

    await user.click(screen.getByRole("button", {name: /Focused/}))
    await user.click(screen.getByRole("button", {name: "Apply focused"}))
    expect(pushEvent).toHaveBeenCalledWith("preference_changed", {density: "focused"})
  })

  it("fails closed while leaving the outer native fallback available", () => {
    render(
      <PreferenceStudioBoundary
        title="Conversation density"
        density="focused"
        pushEvent={vi.fn()}
        unexpected="not-public"
      />,
    )
    expect(screen.getByTestId("preference-studio-error").textContent).toContain("Unexpected PreferenceStudio input")
  })
})
