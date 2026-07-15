import type {LiveProps} from "live_react"
import {PreferenceStudio} from "./preference-studio"
import {
  decodePreferenceChangedPayload,
  decodePreferenceStudioInput,
  PREFERENCE_CHANGED_EVENT,
} from "./preference-studio-contract"

type PushEvent = LiveProps["pushEvent"]

export interface LiveReactRawProps extends Record<string, unknown> {
  readonly pushEvent: PushEvent
}

const publicInputKeys = new Set(["title", "density"])
const nativeBridgeKeys = new Set([
  "pushEvent",
  "pushEventTo",
  "handleEvent",
  "removeHandleEvent",
  "upload",
  "uploadTo",
])

/**
 * Trusted native adapter around stock live_react.
 *
 * Upstream injects a broader LiveView bridge into this component. This adapter
 * validates the exact public JSON surface and passes only a typed callback to
 * PreferenceStudio. It is a capability-narrowing convention, not a sandbox for
 * untrusted React code.
 */
export function PreferenceStudioBoundary(raw: LiveReactRawProps) {
  try {
    if (typeof raw.pushEvent !== "function") {
      throw new Error("live_react did not provide pushEvent")
    }
    const publicInput: Record<string, unknown> = {}
    for (const [key, value] of Object.entries(raw)) {
      if (nativeBridgeKeys.has(key)) continue
      if (!publicInputKeys.has(key)) throw new Error(`Unexpected PreferenceStudio input: ${key}`)
      publicInput[key] = value
    }
    const input = decodePreferenceStudioInput(publicInput)
    return (
      <PreferenceStudio
        {...input}
        onPreferenceChanged={(candidate) => {
          const payload = decodePreferenceChangedPayload(candidate)
          raw.pushEvent(PREFERENCE_CHANGED_EVENT, payload)
        }}
      />
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown component boundary error"
    return (
      <section className="preference-studio preference-studio--invalid" role="alert" data-testid="preference-studio-error">
        <p className="preference-studio__eyebrow">React boundary rejected</p>
        <strong>Native controls remain available.</strong>
        <span>{message}</span>
      </section>
    )
  }
}
