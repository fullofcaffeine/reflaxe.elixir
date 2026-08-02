import type {LiveProps} from "live_react"
import {SignalConsole} from "./signal-console"
import {pushPulse} from "./signal-console-events.generated"

type PushEvent = LiveProps["pushEvent"]

export type SignalConsoleRawProps = Record<string, unknown> & {
  readonly pushEvent: PushEvent
}

interface SignalConsoleInput {
  readonly title: string
  readonly pulseCount: number
}

const publicInputKeys = new Set(["title", "pulseCount"])
const nativeBridgeKeys = new Set([
  "pushEvent",
  "pushEventTo",
  "handleEvent",
  "removeHandleEvent",
  "upload",
  "uploadTo",
])

function decodeSignalConsoleInput(value: Record<string, unknown>): SignalConsoleInput {
  if (
    Object.keys(value).length !== 2 ||
    typeof value.title !== "string" ||
    value.title.trim() === "" ||
    typeof value.pulseCount !== "number" ||
    !Number.isInteger(value.pulseCount) ||
    value.pulseCount < 0
  ) {
    throw new Error("SignalConsole expects a title and a non-negative integer pulseCount")
  }
  return {title: value.title, pulseCount: value.pulseCount}
}

/**
 * Trusted stock LiveReact adapter. It narrows capabilities for a first-party
 * component; it is not a sandbox for untrusted React code.
 */
export function SignalConsoleBoundary(raw: SignalConsoleRawProps) {
  try {
    if (typeof raw.pushEvent !== "function") {
      throw new Error("live_react did not provide pushEvent")
    }
    const publicInput: Record<string, unknown> = {}
    for (const [key, candidate] of Object.entries(raw)) {
      if (nativeBridgeKeys.has(key)) continue
      if (!publicInputKeys.has(key)) throw new Error("Unexpected SignalConsole input: " + key)
      publicInput[key] = candidate
    }

    const input = decodeSignalConsoleInput(publicInput)
    return (
      <SignalConsole
        {...input}
        onPulse={(channel) => pushPulse(raw.pushEvent, {channel})}
      />
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown React boundary error"
    return (
      <section role="alert" data-live-react-boundary="error">
        <strong>SignalConsole is unavailable.</strong>
        <span>Use the native LiveView control below. {message}</span>
      </section>
    )
  }
}
