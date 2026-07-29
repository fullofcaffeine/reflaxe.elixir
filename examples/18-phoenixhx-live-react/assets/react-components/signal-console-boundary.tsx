import {SignalConsole} from "./signal-console"

export type SignalConsoleRawProps = Record<string, unknown>

interface SignalConsoleInput {
  readonly title: string
}

const publicInputKeys = new Set(["title"])
const nativeBridgeKeys = new Set([
  "pushEvent",
  "pushEventTo",
  "handleEvent",
  "removeHandleEvent",
  "upload",
  "uploadTo",
])

function decodeSignalConsoleInput(value: Record<string, unknown>): SignalConsoleInput {
  if (Object.keys(value).length !== 1 || typeof value.title !== "string" || value.title.trim() === "") {
    throw new Error("SignalConsole expects exactly one non-empty string prop: title")
  }
  return {title: value.title}
}

/**
 * Trusted stock LiveReact adapter. It narrows capabilities for a first-party
 * component; it is not a sandbox for untrusted React code.
 */
export function SignalConsoleBoundary(raw: SignalConsoleRawProps) {
  try {
    const publicInput: Record<string, unknown> = {}
    for (const [key, candidate] of Object.entries(raw)) {
      if (nativeBridgeKeys.has(key)) continue
      if (!publicInputKeys.has(key)) throw new Error("Unexpected SignalConsole input: " + key)
      publicInput[key] = candidate
    }

    const input = decodeSignalConsoleInput(publicInput)
    return <SignalConsole {...input} />
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown React boundary error"
    return (
      <section role="alert" data-live-react-boundary="error">
        <strong>SignalConsole is unavailable.</strong>
        <span>{message}</span>
      </section>
    )
  }
}
