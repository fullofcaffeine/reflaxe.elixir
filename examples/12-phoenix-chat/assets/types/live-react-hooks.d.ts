import type {ComponentType} from "react"

/** Closed local declaration over the stock runtime surface used by this proof. */
export interface LiveProps {
  readonly pushEvent: (
    event: string,
    payload?: object,
    onReply?: (reply: Record<string, unknown>) => void,
  ) => Promise<unknown> | void
  readonly pushEventTo: (
    target: string | HTMLElement,
    event: string,
    payload?: object,
    onReply?: (reply: Record<string, unknown>) => void,
  ) => Promise<unknown> | void
  readonly handleEvent: (event: string, callback: (payload: Record<string, unknown>) => void) => string
  readonly removeHandleEvent: (callbackRef: string) => void
  readonly upload: (name: string, files: FileList | File[]) => void
  readonly uploadTo: (target: string, name: string, files: FileList | File[]) => void
}

// Component props are intentionally opaque at this native upstream seam. Each
// registered boundary validates and narrows its own exact public input.
export function getHooks<T extends Readonly<Record<string, ComponentType<any>>>>(
  components: T,
): Readonly<Record<"ReactHook", object>>
