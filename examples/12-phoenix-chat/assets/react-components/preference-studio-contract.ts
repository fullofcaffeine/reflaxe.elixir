import {
  MAX_EVENT_PAYLOAD_BYTES,
  MAX_PUBLIC_INPUT_BYTES,
  PREFERENCE_CHANGED_EVENT,
  PREFERENCE_DENSITIES,
} from "./binding-contract.generated"

export type PreferenceDensity = (typeof PREFERENCE_DENSITIES)[number]

export interface PreferenceStudioInput {
  readonly title: string
  readonly density: PreferenceDensity
}

export interface PreferenceChangedPayload {
  readonly density: PreferenceDensity
}

export {PREFERENCE_CHANGED_EVENT}

export function decodePreferenceStudioInput(value: unknown): PreferenceStudioInput {
  const input = exactObject(value, ["title", "density"], "PreferenceStudio input", MAX_PUBLIC_INPUT_BYTES)
  const title = input.title
  if (typeof title !== "string" || title.trim().length === 0 || title.length > 80) {
    throw new Error("PreferenceStudio title must contain 1 to 80 characters")
  }
  if (!isPreferenceDensity(input.density)) {
    throw new Error("PreferenceStudio density must be calm, focused, or dense")
  }
  return {title, density: input.density}
}

export function decodePreferenceChangedPayload(value: unknown): PreferenceChangedPayload {
  const payload = exactObject(value, ["density"], "preference_changed payload", MAX_EVENT_PAYLOAD_BYTES)
  if (!isPreferenceDensity(payload.density)) {
    throw new Error("preference_changed density must be calm, focused, or dense")
  }
  return {density: payload.density}
}

export function isPreferenceDensity(value: unknown): value is PreferenceDensity {
  return typeof value === "string" && PREFERENCE_DENSITIES.some((density) => density === value)
}

function exactObject(
  value: unknown,
  allowedKeys: readonly string[],
  label: string,
  maxBytes: number,
): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} must be an object`)
  }
  const input = value as Record<string, unknown>
  const actualKeys = Object.keys(input).sort()
  const expectedKeys = [...allowedKeys].sort()
  if (JSON.stringify(actualKeys) !== JSON.stringify(expectedKeys)) {
    throw new Error(`${label} keys must be exactly ${expectedKeys.join(", ")}`)
  }
  const bytes = new TextEncoder().encode(JSON.stringify(input)).byteLength
  if (bytes > maxBytes) {
    throw new Error(`${label} exceeds its ${maxBytes}-byte JSON budget`)
  }
  return input
}
