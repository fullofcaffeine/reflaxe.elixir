import {describe, expect, it} from "vitest"
import {
  decodePreferenceChangedPayload,
  decodePreferenceStudioInput,
  PREFERENCE_CHANGED_EVENT,
} from "./preference-studio-contract"

describe("PreferenceStudio wire contract", () => {
  it("accepts only the closed public input", () => {
    expect(decodePreferenceStudioInput({title: "Conversation density", density: "focused"})).toEqual({
      title: "Conversation density",
      density: "focused",
    })
    expect(() => decodePreferenceStudioInput({title: "Density", density: "focused", pushEvent: "leak"})).toThrow(
      /keys must be exactly/,
    )
    expect(() => decodePreferenceStudioInput({title: "Density", density: "unknown"})).toThrow(/must be calm/)
    expect(() => decodePreferenceStudioInput({title: "x".repeat(600), density: "focused"})).toThrow()
  })

  it("accepts one exact event payload", () => {
    expect(PREFERENCE_CHANGED_EVENT).toBe("preference_changed")
    expect(decodePreferenceChangedPayload({density: "dense"})).toEqual({density: "dense"})
    expect(() => decodePreferenceChangedPayload({density: "dense", extra: true})).toThrow(/keys must be exactly/)
    expect(() => decodePreferenceChangedPayload({density: "loud"})).toThrow(/must be calm/)
  })
})
